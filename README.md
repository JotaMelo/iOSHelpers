(essas classes foram feitas para uso interno na iOasys. Você eventual internauta™ que caiu aqui fique a vontade para usar como quiser, mas a documentação abaixo foi feita com esses usuários especificos em mente)

# **API** #

Classe base de API, com suporte a cache.
Automaticamente faz um multipart/form-data se algum dos parametros for NSData ou um NSArray de NSData.

Usa minha versão modificada do AFNetworking, use a seguinte linha no Podfile:

```ruby
pod "AFNetworking", :git => "https://github.com/jpmfagundes/AFNetworking.git", :commit => "64741e8d341de802093371b6d8f805fe62d60cc5"
```

O primeiro passo é alterar as seguintes três constants no topo do arquivo .m

```objc
NSString * const APIBaseURL       = @"http://example.com";
NSString * const APIPath          = @"/api/v1/";
NSString * const APIErrorDomain   = @"com.company.project.api";
```

Há dois métodos para criar um request de maneira fácil

```objc
+ (instancetype _Nonnull)make:(NSString * _Nonnull)method
              requestWithPath:(NSString * _Nonnull)path
                   parameters:(NSDictionary * _Nullable)parameters
                  cacheOption:(APICacheOption)cacheOption
                   completion:(APIResponseBlock _Nullable)block;
```

O método simplificado, recebe 5 parametros:
* ```method``` método HTTP da request (GET, POST, etc, use as constants)
* ```path``` path relativo a base URL setada anteriormente
* ```parameters``` dicionario com os parametros a serem enviados (enviados como JSON para o servidor)
* ```cacheOption``` a opção de cache (mais detalhes abaixo)
* ```block``` o block a ser chamado com a resposta da request



E o segundo método:
```objc
+ (instancetype _Nonnull)make:(NSString * _Nonnull)method
              requestWithPath:(NSString * _Nonnull)path
                      baseURL:(NSURL * _Nullable)baseURL
                   parameters:(NSDictionary * _Nullable)parameters
                 extraHeaders:(NSDictionary * _Nullable)extraHeaders
           suppressErrorAlert:(BOOL)suppressErrorAlert
                  uploadBlock:(APIProgressBlock _Nullable)uploadBlock
                downloadBlock:(APIProgressBlock _Nullable)downloadBlock
                  cacheOption:(APICacheOption)cacheOption
                   completion:(APIResponseBlock _Nullable)block;
```

Esse é o método mais completo, adiciona alguns parametros como:

* ```baseURL``` permitindo que voce altere a baseURL de um request específico
* ```extraHeaders``` um dicionário com headers adicionais a serem enviados no request
* ```suppressErrorAlert``` um ```BOOL``` que se verdadeiro impede que a classe emita o alerta de erro padrão
* ```uploadBlock``` e ```downloadBlock``` para acompanhar o progresso (de um envio de imagem, por exemplo).

Os dois retornam uma instancia da classe ```API```. Para fazer o request é só chamar o seguinte método na instancia criada:
```objc
- (NSURLSessionDataTask * _Nonnull)makeRequest;
```

Ele retorna uma ```NSURLSessionDataTask``` que pode ser cancelada com o método ```-[NSURLSessionDataTask cancel]```.


## **Cache** ##

São 3 opções de cache ao fazer o request:

* ```APICacheOptionCacheOnly``` - se o request estiver em cache, retorna no block **apenas** a resposta do cache, não fazendo um request. Porem se o request não estiver em cache, o request é feito.
* ```APICacheOptionNetworkOnly``` - ignora completamente o cache e faz o request, retornando apenas a resposta dele.
* ```APICacheOptionBoth``` - se o request estiver em cache, retorno no block a resposta do cache e, posteriormente, a resposta do request. Se o request não estiver em cache, retorna apenas a resposta do request.

O funcionamento do cache é simples: ele cria um nome de arquivo baseado em:
* Método HTTP
* Path
* Parametros e seus valores

Sempre com a extensão de arquivo ```.apicache``` e salva nesse arquivo os dados do ```responseObject```. 

Todo o cache é gerenciado pela classe ```APICacheManager```. Alem do cache em disco, também há um cache em memória. Por padrão tem um tamanho máximo de 1MB, mas esse tamanho pode ser configurado na propriedade ```inMemoryCacheMaxSize``` do ```APICacheManager```. Na inicialização dessa classe, todos os arquivos de cache sao carregados na memória ATÉ que o limite seja atingido. Caso o limite do cache seja atingido ao longo do uso do app, é feita uma otimização: são mantidos em memória os items mais acessados (essa contagem é feita internamente). 

Por padrão **todos** os requests são salvos no cache, mas em alguns casos é ideal desativar isso. Por exemplo, um request que você chama várias vezes com parametros diferentes sempre (pode acabar criando um alto volume de dados no aparelho do usuário), ou requests que incluam dados sensíveis. Então podemos desativar _por request_ o cache:

```objc
+ (NSURLSessionDataTask *)exampleRequestwithBlock:(APIResponseBlock)block
{
    API *request = [API make:APIMethodPOST requestWithPath:@"login" parameters:@{@"user": @"jota", @"senha": @"mansaothugstronda"} cacheOption:APICacheOptionBoth completion:block];
    request.shouldSaveCache = NO;
    
    return [request makeRequest];
}
```

## **Response block** ##

```objc
typedef void(^APIResponseBlock)(id _Nullable response, NSError * _Nullable error, BOOL cache);
```

O block de reposta dos requests, com 3 parametros:
* ```response``` - pode ser um ```NSDictionary```, ```NSArray``` ou ```NSString``` caso ocorra algum erro no parsing do JSON (talvez ocorreu um erro no servidor e foi retornada uma página HTML).
* ```error``` - ```nil``` se o request for OK. Caso contrário retorna um ```NSError``` direto do AFNetworking ou um erro criado por você caso tenha implementado error handling especifico (mais detalhes abaixo).


## **Error handling** ##

Por padrão a classe mostra um ```UIAlertView``` (sim, deprecated, eu sei, mas tem algumas facilidades **apenas** nesse uso especifico que ainda não estou pronto para abandonar. Mas não se preocupe, 0 warnings. Não usem APIs deprecated, crianças) com o ```localizedDescription``` do ```NSError```. Muitas vezes a API retorna uma resposta com uma descrição melhor do erro, então você pode modificar o error handling modificando o método:

```objc
+ (void)handleError:(NSError * _Nonnull)error withResponseObject:(id _Nullable)responseObject
{
    [API showErrorMessage:error.localizedDescription];
}
```

Nele voce tem acesso ao ```NSError``` e ao ```responseObject```. Decida qual vai ser a mensagem apresentada e chame o ```+[API showErrorMessage:]```.

## **E onde eu coloco meus metodos hein?** ##

Minha recomendação (e eu fiz essa classe com isso em mente) é que a classe ```API``` em si fique limpa e voce agrupe seus requests em diferentes subclasses da ```API```. Por exemplo, voce pode ter uma classe ```APIAuthentication``` com todos os requests de login, cadastro, esqueci senha etc, e outra ```APIUser``` com todos os requests relacionados ao usuario como atualizar perfil. 

Isso permite também uma maior costumização. Tive uma situação que em todos os requests relacionados ao usuário eu precisava enviar o email dele tambem, junto dos outros parametros do request. Vamos primeiro analisar o header da classe:

```objc
@property (strong, nonatomic, nonnull) NSString *method;
@property (strong, nonatomic, nonnull) NSString *path;
@property (strong, nonatomic, nullable) NSURL *baseURL;
@property (strong, nonatomic, nullable) NSDictionary *parameters;
@property (strong, nonatomic, nullable) NSDictionary *extraHeaders;

@property (assign, nonatomic) APICacheOption cacheOption;
@property (assign, nonatomic) BOOL suppressErrorAlert;

@property (copy, nonatomic, nullable) APIProgressBlock uploadBlock;
@property (copy, nonatomic, nullable) APIProgressBlock downloadBlock;
@property (copy, nonatomic, nullable) APIResponseBlock completionBlock;

@property (assign, nonatomic) BOOL shouldSaveCache;
@property (strong, nonatomic, nonnull) NSString *cacheFileName;
```

Tudo necessário para o request está nessas propriedades. E como são propriedades você pode implementar seus setters e/ou getters na sua subclasse para ter um comportamento diferente apenas naquela classe. Então como resolver o problema de sempre enviar o email do usuário sem realmente escrever isso em TODOS os requests? Exemplo real:

```objc
- (void)setParameters:(NSDictionary *)parameters
{
    NSString *userEmail = self.userEmail;
    
    if (userEmail) {
        if (!parameters) {
            [super setParameters:@{@"email": userEmail}];
        } else {
            NSMutableDictionary *updatedParameters = parameters.mutableCopy;
            updatedParameters[@"email"] = userEmail;
            
            [super setParameters:updatedParameters];
        }
    } else {
        [super setParameters:parameters];
    }
}
```

Implementando o setter da propriedade ```parameters```. Então sempre que for setado um valor nos parameters, eu tento enfiar um email junto lá, apenas nessa classe. As possibilidades são infinitas (ou quase isso).


## **Sim eu sei que dúvidas** ##

Talvez você se pergunte em um momento: *Uai... e como eu acesso os headers no response block, hein?*

Bem, não acessa. No nosso caso a maioria das vezes que precisamos de dados dos headers é relacionado a algo de autenticação como o **token**. 
Nesse caso a classe já vem com uma solução pronta pensada e ja ajustada para nossas APIs internas. Há um método (uma read-only property na verdade) ```-[API authenticationHeaders]``` que retorna um array de headers usados na authenticação. Em toda response é verificado se foram retornados esses headers e, se sim, são salvos no ```NSUserDefaults```. E ai no request esses headers, se presentes no ```NSUserDefaults```, são incluidos automaticamente. Então no seu método de login, por exemplo, você não precisaria se preocupar em persistir os dados de autenticação: tudo seria feito por voce.

Há também o ```-[API logout]``` que exclui os headers salvos.

Ok, ai mesmo depois disso tudo você ainda pergunta: *Porra mas eu preciso dos headers em altos lugares cara e ai??*

Claro, cada app é um app, vários casos diferentes, vários casos especificos. Essa classe foi feita pensando em ser mais generica possível para a **maioria** das APIs que lidamos por aqui. Algumas fogem disso, então sinta-se livre (mesmo!) para modificar ela do jeito que você quiser. Não só essa classe mas todas nesse repositório foram feitas com essa ideia: são uma base de fácil entendimento (eu tentei, juro) para que você adapte a sua necessidade.



# **Base Model** #

Inicialize um model a partir de um dicionário como _**mágica**_

Supondo que temos o seguinte JSON:
```json
{
    "id": "123",
    "user_name": "fulana22k",
    "email": "fulana22k@hotmail.com",
    "is_first_login": true,
    "register_date": "2015/08/21 15:45:45",
    "favorite_pizza": {
        "pizza_id": 5,
        "name": "Catuperoni",
        "number_of_ingredients": null
    },
    "OrderedPizzas": [{
        "pizza_id": 5,
        "name": "Catuperoni",
        "number_of_ingredients": null
    }, {
        "pizza_id": 10,
        "name": "Calabresa",
        "number_of_ingredients": null
    }]
}
```

Criamos as seguintes classes:
```objc
#import "BaseModel.h"

@interface Pizza : BaseModel

@property (assign, nonatomic) NSInteger pizzaID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *numberOfIngredients;

@end
```

```objc
#import "BaseModel.h"
#import "Pizza.h"

@protocol Pizza
@end

@interface User : BaseModel

@property (assign, nonatomic) NSInteger uid;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *email;
@property (assign, nonatomic) BOOL isFirstLogin;
@property (strong, nonatomic) NSDate *registerDate;
@property (strong, nonatomic) Pizza *favoritePizza;
@property (strong, nonatomic) NSArray<Pizza> *orderedPizzas;

@end
```

O que devemos notar:

* Nomes separados por underscore (``user_name``) são convertidos para camel case (``userName``)
* ``OrderedPizzas`` é convertido para ``orderedPizzas``
* Quando a ultima palavra é ``id`` como em ``pizza_id`` é convertido para ``pizzaID`` e não ``pizzaId`` porque né isso seria feio pra caralho
* ``id`` é convertido para ``uid``
* Se a classe da propriedade for uma subclasse do BaseModel, ele é automaticamente inicializado
* No caso de um array, voce pode declarar um protocolo (veja na classe User) com o mesmo nome da classe dos objetos desse array e usá-lo na propriedade que será automagicamente criado um array com objetos de tal classe. Note que isso é diferente dos ``Objetive-C generics``, infelizmente a informação dos generics é perdida após a compilação.
* No JSON, o ``id`` é uma string, mas na classe foi declarado como ``NSInteger``. Nesse caso tal string será automagicamente convertida.
* No geral, voce pode usar os tipos primitivos (BOOL, NSInteger, CGFloat etc), mas caso haja a possibilidade do valor vir ``null`` da API, como no caso do ``number_of_ingredients`` da pizza, deve ser declarado como NSNumber afinal um primitivo não poder ser ``nil``.

No ```BaseModel.m``` você precisa definir o formato de data que a API usa, nesse caso seria ```yyyy/MM/dd HH:mm:ss```

(inclusive tem um link muito bom de referencia pra formatação do ```NSDateFormatter```, guarde pra sua vida [http://waracle.net/iphone-nsdateformatter-date-formatting-table/](http://waracle.net/iphone-nsdateformatter-date-formatting-table/))

E então é só fazer:
```objc
User *user = [User initWithDictionary:dict];
```



Na classe Helper há um metodo para facilmente transformar uma NSArray de NSDictionaries em uma NSArray de BaseModels.

```objc
+ (NSArray *)transformDictionaryArray:(NSArray<NSDictionary *> *)array intoArrayOfModels:(Class)class
{
    NSMutableArray *newArray = [NSMutableArray new];
    
    for (NSDictionary *item in array) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id parsedItem = [class performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:item];
#pragma clang diagnostic pop
        [newArray addObject:parsedItem];
    }
    
    return newArray;
}
```
Pra usar:
```objc
NSArray *items = [self array:myArrayOfDictionaries ofClass:[User class]];
```
<hr>
O ```BaseModel``` conforma (conforma? sei la falar sobre isso em portugues) ao protocol NSCopying então voce pode criar uma cópia de qualquer model com um simples ```modelObject.copy```. 
<hr>
Você pode usar a propriedade ```modelDateFormat``` para alterar o formato de data apenas naquela instancia. Exemplo:

```objc
User *user = [User new];
user.modelDateFormat = @"yyyy-MM-DD";
user.originalDictionary = userDataDictionary;
```

O setter da propriedade ```originalDictionary``` é o responsavel por toda a _**mágica**_.
<hr>
Apesar de estar declarado diretamente na classe do model ```User```, o ```BaseModel``` declara a propriedade ```uid``` e a usa para implementar o ```-[BaseModel isEqual:]```. Métodos como o ```-[NSArray indexOfObject:]``` usam o ```isEqual``` para verificar se os objetos são iguais.
<hr>
O ```BaseModel``` também declara a propriedade ```dictionaryRepresentation```, ela cria um dicionário com os valores atuais das propriedades e com as mesmas keys que foram usadas no dicionário usado para inicializar o model. Mas atenção: se alguma propriedade não estava presente no dicionário original, também não estará presente no dicionario retornado pelo ```dictionaryRepresentation```. Por que? Bem, raramente o nome da propriedade será o mesmo da key usada na API (afinal a maioria usa _snake case_ e eu espero que voce não esteja usando essa atrocidade no seu código Objective-C), então eu não sei qual key deveria usar, portanto fica de fora. A ideia é ter uma representação atualizada do dicionário inicialmente usado.


~~Detalhe: use a flag ```-fno-objc-arc``` nos arquivos ```NSObject+Properties.m``` e ```NSString+PropertyKVC.m``` já que eles não suportam ARC.~~
_(reescrevi a porra toda em modern Objective-C e agora suporta ARC)_


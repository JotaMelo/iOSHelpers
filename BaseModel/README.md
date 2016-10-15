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


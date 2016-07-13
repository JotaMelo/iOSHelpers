# **API** #

Classe base de API, com suporte a cache.
Automaticamente faz um multipart/form-data se algum dos parametros for NSData ou um NSArray de NSData

Usa minha versão modificada do AFNetworking, use a seguinte linha no Podfile:

```
pod "AFNetworking", :git => "https://github.com/jpmfagundes/AFNetworking.git", :commit => "1fbd6a1fa9fc30f15cae03a6f01eb28b1705816a"
```


# **Base Model** #

É uma classe que uso pra transformar um dictionary de uma API por ex. direto numa classe.
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
+ (NSArray *)array:(NSArray *)array ofClass:(__unsafe_unretained Class)class
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

~~Detalhe: use a flag ```-fno-objc-arc``` nos arquivos ```NSObject+Properties.m``` e ```NSString+PropertyKVC.m``` já que eles não suportam ARC.~~
_(reescrevi a porra toda em Objective-C moderno e agora suporta ARC)_


# **JMGroupImageVIew** #

View para várias imagens, com suporte a 1, 2, 3 ou 4 imagens.
![iOS Simulator Screen Shot Aug 21, 2015, 2.48.48 AM.png](http://i.imgur.com/3Buddmt.png)

Depende do AFNetworking.
Para definir as imagens voce pode passar um array de UIImages, NSURLs ou NSStrings (que sejam URLs). Você pode configurar o espaçamento entre as imagens e o corner radius.

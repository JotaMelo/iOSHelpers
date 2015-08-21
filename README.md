# **API** #

Classe base de API, com suporte a cache. Tentei comentar algumas coisas pra ficar claro o que faz.

Usa versão modificada do AFNetworking, use a seguinte linha no Podfile:

```
pod "AFNetworking", :git => "https://github.com/jpmfagundes/AFNetworking.git", :commit => "5c9f74c24860ee03c3f6a30572651c3d3a86bffd"
```

# **Base Model** #

É uma classe que uso pra transformar um dictionary de uma API por ex. direto numa classe.
Supondo que temos o seguinte JSON:
```
{
	"id": "123",
	"user_name": "fulana22k",
	"email": "fulana22k@hotmail.com",
	"is_first_login": true,
	"register_date": "2015/08/21 15:45:45"
}
```

Criamos uma clase assim:
```
#import "BaseModel.h"

@interface User : BaseModel

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSNumber *isFirstLogin;
@property (strong, nonatomic) NSDate *registerDate;

@end
```
Note que os parametros com ```_``` são convertidos para camel case.

No ```BaseModel.m``` você precisa definir o formato de data que a API usa, nesse caso seria ```yyy/MM/dd HH:mm:ss```

(inclusive tem um link muito bom de referencia pra formatação do ```NSDateFormatter``` [http://waracle.net/iphone-nsdateformatter-date-formatting-table/](http://waracle.net/iphone-nsdateformatter-date-formatting-table/))

E então é só fazer:
```
User *user = [User initWithDictionary:dict];
```



Tem um método que uso pra facilmente transformar uma NSArray de NSDictionaries em uma NSArray de objetos de tal classe

```
+ (NSArray *)array:(NSArray *)array ofClass:(__unsafe_unretained Class)class
{
    NSMutableArray *newArray = [NSMutableArray new];
    
    for (NSDictionary *item in array) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id parsedItem = [[[class alloc] init] performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:item];
#pragma clang diagnostic pop
        [newArray addObject:parsedItem];
    }
    
    return newArray;
}
```
Pra usar:
```
NSArray *items = [self array:meuArrayDeDicionarios ofClass:[User class]];
```


Detalhe: use a flag ```-fno-objc-arc``` nos arquivos ```NSObject+Properties.m``` e ```NSString+PropertyKVC.m``` já que eles não suportam ARC.


# **JMGroupImageVIew** #

View para várias imagens, com suporte a 1, 2, 3 ou 4 imagens.
![iOS Simulator Screen Shot Aug 21, 2015, 2.48.48 AM.png](http://i.imgur.com/3Buddmt.png)

Depende do AFNetworking.
Para definir as imagens voce pode passar um array de UIImages, NSURLs ou NSStrings (que sejam URLs). Você pode configurar o espaçamento entre as imagens e o corner radius.
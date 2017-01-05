# **Update Notes** #

Essa versão da classe ```API``` é a primeira que inclui um número de versão. Em todos os headers voce vai encontrar: ```v1.0```

Nessa versão estou incluindo todo o meu projeto do Xcode, incluindo os testes.

Principais mudanças dessa versão:

### **Makers** ###

Os métodos principais de fazer requests tiveram uma mudança fundamental: apesar de os parametros continuarem os mesmos, agora eles retornam uma instancia da classe ```API``` e nao fazem o request imediatamente. Para fazer o request é necessário chamar o método ```-[API makeRequest]``` que retorna uma ```NSURLSessionDataTask```, como retornavam os makers nas versões anteriores. O principal motivo disso é facilitar a mudança de parametros do request após a inicialização, como por exemplo a propriedade ```shouldSaveCache```. Um exemplo de como fazer requests nessa versão:

```objc
+ (NSURLSessionDataTask *)exampleRequestwithBlock:(APIResponseBlock)block
{
    API *request = [API make:APIMethodPOST requestWithPath:@"login" parameters:@{@"user": @"jota", @"senha": @"mansaothugstronda"} cacheOption:APICacheOptionBoth completion:block];
    request.shouldSaveCache = NO;
    
    return [request makeRequest];
}
```

### **Autenticação** ###

Se estiver usando uma API interna nossa a classe já está preparada para persistir automaticamente os headers de autorização. Os 3 pontos importantes:

* Linha 76:
```objc
- (NSArray<NSString *> *)authenticationHeaders
{
    return @[@"access-token", @"client", @"uid"];
}
```

Uma read-only property que retorna um array dos headers de autenticação usados pela API, atualmente já preenchido com os headers usados nas nossas APIs.

* Linha 255
```objc
NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
for (NSString *headerName in self.authenticationHeaders) {
    if (response.allHeaderFields[headerName]) {
        if (![NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey]) {
            [NSUserDefaults.standardUserDefaults setObject:@{} forKey:APIAuthenticationHeadersDefaultsKey];
        }
        
        NSMutableDictionary *storedAuthenticationHeaders = [[NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey] mutableCopy];
        storedAuthenticationHeaders[headerName] = response.allHeaderFields[headerName];
        [NSUserDefaults.standardUserDefaults setObject:storedAuthenticationHeaders forKey:APIAuthenticationHeadersDefaultsKey];
    }
}
```

No response block, usando a propriedade citada anteriormente, é verificado se existe cada um dos headers na response e, se existe, persiste o valor dele no ```NSUserDefaults```.

* Linha 397
```objc
for (NSString *headerName in self.authenticationHeaders) {
    NSString *headerValue = [NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey][headerName];
    if (headerValue) {
        [manager.requestSerializer setValue:headerValue forHTTPHeaderField:headerName];
    }
}
```

Na preparação do request, é verificado se há valores salvos para os headers de autenticação e, se existe, é adicionado tal header na request.


### **Cache** ###

O sistema de cache foi totalmente reestruturado e ganhou sua própria classe: ```APICacheManager```

Agora gera um hash a partir dos valores do método, path e parametros em vez de uma string apenas concatenando esses valores. 

Foi adicionado um cache em memória. Tem um tamanho máximo, 1MB por padrão mas configurável pela propriedade ```inMemoryCacheMaxSize```. Na inicialização, carrega todos os arquivos para o cache em memória ATÉ o tamanho máximo. Caso o limite do cache seja atingido ao longo do uso do app, é feita uma otimização: os itens do cache em memória são ordenados pelo mais acessado (essa contagem é feita internamente) e a partir do mais acessado vai mantendo o máximo de itens possíveis até atingir o limite.


### **multipart/form-data** ###

Agora é adicionada a extensão do arquivo no "nome do arquivo", se conseguir ser identificada.

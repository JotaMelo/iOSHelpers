# **API** #

Classe base de API, com suporte a cache.
Automaticamente faz um multipart/form-data se algum dos parametros for NSData ou um NSArray de NSData

Usa minha versão modificada do AFNetworking, use a seguinte linha no Podfile:

```
pod "AFNetworking", :git => "https://github.com/jpmfagundes/AFNetworking.git", :commit => "1fbd6a1fa9fc30f15cae03a6f01eb28b1705816a"
```

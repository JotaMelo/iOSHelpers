# **API** #

Classe base de API, com suporte a cache.
Automaticamente faz um multipart/form-data se algum dos parametros for NSData ou um NSArray de NSData

Usa minha versão modificada do AFNetworking, use a seguinte linha no Podfile:

```
pod "AFNetworking", :git => "https://github.com/jpmfagundes/AFNetworking.git", :commit => "64741e8d341de802093371b6d8f805fe62d60cc5"
```

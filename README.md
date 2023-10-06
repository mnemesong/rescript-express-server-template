# rescript-express-server-template
extemdable rescript server and routes builder


## Example of usage
```rescript
//file ExpressPublicUsageCase.res
open ExpressServer
open ExpressHandler
open ExpressParseUrlHandlerConverter
open ExpressParseJsonHandlerConverter
open ExpressFileHandlerConverter
open! ExpressHandlerMiddleware

//Defaultly server await "handler" type = Handler(array<middlewares>, (req, res) => unit)
//Handler modules allow to modify request and response and write hanlder-func use
//this modified versions: (req' => res'), and convert this funciton
//into default "handler" type
module Default = MakeDefault(DefaultErrorStrategy) //default handler builder
module QueryConverter = ExpressParseUrlHandlerConverter.Make(Default)
module QueryHandler = Make( Default, QueryConverter ) //parse url handler
module JsonConverter = ExpressParseJsonHandlerConverter.Make(QueryHandler)
module JsonHandler = Make( QueryHandler, JsonConverter ) //parse json-post-body handler
module FileParseConfig: FileParseConfig = {
    let getFileAwaitFields: () => array<fileAwaitField> =
        () => [{name: "fileInp", maxCount: 1}]
    let getDestPath: () => string =
        () => "/uploads"
}
module FileConverter = 
    ExpressFileHandlerConverter.Make(JsonHandler, FileParseConfig)
module FileHandler = Make( JsonHandler, FileConverter ) //files loading handler

let indexPageHtml = `
<form action="/apply-post" method="post" enctype="multipart/form-data">
    <h1>Test form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="file" name="fileInp" style="display: block;">
    <input type="submit" style="display: block;">
</form>` //page html

let stringifyAny: ('a) => string = %raw(`function (u) {
    return u ? JSON.stringify(u) : ""
}`)

let routes = [
    Route(#get, "/", QueryHandler.handler(r => { //show form and show get-query
        let UrlReq(_, urlData) = r
        let unkToJson: (unknown) => string = %raw(`function(u) {
            return JSON.stringify(u) + ""
        }`)
        let urlDataStr = unkToJson(urlData)
        Html("Url data: " ++ urlDataStr ++ "<br><br>" ++ indexPageHtml)
    })),
    Route(#post, "/apply-post", FileHandler.handler(r => { //form handler and show data
        let FileReq(JsonReq(_, json), files) = r
        let json = `{"json": "${stringifyAny(json)}",
        "files": "${stringifyAny(files)}"}`
        Json(json)
    })),
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
```


## Express server
ExpressServer has simple signature to server running
```rescript
//file ExpressServer.res
open Belt

type request
type response
type middleware
type expressApp

type routeType =
    [ #checkout
    | #copy
    | #get
    | #delete
    | #head
    | #lock
    | #merge
    | #mkactivity
    | #mkcol
    | #move
    | #notify
    | #options
    | #patch
    | #post
    | #purge
    | #put
    | #report
    | #search
    | #subscribe
    | #trace
    | #unlock
    | #unsubscribe
    ]
type scenario = (request, response) => unit
type handler = Handler(array<middleware>, scenario)

type url = string

type route = Route(routeType, url, handler)

let runServer = (
    routes: array<route>,
    middlewares: array<middleware>,
    port: int,
    onInit: () => unit
): unit
```


## ExpressHandler
Defaultly server await handler: `type handler = Handler(array<middlewares>, (req, res) => unit)`
Handler modules allow to modify request and response and write hanlder-func use
this modified versions: `handler' = (req' => res')`, and convert this function
into default `handler` type.

```rescript
//file ExpressHandler.res

//Handler is some module with signature:
module type Handler = {
    type hReq
    type hRes

    let wrapReq: ((request, response)) => hReq
    let applyRes: (hReq, hRes) => unit
    let primalReq: (hReq) => (request, response)
    let convert: 
        (hReq => hRes) => (request, response) => unit
    let middlewares: array<middleware>
    let handler: (hReq => hRes) => handler
}
//which may be used as
...
Route(#get, "/", SomeHanderModule.handler(someF: req'=>res'))
//               ^will be converted into ------------------^
//                Handler(array<middlewares>, (request, response) => unit)
...
```
where `someF: req' => res'` is handler-function writen on confortable for coding and 
reading language. Handler module allows this funciton conversation.


## ExpressHandlerChain
Is a Module of Hanlder type which allows depends with some old Handler and
allowa chain of conversations. 

This modules defining with ExpressHandlerChain.Make functor:
```rescript
//file ExpressHandlerChain.res
module type Make = (
    OldHandler: Handler, 
    Converter: Converter //minimal module for building HandlerChain. See later..
        with type oldReq = OldHandler.hReq
        and type oldRes = OldHandler.hRes
) => Handler
    with type hReq = Converter.newReq
    and type hRes = Converter.newRes
```


## Default Handler
its required for be used as last chain part in handlers chain
```rescript
//file ExpressHandler.res
module DefaultErrorStrategy: ErrorStrategy = {
    let wrapTryCatch: (() => unit) => unit =
        (handler) => try {
            handler()
        } catch {
            | Js.Exn.Error(obj) => Js.Console.log(obj)
            | _ => Js.Console.log("unknown error")
        }
}
module type MakeDefault = (ErrorStrategy: ErrorStrategy) => Default
module MakeDefault: MakeDefault = (ErrorStrategy: ErrorStrategy) => ...
```


## ExpressHandlerConverter
is a minimal required module functionality for creation HandlerMiddleware chain.
```rescript
//file ExpressHandlerChain.res
module type Converter = {
    type oldReq
    type newReq
    type oldRes
    type newRes

    let wrapStepReq: (oldReq) => newReq
    let getOldReq: (newReq) => oldReq
    let applyStepRes: (newReq, newRes) => oldRes
    let middlewares: array<middleware>
}
```
Implement this module and you will make build chain of handlers


## Standart Handler Converters

### ExpressParseUrlHandlerConverter
needs for parsing params from url of GET request
```rescript
//file ExpressParseUrlHandlerConverter.res
type urlReq<'a> = UrlReq('a, unknown)

module type T = (OldHandler: Handler) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = urlReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler) => ...
```

### ExpressJsonHandlerConverter
needs for parsing json-request-body from POST request
```rescript
//file ExpressJsonHandlerConverter.res
type jsonReq<'a> = JsonReq('a, unknown)

module type T = (OldHandler: Handler) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = jsonReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler) => ...
```

### ExpressSessionHandlerConverter
needs for parsing session data and handle session-effects
```rescript
//file ExpressSessionHandlerConverter.res
type sessionReq<'a> = SessionReq('a, unknown)
type sessionEffect = 
    | SetSessionValue(string, unknown)
    | DestroySession
type sessionRes<'a> = SessionRes('a, array<sessionEffect>)

type sessionParam =
    | SessionResave(bool)
    | SessionSaveUnitialized(bool)
    | Cookie(bool, option<int>)

type sessionConfig = SessionConfig(string, array<sessionParam>)

module type SessionConfigurator ={
    let getSessionConfig: () => sessionConfig
}
//for example:
//module DefaultConfigurator: SessionConfigurator = {
//    let getSessionConfig: () => sessionConfig = 
//        () => SessionConfig("dksand9u7sa9db9", [])
//}

module type T = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = sessionReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = sessionRes<OldHandler.hRes>

module Make: T = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) => ...
```

### ExpressFileHandlerConverter
needs for building routes awaits file uploading and get access to files
```rescript
//file ExpressFileHandlerConverter.res
type fileAwaitField = {
    name: string,
    maxCount: int
}

type file = {
    fieldname: string,
    originalname: string,
    encoding: string,
    mimetype: string,
    destination: string,
    filename: string,
    path: string,
    size: int
}
type fileParsedField = {fileName: string, files: array<file>}
type fileReq<'a> = FileReq('a, array<fileParsedField>)

module type FileParseConfig = {
    let getFileAwaitFields: () => array<fileAwaitField>
    let getDestPath: () => string
}

module type T = (OldHandler: Handler, FileParseConfig: FileParseConfig) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = fileReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler, FileParseConfig: FileParseConfig) => ...
```


### ExpressAuthSessionHandlerConverter
needs for authentification using session.
Warning! in case of use with ExpressSessionHandlerConverter use same SessionManager
```rescript
type authSessReq<'r, 'u> = AuthSessReq('r, option<'u>)

type authSessEffect<'u> = 
    | Login('u)
    | Logout

type authSessRes<'r, 'u> = AuthSessRes('r, array<authSessEffect<'u>>)

module type UserManager = {
    type loginData
    type user
    type userCheckAuthData

    let produceAuthData: (user) => userCheckAuthData
    let checkAuthData: (userCheckAuthData) => option<user>
    let checkLoginData: (loginData) => option<user>
    let invalidLoginDataMsg: () => string
}

type sessionParam =
    | SessionResave(bool)
    | SessionSaveUnitialized(bool)
    | Cookie(bool, option<int>)

type sessionConfig = SessionConfig(string, array<sessionParam>)

module type SessionConfigurator ={
    let getSessionConfig: () => sessionConfig
}

module DefaultConfigurator: SessionConfigurator = {
    let getSessionConfig: () => sessionConfig = 
        () => SessionConfig("dksand9u7sa9db9", [])
}

module type T = (
    OldHandler: Handler, 
    UserManager: UserManager, 
    SessionConfigurator: SessionConfigurator
) => Converter
       with type oldReq = OldHandler.hReq
        and type newReq = authSessReq<OldHandler.hReq, UserManager.user>
        and type oldRes = OldHandler.hRes
        and type newRes = 
            authSessRes<OldHandler.hRes, UserManager.user>

module Make: T = (
    OldHandler: Handler, 
    UserManager: UserManager, 
    SessionConfigurator: SessionConfigurator
) => ...
```


## Author
Anatoly Starodubtsev
tostar74@mail.ru


# License
MIT
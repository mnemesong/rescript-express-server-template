# rescript-express-server-template
extemdable rescript server and routes builder


## Depends
- rescript-web-types: https://github.com/mnemesong/rescript-web-types


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


## ExpressServer.resi
ExpressServer has simple signature to server running
```rescript
open Belt
open WebTypes

type request
type response
type middleware
type expressApp

type scenario = (request, response) => unit
type handler = Handler(array<middleware>, scenario)

type url = string

type route = Route(method, url, handler)

let staticFilesMiddleware: string => middleware

let runServer: (array<route>, array<middleware>, int, unit => unit) => unit
```


## ExpressHandler.resi
Defaultly server await handler: `type handler = Handler(array<middlewares>, (req, res) => unit)`
Handler modules allow to modify request and response and write hanlder-func use
this modified versions: `handler' = (req' => res')`, and convert this function
into default `handler` type.
```rescript
open ExpressServer
open WebTypes

module type Handler = {
  type hReq
  type hRes

  let wrapReq: ((request, response)) => hReq
  let applyRes: (hReq, hRes) => unit
  let primalReq: hReq => (request, response)
  let convert: (hReq => hRes, request, response) => unit
  let middlewares: array<middleware>
  let handler: (hReq => hRes) => handler
}

type serverRespType =
  | Html(string)
  | Json(string)
  | OpenFile(string)
  | DownloadFile(string)
  | Redirect(string, redirectStatus)
  | Error(string, errorStatus)

module type Default = Handler with type hReq = (request, response) and type hRes = serverRespType

module type ErrorStrategy = {
  let wrapTryCatch: (unit => unit) => unit
}

module DefaultErrorStrategy: ErrorStrategy

module type MakeDefault = (ErrorStrategy: ErrorStrategy) => Default
//Default handler
module MakeDefault: MakeDefault
```
where `someF: req' => res'` is handler-function writen on confortable for coding and 
reading language. Handler module allows this funciton conversation.


## ExpressHandlerChain.resi
Is a Module of Hanlder type which allows depends with some old Handler and
allowa chain of conversations. 

This modules defining with ExpressHandlerChain.Make functor:
```rescript
open ExpressHandler
open ExpressServer
open Belt

module type Converter = {
  type oldReq
  type newReq
  type oldRes
  type newRes

  let wrapStepReq: oldReq => newReq
  let getOldReq: newReq => oldReq
  let applyStepRes: (newReq, newRes) => oldRes
  let middlewares: array<middleware>
}

module type MakeConverter = (OldHandler: Handler) =>
(Converter with type oldReq = OldHandler.hReq and type oldRes = OldHandler.hRes)

module type Make = (
  OldHandler: Handler,
  Converter: Converter with type oldReq = OldHandler.hReq and type oldRes = OldHandler.hRes,
) => (Handler with type hReq = Converter.newReq and type hRes = Converter.newRes)

module Make: Make
```


## ExpressHandlerConverter.resi
is a minimal required module functionality for creation HandlerMiddleware chain.
```rescript
open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type jsonReq<'a> = JsonReq('a, unknown)

module type Make = (OldHandler: Handler) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = jsonReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make
```
Implement this module and you will make build chain of handlers


## Standart Handler Converters

### ExpressParseUrlHandlerConverter.resi
needs for parsing params from url of GET request
```rescript
open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type urlReq<'a> = UrlReq('a, unknown)

module type Make = (OldHandler: Handler) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = urlReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make
```

### ExpressJsonHandlerConverter.resi
needs for parsing json-request-body from POST request
```rescript
open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type jsonReq<'a> = JsonReq('a, unknown)

module type Make = (OldHandler: Handler) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = jsonReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make
```

### ExpressSessionHandlerConverter.resi
needs for parsing session data and handle session-effects
```rescript
open ExpressHandler
open ExpressHandlerChain

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

let setSessionValue: (string, 'a) => sessionEffect

module type SessionConfigurator = {
  let getSessionConfig: unit => sessionConfig
}

module DefaultConfigurator: SessionConfigurator

module type Make = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = sessionReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = sessionRes<OldHandler.hRes>
)

module Make: Make
```

### ExpressFileHandlerConverter.resi
needs for building routes awaits file uploading and get access to files
```rescript
open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type fileAwaitField = {
  name: string,
  maxCount: int,
}

type file = {
  fieldname: string,
  originalname: string,
  encoding: string,
  mimetype: string,
  destination: string,
  filename: string,
  path: string,
  size: int,
}
type fileParsedField = {fileName: string, files: array<file>}
type fileReq<'a> = FileReq('a, array<fileParsedField>)

module type FileParseConfig = {
  let getFileAwaitFields: unit => array<fileAwaitField>
  let getDestPath: unit => string
}

module type Make = (OldHandler: Handler, FileParseConfig: FileParseConfig) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = fileReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make
```


### ExpressAuthSessionHandlerConverter.resi
needs for authentification using session.
Warning! in case of use with ExpressSessionHandlerConverter use same SessionManager
```rescript
open ExpressHandler
open ExpressHandlerChain

type authSessReq<'r, 'u> = AuthSessReq('r, option<'u>)

type authSessEffect<'u> =
  | Login('u)
  | Logout

type authSessRes<'r, 'u> = AuthSessRes('r, array<authSessEffect<'u>>)

module type UserManager = {
  type loginData
  type user
  type userCheckAuthData

  let produceAuthData: user => userCheckAuthData
  let checkAuthData: userCheckAuthData => option<user>
  let checkLoginData: loginData => option<user>
  let invalidLoginDataMsg: unit => string
}

type sessionParam =
  | SessionResave(bool)
  | SessionSaveUnitialized(bool)
  | Cookie(bool, option<int>)

type sessionConfig = SessionConfig(string, array<sessionParam>)

module type SessionConfigurator = {
  let getSessionConfig: unit => sessionConfig
}

module DefaultConfigurator: SessionConfigurator

module type Make = (
  OldHandler: Handler,
  UserManager: UserManager,
  SessionConfigurator: SessionConfigurator,
) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = authSessReq<OldHandler.hReq, UserManager.user>
    and type oldRes = OldHandler.hRes
    and type newRes = authSessRes<OldHandler.hRes, UserManager.user>
)

module Make: Make
```


## Author
Anatoly Starodubtsev
tostar74@mail.ru


# License
MIT
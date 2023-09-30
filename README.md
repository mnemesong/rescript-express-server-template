# rescript-express-server-template
extemdable rescript server and routes builder

## Example of code
```rescript
open ExpressServerTemplate

let testFilePath: string = %raw(`
    require('path').resolve(module.path, '..', '..', '..', '..', 'resources', 'test-file.txt')
`) //test file path

//Page html
let indexPageHtml = `
<form action="/apply-post" method="post">
    <h1>Test form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="submit" style="display: block;">
</form>
<div>
    <button type="button" onclick="window.open('/download-file');">download file</button>
    <button type="button" onclick="window.open('/set-session');">set session</button>
    <button type="button" onclick="window.open('/delete-session');">delete session</button>
</div>
`

//functions for parsing unknown
let parseUnknownAsString: (unknown) => option<string> = 
%raw(` function(val) {
    return (val && (typeof val === 'string'))
        ? val
        : null;
} `)
let parseUnknownObjectProperty: (unknown, string, (unknown) => option<'a>) => option<'a> =
%raw(` function(obj, prop, parser) {
    return (obj[prop]) ? parser(obj[prop]) : null;
} `)

//routes
type parsedVals = {
    textInp: option<string>,
    textAr: option<string>,
}
let routes: array<ExpressServerConfiguratorTemplate.route> = [
    Route(#get, "/", Default((_) => //get index page
        OnlyResponse(Html(indexPageHtml)))),
    Route(#post, "/apply-post", Default((req) => { //apply post form from index page
        let reqVals: parsedVals = ({
            textInp: parseUnknownObjectProperty(
                req.bodyData, 
                "textInp", 
                parseUnknownAsString
            ),
            textAr: parseUnknownObjectProperty(
                req.bodyData, 
                "textAr", 
                parseUnknownAsString
            ),
        })
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    })),
    Route(#get, "/download-file", Default((_) => { //download file
        OnlyResponse(DownloadFile(testFilePath))
    })),
    Route(#get, "/show-session", Default((req) => { //show current session val
        let sessionVal = parseUnknownObjectProperty(req.session, "sessionVal", parseUnknownAsString)
        let printVal = switch(sessionVal) {
            | Some(v) => v
            | None => ""
        }
        OnlyResponse(Html("Session-val: " ++ printVal))
    })),
    Route(#get, "/set-session", Default((_) => { //set session-val = 11 and redirect
        ResponseWithEffects(
            Redirect("/show-session", #303),
            [RequestEffect(SetSessionVal("sessionVal", %raw(`"11"`)))]
        )
    })),
    Route(#get, "/delete-session", Default((_) => { //remove session-val and redirect
        ResponseWithEffects(
            Redirect("/show-session", #303),
            [RequestEffect(DestroySession)]
        )
    })),
]

// build  server config
let serverConfig = ExpressServerConfiguratorTemplate.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

// run server
ExpressServerTemplate.run(serverConfig)
```

## Default server
ExpressServerConfiguratorTemplate module help to build default routes kind of
```rescript
type serverRespType = 
    | Html(string)
    | Json(string)
    | OpenFile(string)
    | DownloadFile(string)
    | Redirect(string, redirectStatus)
    | Error(string, errorStatus)

Route(
    method: [ #get | #post | #put | ...],
    routePath: string,
    handlerFunction:  
        | Default((req: {
            queryParams: unknown, //for get reqs
            bodyData: unknown, //for post reqs,
            session: unknown, //session store
        }) => serverRespType)
        | Multipart((req: {
            queryParams: unknown, //for get reqs
            bodyData: unknown, //for post req
            session: unknown, //session store
            files: unknown, //downloaded files
        }) => serverRespType)
)
```
next build server config from array of routes and run the server
```rescript
// build  server config
let serverConfig = ExpressServerConfiguratorTemplate.buildConfig(
    routes, //array of routes
    80, //port 
    () => { Js.Console.log("Server had been started") }) //on init handler

// run server
ExpressServerTemplate.run(serverConfig)
```

## Extensibility
ExpressServerConfiguratorFactory functor will help you define your own route 
configurator.
```rescript
type route<'a> = Route(routeType, path, 'a)

type effect<'a, 'b> = 
    | RequestEffect('a)
    | ResponseEffect('b)

type handlingResult<'a, 'b> = 
    | OnlyResponse('a)
    | ResponseWithEffects('a, array<'b>)

//Logger type
module type ILogger = {
    type error

    let catchUnknown: (() => 'a) => result<'a, error>
    let logError: (error) => unit
    let mapResultError: (result<unit, error>) => unit
    let handleResultError: (result<unit, error>, (error) => unit) => unit
    let raiseError: (error) => unit
}

// configurator type
module type IExpressDefaultServerConfigurator = {
    type requestHandling
    type route

    let buildConfig: (array<route>, port, () => unit) => serverStartConfig
}

//request manager for build and handling requests form unknown express types
module type IExpressRequestManager = {
    type requestHandling
    type requestEffect
    type error
    type responseType
    type responseEffect

    let initMiddlewares: (unknown) => unit
    let handleRequest: 
        (requestHandling) => (unknown, unknown) => handlingResult<
            responseType, 
            effect<requestEffect, responseEffect>
        >
    let produceMiddlewares: (requestHandling) => array<middleware>
    let handleEffect: (unknown, requestEffect) => unit
}

//response manager for build and handling responses form unknown express types
module type IExpressResponseManager = {
    type responseType
    type responseEffect
    type error

    let initMiddlewares: (unknown) => unit
    let handleEffect: (unknown, responseEffect) => unit
    let handleResponse: (unknown, responseType) => unit
    let handleInternalError: (unknown, error) => unit
}

//functor to produce configurator uses request-manager and response-manager
module type IExpressDefaultServerConfiguratorFactory = (
    Logger: ILogger, 
    ResponseManager: IExpressResponseManager
        with type error = Logger.error,
    RequestManager: IExpressRequestManager
        with type error = Logger.error
        and type responseType = ResponseManager.responseType
        and type responseEffect = ResponseManager.responseEffect
) => IExpressDefaultServerConfigurator 
    with type requestHandling = RequestManager.requestHandling
    and type route = route<RequestManager.requestHandling>
```
ready ExpressDefaultServerConfiguratorFactory functor exists in module
ExpressDefaultServerConfigurator

## Author
Anatoly Starodubtsev
tostar74@mail.ru

# License
MIT
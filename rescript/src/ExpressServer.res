%%raw(`
const express = require("express")
const app = express();
app.use(express.urlencoded())
app.use(express.json())
`)

let appUnit: unknown = %raw(`app`)

type routeType =
    [ #checkout
    | #copy
    | #get
    | #delete
    | #head
    | #lock
    | #mege
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

type handlerFunc = (unknown, unknown) => unit

type appMiddlewareInit = (unknown) => unit

type middleware = (unknown, unknown, unknown) => unit

type handler = {
    path: string,
    routeType: routeType,
    middlewares: array<middleware>,
    handler: handlerFunc,
}

type serverStartConfig = {
    handlers: array<handler>,
    appMwInits: array<appMiddlewareInit>,
    port: int,
    onInit: () => unit
}


module type ILogger = {
    type error

    let catchUnknown: (() => 'a) => result<'a, error>
}

module type IExpressServer = {
    type error

    let run: (serverStartConfig) => result<unit, error>
}

module type IExpressServerFactory = (Logger: ILogger) =>
    IExpressServer with type error = Logger.error

module ExpressServerFactory: IExpressServerFactory = (Logger: ILogger) => {
    open Belt

    type error = Logger.error
    type path = string

    let registerHandler =
        (handler: handler): unit => {
            let regF: (routeType, path, array<middleware>, handlerFunc) => unit = 
                %raw(`
                    function(route, path, middlewares, handler) {
                        const funParams = [path]
                            .concat(middlewares)
                            .concat([handler]);
                        app[route](...funParams);
                    }
                `)
            regF(
                handler.routeType, 
                handler.path, 
                handler.middlewares, 
                handler.handler
            )
        }

    let run =
        (serverStartConfig: serverStartConfig): result<unit, error> => 
            Logger.catchUnknown(() => {
                Array.forEach(
                    serverStartConfig.appMwInits, 
                    (a) => a(appUnit)
                )
                Array.forEach(
                    serverStartConfig.handlers, 
                    (h) => registerHandler(h)
                )
                let start: (int, () => unit) => unit = %raw(`
                    function(port, onInit) {
                        app.listen(port, onInit)
                    }
                `)
                start(serverStartConfig.port, serverStartConfig.onInit)
            })
}
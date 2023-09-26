%%raw(`
const express = require("express")
const app = express();
const multer = require("multer")
app.use(express.urlencoded())
app.use(express.json())
`)

type fileAwaitingField = (string, int)

type isMultipart =
    | Multipart(array<fileAwaitingField>)
    | NotMultipart

type specialRouteType =
    [ #checkout
    | #copy
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
    | #purge
    | #put
    | #report
    | #search
    | #subscribe
    | #trace
    | #unlock
    | #unsubscribe
    ]


type handlerType =
    | Get
    | Post(isMultipart)
    | Special(specialRouteType, isMultipart)

type serverRespType = 
    | Html(string)
    | Json(string)
    | Redirect(string)

type handlerFunc = (unknown, unknown) => serverRespType

module type ILogger = {
    open Belt

    type error
    type level

    let log: (level, error) => unit
    let initExpressApp: (unknown) => Result.t<unit, error>
    let wrap: (Js.Exn.t) => error
    let getUnknownError: () => error
    let err: level
}

module type IController = {
    open Belt

    type action
    type middleware
    type error

    let getAllActions: () => array<action>
    let getHandlerType: (action) => handlerType
    let getHandlerFunction: (action) => handlerFunc
    let getPath: (action) => string
    let initExpressApp: (unknown) => Result.t<unit, error>
    let getMiddlewares: (action) => array<middleware>
}

module type IRequestResponseManager = {
    type error

    let initExpressApp: (unknown) => result<unit, error>
    let buildMultipartDataMiddleware: (array<fileAwaitingField>) => array<unknown>
}

module type IExpressServerTemplate = (
    Logger: ILogger, 
    Controller: IController with type error = Logger.error,
    RequestResponseManager: IRequestResponseManager with type error = Logger.error
) => {
    open Belt

    let run: (int) => Result.t<unit, Logger.error>
}

module ExpressServerTemplate: IExpressServerTemplate = (
    Logger: ILogger, 
    Controller: IController with type error = Logger.error,
    RequestResponseManager: IRequestResponseManager with type error = Logger.error
) => {
    open Belt

    let initExpressApp = (app: unknown) => {
        Logger.initExpressApp(app)
            -> Result.flatMap(() => RequestResponseManager.initExpressApp(app))
            -> Result.flatMap(() => Controller.initExpressApp(app))
    }

    let appUnit: unknown = %raw(`app`)

    let registerGet = (
        path: string,
        middlewares: array<Controller.middleware>, 
        handlerFunc: handlerFunc
    ): Result.t<unit, Logger.error> => try {
        let res: (
            string, 
            array<Controller.middleware>, 
            handlerFunc
        ) => unit = %raw(`
            function(path, middlewares, handlerFunc) {
                const funParams = [path]
                    .concat(middlewares)
                    .concat([handlerFunc]);
                app.get(...funParams);
            }
        `)
        res(path, middlewares, handlerFunc)
        Ok()
    } catch {
        | Js.Exn.Error(obj) => Error(Logger.wrap(obj))
        | _ => Error(Logger.getUnknownError())
    }

    

    let registerPost = (
        path: string,
        middlewares: array<Controller.middleware>, 
        handlerFunc: handlerFunc,
        isMultipart: isMultipart
    ): Result.t<unit, Logger.error> => try {
        let multiMiddlewares: array<unknown> = switch(isMultipart) {
            | Multipart(fileFields) => 
                RequestResponseManager.buildMultipartDataMiddleware(fileFields)
            | NotMultipart => []
        }
        let res: (
            string, 
            array<Controller.middleware>, 
            handlerFunc, 
            array<unknown>
        ) => unit = %raw(`
            function(path, middlewares, handlerFunc, multiMiddlewares) {
                const middlewares2 = multiMiddlewares.concat(middlewares)
                const funParams = [path]
                    .concat(middlewares2)
                    .concat([handlerFunc]);
                app.post(...funParams);
            }
        `)
        res(path, middlewares, handlerFunc, multiMiddlewares)
        Ok()
    } catch {
        | Js.Exn.Error(obj) => Error(Logger.wrap(obj))
        | _ => Error(Logger.getUnknownError())
    }

    let registerSpecial = (
        path: string,
        middlewares: array<Controller.middleware>, 
        handlerFunc: handlerFunc,
        isMultipart: isMultipart,
        routeType: specialRouteType
    ): Result.t<unit, Logger.error> => try {
        let multiMiddlewares: array<unknown> = switch(isMultipart) {
            | Multipart(fileFields) => 
                RequestResponseManager.buildMultipartDataMiddleware(fileFields)
            | NotMultipart => []
        }
        let res: (
            string, 
            array<Controller.middleware>, 
            handlerFunc, 
            array<unknown>,
            specialRouteType
        ) => unit = %raw(`
            function(path, middlewares, handlerFunc, multiMiddlewares, route) {
                const middlewares2 = multiMiddlewares.concat(middlewares)
                const funParams = [path]
                    .concat(middlewares2)
                    .concat([handlerFunc]);
                app[route](...funParams);
            }
        `)
        res(path, middlewares, handlerFunc, multiMiddlewares, routeType)
        Ok()
    } catch {
        | Js.Exn.Error(obj) => Error(Logger.wrap(obj))
        | _ => Error(Logger.getUnknownError())
    }
    

    let regAction = (action: Controller.action): Result.t<unit, Logger.error> => {
        let handlerType = Controller.getHandlerType(action)
        let handlerFunc = Controller.getHandlerFunction(action)
        let handlerMiddlewares = Controller.getMiddlewares(action)
        let handlerPath = Controller.getPath(action)
        switch handlerType {
            | Get => registerGet(
                handlerPath, 
                handlerMiddlewares, 
                handlerFunc
            )
            | Post(isMulti) => registerPost(
                handlerPath, 
                handlerMiddlewares, 
                handlerFunc, 
                isMulti
            )
            | Special(routeType, isMulti) => registerSpecial(
                handlerPath, 
                handlerMiddlewares, 
                handlerFunc, 
                isMulti,
                routeType
            )
        }
    }

    let registerActions = (): Result.t<unit, Logger.error> => {
        let result = Controller.getAllActions()
            -> Array.map(a => regAction(a))
            -> Array.reduce(None, (
                    err: option<Logger.error>, 
                    res: Result.t<unit, Logger.error>
                ) => switch(res) {
                    | Ok(_) => err
                    | Error(e) => switch(err) {
                        | None => Some(e)
                        | Some(i) => Some(i)
                    }
                })
        switch (result) {
            | None => Ok()
            | Some(e) => Error(e)
        }
    }

    let startServer = (port: int): Result.t<unit, Logger.error> => try {
        let result: (int) => unit = %raw(`
            function(p) {
                app.listen(p, () => {
                    console.log("Server start")
                })
            }
        `)
        result(port)
        Ok()
    } catch {
        | Js.Exn.Error(obj) => Error(Logger.wrap(obj))
        | _ => Error(Logger.getUnknownError())
    }

    let run = (port: int): Result.t<unit, Logger.error> => {
        initExpressApp(appUnit)
            -> Result.flatMap(registerActions)
            -> Result.flatMap(() => startServer(port))
    }

}




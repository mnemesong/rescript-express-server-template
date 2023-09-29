open ExpressServer

type path = string

type port = int

type route<'a> = Route(routeType, path, 'a)

type effect<'a, 'b> = 
    | RequestEffect('a)
    | ResponseEffect('b)

type handlingResult<'a, 'b> = 
    | OnlyResponse('a)
    | ResponseWithEffects('a, array<'b>)

module type IExpressDefaultServerConfigurator = {
    type requestHandling
    type route

    let buildConfig: (array<route>, port, () => unit) => serverStartConfig
}

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

module type IExpressResponseManager = {
    type responseType
    type responseEffect
    type error

    let initMiddlewares: (unknown) => unit
    let handleEffect: (unknown, responseEffect) => unit
    let handleResponse: (unknown, responseType) => unit
    let handleInternalError: (unknown, error) => unit
}

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

module ExpressDefaultServerConfiguratorFactory: IExpressDefaultServerConfiguratorFactory = (
    Logger: ILogger, 
    ResponseManager: IExpressResponseManager
        with type error = Logger.error,
    RequestManager: IExpressRequestManager
        with type error = Logger.error
        and type responseType = ResponseManager.responseType
        and type responseEffect = ResponseManager.responseEffect
) => {
    open Belt

    type requestHandling = RequestManager.requestHandling
    type route = route<RequestManager.requestHandling>
    type effect = effect<RequestManager.requestEffect, ResponseManager.responseEffect>
    type responseType = ResponseManager.responseType

    let handleEffect = (req: unknown, res: unknown, e: effect): unit =>
        switch(e) {
            | RequestEffect(re) => RequestManager.handleEffect(req, re)
            | ResponseEffect(re) => ResponseManager.handleEffect(res, re)
        }

    let applyHandlingResult = 
        (req: unknown, res:unknown, result: handlingResult<responseType, effect>) =>
            switch(result) {
                | OnlyResponse(resp) => 
                    ResponseManager.handleResponse(res, resp)
                | ResponseWithEffects(resp, effects) => {
                    Array.forEach(effects, (e) => handleEffect(req, res, e))
                    ResponseManager.handleResponse(res, resp)
                }
            }

    let routeToHandler = 
        (route: route): handler => {
            let Route(routeType, path, requestHandling) = route
            let handlingFunc = (req, res) => {
                Logger.catchUnknown(() => {
                    let result = RequestManager.handleRequest(requestHandling)(req, res)
                    applyHandlingResult(req, res, result)
                }) -> Logger.handleResultError( (err) => {
                    ResponseManager.handleInternalError(res, err)
                } )
            }
            let middlewares = RequestManager.produceMiddlewares(requestHandling)
            ({
                path: path,
                routeType: routeType,
                middlewares: middlewares,
                handler: handlingFunc,
            })
        }

    let initMiddlewares = 
        (app: unknown): unit => RequestManager.initMiddlewares(app)

    let buildConfig: (array<route>, port, () => unit) => serverStartConfig =
        (routes, port, onInit) => {
            let routeHandlers = Array.map(routes, (r) => routeToHandler(r))
            ({
                handlers: routeHandlers,
                appMwInits: [initMiddlewares],
                port: port,
                onInit: onInit,
            })
        }
}
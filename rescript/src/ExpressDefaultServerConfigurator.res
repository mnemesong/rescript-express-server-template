open ExpressServer


type redirectStatus = 
    [ #301 
    | #302 
    | #303 
    | #304 
    | #306 
    | #307 
    | #308 
    ]

type errorStatus = 
    [ #400 
    | #401 
    | #402 
    | #403 
    | #404 
    | #405 
    | #406 
    | #407 
    | #408
    | #500
    | #501
    | #502
    | #503
    | #504
    ]

type serverRespType = 
    | Html(string)
    | Json(string)
    | OpenFile(string)
    | DownloadFile(string)
    | Redirect(string, redirectStatus)
    | Error(string, errorStatus)

type handlingResult<'a> = 
    | OnlyResponse(serverRespType)
    | ResponseWithEffects(serverRespType, array<'a>)

type path = string

type port = int

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

type route<'a> = Route(routeType, path, 'a)

module type IExpressDefaultServerConfigurator = {
    type requestHandling
    type route

    let buildConfig: (array<route>, port, () => unit) => serverStartConfig
    let route: (routeType, path, requestHandling) => route
}

module type IExpressRequestManager = {
    type requestHandling
    type requestEffect
    type error

    let initMiddlewares: (unknown) => unit
    let handleRequest: 
        (requestHandling) => (unknown, unknown) => handlingResult<requestEffect>
    let produceMiddlewares: (requestHandling) => array<middleware>
    let handleEffect: (requestEffect, unknown, unknown) => unit
}

module type IExpressDefaultServerConfiguratorFactory = (
    Logger: ILogger, 
    RequestManager: IExpressRequestManager with type error = Logger.error
) => IExpressDefaultServerConfigurator 
    with type requestHandling = RequestManager.requestHandling
    and type route = route<RequestManager.requestHandling>

module ExpressDefaultServerConfiguratorFactory: IExpressDefaultServerConfiguratorFactory = (
    Logger: ILogger, 
    RequestManager: IExpressRequestManager with type error = Logger.error
) => {
    open Belt

    type requestHandling = RequestManager.requestHandling
    type route = route<requestHandling>
    type requestEffect = RequestManager.requestEffect

    let route = (
        routeType: routeType, 
        path: path, 
        handling: requestHandling
    ): route => Route(routeType, path, handling)

    let handleHtmlResp: (unknown, string) => unit = %raw(`
        function(res, html) {
            res.setHeader('content-type', 'text/html');
            res.send(html);
        }
    `)

    let handleJsonResp: (unknown, string) => unit = %raw(`
        function(res, json) {
            res.setHeader('content-type', 'application/json');
            res.send(json);
        }
    `)

    let handleOpenFileResp: (unknown, string) => unit = %raw(`
        function(res, filePath) {
            res.sendFile(filePath);
        }
    `)

    let handleDownloadFileResp: (unknown, string) => unit = %raw(`
        function(res, filePath) {
            res.download(filePath);
        }
    `)

    let hanleRedirectResp: (unknown, string, redirectStatus) => unit = %raw(`
        function(res, redirectPath, redirectStatus) {
            res.redirect(redirectStatus, redirectPath);
        }
    `)

    let handleErrorResp: (unknown, string, errorStatus) => unit = %raw(`
        function(res, msg, status) {
            res.status(status).send(msg);
        }
    `)

    let handleRespResult =
        (res: unknown, response: serverRespType): unit =>
            switch(response) {
                | Html(html) => handleHtmlResp(res, html)
                | Json(json) => handleJsonResp(res, json)
                | OpenFile(path) => handleOpenFileResp(res, path)
                | DownloadFile(path) => handleDownloadFileResp(res, path)
                | Redirect(url, status) => hanleRedirectResp(res, url, status)
                | Error(msg, status) => handleErrorResp(res, msg, status)
            }

    let applyHandlingResult = 
        (req: unknown, res:unknown, result: handlingResult<requestEffect>) =>
            switch(result) {
                | OnlyResponse(resp) => 
                    handleRespResult(res, resp)
                | ResponseWithEffects(resp, effects) => {
                    Array.forEach(effects, (e) => RequestManager.handleEffect(e, req, res))
                    handleRespResult(res, resp)
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
                    Logger.logError(err)
                    handleErrorResp(res, "Internal error", #500)
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
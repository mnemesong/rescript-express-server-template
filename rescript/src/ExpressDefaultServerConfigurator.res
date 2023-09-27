open ExpressServer

%%raw(`
    const multer = require("multer");
`)

type serverEffect = 
    | DestroySession
    | SetSessionVal(string, unknown)

type fileAwaitingField = (string, int)

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
    | File(string)
    | Redirect(string, redirectStatus)
    | Error(string, errorStatus)

type handlingResult = {
    resp: serverRespType,
    effects: array<serverEffect>
}

type reqDefault = {
    queryParams: unknown,
    data: unknown,
    session: unknown,
}

type reqMultipart = {
    queryParams: unknown,
    data: unknown,
    session: unknown,
    files: unknown,
}

type filesDestinationPath = string

type fileField = (string, int)

type filesHandlingConfig = 
    | None
    | Files(filesDestinationPath, array<fileField>)

type queryHandling = 
    | Multipart(reqMultipart => handlingResult, filesHandlingConfig)
    | Default(reqDefault => handlingResult)

type path = string

type route = (routeType, path, queryHandling)

type port = int

module type IExpressDefaultServerConfigurator = {
    let buildConfig: (array<route>, port, () => unit) => serverStartConfig
}

module type IExpressDefaultServerConfiguratorFactory = (Logger: ILogger) =>
    IExpressDefaultServerConfigurator

module ExpressDefaultServerConfigurator: IExpressDefaultServerConfiguratorFactory = 
    (Logger: ILogger) => {
    open Belt

    type error = Logger.error

    let parseQueryParams: (unknown) => unknown = %raw(`
        function(req) {
            return req.query ? JSON.parse(JSON.stringify(req)) : {};
        }
    `)

    let parseBodyData: (unknown) => unknown = %raw(`
        function(req) {
            return req.body ? JSON.parse(JSON.stringify(req.body)) : {};
        }
    `)

    let parseFiles: (unknown) => unknown = %raw(`
        function(req) {
            return req.files ? JSON.parse(JSON.stringify(req.files)) : {};
        }
    `)

    let parseSession: (unknown) => unknown = %raw(`
        function(req) {
            return req.session ? JSON.parse(JSON.stringify(req.session)) : {};
        }
    `)

    let handleDestroySession =
        (req: unknown): result<unit, error> => 
            Logger.catchUnknown(() => {
                let f: (unknown) => unit = %raw(`
                    function(req) {
                        req.session.destroy((e) => {
                            console.log("Session destory erorr: ", e);
                        });
                    }
                `)
                f(req)
            })

    let handleSetSessionVal = 
        (req: unknown, name: string, val: 'a): result<unit, error> =>
            Logger.catchUnknown(() => {
                let f: (unknown, string, 'a) => unit = %raw(`
                    function(req, name, val) {
                        req.session[name] = val;
                    }
                `)
                f(req, name, val)
            })

    let handleEffect = 
        (se: serverEffect, req: unknown): result<unit, error> => 
            switch(se) {
                | DestroySession => handleDestroySession(req)
                | SetSessionVal(name, val) => handleSetSessionVal(req, name, val)
            }

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

    let handleFileResp: (unknown, string) => unit = %raw(`
        function(res, filePath) {
            res.setHeader('content-type', 'application/json');
            res.sendFile(filePath);
        }
    `)

    let hanleRedirectResp: (unknown, string, redirectStatus) => unit = %raw(`
        function(res, redirectPath, redirectStatus) {
            res.redirect(redirectStatus, redirectPath);
        }
    `)

    let handleErrorResp: (unknown, string, errorStatus) => unit = %raw(`
        function(res, msg, status) {
            res.status(errorStatus).send(msg);
        }
    `)

    let handleRespResult =
        (res: unknown, response: serverRespType): unit =>
            switch(response) {
                | Html(html) => handleHtmlResp(res, html)
                | Json(json) => handleJsonResp(res, json)
                | File(path) => handleFileResp(res, path)
                | Redirect(url, status) => hanleRedirectResp(res, url, status)
                | Error(msg, status) => handleErrorResp(res, msg, status)
            }

    let produceMulterFilesMiddleware: 
        (string, array<fileField>) => middleware = %raw(`
            function(path, fileFields) {
                const fields = fileField.map(ff => ({
                    name: ff[0],
                    maxCount: ff[1]
                }));
                return multer({ dest: path }).fields(fields);
            }
        `)

    let produceMulterNoneMiddleware:
        () => middleware = %raw(`
            function() {
                return multer().none();
            }
        `)

    let routeToHandler = 
        (route: route): handler => {
            let (routeType, path, queryHandling) = route
            let handlingFunc = switch(queryHandling) {
                | Default(defHandler) => (req: unknown, res: unknown) => { 
                    Logger.catchUnknown(() => {
                        let reqDefault: reqDefault = {
                            queryParams: parseQueryParams(req),
                            data: parseBodyData(req),
                            session: parseSession(req),
                        }
                        let result = defHandler(reqDefault)
                        Array.forEach(result.effects, (e) => 
                            switch(handleEffect(e, req)) {
                                | Ok(_) => ()
                                | Error(obj) => Logger.raiseError(obj)
                            })
                        handleRespResult(res, result.resp)
                    }) -> Logger.handleResultError( (err) => {
                        Logger.logError(err)
                        handleErrorResp(res, "Internal error", #500)
                    } )
                }
                | Multipart(multipartHandler, _) => (req: unknown, res: unknown) => { 
                    Logger.catchUnknown(() => {
                        let reqMult: reqMultipart = {
                            queryParams: parseQueryParams(req),
                            data: parseBodyData(req),
                            session: parseSession(req),
                            files: parseFiles(req),
                        }
                        let result = multipartHandler(reqMult)
                        Array.forEach(result.effects, (e) => 
                            switch(handleEffect(e, req)) {
                                | Ok(_) => ()
                                | Error(obj) => Logger.raiseError(obj)
                            })
                        handleRespResult(res, result.resp)
                    }) -> Logger.handleResultError( (err) => {
                        Logger.logError(err)
                        handleErrorResp(res, "Internal error", #500)
                    } )
                }
            }
            let middlewares = switch(queryHandling) {
                | Default(_) => []
                | Multipart(_, filesHandlingConfig) => 
                    switch(filesHandlingConfig) {
                        | None => [produceMulterNoneMiddleware()]
                        | Files(filesDestinationPath, fileFields) => [
                            produceMulterFilesMiddleware(
                                filesDestinationPath, 
                                fileFields
                            )
                        ]
                    }
            }
            ({
                path: path,
                routeType: routeType,
                middlewares: middlewares,
                handler: handlingFunc,
            })
        }

    let initMiddlewares: (unknown) => unit = %raw(`
        function(app) {
            app.use(express.urlencoded({ extended: true }));
            app.use(express.json());
        }
    `)

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
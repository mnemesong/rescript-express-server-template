open ExpressDefaultServerConfigurator
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

type responseEffect = unit

module type IExpressDefaultResponseManager = 
    IExpressResponseManager 
        with type responseType = serverRespType
        and type responseEffect = responseEffect

module type IExpressDefaultResponseManagerFactory = (Logger: ILogger) =>
    IExpressDefaultResponseManager
        with type error = Logger.error

module ExpressDefaultResponseManagerFactory: IExpressDefaultResponseManagerFactory = (
    Logger: ILogger
) => {
    type responseType = serverRespType
    type responseEffect = responseEffect
    type error = Logger.error

    let initMiddlewares: (unknown) => unit = (_) => ()

    let handleEffect = (_, _): unit => ()

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

    let handleResponse =
        (res: unknown, response: responseType): unit =>
            switch(response) {
                | Html(html) => handleHtmlResp(res, html)
                | Json(json) => handleJsonResp(res, json)
                | OpenFile(path) => handleOpenFileResp(res, path)
                | DownloadFile(path) => handleDownloadFileResp(res, path)
                | Redirect(url, status) => hanleRedirectResp(res, url, status)
                | Error(msg, status) => handleErrorResp(res, msg, status)
            }

    let handleInternalError = (res: unknown, err: error): unit => {
        Logger.logError(err)
        handleErrorResp(res, "Internal error", #500)
    }
} 
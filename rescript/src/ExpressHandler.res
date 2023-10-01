open ExpressNewServer

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

module type Default = Handler
    with type hReq = (request, response)
    and type hRes = serverRespType

module Default: Default = {
    type hReq = (request, response)
    type hRes = serverRespType

    let handleHtmlResp: (response, string) => unit = %raw(`
        function(res, html) {
            res.setHeader('content-type', 'text/html');
            res.send(html);
        }
    `)

    let handleJsonResp: (response, string) => unit = %raw(`
        function(res, json) {
            res.setHeader('content-type', 'application/json');
            res.send(json);
        }
    `)

    let handleOpenFileResp: (response, string) => unit = %raw(`
        function(res, filePath) {
            res.sendFile(filePath);
        }
    `)

    let handleDownloadFileResp: (response, string) => unit = %raw(`
        function(res, filePath) {
            res.download(filePath);
        }
    `)

    let hanleRedirectResp: (response, string, redirectStatus) => unit = %raw(`
        function(res, redirectPath, redirectStatus) {
            res.redirect(redirectStatus, redirectPath);
        }
    `)

    let handleErrorResp: (response, string, errorStatus) => unit = %raw(`
        function(res, msg, status) {
            res.status(status).send(msg);
        }
    `)

    let wrapReq: ((request, response)) => (request, response) = 
        ((request, response)) => (request, response)

    let primalReq: (hReq) => (request, response) =
        (hReq) => (hReq)

    let applyRes: (hReq, hRes) => unit = ((_, res), srt: serverRespType) =>  
        switch(srt) {
            | Html(html) => handleHtmlResp(res, html)
            | Json(json) => handleJsonResp(res, json)
            | OpenFile(path) => handleOpenFileResp(res, path)
            | DownloadFile(path) => handleDownloadFileResp(res, path)
            | Redirect(url, status) => hanleRedirectResp(res, url, status)
            | Error(msg, status) => handleErrorResp(res, msg, status)
        }

    let convert:  (hReq => hRes) => (request, response) => unit =
        (handler: hReq => hRes) => 
            (req, res) => 
                handler((req, res))|>applyRes((req, res))

    let middlewares: array<middleware> = []

    let handler: (hReq => hRes) => handler = (h) => Handler([], convert(h))
}
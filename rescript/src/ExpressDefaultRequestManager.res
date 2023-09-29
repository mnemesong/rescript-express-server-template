open ExpressServer
open ExpressDefaultServerConfigurator
open ExpressDefaultResponseManager

%%raw(`
    const multer = require("multer");
    const express = require("express");
    const session = require('express-session');
`)

type reqDefault = {
    queryParams: unknown,
    bodyData: unknown,
    session: unknown,
}

type reqMultipart = {
    queryParams: unknown,
    bodyData: unknown,
    session: unknown,
    files: unknown,
}

type fileField = (string, int)

type filesDestinationPath = string

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

type filesHandlingConfig = 
    | None
    | Files(filesDestinationPath, array<fileField>)

type requestEffect = 
    | DestroySession
    | SetSessionVal(string, unknown)

type requestHandling<'a> = 
    | Multipart(
        reqMultipart => handlingResult<serverRespType, effect<'a, responseEffect>>, 
        filesHandlingConfig
    )
    | Default(reqDefault => handlingResult<serverRespType, effect<'a, responseEffect>>)

module type IExpressDefaultRequestManagerFactory = (
    Logger: ILogger
) => IExpressRequestManager 
    with type error = Logger.error
    and type requestEffect = requestEffect
    and type requestHandling = requestHandling<requestEffect>
    and type responseType = serverRespType
    and type responseEffect = responseEffect

module ExpressDefaultRequestManagerFactory: IExpressDefaultRequestManagerFactory = (
    Logger: ILogger
) => {
    type error = Logger.error
    type requestEffect = requestEffect
    type responseType = serverRespType
    type responseEffect = responseEffect
    type handlingResult = handlingResult<
        responseType, 
        effect<requestEffect, responseEffect>
    >
    type requestHandling = requestHandling<requestEffect>

    let parseQueryParams: (unknown) => unknown = %raw(`
        function(req) {
            return req.query ? JSON.parse(JSON.stringify(req.query)) : {};
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
            const result = {};
            Object.keys(req.session).forEach(k => {result[k] = req.session[k]});
            return req.session ? JSON.parse(JSON.stringify(result)) : {};
        }
    `)

    let initMiddlewares: (unknown) => unit = %raw(`
        function (app) {
            app.use(express.urlencoded({ extended: true }));
            app.use(express.json());
            app.use(session({
              secret: 'sha7d87asb78d',
            }));
        }
    `)

    let produceMulterFilesMiddleware: 
        (string, array<fileField>) => middleware = %raw(`
            function(path, fileFields) {
                const fields = fileFields.map(ff => ({
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

    let handleRequest: 
        (requestHandling) => (unknown, unknown) => handlingResult =
        (requestHandling) => switch(requestHandling) {
            | Default(defHandler) => (req: unknown, _) => {
                let reqDefault: reqDefault = {
                    queryParams: parseQueryParams(req),
                    bodyData: parseBodyData(req),
                    session: parseSession(req),
                }
                defHandler(reqDefault)
            }
            | Multipart(multipartHandler, _) => (req: unknown, _) => {
                let reqMult: reqMultipart = {
                    queryParams: parseQueryParams(req),
                    bodyData: parseBodyData(req),
                    session: parseSession(req),
                    files: parseFiles(req),
                }
                multipartHandler(reqMult)
            }
        }

    let produceMiddlewares: (requestHandling) => array<middleware> =
        (requestHandling) => switch(requestHandling) {
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

    let handleDestroySession = (req: unknown): unit => {
        let f: (unknown) => unit = %raw(`
            function(req) {
                req.session.destroy((e) => {
                    console.log("Session destory erorr: ", e);
                });
            }
        `)
        f(req)
    }

    let handleSetSessionVal =  (req: unknown, name: string, val: 'a): unit => {
        let f: (unknown, string, 'a) => unit = %raw(`
            function(req, name, val) {
                req.session[name] = val;
            }
        `)
        f(req, name, val)
    }

    let handleEffect = 
        (req: unknown, re: requestEffect): unit => 
            switch(re) {
                | DestroySession => handleDestroySession(req)
                | SetSessionVal(name, val) => handleSetSessionVal(req, name, val)
            }
}
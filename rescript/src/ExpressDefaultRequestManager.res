open ExpressServer
open ExpressDefaultServerConfigurator

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

type filesHandlingConfig = 
    | None
    | Files(filesDestinationPath, array<fileField>)

type reqHandling = 
    | Multipart(reqMultipart => handlingResult, filesHandlingConfig)
    | Default(reqDefault => handlingResult)

module type IExpressDefaultRequestManagerFactory = (Logger: ILogger) =>
    IExpressRequestManager 
        with type error = Logger.error
        and type requestHandling = reqHandling 

module ExpressDefaultRequestManagerFactory: IExpressDefaultRequestManagerFactory = 
    (Logger: ILogger) => 
{
    type error = Logger.error
    type requestHandling = reqHandling

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
}
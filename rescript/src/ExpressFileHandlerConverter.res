open ExpressNewServer
open ExpressHandler
open ExpressHandlerMiddleware

%%raw(`
const express = require("express");
const multer = require("multer");
`)

type fileAwaitField = {
    name: string,
    maxCount: int
}

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
type fileParsedField = {fileName: string, files: array<file>}
type fileReq<'a> = FileReq('a, array<fileParsedField>)

module type FileParseConfig = {
    let getFileAwaitFields: () => array<fileAwaitField>
    let getDestPath: () => string
}

module type T = (OldHandler: Handler, FileParseConfig: FileParseConfig) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = fileReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler, FileParseConfig: FileParseConfig) => {
    type oldReq = OldHandler.hReq
    type newReq = fileReq<OldHandler.hReq>
    type oldRes = OldHandler.hRes
    type newRes = OldHandler.hRes

    let wrapStepReq: (oldReq) => newReq = (oldReq) => {
        let (req, _) = OldHandler.primalReq(oldReq)
        let parse: (request) => array<fileParsedField> = %raw(`
            function(req) {
                console.log(req.files );
                const files = req.files 
                    ? JSON.parse(JSON.stringify(req.files)) 
                    : {};
                return Object.keys(files).map(k => ({fileName: k, files: files[k]}))
            }
        `)
        FileReq(oldReq, parse(req))
    }
    let getOldReq: (newReq) => oldReq = (newReq) => {
        let FileReq(oldReq, _) = newReq
        oldReq
    }

    let applyStepRes: (newReq, newRes) => oldRes =
        (_, newRes) => newRes

    let produceFileMw = () => {
        let mw: (array<fileAwaitField>, string) => middleware = %raw(`
        function(fields, dest){
            return multer({ dest: dest }).fields(fields);
        }`)
        mw(FileParseConfig.getFileAwaitFields(), FileParseConfig.getDestPath())
    }

    let middlewares: array<middleware> = [
        produceFileMw(),
    ]
}
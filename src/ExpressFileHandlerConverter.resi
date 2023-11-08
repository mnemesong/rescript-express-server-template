open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type fileAwaitField = {
  name: string,
  maxCount: int,
}

type file = {
  fieldname: string,
  originalname: string,
  encoding: string,
  mimetype: string,
  destination: string,
  filename: string,
  path: string,
  size: int,
}
type fileParsedField = {fileName: string, files: array<file>}
type fileReq<'a> = FileReq('a, array<fileParsedField>)

module type FileParseConfig = {
  let getFileAwaitFields: unit => array<fileAwaitField>
  let getDestPath: unit => string
}

module type Make = (OldHandler: Handler, FileParseConfig: FileParseConfig) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = fileReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make

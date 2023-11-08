open ExpressServer
open WebTypes

module type Handler = {
  type hReq
  type hRes

  let wrapReq: ((request, response)) => hReq
  let applyRes: (hReq, hRes) => unit
  let primalReq: hReq => (request, response)
  let convert: (hReq => hRes, request, response) => unit
  let middlewares: array<middleware>
  let handler: (hReq => hRes) => handler
}

type serverRespType =
  | Html(string)
  | Json(string)
  | OpenFile(string)
  | DownloadFile(string)
  | Redirect(string, redirectStatus)
  | Error(string, errorStatus)

module type Default = Handler with type hReq = (request, response) and type hRes = serverRespType

module type ErrorStrategy = {
  let wrapTryCatch: (unit => unit) => unit
}

module DefaultErrorStrategy: ErrorStrategy

module type MakeDefault = (ErrorStrategy: ErrorStrategy) => Default

module MakeDefault: MakeDefault

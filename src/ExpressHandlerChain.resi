open ExpressHandler
open ExpressServer
open Belt

module type Converter = {
  type oldReq
  type newReq
  type oldRes
  type newRes

  let wrapStepReq: oldReq => newReq
  let getOldReq: newReq => oldReq
  let applyStepRes: (newReq, newRes) => oldRes
  let middlewares: array<middleware>
}

module type MakeConverter = (OldHandler: Handler) =>
(Converter with type oldReq = OldHandler.hReq and type oldRes = OldHandler.hRes)

module type Make = (
  OldHandler: Handler,
  Converter: Converter with type oldReq = OldHandler.hReq and type oldRes = OldHandler.hRes,
) => (Handler with type hReq = Converter.newReq and type hRes = Converter.newRes)

module Make: Make

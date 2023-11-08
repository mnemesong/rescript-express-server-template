open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type jsonReq<'a> = JsonReq('a, unknown)

module type Make = (OldHandler: Handler) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = jsonReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make

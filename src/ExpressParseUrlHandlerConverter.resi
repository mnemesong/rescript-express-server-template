open ExpressServer
open ExpressHandler
open ExpressHandlerChain

type urlReq<'a> = UrlReq('a, unknown)

module type Make = (OldHandler: Handler) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = urlReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = OldHandler.hRes
)

module Make: Make

open ExpressHandler
open ExpressServer
open Belt

module type Converter = {
    type oldReq
    type newReq
    type oldRes
    type newRes

    let wrapStepReq: (oldReq) => newReq
    let getOldReq: (newReq) => oldReq
    let applyStepRes: (newReq, newRes) => oldRes
    let middlewares: array<middleware>
}

module type MakeConverter = (OldHandler: Handler) => 
    Converter
        with type oldReq = OldHandler.hReq
        and type oldRes = OldHandler.hRes

module type Make = (
    OldHandler: Handler, 
    Converter: Converter
        with type oldReq = OldHandler.hReq
        and type oldRes = OldHandler.hRes
) => Handler
    with type hReq = Converter.newReq
    and type hRes = Converter.newRes

module Make: Make = (
    OldHandler: Handler, 
    Converter: Converter
        with type oldReq = OldHandler.hReq
        and type oldRes = OldHandler.hRes
) => {
    type hReq = Converter.newReq
    type hRes = Converter.newRes

    let wrapReq = (r: (request, response)) => 
        OldHandler.wrapReq(r)->Converter.wrapStepReq

    let applyRes: (hReq, hRes) => unit = 
        (hReq, hRes) => 
            OldHandler.applyRes(Converter.getOldReq(hReq), Converter.applyStepRes(hReq, hRes))

    let convert = (handler: hReq => hRes): ((request, response) => unit) => 
        (req, res) => wrapReq((req, res))->handler|>applyRes(wrapReq((req, res)))

    let primalReq: (hReq) => (request, response) =
        (hReq) => Converter.getOldReq(hReq)->OldHandler.primalReq

    let middlewares = OldHandler.middlewares 
        -> Array.concat(Converter.middlewares)

    let handler: (hReq => hRes) => handler = (h) => Handler(middlewares, convert(h))
}
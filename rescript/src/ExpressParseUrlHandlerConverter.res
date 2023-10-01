open ExpressNewServer
open ExpressHandler
open ExpressHandlerMiddleware

%%raw(`
const express = require("express");
`)

type urlReq<'a> = UrlReq('a, unknown)

module type T = (OldHandler: Handler) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = urlReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler) => {
    type oldReq = OldHandler.hReq
    type newReq = urlReq<OldHandler.hReq>
    type oldRes = OldHandler.hRes
    type newRes = oldRes

    let wrapStepReq: (oldReq) => newReq =
        (oldReq) => {
            let (req, _) = OldHandler.primalReq(oldReq)
            let parse: (request) => unknown = %raw(`
                function(req) {
                    return req.query ? req.query : {};
                }
            `)
            UrlReq(oldReq, parse(req))
        }

    let applyStepRes: (newReq, newRes) => oldRes =
        (_, newRes) => newRes

    let getOldReq: (newReq) => oldReq =
        (newReq) => {
            let UrlReq(oldReq, _) = newReq
            oldReq
        }

    let middlewares: array<middleware> = [
        %raw(`express.urlencoded({ extended: true })`),
    ]
}
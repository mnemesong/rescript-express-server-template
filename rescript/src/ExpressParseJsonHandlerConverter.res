open ExpressNewServer
open ExpressHandler
open ExpressHandlerMiddleware

type jsonReq<'a> = JsonReq('a, unknown)

%%raw(`
const express = require("express");
const multer = require("multer");
`)

module type T = (OldHandler: Handler) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = jsonReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = OldHandler.hRes

module Make: T = (OldHandler: Handler) => {
    type oldReq = OldHandler.hReq
    type newReq = jsonReq<OldHandler.hReq>
    type oldRes = OldHandler.hRes
    type newRes = oldRes

    let wrapStepReq: (oldReq) => newReq =
        (oldReq) => {
            let (req, _) = OldHandler.primalReq(oldReq)
            let parse: (request) => unknown = %raw(`
                function(req) {
                    return req.body ? req.body : {};
                }
            `)
            JsonReq(oldReq, parse(req))
        }

    let applyStepRes: (newReq, newRes) => oldRes =
        (_, newRes) => newRes

    let getOldReq: (newReq) => oldReq =
        (newReq) => {
            let JsonReq(oldReq, _) = newReq
            oldReq
        }

    let middlewares: array<middleware> = [
        %raw(`express.json()`),
    ]
}
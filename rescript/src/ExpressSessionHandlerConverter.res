open ExpressNewServer
open ExpressHandler
open ExpressHandlerMiddleware
open Belt

%%raw(`
const express = require("express");
const session = require('express-session');
`)

type sessionReq<'a> = SessionReq('a, unknown)
type sessionEffect = 
    | SetSessionValue(string, unknown)
    | DestroySession
type sessionRes<'a> = SessionRes('a, array<sessionEffect>)

type sessionParam =
    | SessionResave(bool)
    | SessionSaveUnitialized(bool)
    | Cookie(bool, option<int>)

type sessionConfig = SessionConfig(string, array<sessionParam>)

let setSessionValue = (k: string, val: 'a): sessionEffect => {
    let convertVal: ('a) => unknown  = %raw(`function(a) {
        return a
    }`)
    SetSessionValue(k, convertVal(val))
}

module type SessionConfigurator ={
    let getSessionConfig: () => sessionConfig
}

module DefaultConfigurator: SessionConfigurator = {
    let getSessionConfig: () => sessionConfig = 
        () => SessionConfig("dksand9u7sa9db9", [])
}

module type T = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) =>
    Converter
        with type oldReq = OldHandler.hReq
        and type newReq = sessionReq<OldHandler.hReq>
        and type oldRes = OldHandler.hRes
        and type newRes = sessionRes<OldHandler.hRes>

module Make: T = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) => {
    type oldReq = OldHandler.hReq
    type newReq = sessionReq<OldHandler.hReq>
    type oldRes = OldHandler.hRes
    type newRes = sessionRes<OldHandler.hRes>

    let wrapStepReq: (oldReq) => newReq =
        (oldReq) => {
            let (req, _) = OldHandler.primalReq(oldReq)
            let parse: (request) => unknown = %raw(`
                function(req) {
                    const result = {};
                    if(req.session) {
                        Object.keys(req.session)
                            .forEach(k => {result[k] = req.session[k]});
                    }
                    return req.session ? JSON.parse(JSON.stringify(result)) : {};
                }
            `)
            SessionReq(oldReq, parse(req))
        }

    let getOldReq: (newReq) => oldReq =
        (newReq) => {
            let SessionReq(oldReq, _) = newReq
            oldReq
        }

    let applyStepRes: (newReq, newRes) => oldRes = (newReq, newRes) => {
        let (request, _) = getOldReq(newReq)->OldHandler.primalReq
        let SessionRes(oldRes, effects) = newRes
        let applySetSessionVal: (request, string, unknown) => unit = 
        %raw(` function(req, k, v) {
            req.session[k] = v;
        } `)
        let applyDestroySession: (request) => unit = %raw(`function(req) {
            req.session.destroy();
        }`)
        Array.forEach(effects, (e) => switch e {
            | SetSessionValue(k, v) => applySetSessionVal(request, k, v)
            | DestroySession => applyDestroySession(request)
        })
        oldRes
    }

    let prepareSessionConfig = (): unknown => {
        let SessionConfig(secret, params) = SessionConfigurator.getSessionConfig()
        let conf = %raw(`{}`)
        let setSecret: (string) => unit = %raw(`function(s) {
            conf.secret = s;
        }`)
        setSecret(secret)
        let setSessionResave: (bool) => unit = %raw(`function(s) {
            conf.resave = s
        }`)
        let setSessionSaveUninitialized: (bool) => unit = %raw(`function(s) {
            conf.saveUninitialized = s;
        }`)
        let setSessionCookie: (bool, option<int>) => unit = %raw(`function(s, ma) {
            const cookiePar = {secure: s};
            if(ma) { cookiePar.maxAge = ma; }
            conf.cookie = cookiePar;
        }`)
        Array.forEach(params, (p) => switch(p) {
            | SessionResave(b) => setSessionResave(b)
            | SessionSaveUnitialized(b) => setSessionSaveUninitialized(b)
            | Cookie(b, ma) => setSessionCookie(b, ma)
        })
        conf
    }

    let getSessionMw: (unknown) => middleware = %raw(`
    function (sc) {
        return session(sc);
    }
    `)

    let middlewares: array<middleware> = [
        getSessionMw(prepareSessionConfig()),
    ]
}
open ExpressServer
open ExpressHandler
open ExpressHandlerChain
open Belt

%%raw(`
const express = require("express");
const session = require('express-session');
`)

type authSessReq<'r, 'u> = AuthSessReq('r, option<'u>)

type authSessEffect<'u> =
  | Login('u)
  | Logout

type authSessRes<'r, 'u> = AuthSessRes('r, array<authSessEffect<'u>>)

module type UserManager = {
  type loginData
  type user
  type userCheckAuthData

  let produceAuthData: user => userCheckAuthData
  let checkAuthData: userCheckAuthData => option<user>
  let checkLoginData: loginData => option<user>
  let invalidLoginDataMsg: unit => string
}

type sessionParam =
  | SessionResave(bool)
  | SessionSaveUnitialized(bool)
  | Cookie(bool, option<int>)

type sessionConfig = SessionConfig(string, array<sessionParam>)

module type SessionConfigurator = {
  let getSessionConfig: unit => sessionConfig
}

module DefaultConfigurator: SessionConfigurator = {
  let getSessionConfig: unit => sessionConfig = () => SessionConfig("dksand9u7sa9db9", [])
}

module type Make = (
  OldHandler: Handler,
  UserManager: UserManager,
  SessionConfigurator: SessionConfigurator,
) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = authSessReq<OldHandler.hReq, UserManager.user>
    and type oldRes = OldHandler.hRes
    and type newRes = authSessRes<OldHandler.hRes, UserManager.user>
)

module Make: Make = (
  OldHandler: Handler,
  UserManager: UserManager,
  SessionConfigurator: SessionConfigurator,
) => {
  type oldReq = OldHandler.hReq
  type newReq = authSessReq<OldHandler.hReq, UserManager.user>
  type oldRes = OldHandler.hRes
  type newRes = authSessRes<OldHandler.hRes, UserManager.user>

  let wrapStepReq = (oldReq: oldReq): newReq => {
    let (req, _) = OldHandler.primalReq(oldReq)
    let parse: request => option<UserManager.userCheckAuthData> = %raw(`
      function(req) {
        const result = {};
        if(req.session && req.session.userCheckAuthData) {
          return JSON.parse(JSON.stringify(
            req.session.userCheckAuthData));
        }
        return undefined;
      }
    `)
    let maybeUser = parse(req)->Option.flatMap(ucad => UserManager.checkAuthData(ucad))
    AuthSessReq(oldReq, maybeUser)
  }

  let getOldReq = (newReq: newReq): oldReq => {
    let AuthSessReq(oldReq, _) = newReq
    oldReq
  }

  let applyStepRes = (newReq: newReq, newRes: newRes): oldRes => {
    let (request, _) = getOldReq(newReq)->OldHandler.primalReq
    let AuthSessRes(oldReq, authSessEffects) = newRes
    let applyLoginAuthData: (request, UserManager.userCheckAuthData) => unit = %raw(` 
    function(req, u) {
      req.session.userCheckAuthData = u;
    } 
    `)
    let applyLogout: request => unit = %raw(`
    function(req) {
      delete req.session.userCheckAuthData;
    }
    `)
    Array.forEach(authSessEffects, e =>
      switch e {
      | Login(u) => {
          let ucad = UserManager.produceAuthData(u)
          applyLoginAuthData(request, ucad)
        }
      | Logout => applyLogout(request)
      }
    )
    oldReq
  }

  let prepareSessionConfig = (): unknown => {
    let SessionConfig(secret, params) = SessionConfigurator.getSessionConfig()
    let conf = %raw(`{}`)
    let setSecret: string => unit = %raw(`
    function(s) {
      conf.secret = s;
    }
    `)
    setSecret(secret)
    let setSessionResave: bool => unit = %raw(`
    function(s) {
      conf.resave = s
    }
    `)
    let setSessionSaveUninitialized: bool => unit = %raw(`
    function(s) {
      conf.saveUninitialized = s;
    }
    `)
    let setSessionCookie: (bool, option<int>) => unit = %raw(`
    function(s, ma) {
      const cookiePar = {secure: s};
      if(ma) { cookiePar.maxAge = ma; }
      conf.cookie = cookiePar;
    }
    `)
    Array.forEach(params, p =>
      switch p {
      | SessionResave(b) => setSessionResave(b)
      | SessionSaveUnitialized(b) => setSessionSaveUninitialized(b)
      | Cookie(b, ma) => setSessionCookie(b, ma)
      }
    )
    conf
  }

  let getSessionMw: unknown => middleware = %raw(`
  function (sc) {
    return session(sc);
  }
  `)

  let middlewares: array<middleware> = [getSessionMw(prepareSessionConfig())]
}

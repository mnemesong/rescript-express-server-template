open ExpressHandler
open ExpressHandlerChain

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

module DefaultConfigurator: SessionConfigurator

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

module Make: Make

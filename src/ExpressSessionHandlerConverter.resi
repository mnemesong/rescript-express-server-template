open ExpressHandler
open ExpressHandlerChain

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

let setSessionValue: (string, 'a) => sessionEffect

module type SessionConfigurator = {
  let getSessionConfig: unit => sessionConfig
}

module DefaultConfigurator: SessionConfigurator

module type Make = (OldHandler: Handler, SessionConfigurator: SessionConfigurator) =>
(
  Converter
    with type oldReq = OldHandler.hReq
    and type newReq = sessionReq<OldHandler.hReq>
    and type oldRes = OldHandler.hRes
    and type newRes = sessionRes<OldHandler.hRes>
)

module Make: Make

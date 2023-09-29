//open ExpressDefaultAuthHandler
//
//type denyStrategy =
//    | JsonDeny
//    | RedirectHome
//    | RedirectLoginPage
//
//type response = handlingResult<serverRespType, effect<'a, responseEffect>>
//
//type userResponseEffect<'user> =
//    | None
//    | LoginAs('user)
//    | Logout
//
//module type IExpressIExpressAuthResponseMangerFactory = (
//
//) =>
//
//module ExpressIExpressAuthResponseManger = {
//    type denyStrategy
//    type response = response
//    type userResponseEffect
//
//    let handleDenyStrategy: (denyStrategy) => response
//    let applyResponseEffect: (response, userResponseEffect) => response
//}
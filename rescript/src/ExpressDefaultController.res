open ExpressServerTemplate


module type ILoggerAdv = {
    include ILogger

    let getUnknownErrorInRoute: (string) => error
    let userIsNotGuestError: error
    let accessDeniedForUserError: error
    let userIsNotLoggedInError: error
}


module type IRbacManager = {
    type request
    type permission
    type user
    type permissionStrategy =
        | Any
        | RegisteredExclude(array<permission>)
        | OnlyWithPermission(array<permission>)
        | OnlyGuest

    let getPermissions: (user) => array<permission>
    let isPermissionsEq: (permission, permission) => bool
    let getUser: (request) => option<user>
}


module type IDefaultPagesStrategy = {
    open Belt

    type error

    let errorHandlingStrategy: (error) => serverRespType
    let initExpressApp: (unknown) => Result.t<unit, error>
}


module type IRequestResponseManagerAdv = {
    include IRequestResponseManager

    type data
    type request
    type responseEffect
    type file

    let parseRequest: (unknown) => result<request, error>
    let applyResponseEffects: (unknown, array<responseEffect>) => result<unit, error>
    let getData: (request) => data
    let getFiles: (request, fileAwaitingField) => array<file>
}


module type IExpressDefaultControllerFactory = (
    Logger: ILoggerAdv,
    DefaultPagesStrategy: IDefaultPagesStrategy 
        with type error = Logger.error,
    RequestResponseManager : IRequestResponseManagerAdv 
        with type error = Logger.error,
    RbacManager: IRbacManager
        with type request = RequestResponseManager.request,
) => IController


module ExpressDefaultControllerFactory: IExpressDefaultControllerFactory = (
    Logger: ILoggerAdv,
    DefaultPagesStrategy: IDefaultPagesStrategy 
        with type error = Logger.error,
    RequestResponseManager : IRequestResponseManagerAdv 
        with type error = Logger.error,
    RbacManager: IRbacManager
        with type request = RequestResponseManager.request,
) => {
    open Belt

    type middleware = (unknown, unknown, unknown) => unit
    type handleResult = {
        resp: serverRespType,
        effects: array<RequestResponseManager.responseEffect>
    }
    type request = RequestResponseManager.request
    type action = {
        t: handlerType,
        path: string,
        func: (request) => handleResult,
        permStrat: RbacManager.permissionStrategy,
        middlewares: array<middleware>,
    }
    type error = Logger.error
    type permStrat = RbacManager.permissionStrategy
    type perm = RbacManager.permission

    let actionsCollection = ref([]: array<action>)

    let getHandlerType: (action) => handlerType =
        (a) => a.t

    let isPermissionsIntersect =
        (pa1: array<perm>, pa2: array<perm>): bool => 
            Array.some(pa1, (p1) => Array.reduce(
                pa2, 
                false, 
                (r, p2) => r || RbacManager.isPermissionsEq(p1, p2)
            ))

    let checkAccess: (permStrat, request) => result<request, error> = 
        ( permStrat, request ) => {
            let user = RbacManager.getUser(request)
            switch(permStrat) {
                | Any => Ok(request)
                | OnlyGuest => switch(user) {
                    | Some(_) => Error(Logger.userIsNotGuestError)
                    | None => Ok(request)
                }
                | RegisteredExclude(excludePerms) => switch(user) {
                    | Some(u) => {
                        let isIntersects = isPermissionsIntersect(
                            RbacManager.getPermissions(u),
                            excludePerms
                        )
                        (isIntersects == true)
                            ? Error(Logger.accessDeniedForUserError)
                            : Ok(request)
                    }
                    | None => Error(Logger.userIsNotLoggedInError)
                }
                | OnlyWithPermission(needPerms) => switch(user) {
                    | None => Error(Logger.userIsNotLoggedInError)
                    | Some(u) => {
                        let isIntersects = isPermissionsIntersect(
                            RbacManager.getPermissions(u),
                            needPerms
                        )
                        (isIntersects == true)
                            ? Ok(request)
                            : Error(Logger.accessDeniedForUserError)
                    }
                }
            }
        }

    let applyEffects = 
        (hr: handleResult, res: unknown): result<serverRespType, error> => {
            let applyEffectsResult = 
                RequestResponseManager.applyResponseEffects(
                    res,
                    hr.effects
                )
            switch(applyEffectsResult) {
                | Error(e) => Error(e)
                | Ok(_) => Ok(hr.resp)
            }
        }

    let getHandlerFunction: (action) => handlerFunc = 
        (a) => 
            (req, res) => try {
                let result = RequestResponseManager.parseRequest(req)
                    -> Result.flatMap((r) => checkAccess(a.permStrat, r))
                    -> Result.map((r) => a.func(r))
                    -> Result.flatMap((hr) => applyEffects(hr, res))
                switch(result) {
                    | Error(e) => DefaultPagesStrategy.errorHandlingStrategy(e)
                    | Ok(r) => r
                }
            } catch {
                | Js.Exn.Error(obj) => {
                    let err = Logger.wrap(obj)
                    Logger.log(Logger.err, err)
                    DefaultPagesStrategy.errorHandlingStrategy(err)
                }
                | _ => {
                    let err = Logger.getUnknownErrorInRoute(a.path)
                    Logger.log(Logger.err, err)
                    DefaultPagesStrategy.errorHandlingStrategy(err)
                }
            }

    let getPath: (action) => string =
        (a) => a.path

    let initExpressApp: (unknown) => Result.t<unit, Logger.error> = 
        (u) => DefaultPagesStrategy.initExpressApp(u)

    let getMiddlewares: (action) => array<middleware> = 
        (a) => a.middlewares

    let getAllActions: () => array<action> =
        () => actionsCollection.contents

}
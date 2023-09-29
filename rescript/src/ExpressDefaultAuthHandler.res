type userResponse<'resp, 'userEffect> = AuthResponse('resp, array<'userEffect>)

module type IExpressUserIdentityManager = {
    type user
    type loginData

    let isHasPermission: (user, string) => bool
    let checkLoginData: (loginData) => option<user>
}

module type IExpressAuthResponseManager = {
    type denyStrategy
    type response
    type userResponseEffect

    let handleDenyStrategy: (denyStrategy) => response
    let applyResponseEffect: (response, userResponseEffect) => response
}

module type IExpressAuthRequestManager = {
    type request
    type user

    let pullUserFromRequest: (request) => option<user>
}

module type IExpressAuthHandler = {
    type user
    type userResponseEffect
    type request
    type response
    type denyStrategy

    let any: (
        (request, option<user>) => userResponse<response, userResponseEffect>
    ) => (request => response)

    let onlyPermissions: (
        (request, user) => userResponse<response, userResponseEffect>, 
        array<string>, 
        denyStrategy
    ) => (request => response)

    let anyRegistered: (
        (request, user) => userResponse<response, userResponseEffect>, 
        denyStrategy
    ) => (request => response)

    let onlyGuest: (
        (request) => userResponse<response, userResponseEffect>, 
        denyStrategy
    ) => (request => response)
}

module type IExpressAuthHandlerFactory = (
    UserIdentityManager: IExpressUserIdentityManager,
    ExpressAuthResponseManager: IExpressAuthResponseManager,
    ExpressAuthRequestInteractor: IExpressAuthRequestManager
        with type user = UserIdentityManager.user
) => IExpressAuthHandler
    with type user = UserIdentityManager.user
    and type denyStrategy = ExpressAuthResponseManager.denyStrategy
    and type response = ExpressAuthResponseManager.response
    and type userResponseEffect = ExpressAuthResponseManager.userResponseEffect
    and type request = ExpressAuthRequestInteractor.request

module ExpressDefaultAuthHandlerFactory: IExpressAuthHandlerFactory  = (
    UserIdentityManager: IExpressUserIdentityManager,
    ExpressAuthResponseManager: IExpressAuthResponseManager,
    ExpressAuthRequestInteractor: IExpressAuthRequestManager
        with type user = UserIdentityManager.user
) => {
    open Belt

    type user = UserIdentityManager.user
    type userResponseEffect = ExpressAuthResponseManager.userResponseEffect
    type request = ExpressAuthRequestInteractor.request
    type response = ExpressAuthResponseManager.response
    type denyStrategy = ExpressAuthResponseManager.denyStrategy

    let handleUserResponse = (
        userResp: userResponse<response, userResponseEffect>
    ): response => {
        let AuthResponse(resp, userEffs) = userResp
        Array.reduce(
            userEffs, 
            resp, 
            (r, ef) => ExpressAuthResponseManager.applyResponseEffect(r, ef)
        )
    }

    let any = (
        handler: (request, option<user>) => userResponse<response, userResponseEffect>, 
    ): (request => response) => (req) => {
        let user = ExpressAuthRequestInteractor.pullUserFromRequest(req)
        handleUserResponse(handler(req, user))
    }

    let onlyPermissions = (
        handler: (request, user) => userResponse<response, userResponseEffect>,
        permissions: array<string>,
        denyStrategy: denyStrategy
    ): (request => response) => (req) => {
        let maybeUser = ExpressAuthRequestInteractor.pullUserFromRequest(req)
            -> Option.flatMap(u => 
                (Array.reduce(
                    permissions, 
                    false, 
                    (isHasPermission, p) => isHasPermission
                        ? true
                        : UserIdentityManager.isHasPermission(u, p) 
                )) ? Some(u) : None
            )
        switch maybeUser {
            | None => 
                ExpressAuthResponseManager.handleDenyStrategy(denyStrategy)
            | Some(u) => {
                handleUserResponse(handler(req, u))
            }
        }
    }

    let anyRegistered = (
        handler: (request, user) => userResponse<response, userResponseEffect>,
        denyStrategy: denyStrategy
    ): (request => response) => (req) => {
        let maybeUser = ExpressAuthRequestInteractor.pullUserFromRequest(req)
        switch maybeUser {
            | None => 
                ExpressAuthResponseManager.handleDenyStrategy(denyStrategy)
            | Some(u) => {
                handleUserResponse(handler(req, u))
            }
        }
    }

    let onlyGuest = (
        handler: (request) => userResponse<response, userResponseEffect>,
        denyStrategy: denyStrategy
    ): (request => response) => (req) => {
        let maybeUser = ExpressAuthRequestInteractor.pullUserFromRequest(req)
        switch maybeUser {
            | Some(_) => 
                ExpressAuthResponseManager.handleDenyStrategy(denyStrategy)
            | None =>
                handleUserResponse(handler(req))
        }
    }
}

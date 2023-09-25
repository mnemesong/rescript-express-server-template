module type IRbacManager = (Logger: ExpressServerTemplate.ILogger) => {
    open Belt

    type permission
    type user
    let getUser: (unknown) => option<user>
    let getPermissions: (user) => Result.t<array<permission>, Logger.error>
    let setUser: (user) => Result.t<unit, Logger.error>
    let initExpressApp: (unknown) => Result.t<unit, Logger.error>
}
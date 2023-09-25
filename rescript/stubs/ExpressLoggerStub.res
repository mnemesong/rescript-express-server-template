module type IExpressLoggerStub = {
    include ExpressServerTemplate.ILogger

    let err: level
}

module ExpressLoggerStub: IExpressLoggerStub = {
    open Belt

    type error = string
    type level = [ #error ]

    @@warning("-27")
    let log: (level, error) => unit = 
        (lev, err) => Js.Console.log(err)
    @@warning("+27")

    @@warning("-27")
    let initExpressApp: (unknown) => Result.t<unit, error> = 
        (u) => Ok()
    @@warning("+27")

    let err: level = #error

    let wrap: (Js.Exn.t) => error =
        (obj) => switch Js.Exn.message(obj) {
            | Some(msg) => msg
            | None => ""
        }
}
open ExpressServerTemplate
open ExpressLoggerStub

module type IExpressRequestResponseManagerStub = 
    IRequestResponseManager with type error = ExpressLoggerStub.error

module ExpressRequestResponseManagerStub: IExpressRequestResponseManagerStub = {
    type error = ExpressLoggerStub.error

    @@warning("-27")
    let initExpressApp: (unknown) => result<unit, error> = 
        (app) => Ok()
    @@warning("+27")

    @@warning("-27")
    let buildMultipartDataMiddleware: (array<fileAwaitingField>) => array<unknown> =
        (fields) => []
    @@warning("+27")
}
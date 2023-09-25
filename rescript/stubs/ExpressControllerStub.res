open ExpressServerTemplate

module ExpressControllerStub: IController = (
    Logger: ILogger
) => {
    open Belt

    type action = {
        t: handlerType,
        path: string,
        func: handlerFunc,
    }
    type middleware = string

    let getHandlerType: (action) => handlerType =
        (a) => a.t

    let getHandlerFunction: (action) => handlerFunc =
        (a) => a.func

    let getPath: (action) => string =
        (a) => a.path

    @@warning("-27")
    let initExpressApp: (unknown) => Result.t<unit, Logger.error> =
        (u) => Ok()
    @@warning("+27")

    @@warning("-27")
    let getMiddlewares: (action) => array<middleware> =
        (action) => []
    @@warning("+27")

    let defaultHandlerFunc: handlerFunc = %raw(`
        function(req, res) {
            res.send("Hello world!")
        }
    `)

    let getAllActions: () => array<action> = () => [
        {
            t: Get,
            path: "/",
            func: defaultHandlerFunc,
        }
    ]
}
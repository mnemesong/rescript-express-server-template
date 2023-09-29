open ExpressServer
open ExpressDefaultLogger

module ExpressServerTest = ExpressServerFactory(ExpressDefaultLogger)

let indexHandler: (unknown, unknown) => unit = 
%raw(`
    function(req, res) {
        res.send("Hello world");
    }
`)

let onInit: () => unit = 
    () => Js.Console.log("Server works")

ExpressServerTest.run({
    handlers: [{
        path: "/",
        routeType: #get,
        middlewares: [],
        handler: indexHandler,
    }],
    appMwInits: [],
    port: 80,
    onInit: onInit
})

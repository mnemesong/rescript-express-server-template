open ExpressServer
open SimpleLogger
open ExpressDefaultServerConfigurator

module ExpressDefaultServerConfigurator = 
    ExpressDefaultServerConfiguratorFactory(SimpleLogger)

let routes: array<route> = [
    (#get, "/", Default((_) => OnlyResponse(Html("<h1>Hello world!</h1>"))))
]

let serverConfig = ExpressDefaultServerConfigurator.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

module ExpressServerTest2 = ExpressServerFactory(SimpleLogger)

ExpressServerTest2.run(serverConfig)
open ExpressServer

let routes = [
    Route(#get, "/", Handler([], (_, res) => {
        let sayHello: (response) => unit = 
        %raw(`function(res) {
            res.send("Hello world!");
        }`)
        sayHello(res)
    }))
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
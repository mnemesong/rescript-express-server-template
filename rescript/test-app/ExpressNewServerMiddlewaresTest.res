open ExpressNewServer
open ExpressHandler
open ExpressParseUrlHandlerConverter
open ExpressParseJsonHandlerConverter
open! ExpressHandlerMiddleware

module QueryConverter = ExpressParseUrlHandlerConverter.Make(Default)
module QueryHandler = Make( Default, QueryConverter )
module JsonConverter = ExpressParseJsonHandlerConverter.Make(QueryHandler)
module JsonHandler = Make( QueryHandler, JsonConverter )

let routes = [
    Route(#get, "/", JsonHandler.handler(r => {
        let JsonReq(r1: QueryConverter.newReq, _) = r
        let UrlReq(_, urlData) = r1
        let unkToJson: (unknown) => string = %raw(`function(u) {
            return JSON.stringify(u) + ""
        }`)
        let urlDataStr = unkToJson(urlData)
        Html("Url data: " ++ urlDataStr)
    }))
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
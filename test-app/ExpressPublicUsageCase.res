open ExpressServer
open ExpressHandler
open ExpressParseUrlHandlerConverter
open ExpressParseJsonHandlerConverter
open ExpressFileHandlerConverter
open! ExpressHandlerChain

//Defaultly server await "handler" type = Handler(array<middlewares>, (req, res) => unit)
//Handler modules allow to modify request and response and write hanlder-func use
//this modified versions: (req' => res'), and convert this funciton
//into default "handler" type
module DefaultHandler = MakeDefault(DefaultErrorStrategy) //default handler builder
module QueryConverter = ExpressParseUrlHandlerConverter.Make(DefaultHandler)
module QueryHandler = Make( DefaultHandler, QueryConverter ) //parse url handler
module JsonConverter = ExpressParseJsonHandlerConverter.Make(QueryHandler)
module JsonHandler = Make( QueryHandler, JsonConverter ) //parse json-post-body handler
module FileParseConfig: FileParseConfig = {
    let getFileAwaitFields: () => array<fileAwaitField> =
        () => [{name: "fileInp", maxCount: 1}]
    let getDestPath: () => string =
        () => "/uploads"
}
module FileConverter = 
    ExpressFileHandlerConverter.Make(JsonHandler, FileParseConfig)
module FileHandler = Make( JsonHandler, FileConverter ) //files loading handler

let indexPageHtml = `
<form action="/apply-post" method="post" enctype="multipart/form-data">
    <h1>Test form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="file" name="fileInp" style="display: block;">
    <input type="submit" style="display: block;">
</form>` //page html

let stringifyAny: ('a) => string = %raw(`function (u) {
    return u ? JSON.stringify(u) : ""
}`)

let routes = [
    Route(#get, "/", QueryHandler.handler(r => { //show form and show get-query
        let UrlReq(_, urlData) = r
        let unkToJson: (unknown) => string = %raw(`function(u) {
            return JSON.stringify(u) + ""
        }`)
        let urlDataStr = unkToJson(urlData)
        Html("Url data: " ++ urlDataStr ++ "<br><br>" ++ indexPageHtml)
    })),
    Route(#post, "/apply-post", FileHandler.handler(r => { //form handler and show data
        let FileReq(JsonReq(_, json), files) = r
        let json = `{"json": "${stringifyAny(json)}",
        "files": "${stringifyAny(files)}"}`
        Json(json)
    })),
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
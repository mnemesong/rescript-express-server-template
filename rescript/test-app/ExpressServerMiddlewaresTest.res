open ExpressServer
open ExpressHandler
open ExpressParseUrlHandlerConverter
open ExpressParseJsonHandlerConverter
open ExpressSessionHandlerConverter
open ExpressFileHandlerConverter
open! ExpressHandlerMiddleware

module Default = MakeDefault(DefaultErrorStrategy)
module QueryConverter = ExpressParseUrlHandlerConverter.Make(Default)
module QueryHandler = Make( Default, QueryConverter )
module JsonConverter = ExpressParseJsonHandlerConverter.Make(QueryHandler)
module JsonHandler = Make( QueryHandler, JsonConverter )
module SessionConverter = ExpressSessionHandlerConverter.Make(
    JsonHandler,
    ExpressSessionHandlerConverter.DefaultConfigurator
)
module SessionHandler = Make( JsonHandler, SessionConverter )
module FileParseConfig: FileParseConfig = {
    let getFileAwaitFields: () => array<fileAwaitField> =
        () => [{name: "fileInp", maxCount: 1}]
    let getDestPath: () => string =
        () => "/uploads"
}
module FileConverter = 
    ExpressFileHandlerConverter.Make(SessionHandler, FileParseConfig)
module FileHandler = Make( SessionHandler, FileConverter )

module OnlySessionConverter = ExpressSessionHandlerConverter.Make(
    Default, 
    ExpressSessionHandlerConverter.DefaultConfigurator
)
module OnlySessionHandler = Make(Default, OnlySessionConverter)

let testFilePath: string = %raw(`
    require('path').resolve(module.path, '..', '..', '..', '..', 'resources', 'test-file.txt')
`)

let indexPageHtml = `
<form action="/apply-post" method="post" enctype="multipart/form-data">
    <h1>Test form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="file" name="fileInp" style="display: block;">
    <input type="submit" style="display: block;">
</form>
<hr>
<div>
    <button type="button" onclick="window.open('/download-file');">download file</button>
    <button type="button" onclick="window.open('/set-session');">set session</button>
    <button type="button" onclick="window.open('/delete-session');">delete session</button>
</div>
`

let stringifyAny: ('a) => string = %raw(`
function (u) {
    return u
        ? JSON.stringify(u)
        : ""
}`)

let routes = [
    Route(#get, "/", QueryHandler.handler(r => {
        let UrlReq(_, urlData) = r
        let unkToJson: (unknown) => string = %raw(`function(u) {
            return JSON.stringify(u) + ""
        }`)
        let urlDataStr = unkToJson(urlData)
        Html("Url data: " ++ urlDataStr ++ "<br><br>" ++ indexPageHtml)
    })),
    Route(#post, "/apply-post", FileHandler.handler(r => {
        let FileReq(SessionReq(JsonReq(_, json), session), files) = r
        let html = `
        json: ${stringifyAny(json)}<br>
        session: ${stringifyAny(session)}<br>
        files: ${stringifyAny(files)}
        `
        SessionRes(Html(html), [])
    })),
    Route(#get, "/download-file", QueryHandler.handler((_) => {
        DownloadFile(testFilePath)
    })),
    Route(#get, "/show-session", OnlySessionHandler.handler(r => {
        let SessionReq(_, session) = r
        let html = "session: " ++ stringifyAny(session)
        SessionRes(Html(html), [])
    })),
    Route(#get, "/set-session", OnlySessionHandler.handler((_) => {
        SessionRes(Redirect("/show-session", #302), [
            SetSessionValue("a", %raw(`12`))
        ])
    })),
    Route(#get, "/delete-session", OnlySessionHandler.handler((_) => {
        SessionRes(Redirect("/show-session", #302), [
            DestroySession
        ])
    }))
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
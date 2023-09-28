open ExpressServer
open SimpleLogger
open ExpressDefaultServerConfigurator
open ExpressDefaultRequestManager
open Belt

module ExpressDefaultRequestManager = 
    ExpressDefaultRequestManagerFactory(SimpleLogger)

module ExpressDefaultServerConfiguratorTest = 
    ExpressDefaultServerConfiguratorFactory(SimpleLogger, ExpressDefaultRequestManager)

let formHtml = (method: routeType, path: string) => `
<form action="${path}" method="${method :> string}">
    <h1>Test ${method :> string} form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="submit" style="display: block;">
</form>
`

let fileForm = (method: routeType, path: string) => `
<form action="${path}" method="${method :> string}" enctype="multipart/form-data">
    <h1>Test multipart form</h1>
    <input name="textInp" value="" style="display: block;">
    <input type="file" name="fileInp" style="display: block;">
    <input type="submit" style="display: block;">
</form>
`

let testButtons = `
<div>
    <button type="button" onclick="window.open('/open-file');">open file</button>
    <button type="button" onclick="window.open('/download-file');">download file</button>
    <button type="button" onclick="window.open('/set-session');">set session</button>
    <button type="button" onclick="window.open('/delete-session');">delete session</button>
</div>
`

let testFilePath: string = %raw(`
    require('path').resolve(module.path, '..', '..', '..', '..', 'resources', 'test-file.txt')
`)

let printForms = (forms: array<string>): string => `
<div style="display:grid; grid-template-columns: ${
    Array.map(forms, (_) => "1fr") -> Js.Array2.joinWith(" ")
};">
    ${Js.Array2.joinWith(forms, "")}
</div>
`


let indexPageHtml = [
    formHtml(#get, "/apply-get"),
    formHtml(#post, "/apply-post"),
    fileForm(#post, "/apply-file"),
    testButtons
] -> printForms

let parseUnknownAsString: (unknown) => option<string> = %raw(`
    function(val) {
        return (val && (typeof val === 'string'))
            ? val
            : null;
    }
`)

let parseUnknownObjectProperty: (unknown, string, (unknown) => option<'a>) => option<'a> =
%raw(`
    function(obj, prop, parser) {
        return (obj[prop]) ? parser(obj[prop]) : null;
    }
`)

let parseUnknownAsFile: (unknown) => option<string> = %raw(`
    function (val) {
        console.log(val);
        return null;
    }
`)

let parseUnknownAsArray: (unknown, (unknown) => option<'a>) => option<array<option<'a>>> =
%raw(`
    function(arr, parser) {
        return Array.isArray(arr)
            ? arr.map(parser)
            : null;
    }
`)

type parsedVals = {
    textInp: option<string>,
    textAr: option<string>,
}

let parseFormValues = (u: unknown): parsedVals => ({
    textInp: parseUnknownObjectProperty(u, "textInp", parseUnknownAsString),
    textAr: parseUnknownObjectProperty(u, "textAr", parseUnknownAsString),
})

let routes: array<ExpressDefaultServerConfiguratorTest.route> = [
    Route(#get, "/", Default((_) => 
        OnlyResponse(Html(indexPageHtml)))),
    Route(#get, "/apply-get", Default((req) => {
        let reqVals = parseFormValues(req.queryParams)
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    })),
    Route(#post, "/apply-post", Default((req) => {
        let reqVals = parseFormValues(req.bodyData)
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    })),
    Route(#post, "/apply-file", Multipart((req) => {
        let reqVals = ({
            "textInp": parseUnknownObjectProperty(req.bodyData, "textInp", parseUnknownAsString),
            "fileInp": parseUnknownObjectProperty(req.files, "fileInp", (a) => 
                parseUnknownAsArray(a, (u) => 
                    parseUnknownObjectProperty(u, "originalname", parseUnknownAsString)))
        })
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    }, Files("/uploads", [("fileInp", 1)]))),
    Route(#get, "/open-file", Default((_) => {
        OnlyResponse(OpenFile(testFilePath))
    })),
    Route(#get, "/download-file", Default((_) => {
        OnlyResponse(DownloadFile(testFilePath))
    })),
    Route(#get, "/show-session", Default((req) => {
        let sessionVal = parseUnknownObjectProperty(req.session, "sessionVal", parseUnknownAsString)
        let printVal = switch(sessionVal) {
            | Some(v) => v
            | None => ""
        }
        OnlyResponse(Html("Session-val: " ++ printVal))
    })),
    Route(#get, "/set-session", Default((_) => {
        ResponseWithEffects(
            Redirect("/show-session", #303),
            [SetSessionVal("sessionVal", %raw(`"11"`))]
        )
    })),
    Route(#get, "/delete-session", Default((_) => {
        ResponseWithEffects(
            Redirect("/show-session", #303),
            [DestroySession]
        )
    })),
]

let serverConfig = ExpressDefaultServerConfiguratorTest.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

module ExpressServerTest2 = ExpressServerFactory(SimpleLogger)

ExpressServerTest2.run(serverConfig)
open ExpressServer
open SimpleLogger
open ExpressDefaultServerConfigurator
open Belt

module ExpressDefaultServerConfigurator = 
    ExpressDefaultServerConfiguratorFactory(SimpleLogger)

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

let routes: array<route> = [
    (#get, "/", Default((_) => 
        OnlyResponse(Html(indexPageHtml)))),
    (#get, "/apply-get", Default((req) => {
        let reqVals = parseFormValues(req.queryParams)
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    })),
    (#post, "/apply-post", Default((req) => {
        let reqVals = parseFormValues(req.bodyData)
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
    })),
    (#post, "/apply-file", Multipart((req) => {
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
    (#get, "/open-file", Default((_) => {
        OnlyResponse(OpenFile(testFilePath))
    })),
    (#get, "/download-file", Default((_) => {
        OnlyResponse(DownloadFile(testFilePath))
    }))
]

let serverConfig = ExpressDefaultServerConfigurator.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

module ExpressServerTest2 = ExpressServerFactory(SimpleLogger)

ExpressServerTest2.run(serverConfig)
open ExpressServerTemplate

let testFilePath: string = %raw(`
    require('path').resolve(module.path, '..', '..', '..', '..', 'resources', 'test-file.txt')
`)

let indexPageHtml = `
<form action="/apply-post" method="post">
    <h1>Test form</h1>
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="submit" style="display: block;">
</form>
<div>
    <button type="button" onclick="window.open('/download-file');">download file</button>
    <button type="button" onclick="window.open('/set-session');">set session</button>
    <button type="button" onclick="window.open('/delete-session');">delete session</button>
</div>
`

let parseUnknownAsString: (unknown) => option<string> = 
%raw(` function(val) {
    return (val && (typeof val === 'string'))
        ? val
        : null;
} `)

let parseUnknownObjectProperty: (unknown, string, (unknown) => option<'a>) => option<'a> =
%raw(` function(obj, prop, parser) {
    return (obj[prop]) ? parser(obj[prop]) : null;
} `)

type parsedVals = {
    textInp: option<string>,
    textAr: option<string>,
}
let routes: array<ExpressServerConfiguratorTemplate.route> = [
    Route(#get, "/", Default((_) => 
        OnlyResponse(Html(indexPageHtml)))),
    Route(#post, "/apply-post", Default((req) => {
        let reqVals: parsedVals = ({
            textInp: parseUnknownObjectProperty(req.bodyData, "textInp", parseUnknownAsString),
            textAr: parseUnknownObjectProperty(req.bodyData, "textAr", parseUnknownAsString),
        })
        let result = Js.Json.stringifyAny(reqVals)
        switch result {
            |Some(a) => OnlyResponse(Json(a))
            |None => OnlyResponse(Json("{}"))
        }
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
            [RequestEffect(SetSessionVal("sessionVal", %raw(`"11"`)))]
        )
    })),
    Route(#get, "/delete-session", Default((_) => {
        ResponseWithEffects(
            Redirect("/show-session", #303),
            [RequestEffect(DestroySession)]
        )
    })),
]

let serverConfig = ExpressServerConfiguratorTemplate.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

ExpressServerTemplate.run(serverConfig)
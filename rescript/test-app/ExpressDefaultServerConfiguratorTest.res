open ExpressServer
open SimpleLogger
open ExpressDefaultServerConfigurator

module ExpressDefaultServerConfigurator = 
    ExpressDefaultServerConfiguratorFactory(SimpleLogger)

let formHtml = (method: routeType, path: string) => `
<h1>Test ${method :> string} form</h1>
<form action="${path}" method="${method :> string}">
    <input name="textInp" value="" style="display: block;">
    <textarea name="textAr" style="display: block;"></textarea>
    <input type="submit" style="display: block;">
</form>
`

let indexPageHtml = formHtml(#get, "/apply-get")

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
    }))
]

let serverConfig = ExpressDefaultServerConfigurator.buildConfig(routes, 80, () => {
    Js.Console.log("Server had been started")
})

module ExpressServerTest2 = ExpressServerFactory(SimpleLogger)

ExpressServerTest2.run(serverConfig)
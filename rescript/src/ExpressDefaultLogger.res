open ExpressServer

module ExpressDefaultLogger: ILogger = {
    type error = Js.Exn.t

    let catchUnknown: (() => 'a) => result<'a, error> =
        (riskF) => try {
            Ok(riskF())
        } catch {
            | Js.Exn.Error(obj) => Error(obj)
            | _ => Error(Js.Exn.raiseError("Unknown error"))
        }

    let logError = (err: error): unit => Js.Console.log(err)

    let mapResultError = (r: result<unit, error>): unit =>
        switch r {
            | Ok(_) => ()
            | Error(err) => logError(err)
        }

    let handleResultError = 
        (r: result<unit, error>, handler: (error) => unit): unit =>
            switch r {
                | Ok(_) => ()
                | Error(err) => handler(err)
            }

    let raiseError: (error) => unit = %raw(`
        function(err) {
            throw err;
        }
    `)
    
}
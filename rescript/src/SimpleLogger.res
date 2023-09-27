open ExpressServer

module SimpleLogger: ILogger = {
    type error = Js.Exn.t

    let catchUnknown: (() => 'a) => result<'a, error> =
        (riskF) => try {
            Ok(riskF())
        } catch {
            | Js.Exn.Error(obj) => Error(obj)
            | _ => Error(Js.Exn.raiseError("Unknown error"))
        }
}
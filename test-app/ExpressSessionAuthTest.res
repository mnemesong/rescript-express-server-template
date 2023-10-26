open ExpressAuthSessionHandlerConverter
open ExpressParseJsonHandlerConverter
open ExpressHandler
open ExpressServer
open! ExpressHandlerChain
open Belt

type loginData = {
    login: string,
    pass: string,
}
type user = {
    id: int,
    login: string,
    pass: string,
}
type userCheckAuthData = {
    login: string,
}

module UserManager: UserManager 
    with type loginData = loginData
    and type user = user
    and type userCheckAuthData = userCheckAuthData
 = {
    type loginData = loginData
    type user = user
    type userCheckAuthData = userCheckAuthData

    let users: array<user> = [
        {
            id: 1,
            login: "admin",
            pass: "111"
        }
    ]

    let produceAuthData = (user: user): userCheckAuthData => {
        {login: user.login}
    }

    let checkAuthData = (userCheckAuthData: userCheckAuthData): option<user> => {
        Array.reduce(
            users, 
            None, 
            (curUsr: option<user>, usr: user) => {
                (usr.login == userCheckAuthData.login) 
                    ? Some(usr)
                    : curUsr
            }
        )
    }

    let checkLoginData = (loginData: loginData): option<user> => {
        Array.reduce(
            users, 
            None, 
            (curUsr: option<user>, usr: user) => {
                ((usr.login == loginData.login) && (usr.pass == loginData.pass)) 
                    ? Some(usr)
                    : curUsr
            }
        )
    }

    let invalidLoginDataMsg = (): string => "Invalid login or password"
}


module DefaultHandler = MakeDefault(DefaultErrorStrategy)
module JsonConverter = ExpressParseJsonHandlerConverter.Make(DefaultHandler)
module JsonHandler = Make(
    DefaultHandler,
    JsonConverter
)
module AuthSessionConverter = ExpressAuthSessionHandlerConverter.Make(
    JsonHandler,
    UserManager,
    DefaultConfigurator
)
module AuthSessionHandler = Make(
    JsonHandler,
    AuthSessionConverter
)

let loginPageHtml = `
<form action="/apply-login" method="post">
    <h1>Test form</h1>
    <input name="login" value="" style="display: block;">
    <input name="pass" value="" style="display: block;">
    <input type="submit" style="display: block;">
</form>`

let indexPageHtml = (usr: user) => `
User: ${usr.login}<br>
<button onclick="window.location.href='/logout'">Log out</button>`

let routes = [
    Route(#get, "/", AuthSessionHandler.handler((r) => {
        let AuthSessReq(_, maybeUsr) = r
        switch maybeUsr {
            | None => AuthSessRes(Redirect("/login", #302), [])
            | Some(u) => AuthSessRes(Html(indexPageHtml(u)), [])
        }
    })),
    Route(#get, "/login", AuthSessionHandler.handler((r) => {
        let AuthSessReq(_, maybeUsr) = r
        switch maybeUsr {
            | None => AuthSessRes(Html(loginPageHtml), [])
            | Some(_) => AuthSessRes(Redirect("/", #302), [])
        }
    })),
    Route(#post, "/apply-login", AuthSessionHandler.handler((r) => {
        let AuthSessReq(JsonReq(_, jsonData), _) = r
        let extractLoginDataFromJsonData: (unknown) => option<loginData> =
        %raw(`function (u) {
            console.log("Json data:" , u);
            if(!u) return undefined;
            if((!u.login) 
                || (typeof u.login !== 'string') 
                || (!u.pass)
                || (typeof u.pass !== 'string')
            ) {
                console.log("no login or pass");
                return undefined;
            }
            return {
                login: u.login,
                pass: u.pass
            };
        }`)
        switch extractLoginDataFromJsonData(jsonData) {
            | None => {
                Js.Console.log("No loging pata after extraction")
                AuthSessRes(Redirect("/", #302), [Logout])
            }
            | Some(eld) => {
                switch UserManager.checkLoginData(eld) {
                    | None => {
                        Js.Console.log("Wrong checking login data")
                        AuthSessRes(Redirect("/", #302), [Logout])
                    }
                    | Some(usr) => {
                        Js.Console.log("Successfull checking login data")
                        AuthSessRes(Redirect("/", #302), [Login(usr)])
                    }
                }
            }
        }
    })),
    Route(#get, "/logout", AuthSessionHandler.handler((_) => {
        AuthSessRes(Redirect("/login", #302), [Logout])
    })),
]

runServer(routes, [], 80, () => {Js.Console.log("Server started!")})
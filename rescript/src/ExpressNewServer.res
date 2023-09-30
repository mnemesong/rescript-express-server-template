%%raw(`
const express = require("express");
`)

open Belt

type request
type response
type middleware
type expressApp

type routeType =
    [ #checkout
    | #copy
    | #get
    | #delete
    | #head
    | #lock
    | #merge
    | #mkactivity
    | #mkcol
    | #move
    | #notify
    | #options
    | #patch
    | #post
    | #purge
    | #put
    | #report
    | #search
    | #subscribe
    | #trace
    | #unlock
    | #unsubscribe
    ]
type scenario = (request, response) => unit
type handler = Handler(array<middleware>, scenario)

type url = string

type route = Route(routeType, url, handler)

let runServer = (
    routes: array<route>,
    middlewares: array<middleware>,
    port: int,
    onInit: () => unit
): unit => {
    let app: expressApp = %raw(`express()`)
    let useMiddleware: (expressApp, middleware) => unit = 
    %raw(` function(app, mw) {
        app.use(mw);
    } `)
    Array.forEach(middlewares, (mw) => useMiddleware(app, mw))
    let registerRoute = (expressApp: expressApp, route: route): unit => {
        let Route(routeType, url, handler) = route
        let Handler(middlewares, scenario) = handler
        let reg: (expressApp, routeType, url, array<middleware>, scenario) => unit =
        %raw(`function(app, routeType, url, middlewares, scenario) {
            console.log("Register route:", url);
            const fParams = [url].concat(middlewares).concat([scenario]);
            app[routeType](...fParams);
        }`)
        reg(expressApp, routeType, url, middlewares, scenario)
    }
    Array.forEach(routes, (r) => registerRoute(app, r))
    let listen: (expressApp, int, () => unit) => unit = 
    %raw(`function(app, port, onInit) {
        app.listen(port, onInit)
    }`)
    listen(app, port, onInit)
}
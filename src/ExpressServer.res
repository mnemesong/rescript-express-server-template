%%raw(`
const express = require("express");
`)

open Belt
open WebTypes

type request
type response
type middleware
type expressApp

type scenario = (request, response) => unit
type handler = Handler(array<middleware>, scenario)

type url = string

type route = Route(method, url, handler)

let staticFilesMiddleware: string => middleware = %raw(`
function (root) {
return express.static(root);
}
`)

let runServer = (
  routes: array<route>,
  middlewares: array<middleware>,
  port: int,
  onInit: unit => unit,
): unit => {
  let app: expressApp = %raw(`express()`)
  let useMiddleware: (expressApp, middleware) => unit = %raw(` 
  function(app, mw) {
    app.use(mw);
  } 
  `)
  Array.forEach(middlewares, mw => useMiddleware(app, mw))
  let registerRoute = (expressApp: expressApp, route: route): unit => {
    let Route(method, url, handler) = route
    let Handler(middlewares, scenario) = handler
    let reg: (
      expressApp,
      method,
      url,
      array<middleware>,
      scenario,
    ) => unit = %raw(`function(app, method, url, middlewares, scenario) {
      const fParams = [url].concat(middlewares).concat([scenario]);
      app[method](...fParams);
    }`)
    reg(expressApp, method, url, middlewares, scenario)
  }
  Array.forEach(routes, r => registerRoute(app, r))
  let listen: (expressApp, int, unit => unit) => unit = %raw(`function(app, port, onInit) {
    app.listen(port, onInit)
  }`)
  listen(app, port, onInit)
}

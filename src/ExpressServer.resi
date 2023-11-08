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

let staticFilesMiddleware: string => middleware

let runServer: (array<route>, array<middleware>, int, unit => unit) => unit

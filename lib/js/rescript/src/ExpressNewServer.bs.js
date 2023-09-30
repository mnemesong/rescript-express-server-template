// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Belt_Array = require("rescript/lib/js/belt_Array.js");

const express = require("express");
;

function runServer(routes, middlewares, port, onInit) {
  var app = (express());
  var useMiddleware = (function(app, mw) {
        app.use(mw);
    });
  Belt_Array.forEach(middlewares, (function (mw) {
          useMiddleware(app, mw);
        }));
  Belt_Array.forEach(routes, (function (r) {
          var handler = r._2;
          var reg = (function(app, routeType, url, middlewares, scenario) {
            console.log("Register route:", url);
            const fParams = [url].concat(middlewares).concat([scenario]);
            app[routeType](...fParams);
        });
          reg(app, r._0, r._1, handler._0, handler._1);
        }));
  var listen = (function(app, port, onInit) {
        app.listen(port, onInit)
    });
  listen(app, port, onInit);
}

exports.runServer = runServer;
/*  Not a pure module */
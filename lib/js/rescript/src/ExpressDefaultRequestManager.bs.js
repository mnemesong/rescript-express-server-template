// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");

const multer = require("multer");
    const express = require("express");
    const session = require('express-session');
;

function ExpressDefaultRequestManagerFactory(Logger) {
  var parseQueryParams = (function(req) {
            return req.query ? JSON.parse(JSON.stringify(req.query)) : {};
        });
  var parseBodyData = (function(req) {
            return req.body ? JSON.parse(JSON.stringify(req.body)) : {};
        });
  var parseFiles = (function(req) {
            return req.files ? JSON.parse(JSON.stringify(req.files)) : {};
        });
  var parseSession = (function(req) {
            const result = {};
            Object.keys(req.session).forEach(k => {result[k] = req.session[k]});
            return req.session ? JSON.parse(JSON.stringify(result)) : {};
        });
  var initMiddlewares = (function (app) {
            app.use(express.urlencoded({ extended: true }));
            app.use(express.json());
            app.use(session({
              secret: 'sha7d87asb78d',
            }));
        });
  var produceMulterFilesMiddleware = (function(path, fileFields) {
                const fields = fileFields.map(ff => ({
                    name: ff[0],
                    maxCount: ff[1]
                }));
                return multer({ dest: path }).fields(fields);
            });
  var produceMulterNoneMiddleware = (function() {
                return multer().none();
            });
  var handleRequest = function (requestHandling) {
    if (requestHandling.TAG === /* Multipart */0) {
      var multipartHandler = requestHandling._0;
      return function (req, param) {
        return Curry._1(multipartHandler, {
                    queryParams: parseQueryParams(req),
                    bodyData: parseBodyData(req),
                    session: parseSession(req),
                    files: parseFiles(req)
                  });
      };
    }
    var defHandler = requestHandling._0;
    return function (req, param) {
      return Curry._1(defHandler, {
                  queryParams: parseQueryParams(req),
                  bodyData: parseBodyData(req),
                  session: parseSession(req)
                });
    };
  };
  var produceMiddlewares = function (requestHandling) {
    if (requestHandling.TAG !== /* Multipart */0) {
      return [];
    }
    var filesHandlingConfig = requestHandling._1;
    if (filesHandlingConfig) {
      return [produceMulterFilesMiddleware(filesHandlingConfig._0, filesHandlingConfig._1)];
    } else {
      return [Curry._1(produceMulterNoneMiddleware, undefined)];
    }
  };
  var handleEffect = function (req, param, re) {
    if (re) {
      var name = re._0;
      var val = re._1;
      var f = (function(req, name, val) {
                req.session[name] = val;
            });
      return f(req, name, val);
    } else {
      var f$1 = (function(req) {
                req.session.destroy((e) => {
                    console.log("Session destory erorr: ", e);
                });
            });
      return f$1(req);
    }
  };
  return {
          initMiddlewares: initMiddlewares,
          handleRequest: handleRequest,
          produceMiddlewares: produceMiddlewares,
          handleEffect: handleEffect
        };
}

exports.ExpressDefaultRequestManagerFactory = ExpressDefaultRequestManagerFactory;
/*  Not a pure module */
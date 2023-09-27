// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");
var Belt_Array = require("rescript/lib/js/belt_Array.js");

const multer = require("multer");
    const express = require("express")
;

function ExpressDefaultServerConfiguratorFactory(Logger) {
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
            return req.session ? JSON.parse(JSON.stringify(req.session)) : {};
        });
  var handleEffect = function (se, req) {
    if (se) {
      var name = se._0;
      var val = se._1;
      return Curry._1(Logger.catchUnknown, (function (param) {
                    var f = (function(req, name, val) {
                        req.session[name] = val;
                    });
                    f(req, name, val);
                  }));
    } else {
      return Curry._1(Logger.catchUnknown, (function (param) {
                    var f = (function(req) {
                        req.session.destroy((e) => {
                            console.log("Session destory erorr: ", e);
                        });
                    });
                    f(req);
                  }));
    }
  };
  var handleHtmlResp = (function(res, html) {
            res.setHeader('content-type', 'text/html');
            res.send(html);
        });
  var handleJsonResp = (function(res, json) {
            res.setHeader('content-type', 'application/json');
            res.send(json);
        });
  var handleFileResp = (function(res, filePath) {
            res.setHeader('content-type', 'application/json');
            res.sendFile(filePath);
        });
  var hanleRedirectResp = (function(res, redirectPath, redirectStatus) {
            res.redirect(redirectStatus, redirectPath);
        });
  var handleErrorResp = (function(res, msg, status) {
            res.status(status).send(msg);
        });
  var handleRespResult = function (res, response) {
    switch (response.TAG | 0) {
      case /* Html */0 :
          return handleHtmlResp(res, response._0);
      case /* Json */1 :
          return handleJsonResp(res, response._0);
      case /* File */2 :
          return handleFileResp(res, response._0);
      case /* Redirect */3 :
          return hanleRedirectResp(res, response._0, response._1);
      case /* Error */4 :
          return handleErrorResp(res, response._0, response._1);
      
    }
  };
  var produceMulterFilesMiddleware = (function(path, fileFields) {
                const fields = fileField.map(ff => ({
                    name: ff[0],
                    maxCount: ff[1]
                }));
                return multer({ dest: path }).fields(fields);
            });
  var produceMulterNoneMiddleware = (function() {
                return multer().none();
            });
  var applyHandlingResult = function (req, res, result) {
    if (result.TAG === /* OnlyResponse */0) {
      return handleRespResult(res, result._0);
    }
    Belt_Array.forEach(result._1, (function (e) {
            var obj = handleEffect(e, req);
            if (obj.TAG === /* Ok */0) {
              return ;
            } else {
              return Curry._1(Logger.raiseError, obj._0);
            }
          }));
    handleRespResult(res, result._0);
  };
  var initMiddlewares = (function(app) {
            app.use(express.urlencoded({ extended: true }));
            app.use(express.json());
        });
  var buildConfig = function (routes, port, onInit) {
    var routeHandlers = Belt_Array.map(routes, (function (r) {
            var queryHandling = r[2];
            var handlingFunc;
            if (queryHandling.TAG === /* Multipart */0) {
              var multipartHandler = queryHandling._0;
              handlingFunc = (function (req, res) {
                  Curry._2(Logger.handleResultError, Curry._1(Logger.catchUnknown, (function (param) {
                              var reqMult_queryParams = parseQueryParams(req);
                              var reqMult_data = parseBodyData(req);
                              var reqMult_session = parseSession(req);
                              var reqMult_files = parseFiles(req);
                              var reqMult = {
                                queryParams: reqMult_queryParams,
                                data: reqMult_data,
                                session: reqMult_session,
                                files: reqMult_files
                              };
                              var result = Curry._1(multipartHandler, reqMult);
                              applyHandlingResult(req, res, result);
                            })), (function (err) {
                          Curry._1(Logger.logError, err);
                          handleErrorResp(res, "Internal error", 500);
                        }));
                });
            } else {
              var defHandler = queryHandling._0;
              handlingFunc = (function (req, res) {
                  Curry._2(Logger.handleResultError, Curry._1(Logger.catchUnknown, (function (param) {
                              var reqDefault_queryParams = parseQueryParams(req);
                              var reqDefault_data = parseBodyData(req);
                              var reqDefault_session = parseSession(req);
                              var reqDefault = {
                                queryParams: reqDefault_queryParams,
                                data: reqDefault_data,
                                session: reqDefault_session
                              };
                              var result = Curry._1(defHandler, reqDefault);
                              applyHandlingResult(req, res, result);
                            })), (function (err) {
                          Curry._1(Logger.logError, err);
                          handleErrorResp(res, "Internal error", 500);
                        }));
                });
            }
            var middlewares;
            if (queryHandling.TAG === /* Multipart */0) {
              var filesHandlingConfig = queryHandling._1;
              middlewares = filesHandlingConfig ? [produceMulterFilesMiddleware(filesHandlingConfig._0, filesHandlingConfig._1)] : [Curry._1(produceMulterNoneMiddleware, undefined)];
            } else {
              middlewares = [];
            }
            return {
                    path: r[1],
                    routeType: r[0],
                    middlewares: middlewares,
                    handler: handlingFunc
                  };
          }));
    return {
            handlers: routeHandlers,
            appMwInits: [initMiddlewares],
            port: port,
            onInit: onInit
          };
  };
  return {
          buildConfig: buildConfig
        };
}

exports.ExpressDefaultServerConfiguratorFactory = ExpressDefaultServerConfiguratorFactory;
/*  Not a pure module */
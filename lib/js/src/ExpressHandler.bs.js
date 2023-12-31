// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

function wrapTryCatch(handler) {
  try {
    return Curry._1(handler, undefined);
  }
  catch (raw_obj){
    var obj = Caml_js_exceptions.internalToOCamlException(raw_obj);
    if (obj.RE_EXN_ID === Js_exn.$$Error) {
      console.log(obj._1);
    } else {
      console.log("unknown error");
    }
    return ;
  }
}

var DefaultErrorStrategy = {
  wrapTryCatch: wrapTryCatch
};

function MakeDefault(ErrorStrategy) {
  var handleHtmlResp = (function(res, html) {
    res.setHeader('content-type', 'text/html');
    res.send(html);
  });
  var handleJsonResp = (function(res, json) {
    res.setHeader('content-type', 'application/json');
    res.send(json);
  });
  var handleOpenFileResp = (function(res, filePath) {
    res.sendFile(filePath);
  });
  var handleDownloadFileResp = (function(res, filePath) {
    res.download(filePath);
  });
  var hanleRedirectResp = (function(res, redirectPath, redirectStatus) {
    res.redirect(redirectStatus, redirectPath);
  });
  var handleErrorResp = (function(res, msg, status) {
    res.status(status).send(msg);
  });
  var wrapReq = function (param) {
    return [
            param[0],
            param[1]
          ];
  };
  var primalReq = function (hReq) {
    return hReq;
  };
  var applyRes = function (param, srt) {
    var res = param[1];
    switch (srt.TAG | 0) {
      case /* Html */0 :
          return handleHtmlResp(res, srt._0);
      case /* Json */1 :
          return handleJsonResp(res, srt._0);
      case /* OpenFile */2 :
          return handleOpenFileResp(res, srt._0);
      case /* DownloadFile */3 :
          return handleDownloadFileResp(res, srt._0);
      case /* Redirect */4 :
          return hanleRedirectResp(res, srt._0, srt._1);
      case /* Error */5 :
          return handleErrorResp(res, srt._0, srt._1);
      
    }
  };
  var convert = function (handler, req, res) {
    Curry._1(ErrorStrategy.wrapTryCatch, (function (param) {
            applyRes([
                  req,
                  res
                ], Curry._1(handler, [
                      req,
                      res
                    ]));
          }));
  };
  var middlewares = [];
  var handler = function (h) {
    return /* Handler */{
            _0: [],
            _1: (function (param, param$1) {
                return convert(h, param, param$1);
              })
          };
  };
  return {
          wrapReq: wrapReq,
          applyRes: applyRes,
          primalReq: primalReq,
          convert: convert,
          middlewares: middlewares,
          handler: handler
        };
}

exports.DefaultErrorStrategy = DefaultErrorStrategy;
exports.MakeDefault = MakeDefault;
/* No side effect */

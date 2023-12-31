// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Curry = require("rescript/lib/js/curry.js");
var ExpressServer = require("../src/ExpressServer.bs.js");
var ExpressHandler = require("../src/ExpressHandler.bs.js");
var ExpressHandlerChain = require("../src/ExpressHandlerChain.bs.js");
var ExpressFileHandlerConverter = require("../src/ExpressFileHandlerConverter.bs.js");
var ExpressParseUrlHandlerConverter = require("../src/ExpressParseUrlHandlerConverter.bs.js");
var ExpressParseJsonHandlerConverter = require("../src/ExpressParseJsonHandlerConverter.bs.js");

var DefaultHandler = ExpressHandler.MakeDefault(ExpressHandler.DefaultErrorStrategy);

var QueryConverter = ExpressParseUrlHandlerConverter.Make(DefaultHandler);

var QueryHandler = ExpressHandlerChain.Make(DefaultHandler, QueryConverter);

var JsonConverter = ExpressParseJsonHandlerConverter.Make(QueryHandler);

var JsonHandler = ExpressHandlerChain.Make(QueryHandler, JsonConverter);

function getFileAwaitFields(param) {
  return [{
            name: "fileInp",
            maxCount: 1
          }];
}

function getDestPath(param) {
  return "/uploads";
}

var FileParseConfig = {
  getFileAwaitFields: getFileAwaitFields,
  getDestPath: getDestPath
};

var FileConverter = ExpressFileHandlerConverter.Make(JsonHandler, FileParseConfig);

var FileHandler = ExpressHandlerChain.Make(JsonHandler, FileConverter);

var indexPageHtml = "\r\n<form action=\"/apply-post\" method=\"post\" enctype=\"multipart/form-data\">\r\n    <h1>Test form</h1>\r\n    <input name=\"textInp\" value=\"\" style=\"display: block;\">\r\n    <textarea name=\"textAr\" style=\"display: block;\"></textarea>\r\n    <input type=\"file\" name=\"fileInp\" style=\"display: block;\">\r\n    <input type=\"submit\" style=\"display: block;\">\r\n</form>";

var stringifyAny = (function (u) {
    return u ? JSON.stringify(u) : ""
});

var routes = [
  /* Route */{
    _0: "get",
    _1: "/",
    _2: Curry._1(QueryHandler.handler, (function (r) {
            var unkToJson = (function(u) {
            return JSON.stringify(u) + ""
        });
            var urlDataStr = unkToJson(r._1);
            return {
                    TAG: /* Html */0,
                    _0: "Url data: " + urlDataStr + "<br><br>" + indexPageHtml
                  };
          }))
  },
  /* Route */{
    _0: "post",
    _1: "/apply-post",
    _2: Curry._1(FileHandler.handler, (function (r) {
            var json = "{\"json\": \"" + stringifyAny(r._0._1) + "\",\r\n        \"files\": \"" + stringifyAny(r._1) + "\"}";
            return {
                    TAG: /* Json */1,
                    _0: json
                  };
          }))
  }
];

ExpressServer.runServer(routes, [], 80, (function (param) {
        console.log("Server started!");
      }));

exports.DefaultHandler = DefaultHandler;
exports.QueryConverter = QueryConverter;
exports.QueryHandler = QueryHandler;
exports.JsonConverter = JsonConverter;
exports.JsonHandler = JsonHandler;
exports.FileParseConfig = FileParseConfig;
exports.FileConverter = FileConverter;
exports.FileHandler = FileHandler;
exports.indexPageHtml = indexPageHtml;
exports.stringifyAny = stringifyAny;
exports.routes = routes;
/* DefaultHandler Not a pure module */

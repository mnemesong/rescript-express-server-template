const path = require("path");

const pathResolve = (srcName) => require(
        path.resolve(module.path, "lib", "js", "rescript", "src", srcName + ".bs"));

module.exports.ExpressAuthSessionHandlerConverter =
    pathResolve("ExpressAuthSessionHandlerConverter");

module.exports.ExpressFileHandlerConverter =
    pathResolve("ExpressFileHandlerConverter");

module.exports.ExpressHandler =
    pathResolve("ExpressHandler");

module.exports.ExpressHandlerChain =
    pathResolve("ExpressHandlerChain");

module.exports.ExpressParseJsonHandlerConverter =
    pathResolve("ExpressParseJsonHandlerConverter");

module.exports.ExpressParseUrlHandlerConverter =
    pathResolve("ExpressParseUrlHandlerConverter");

module.exports.ExpressServer =
    pathResolve("ExpressServer");

module.exports.ExpressSessionHandlerConverter =
    pathResolve("ExpressSessionHandlerConverter");
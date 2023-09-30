const path = require("path");

const pathResolve = (srcName) => require(
        path.resolve(module.path, "lib", "js", "rescript", "src", srcName + ".bs"));

module.exports.ExpressDefaultLogger = pathResolve("ExpressDefaultLogger");

module.exports.ExpressDefaultRequestManager =
    pathResolve("ExpressDefaultRequestManager");

module.exports.ExpressDefaultResponseManager =
    pathResolve("ExpressDefaultResponseManager");

module.exports.ExpressDefaultServerConfigurator =
    pathResolve("ExpressDefaultServerConfigurator");

module.exports.ExpressServer = 
    pathResolve("ExpressServer");

module.exports.ExpressServerTemplate =
    pathResolve("ExpressServerTemplate");
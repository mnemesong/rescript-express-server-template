open ExpressServer
open ExpressDefaultLogger
open ExpressDefaultServerConfigurator
open ExpressDefaultRequestManager
open ExpressDefaultResponseManager

type routeType = routeType
type handlerFunc = handlerFunc
type appMiddlewareInit = appMiddlewareInit
type middleware = middleware
type handler = handler
type path = path
type port = port
type route<'a> = route<'a>
type effect<'a, 'b> = effect<'a, 'b>
type handlingResult<'a, 'b> = handlingResult<'a, 'b>
type serverStartConfig = serverStartConfig
type reqDefault = reqDefault
type reqMultipart = reqMultipart
type fileField = (string, int)
type file = {
    fieldname: string,
    originalname: string,
    encoding: string,
    mimetype: string,
    destination: string,
    filename: string,
    path: string,
    size: int
}

module ExpressResponseManagerTemplate = 
    ExpressDefaultResponseManagerFactory(ExpressDefaultLogger)

module ExpressRequestManagerTemplate = 
    ExpressDefaultRequestManagerFactory(ExpressDefaultLogger)

module ExpressServerConfiguratorTemplate = 
    ExpressDefaultServerConfiguratorFactory(
        ExpressDefaultLogger, 
        ExpressResponseManagerTemplate, 
        ExpressRequestManagerTemplate
    )

module ExpressServerTemplate = ExpressServerFactory(ExpressDefaultLogger)
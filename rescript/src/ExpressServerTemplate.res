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
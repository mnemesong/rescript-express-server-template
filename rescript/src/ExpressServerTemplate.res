open ExpressServer
open ExpressDefaultLogger
open ExpressDefaultServerConfigurator
open ExpressDefaultRequestManager
open ExpressDefaultResponseManager
open Belt

type routeType = routeType

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
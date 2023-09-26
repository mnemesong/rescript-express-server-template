open ExpressServerTemplate
open ExpressLoggerStub
open ExpressControllerStub
open ExpressRequestResponseManagerStub

module ExpressServerTemplateTest = 
    ExpressServerTemplate(
        ExpressLoggerStub,
        ExpressControllerStub,
        ExpressRequestResponseManagerStub
    )

switch(ExpressServerTemplateTest.run(80)) {
    | Ok(_) => ()
    | Error(e) => ExpressLoggerStub.log(ExpressLoggerStub.err, e)
}
open ExpressServerTemplate
open ExpressLoggerStub
open ExpressControllerStub

module ExpressServerTemplateTest = 
    ExpressServerTemplate(
        ExpressLoggerStub,
        ExpressControllerStub
    )

switch(ExpressServerTemplateTest.run(80)) {
    | Ok(_) => ()
    | Error(e) => ExpressLoggerStub.log(ExpressLoggerStub.err, e)
}
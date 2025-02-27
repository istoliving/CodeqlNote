/**
 * @kind path-problem
 */

import go
import DataFlow::PathGraph


// class GfSource extends DataFlow::Node {
//     GfSource(){
//         exists( Function fun, CallExpr call| 
//             fun.hasQualifiedName("github.com/grafana/grafana/pkg/api/routing.RouteRegister",
//         ["Get","Post","Delete","Put","Patch","Any"]) and 
//           //["Get","Post"]) and 
//         call.getTarget() = fun and 
//         call.getCalleeExpr()= this.asExpr()
//         )
//     }
// }

class GfSource1 extends DataFlow::Node {
    GfSource1(){
        exists( Function fun, CallExpr call,SelectorExpr se| 
            call.getTarget().hasQualifiedName("github.com/grafana/grafana/pkg/api/routing.RouteRegister",
        ["Get","Post","Delete","Put","Patch","Any"]) and 
          //["Get","Post"]) and 
          (call.getAnArgument() =se or call.getAnArgument().getAChildExpr()=se) and
          fun.getAReference() = se.getSelector() and 
          fun.getAParameter()= this.asParameter()
        )
    }
}

// class GfSource1 extends DataFlow::Node {
//     GfSource1(){
//         exists(Type tp, Function fun,TypeEntity ent |
//             tp.hasQualifiedName("github.com/grafana/grafana/pkg/api", "HTTPServer")and
//             ent = tp.getEntity() and
//             ent.getAReference().getEnclosingFunction() = fun.getFuncDecl())
//     }
// }

// predicate isApi(DataFlow::Node expSrc, DataFlow::Node expDest) {
//     exists(CallExpr call|
//         call=expSrc.asExpr()  and 
//         call.getArgument(0).getType().toString()="string" and
//         call.getNumArgument()=2 and
//         call.getArgument(1).(CallExpr).getTarget().getAParameter()=expDest.asParameter()
//         )
// }

// predicate isApi1(DataFlow::Node expSrc, DataFlow::Node expDest) {
//     exists(CallExpr call|
//         call=expSrc.asExpr()  and 
//         call.getArgument(0).getType().toString()="string" and
//         call.getNumArgument()=2 and
//         call.getArgument(1).(CallExpr).getTarget().getAParameter()=expDest.asParameter()
//         )
// }


predicate isOther(DataFlow::Node expSrc, DataFlow::Node expDest) {
    exists(CallExpr call, SimpleAssignStmt sas|
        call.getTarget().getName().toString()="Params" and 
        call.getArgument(0)=expSrc.asExpr() and
        sas.getRhs().getAChild()=call.getParent*().getAChild() and
        sas.getRhs()=expDest.asExpr()
        )
}

// predicate isWrap(DataFlow::Node expSrc, DataFlow::Node expDest) {
//     exists(CallExpr call,Function fun|
//         fun.hasQualifiedName("github.com/grafana/grafana/pkg/api/routing", "Wrap") and 
//         fun.getAReference() = expSrc.asExpr() and 
//         call.getTarget() = fun and
//         call.getArgument(0).(CallExpr).getTarget().getAParameter()=expDest.asParameter()
//         )
// }

class Gfconfig extends TaintTracking::Configuration{

    Gfconfig() { this = "Gfconfig" }

    override predicate isSource(DataFlow::Node source) {
        source instanceof GfSource1
    }
  
    override predicate isSink(DataFlow::Node sink) {
        exists(Function fun ,CallExpr call| 
            fun.hasQualifiedName("os", "Open") and 
        call.getTarget() = fun and 
        call.getAnArgument()= sink.asExpr()
        )
    }

    /**
     * sink参数只能是两个，第二个参数才是真正的sink
     */
    override predicate isAdditionalTaintStep(DataFlow::Node expSrc, DataFlow::Node expDest) {
      isOther(expSrc, expDest)
      }
  }

from Gfconfig gf,DataFlow::PathNode source,DataFlow::PathNode sink
where gf.hasFlowPath(source, sink)
select source.getNode(), source, sink, "test"
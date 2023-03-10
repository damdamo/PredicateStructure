import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class ListExampleTests: XCTestCase {
  
    
  func testSwimmingPool() {
    let p1 = PnmlParser()
    let (net1, marking1) = p1.loadPN(filePath: "SwimmingPool-1.pnml")

//    let ctlFormula1: CTL = .EF(.ap("GetK"))
//    let eval1 = ctlFormula1.eval(net: net1)
//    print(eval1.count)
//    print(eval1)
//
//    print("---------------")
//
//    let ctlFormula2: CTL = .AX(.ap("GetK"))
//    let eval2 = ctlFormula2.eval(net: net1)
//    print(eval2.count)
//
//    print("---------------")
//
//    let ctlFormula3: CTL = .AG(.ap("GetK"))
//    let eval3 = ctlFormula3.eval(net: net1)
//    print(eval3.count)
    
//    let ctlFormula4: CTL = .and(.ap("GetK"), .ap("RBag"))
//    let eval4 = ctlFormula4.eval(net: net1).revertTilde()
//    print(eval4.count)
//    let eval4Simplified = eval4.simplified()
//    print(eval4Simplified.count)
//      print("---------------")
  
    // Example to observe that we do not need to compute EF fully to return true.
    // Thanks to the lowest fixpoint, at each step, the state space can only grow.
    // Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
    // The additional optimisation happens when eval is called with the given marking
//    let ctlFormula1: CTL = .EF(.ap("RBag"))
//    let eval1 = ctlFormula1.eval(marking: marking1, net: net1)
//    print(eval1)
//    print("---------------")
    // When we call eval with the marking, there is an addi
//    print(ctlFormula1.eval(net: net1))
    
//    let ctlFormula2: CTL = .AF(.ap("RBag"))
//    let eval2 = ctlFormula2.eval(marking: marking1, net: net1)
//    print(eval2)
//    print("---------------")
//    print(ctlFormula1.eval(net: net1))
    
//    let ctlFormula3: CTL = .EU(.ap("GetB"), .ap("RBag"))
//    let eval3 = ctlFormula3.eval(marking: marking1, net: net1)
//    print(eval3)
//    print("---------------")
//    print(ctlFormula3.eval(net: net1))
  }
  
    
}
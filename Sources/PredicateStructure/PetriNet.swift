/// A Petri net.
///
/// `PetriNet` is a generic type, accepting two types representing the set of places and the set
/// of transitions that structurally compose the model. Both should conform to `CaseIterable`,
/// which guarantees that the set of places (resp. transitions) is bounded, and known statically.
/// The following example illustrates how to declare the places and transition of a simple Petri
/// net representing an on/off switch:
///
///     enum P: Place {
///       typealias Content = Int
///       case on, off
///     }
///
///     enum T: Transition {
///       case switchOn, switchOff
///     }
///
/// Petri net instances are created by providing the list of the preconditions and postconditions
/// that compose them. These should be provided in the form of arc descriptions (i.e. instances of
/// `ArcDescription`) and fed directly to the Petri net's initializer. The following example shows
/// how to create an instance of the on/off switch:
///
///
///     let model = PetriNet<P, T>(
///       .pre(from: .on, to: .switchOff),
///       .post(from: .switchOff, to: .off),
///       .pre(from: .off, to: .switchOn),
///       .post(from: .switchOn, to: .on),
///     )
///
/// Petri net instances only represent the structual part of the corresponding model, meaning that
/// markings should be stored externally. They can however be used to compute the marking resulting
/// from the firing of a particular transition, using the method `fire(transition:from:)`. The
/// following example illustrates this method's usage:
///
///     if let marking = model.fire(.switchOn, from: [.on: 0, .off: 1]) {
///       print(marking)
///     }
///     // Prints "[.on: 1, .off: 0]"
///
public class PetriNet
{

  public typealias ArcLabel = Int
  public typealias PlaceType = String
  public typealias TransitionType = String

  /// The description of an arc.
  public struct ArcDescription {

    /// The place to which the arc is connected.
    fileprivate let place: PlaceType

    /// The transition to which the arc is connected.
    fileprivate let transition: TransitionType

    /// The arc's label.
    fileprivate let label: ArcLabel

    /// The arc's direction.
    fileprivate let isPre: Bool

    private init(place: PlaceType, transition: TransitionType, label: ArcLabel, isPre: Bool) {
      self.place = place
      self.transition = transition
      self.label = label
      self.isPre = isPre
    }

    /// Creates the description of a precondition arc.
    ///
    /// - Parameters:
    ///   - place: The place from which the arc comes.
    ///   - transition: The transition to which the arc goes.
    ///   - label: The arc's label.
    public static func pre(
      from place: PlaceType,
      to transition: TransitionType,
      labeled label: ArcLabel)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: true)
    }

    /// Creates the description of a postcondition arc.
    ///
    /// - Parameters:
    ///   - transition: The transition from which the arc comes.
    ///   - place: The place to which the arc goes.
    ///   - label: The arc's label.
    public static func post(
      from transition: TransitionType,
      to place: PlaceType,
      labeled label: ArcLabel)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: false)
    }

  }

  /// Places of the net
  public let places: Set<PlaceType>
  /// Transitions of the net
  public let transitions: Set<TransitionType>
  /// This net's input matrix.
  public let input: [TransitionType: [PlaceType: ArcLabel]]
  /// This net's output matrix.
  public let output: [TransitionType: [PlaceType: ArcLabel]]
  /// The maximum number of tokens inside a place
  public let capacity: [PlaceType: Int]

  /// Initializes a Petri net with a sequence describing its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A sequence containing the descriptions of the Petri net's arcs.
  public init(places: Set<PlaceType>, transitions: Set<TransitionType>, arcs: [ArcDescription], capacity: [PlaceType: Int] = [:]) {
    
    self.places = places
    self.transitions = transitions
    var pre: [TransitionType: [PlaceType: ArcLabel]] = [:]
    var post: [TransitionType: [PlaceType: ArcLabel]] = [:]

    for arc in arcs {
      if arc.isPre {
        PetriNet.add(arc: arc, to: &pre)
      } else {
        PetriNet.add(arc: arc, to: &post)
      }
    }
    
    for (transition, dicPlaceToArc) in pre {
      precondition(transitions.contains(transition), "All transitions have not been declared in transitions")
      for (place, _) in dicPlaceToArc {
        precondition(places.contains(place), "All places have not been declared in places")
      }
    }
    
    self.input = pre
    self.output = post
    if capacity == [:] {
      var newCap: [PlaceType: Int] = [:]
      for place in places {
        newCap[place] = 20
      }
      self.capacity = newCap
    } else {
      precondition(Set(capacity.keys) == places, "The capacity do not match the required places")
      self.capacity = capacity
    }
  }

  /// Initializes a Petri net with descriptions of its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A variadic argument representing the descriptions of the Petri net's arcs.
  public convenience init(places: Set<PlaceType>, transitions: Set<TransitionType>, arcs: ArcDescription..., capacity: [PlaceType: Int] = [:]) {
    let newArcs: [ArcDescription] = arcs
    self.init(
      places: places,
      transitions: transitions,
      arcs: newArcs,
      capacity: capacity)
  }
  

  /// Computes the marking resulting from the firing of the given transition, from the given
  /// marking, assuming the former is fireable.
  /// If the number of tokens in a place would be greater than the capacity of the place, it returns nil.
  /// - Parameters:
  ///   - transition: The transition to fire.
  ///   - marking: The marking from which the given transition should be fired.
  /// - Returns:
  ///   The marking that results from the firing of the given transition if it is fireable, or
  ///   `nil` otherwise.
  public func fire(transition: TransitionType, from marking: Marking)
    -> Marking?
  {
    var newMarking = marking

    let pre = input[transition]
    let post = output[transition]

    for place in places {
      if let n = pre?[place] {
        guard marking[place]! >= n
          else { return nil }
        newMarking[place]! -= n
      }

      if let n = post?[place] {
        newMarking[place]! += n
        // If the marking generates a number of tokens greater than the capacity, we return nil
        if newMarking[place]! > capacity[place]! {
          return nil
        }
      }
    }

    return newMarking
  }

  /// Internal helper to process preconditions and postconditions.
  private static func add(
    arc: ArcDescription,
    to matrix: inout [TransitionType: [PlaceType: ArcLabel]])
  {
    if var column = matrix[arc.transition] {
      precondition(column[arc.place] == nil, "duplicate arc declaration")
      column[arc.place] = arc.label
      matrix[arc.transition] = column
    } else {
      matrix[arc.transition] = [arc.place: arc.label]
    }
  }

}

extension PetriNet {
  
  
  /// Compute the inverse of the firing function. It takes the marking and the transition, and it adds tokens in the pre places and removes token in the post places.
  /// - Parameters:
  ///   - marking: The marking
  ///   - transition: The transition
  /// - Returns: The new marking after the revert firing.
  public func revert(marking: Marking, transition: TransitionType) -> Marking? {
    var markingRes = marking
    for place in places {
      if let pre = input[transition]?[place] {
        if let post = output[transition]?[place] {
          if marking[place]! <= post {
            markingRes[place] = pre
          } else {
            markingRes[place] = marking[place]! + pre - post
          }
        } else {
          markingRes[place] = marking[place]! + pre
        }
        if marking[place]! > capacity[place]! {
          return nil
        }
      } else {
        if let post = output[transition]?[place] {
          if marking[place]! <= post {
            markingRes[place] = 0
          } else {
            markingRes[place] = marking[place]! - post
          }
        }
      }
    }
    return markingRes
  }
  
  /// Apply the revert function for all transitions
  /// - Parameter marking: The marking
  /// - Returns: A set of markings that contains each new marking for each transition
  public func revert(marking: Marking) -> Set<Marking> {
    var res: Set<Marking> = []
    for transition in transitions {
      if let rev = revert(marking: marking, transition: transition) {
        res.insert(rev)
      }
    }
    return res
  }
  
  /// Apply the revert on a set of markings.
  /// - Parameter markings: The set of markings
  /// - Returns: The new sets of markings, which is a union of all revert firing for each marking.
  public func revert(markings: Set<Marking>) -> Set<Marking> {
    var res: Set<Marking> = []
    for marking in markings {
      res = res.union(revert(marking: marking))
    }
    return res
  }
  
  /// Return a marking that contains the minimum amount of tokens in each required place to allow a transition to be fired.
  func inputMarkingForATransition(transition: TransitionType) -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      if let v = input[transition]?[place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking, net: self)
  }
  
  /// Return a marking that contains the exact amount of tokens after a firing of a transition
  func outputMarkingForATransition(transition: TransitionType) -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      if let v = output[transition]![place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking, net: self)
  }
  
  func zeroMarking() -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      dicMarking[place] = 0
    }
    return Marking(dicMarking, net: self)
  }
  
}

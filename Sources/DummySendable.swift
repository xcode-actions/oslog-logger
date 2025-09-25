import Foundation
import os


/* Sendable exists from Swift 5.5, however OSLog is only Sendable starting from Xcode with at least Swift 5.8.
 * That being said, the Sendability issues regarding OSLog not being Sendable only trigger errors when compiling with Swift 5.5 exactly,
 *  so we cheat and make a dummy Sendable protocol for Swift 5.5 too. */
#if swift(>=5.6)
public protocol GHALogger_Sendable : Sendable {}
#else
public protocol GHALogger_Sendable {}
#endif

#if swift(>=5.3)
@available(macOS 11.0, tvOS 14.0, iOS 14.0, watchOS 7.0, *)
extension Logger : GHALogger_Sendable {}
#endif

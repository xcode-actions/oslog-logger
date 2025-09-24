import Foundation
import os


#if swift(>=5.5)
public protocol GHALogger_Sendable : Sendable {}
#else
public protocol GHALogger_Sendable {}
#endif

#if swift(>=5.3)
@available(macOS 11.0, tvOS 14.0, iOS 14.0, watchOS 7.0, *)
extension Logger : GHALogger_Sendable {}
#endif

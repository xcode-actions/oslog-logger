import Foundation
import os



/* This represents the underlying logger we’ll use to do the actual logging.
 * On macOS 11+, tvOS 14+, etc. we use os.Logger.
 * On lower platforms we use OSLog.
 *
 * Why not use OSLog everywhere?
 * Because it is broken (at least on macOS 14/iOS 17) and the subsystem and category are not properly set. */
internal enum UnderlyingLogger : GHALogger_Sendable {
	
	case oslog(OSLog)
	case logger(GHALogger_Sendable)
	
	var oslog: OSLog! {
		switch self {
			case .oslog(let r): return r
			case .logger:       return nil
		}
	}
	
	@available(macOS 11, tvOS 14, iOS 14, watchOS 7, *)
	var logger: Logger! {
		switch self {
			case .oslog:         return nil
			case .logger(let r): return (r as! Logger)
		}
	}
	
}

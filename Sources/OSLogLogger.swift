import Foundation
import os.log

import Logging



public struct OSLogLogger : LogHandler {
	
	public static let pubMetaPrefix = "pub."
	
	public var logLevel: Logging.Logger.Level = .info
	
	public var metadata: Logging.Logger.Metadata = [:] {
		didSet {flatMetadataCache = flatMetadataArrays(metadata)}
	}
	public var metadataProvider: Logging.Logger.MetadataProvider?
	
	/**
	 Convenience init that splits the label in a subsystem and a category.
	 
	 The format of the lable should be as follow: "subsystem:category".
	 The subsystem _should_ be a reverse-DNS identifier (as per Apple doc).
	 Example: "`com.xcode-actions.oslog-logger:LogHandler`".
	 
	 If there is no colon in the given label
	 we set the category to “`<none>`” (it cannot be `nil`, suprisingly, and we decided against the empty String to be able to still filter this category)
	 and we use the whole label for the subsystem.
	 
	 It is _not_ possible to have a subsystem containing a colon using this initializer. */
	public init(label: String, metadataProvider: Logging.Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		let split = label.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
		let subsystem = split[0] /* Cannot not exists as we do not omit empty subsequences in the split. */
		let categoryCollection = split.dropFirst()
		assert(categoryCollection.count <= 1)
		
		self.init(subsystem: String(subsystem), category: categoryCollection.first.flatMap(String.init) ?? "<none>", metadataProvider: metadataProvider)
	}
	
	public init(subsystem: String, category: String, metadataProvider: Logging.Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		self.metadataProvider = metadataProvider
		self.oslog = .init(subsystem: subsystem, category: category)
	}
	
	/* Honestly I think this init is useless.
	 * I only included it because the init with a structured category exists in OSLog,
	 *  but this init does not even exists for os.Logger, so it is probably useless. */
	@available(macOS 10.14, *)
	public init(subsystem: String, category: OSLog.Category, metadataProvider: Logging.Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		self.metadataProvider = metadataProvider
		self.oslog = .init(subsystem: subsystem, category: category)
	}
	
	public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
		get {metadata[metadataKey]}
		set {metadata[metadataKey] = newValue}
	}
	
	public func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata logMetadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
		let effectiveFlatMetadata: (public: [String], private: [String])
		if let m = mergedMetadata(with: logMetadata) {effectiveFlatMetadata = flatMetadataArrays(m)}
		else                                         {effectiveFlatMetadata = flatMetadataCache}
		
		if #available(macOS 11, *) {
			switch (effectiveFlatMetadata.public.isEmpty, effectiveFlatMetadata.private.isEmpty) {
				case ( true,  true): os_log(Self.logLevelToLogType(level), "\(message, privacy: .public)")
				case (false,  true): os_log(Self.logLevelToLogType(level), "\(message, privacy: .public)\n  ▷ \(effectiveFlatMetadata.public .joined(separator: "\n  ▷ "), privacy: .public)")
				case ( true, false): os_log(Self.logLevelToLogType(level), "\(message, privacy: .public)\n  ▷ \(effectiveFlatMetadata.private.joined(separator: "\n  ▷ "), privacy: .private)")
				case (false, false): os_log(Self.logLevelToLogType(level), "\(message, privacy: .public)\n  ▷ \(effectiveFlatMetadata.public .joined(separator: "\n  ▷ "), privacy: .public)\n  ▷ \(effectiveFlatMetadata.private.joined(separator: "\n  ▷ "), privacy: .private)")
			}
			/* If we could use os.Logger directly.
			 * Note these calls probably do more or less what the os_log call above does… */
//			let oslogger = os.Logger(oslog)
//			switch logLevel {
//				case .trace:    oslogger.trace   (...)
//				case .debug:    oslogger.debug   (...)
//				case .info:     oslogger.info    (...)
//				case .notice:   oslogger.notice  (...)
//				case .warning:  oslogger.warning (...)
//				case .error:    oslogger.error   (...)
//				case .critical: oslogger.critical(...)
//			}
		} else {
			switch (effectiveFlatMetadata.public.isEmpty, effectiveFlatMetadata.private.isEmpty) {
				case ( true,  true): os_log("%{public}@",                                   log: oslog, type: Self.logLevelToLogType(level), "\(message)")
				case (false,  true): os_log("%{public}@\n  ▷ %{public}@",                   log: oslog, type: Self.logLevelToLogType(level), "\(message)", effectiveFlatMetadata.public .joined(separator: "\n  ▷ "))
				case ( true, false): os_log("%{public}@\n  ▷ %{private}@",                  log: oslog, type: Self.logLevelToLogType(level), "\(message)", effectiveFlatMetadata.private.joined(separator: "\n  ▷ "))
				case (false, false): os_log("%{public}@\n  ▷ %{public}@\n  ▷ %{private}@",  log: oslog, type: Self.logLevelToLogType(level), "\(message)", effectiveFlatMetadata.public .joined(separator: "\n  ▷ "), effectiveFlatMetadata.private.joined(separator: "\n  ▷ "))
			}
		}
	}
	
	/* Note about os.Logger:
	 * os.Logger has all the methods to log using the same log levels as Logging.Logger,
	 *  however it seems the core log method of os.Logger is still using OSLogType under the hood,
	 *  and thus do not have actual access to the additional log levels it provides through its API…
	 * If we decide to use os.Logger at some point we should _probably_ use the methods provided to log at the level we want directly,
	 *  in case either Apple uses private stuff and actually logs at the given level or if Apple adds the log levels in question later. */
	private static func logLevelToLogType(_ logLevel: Logging.Logger.Level) -> OSLogType {
		switch logLevel {
			case .trace:    return .debug
			case .debug:    return .debug
			case .info:     return .info
			case .notice:   return .default
			case .warning:  return .error
			case .error:    return .error
			case .critical: return .fault
		}
	}
	
	/* os.Logger is only available from macOS 11.
	 * Let’s be as compatible as possible. */
	private var oslog: OSLog
	
	private var flatMetadataCache = (public: [String](), private: [String]())
	
}


/* Adapted from CLTLogger. */
private extension OSLogLogger {
	
	/**
	 Merge the logger’s metadata, the provider’s metadata and the given explicit metadata and return the new metadata.
	 If the provider’s metadata and the explicit metadata are `nil`, returns `nil` to signify the current `flatMetadataCache` can be used. */
	func mergedMetadata(with explicit: Logging.Logger.Metadata?) -> Logging.Logger.Metadata? {
		var metadata = metadata
		let provided = metadataProvider?.get() ?? [:]
		
		guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
			/* All per-log-statement values are empty or not set: we return nil. */
			return nil
		}
		
		if !provided.isEmpty {
			metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
		}
		if let explicit = explicit, !explicit.isEmpty {
			metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
		}
		return metadata
	}
	
	func flatMetadataArrays(_ metadata: Logging.Logger.Metadata) -> (public: [String], private: [String]) {
		var  pubMeta = [String]()
		var privMeta = [String]()
		metadata.lazy.sorted{ $0.key < $1.key }.forEach{ keyVal in
			let flat = prettyMetadataKeyValPair(keyVal)
			if keyVal.key.starts(with: Self.pubMetaPrefix) { pubMeta.append(flat)}
			else                                           {privMeta.append(flat)}
		}
		return (pubMeta, privMeta)
	}
	
	func flatMetadataArray(_ metadata: Logging.Logger.Metadata) -> [String] {
		return metadata.lazy.sorted{ $0.key < $1.key }.map(prettyMetadataKeyValPair)
	}
	
	func prettyMetadataKeyValPair(_ pair: (key: String, value: Logging.Logger.MetadataValue)) -> String {
		return (
			pair.key.processForLogging(escapingMode: .escapeScalars(asASCII: true, octothorpLevel: 1), newLineProcessing: .escape).string +
			": " +
			prettyMetadataValue(pair.value)
		)
	}
	
	func prettyMetadataValue(_ v: Logging.Logger.MetadataValue) -> String {
		/* We return basically v.description, but dictionary keys are sorted. */
		return switch v {
			case .string(let str):      str.processForLogging(escapingMode: .escapeScalars(asASCII: true, octothorpLevel: nil, showQuotes: true), newLineProcessing: .escape).string
			case .array(let array):     #"["# + array.map{ prettyMetadataValue($0) }.joined(separator: ", ") + #"]"#
			case .dictionary(let dict): #"["# +              flatMetadataArray(dict).joined(separator: ", ") + #"]"#
			case .stringConvertible(let c): prettyMetadataValue(.string(c.description))
		}
	}
	
}

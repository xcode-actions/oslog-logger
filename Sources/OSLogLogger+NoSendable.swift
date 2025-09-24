import Foundation

import Logging



extension OSLogLogger {
	
	/**
	 Convenience init that splits the label in a subsystem and a category.
	 
	 The format of the label should be as follow: "subsystem:category".
	 The subsystem _should_ be a reverse-DNS identifier (as per Apple doc).
	 Example: "`com.xcode-actions.oslog-logger:LogHandler`".
	 
	 If there is no colon in the given label
	  we set the category to “`<none>`” (it cannot be `nil`, surprisingly, and we decided against the empty String to be able to still filter this category)
	  and we use the whole label for the subsystem.
	 
	 It is _not_ possible to have a subsystem containing a colon using this initializer. */
	public init(label: String, metadataProvider: Logging.Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		let split = label.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
		let subsystem = split[0] /* Cannot not exists as we do not omit empty subsequences in the split. */
		let categoryCollection = split.dropFirst()
		assert(categoryCollection.count <= 1)
		
		self.init(subsystem: String(subsystem), category: categoryCollection.first.flatMap(String.init) ?? "<none>", metadataProvider: metadataProvider)
	}
	
}

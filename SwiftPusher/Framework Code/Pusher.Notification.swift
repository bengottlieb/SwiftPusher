//
//  Pusher.Notification.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation


extension Pusher {
	public class Notification {
		public var payload: [String: Any]?
		public var target: String?
		public var title: String?
		public var soundName: String?
		public var badgeCount: Int?
		public var contentAvailable = false
		
		
		public let identifier: Int
		public var priority = 5
		
		public init(payload: [String: Any]? = nil, target: String? = nil) {
			self.payload = payload
			self.target = target
			self.identifier = Int(Date().timeIntervalSince1970)
		}
		
		var fullJSONPayload: [String: Any] {
			var aps = self.payload ?? [:]
			
			if let title = self.title { aps["alert"] = title }
			if self.contentAvailable { aps["content-available"] = 1 }
			if let badgeCount = self.badgeCount { aps["badge"] = badgeCount }
			if let soundName = self.soundName { aps["sound"] = soundName }

			return self.payload ?? ["aps": aps]
		}
		
		public var payloadData: Data? {
			var data = Data(bytes: [0, 0, 0, 0, 0])
			
			if let tokenData = self.target?.dataFromHex { data.append(data: tokenData, withPrefix: 1) }
			if let json = try? JSONSerialization.data(withJSONObject: self.fullJSONPayload, options: []) { data.append(data: json, withPrefix: 2) }
			
			
			let length: UInt32 = UInt32(data.count) - 5
			let header: [UInt8] = [2, UInt8((length >> 24) & 0xFF), UInt8((length >> 16) & 0xFF), UInt8((length >> 8) & 0xFF), UInt8((length) & 0xFF) ]
			
			data.replaceSubrange(data.startIndex..<(data.index(0, offsetBy: 5)), with: header)
			
			return data
		}
	}
}

extension Data {
	mutating func append(data: Data, withPrefix prefix: UInt8) {
		let length = data.count
		let prefixArray = [prefix, UInt8((length >> 8) % 256), UInt8(length % 256)]
		
		
		self.append(prefixArray, count: prefixArray.count)
		
		self.append(data)
	}
	
	public var hexString: String {
		
		let result: String = self.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> String in
			var string = ""
			for i in 0..<self.count {
				let byte = Int(bytes[i])
				let chunk = String(format: "%02x", byte)
				string += chunk
			}
			return string
		}
		
		return result;
	}

}

extension String {
	var dataFromHex: Data? {
		guard self.count == 64 else { return nil }
		var result = Data()
		
		for i in stride(from: 0, to: 64, by: 2) {
			let firstIndex = self.index(self.startIndex, offsetBy: i)
			let lastIndex = self.index(firstIndex, offsetBy: 1)
			let sub = self[firstIndex...lastIndex]
			guard var byte = UInt8(sub, radix: 16) else { return nil }
			result.append(&byte, count: 1)
		}
		
		return result
	}
}

//
//  Pusher.Key.swift
//  
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Foundation

extension Pusher {
	public struct Key {
		public init(name: String, data: Data? = nil, bundle: Bundle = .main, filename: String = "apns.p8") {
			self.bundle = bundle
			self.name = name
			self.filename = filename
			self.data = data
		}
		
		let name: String
		var filename = "apns.p8"
		var data: Data?
		let bundle: Bundle
		var keyData: Data {
			get throws {
				if let data { return data }
				let keyURL = bundle.url(forResource: filename, withExtension: nil)!
				return try Data(contentsOf: keyURL)
			}
		}
	}
}

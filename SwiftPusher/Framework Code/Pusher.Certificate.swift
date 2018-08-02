//
//  Pusher.Certificate.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Pusher {
	public struct Certificate {
		public let pkcs12Data: Data
		public let password: String
		
		public init(data: Data, password: String) {
			self.pkcs12Data = data
			self.password = password
		}
		
		func buildSSLCertificate() throws -> CFArray? {
			let options = [kSecImportExportPassphrase as String: self.password]
			var items: CFArray?
			let status = SecPKCS12Import(self.pkcs12Data as CFData, options as CFDictionary, &items)
			
			guard let parts = items as? [[String: Any]], status == errSecSuccess else { throw Pusher.Error.pkcs12Decode }
			
			if let first = parts.first, let identity = first["identity"] { return [identity] as CFArray }
			
			throw Pusher.Error.pkcs12NoItems
		}
	}
}


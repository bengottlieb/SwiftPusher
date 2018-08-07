//
//  Pusher.Certificate.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Pusher {
	public struct Certificate: Equatable {
		public let pkcs12Data: Data
		public let password: String
		
		public static func validate(pkcs: Data, password: String) -> Bool {
			let cert = Certificate(data: pkcs, password: password)
			
			do {
				return try cert.buildSSLCertificate() != nil
			} catch {
				return false
			}
			
		}
		
		static public func ==(lhs: Certificate, rhs: Certificate) -> Bool {
			return lhs.pkcs12Data == rhs.pkcs12Data && lhs.password == rhs.password
		}
		
		public init(data: Data, password: String) {
			self.pkcs12Data = data
			self.password = password
		}
		
		func buildSSLCertificate() throws -> CFArray? {
			let options = [kSecImportExportPassphrase as String: self.password]
			var items: CFArray?
			let status = SecPKCS12Import(self.pkcs12Data as CFData, options as CFDictionary, &items)
			
			if status == errSecAuthFailed {		//  -25293
				throw Pusher.Error.pkcs12Password
			} else if status != errSecSuccess {
				print("Error: \(status)")
			}
			
			guard let parts = items as? [[String: Any]], status == errSecSuccess else { throw Pusher.Error.pkcs12Decode }
			
			if let first = parts.first, let identity = first["identity"] { return [identity] as CFArray }
			
			throw Pusher.Error.pkcs12NoItems
		}
	}
}


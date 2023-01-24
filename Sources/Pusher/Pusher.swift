//
//  Pusher.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/21/23.
//

import Foundation
import CryptoKit
import SwiftJWT

public class Pusher {
	public static let instance = Pusher()
	
	public func setup(teamID: String, key: Key, bundleID: String) {
		self.teamID = teamID
		self.key = key
		self.bundleID = bundleID
	}
		
	var teamID = ""
	var key: Key!
	var bundleID = ""
	public var server = Server.sandbox
	
	public func send(message: String, to token: String) async throws {
		assert(!teamID.isEmpty && !bundleID.isEmpty && key != nil, "Please call Pusher.instance.setup(teamID:key:bundleID:) before sending.")
		
		let path = "/3/device/\(token)"
		let jwt = try buildJWT()
		let headers: [String: String] = [
		  "apns-topic": bundleID,
		  "authorization": "bearer \(jwt)",
		  "Content-Type": "application/json; charset=utf-8",
		]
		let payload = APNS(aps: .init(alert: message))
		let url = server.url.appending(path: path)
		var request = URLRequest(url: url)
		let body = try JSONEncoder().encode(payload)
		request.httpBody = body
		request.httpMethod = "post"
		request.allHTTPHeaderFields = headers
		
		let r = try await URLSession.shared.data(for: request)
		print(r)
	}
	
	struct APNS: Encodable {
		let aps: APS
		
		struct APS: Encodable {
			let alert: String
			let sound = "default"
		}
	}
	
	func buildJWT() throws -> String {
		let keyData = try key!.keyData
		let header = Header(kid: key.name)
		let claims = PusherClaims(iss: teamID)
		let signer = JWTSigner.es256(privateKey: keyData)
		var jwt = JWT(header: header, claims: claims)
		
		return try jwt.sign(using: signer)
	}
	
	struct PusherClaims: Claims, Encodable {
		var iss: String
		var iat = Int(Date().timeIntervalSince1970)
	}
}

extension Pusher {
	public struct Key {
		public init(name: String, data: Data? = nil, filename: String = "apns.p8") {
			self.name = name
			self.filename = filename
			self.data = data
		}
		
		let name: String
		var filename = "apns.p8"
		var data: Data?
		var keyData: Data {
			get throws {
				if let data { return data }
				let keyURL = Bundle.main.url(forResource: filename, withExtension: nil)!
				return try Data(contentsOf: keyURL)
			}
		}
	}
	public enum Server: String, Codable { case sandbox, production
		var url: URL {
			switch self {
			case .sandbox: return URL(string: "https://api.sandbox.push.apple.com")!
			case .production: return URL(string: "https://api.push.apple.com")!
			}
		}
	}
}

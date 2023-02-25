//
//  Pusher+JWT.swift
//  
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Foundation
import SwiftJWT

extension Pusher {
	func buildJWT() throws -> String {
		if let cached = cachedJWT { return cached }
		let keyData = try key!.keyData
		let header = Header(kid: key.name)
		let claims = PusherClaims(iss: teamID)
		let signer = JWTSigner.es256(privateKey: keyData)
		var jwt = JWT(header: header, claims: claims)
		
		let result = try jwt.sign(using: signer)
		cachedJWT = result
		return result
	}
	
	struct PusherClaims: Claims, Encodable {
		var iss: String
		var iat = Int(Date().timeIntervalSince1970)
	}
	
	var cachedJWT: String? {
		get {
			guard let raw = UserDefaults.standard.data(forKey: cachedJWTDefaultsKey) else { return nil }
			guard let cached = try? JSONDecoder().decode(CachedJWT.self, from: raw) else { return nil }
			
			if abs(cached.date.timeIntervalSinceNow) > cachedJWTLifetime { return nil }
			return cached.jwt
		}
		
		set {
			guard let newValue else { return }
			let cached = CachedJWT(jwt: newValue)
			guard let data = try? JSONEncoder().encode(cached) else { return }
			
			UserDefaults.standard.set(data, forKey: cachedJWTDefaultsKey)
		}
	}
	
	struct CachedJWT: Codable {
		var date = Date()
		let jwt: String
	}
}

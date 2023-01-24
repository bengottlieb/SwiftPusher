//
//  Pusher.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/21/23.
//

import Foundation

public class Pusher {
	public static let instance = Pusher()
	
	public func setup(teamID: String, key: Key, bundleID: String) {
		self.teamID = teamID
		self.key = key
		self.bundleID = bundleID
	}
		
	public var cachedJWTDefaultsKey = "cached_jwt"
	var cachedJWTLifetime: TimeInterval = 60 * 15

	
	var teamID = ""
	var key: Key!
	var bundleID = ""
	public var server = Server.sandbox
	
	public func send(message: String, body: String? = nil, sound: String? = "default", to token: String) async throws {
		assert(!teamID.isEmpty && !bundleID.isEmpty && key != nil, "Please call Pusher.instance.setup(teamID:key:bundleID:) before sending.")
		
		let path = "/3/device/\(token)"
		let jwt = try buildJWT()
		let headers: [String: String] = [
		  "apns-topic": bundleID,
		  "authorization": "bearer \(jwt)",
		  "Content-Type": "application/json; charset=utf-8",
		]
		let payload = APNS(aps: .init(alert: .init(title: message, body: body), sound: sound))
		let url = server.url.appendingPathComponent(path)
		var request = URLRequest(url: url)
		let body = try JSONEncoder().encode(payload)
		request.httpBody = body
		request.httpMethod = "post"
		request.allHTTPHeaderFields = headers
		
		let r = try await URLSession.shared.data(for: request)
		print(r)
	}
		
}


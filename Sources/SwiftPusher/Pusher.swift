//
//  Pusher.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/21/23.
//

import Foundation
import Suite

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
	
	public func send(message: String, body: String? = nil, sound: String? = "default", to token: String, background: Bool = false) async throws {
		
		let payload = APNS(alert: .init(title: message, body: body), sound: sound)
		try await send(payload: payload.asJSON(), to: token, background: background)
	}

	public func send(payload aps: [String: Any], to token: String, background: Bool = false) async throws {
		assert(!teamID.isEmpty && !bundleID.isEmpty && key != nil, "Please call Pusher.instance.setup(teamID:key:bundleID:) before sending.")
		
		let path = "/3/device/\(token)"
		let jwt = try buildJWT()
		let headers: [String: String] = [
		  "apns-topic": bundleID,
		  "authorization": "bearer \(jwt)",
		  "Content-Type": "application/json; charset=utf-8",
		  "apns-push-type": background ? "background" : "alert",
		  "apns-priority": background ? "5" : "10",
		]
		
		PusherLog.instance.log("Sending to \(token)")

		var apsCopy = aps
		if background { apsCopy["content-available"] = 1 }
		let url = server.url.appendingPathComponent(path)
		var request = URLRequest(url: url)
		let body = try JSONSerialization.data(withJSONObject: ["aps": apsCopy])
		request.httpBody = body
		request.httpMethod = "post"
		request.allHTTPHeaderFields = headers
		
		let r = try await URLSession.shared.data(for: request)
		
		var results = "Push Results: "
		if let response = r.1 as? HTTPURLResponse {
			results += "\(response.statusCode)"
			if let header = response.allHeaderFields["apns-unique-id"] as? String {
				results += "\n\(header)\n"
			}
		}
		if let string = String(data: r.0) {
			results += "\n\(string)"
		}
		PusherLog.instance.log(results)
	}

}


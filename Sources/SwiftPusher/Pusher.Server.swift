//
//  Pusher.Server.swift
//  
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Foundation

extension Pusher {
	public enum Server: String, Codable { case sandbox, production
		var url: URL {
			switch self {
			case .sandbox: return URL(string: "https://api.sandbox.push.apple.com")!
			case .production: return URL(string: "https://api.push.apple.com")!
			}
		}
	}
}

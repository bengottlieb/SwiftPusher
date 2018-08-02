//
//  Pusher.swift
//  Pusher
//
//  Created by Ben Gottlieb on 8/1/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation
import Security

public class Pusher {
	public static let instance = Pusher()
	
	public enum Host: String { case sandbox = "gateway.sandbox.push.apple.com", production = "gateway.push.apple.com"
		var name: String { return self.rawValue }
	}
	public static let defaultPort = 2195
	var activeConnection: SSLConnection!
	var internalQueue = DispatchQueue(label: "Pusher_queue")
	
	public func load(certificate: Certificate) throws {
		self.activeConnection?.disconnect()
		self.activeConnection = SSLConnection(certificate: certificate)
		try self.activeConnection?.connect()
	}
	
	public func send(_ notification: Notification, completion: @escaping (Swift.Error?) -> Void) {
		guard let data = notification.payloadData else {
			completion(Pusher.Error.unableToConstructNotificationData)
			return
		}
		guard let connection = self.activeConnection else {
			completion(Pusher.Error.noActiveConnection)
			return
		}
		
		do {
			let written = try connection.write(data)
			if written != data.count {
				print("Too few bytes written: \(written) vs. \(data.count)")
			}
			
			self.internalQueue.asyncAfter(wallDeadline: .now() + 1) {
				do {
					let errorPayloadSize = 6
					let result = try connection.read(count: errorPayloadSize)
					if result.count == 0 {
						completion(nil)
						return
					}
					try result.withUnsafeBytes { (raw: UnsafePointer<UInt8>) in
						let bytes = [UInt8](UnsafeBufferPointer(start: raw, count: result.count))
						
						if bytes[0] != 8 { throw Pusher.Error.APNSUnknownReason }

						switch (bytes[1]) {
						case 0: break
						case 1: throw Pusher.Error.APNSProcessing
						case 2: throw Pusher.Error.APNSMissingDeviceToken
						case 3: throw Pusher.Error.APNSMissingTopic
						case 4: throw Pusher.Error.APNSMissingPayload
						case 5: throw Pusher.Error.APNSInvalidTokenSize
						case 6: throw Pusher.Error.APNSInvalidTopicSize
						case 7: throw Pusher.Error.APNSInvalidPayloadSize
						case 8: throw Pusher.Error.APNSInvalidTokenContent
						case 10: throw Pusher.Error.APNSShutdown
						default: throw Pusher.Error.APNSUnknownReason
						}
					}
					completion(nil)
				} catch {
					completion(error)
				}
			}
		} catch {
			completion(error)
		}
	}
}


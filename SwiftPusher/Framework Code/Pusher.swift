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
	public var isApplicationInTheBackground = false { didSet { if self.isApplicationInTheBackground { self.disconnect() }}}
	public static let defaultPort = 2195
	var activeConnection: SSLConnection!
	var internalQueue = DispatchQueue(label: "Pusher_queue")
	var certificate: Certificate?
	
	public func load(certificate: Certificate) throws {
		if certificate == self.certificate { return }
		
		self.disconnect()
		self.certificate = certificate
	}
	
	public func restartConnection() throws {
		guard let cert = self.certificate else { throw Pusher.Error.missingCertificate }
		self.disconnect()
		try self.load(certificate: cert)
	}
	
	@discardableResult public func connect() -> Bool {
		guard self.activeConnection?.isConnected != true else { return true }
		guard let cert = self.certificate else { return false }
		
		self.activeConnection = SSLConnection(certificate: cert)
		do {
			try self.activeConnection?.connect()
			return true
		} catch {
			return false
		}
	}
	
	public func disconnect() {
		self.activeConnection?.disconnect()
		self.activeConnection = nil
	}
	
	public func send(_ notification: Notification, retryCount: Int = 1, completion: @escaping (Swift.Error?) -> Void) {
		self.connect()
		defer { if self.isApplicationInTheBackground { self.activeConnection.closeAfterRead = true }}
		
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
			if retryCount > 0 {
				print("Error when sending: \(error), retrying")
				try? self.restartConnection()
				self.send(notification, retryCount: retryCount - 1, completion: completion)
			} else {
				completion(error)
			}
		}
	}
}


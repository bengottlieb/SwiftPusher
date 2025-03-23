//
//  DeviceManager.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Suite
import Nearby
import CrossPlatformKit

public class PushTargetManager: NSObject, ObservableObject {
	public static let instance = PushTargetManager()
	public var devices: [DiscoveredPushTargetDevice] = []
	public var apnsToken: String? { didSet { updateTokens() }}
	
	public let apnsTokenCommand = "apns"
	public var count: Int { devices.count }
	
	public func updateTokens() {
		devices.forEach { $0.send(token: apnsToken) }
	}
	
	public func setup(serviceType: String) {
		NearbySession.instance.serviceType = serviceType
		NearbySession.instance.startup(withRouter: self, application: UXApplication.shared)
		addAsObserver(of: NearbyDevice.Notifications.deviceConnected, selector: #selector(deviceConnected))
	}
	
	@objc public func deviceConnected(note: Notification) {
		if let device = note.object as? NearbyDevice {
			let added = add(device: device)
			added.send(token: apnsToken)
			print(added)
		}
	}
}

class APNSTokenMessage: NearbyMessage {
	static let command = "apns"
	var command: String = APNSTokenMessage.command
	let token: String
	
	init(token: String) {
		self.token = token
	}
}

extension PushTargetManager: NearbyMessageRouter {
    public func didProvision(device: Nearby.NearbyDevice) {
        
    }
    
	public func didDiscover(device: Nearby.NearbyDevice) {
		print("New device: \(device)")
	}
	
	public var fileID: String {
		#file
	}
	
	public func route(_ payload: NearbyMessagePayload, from device: NearbyDevice) -> NearbyMessage? {

		switch payload.command {
		case APNSTokenMessage.command:
			if let msg = try? payload.reconstitute(APNSTokenMessage.self) {
				let discovered = add(device: device)
				discovered.apnsToken = msg.token

			}
			
		default: break
		}
		return nil
	}
	
	public func received(dictionary: [String: String], from device: NearbyDevice) {
		print(dictionary)
	}
	
	func add(device: NearbyDevice) -> DiscoveredPushTargetDevice {
		if let discovered = devices.first(where: { $0.device == device }) { return discovered }
		
		let new = DiscoveredPushTargetDevice(nearby: device)
		devices.append(new)
		new.send(token: apnsToken)
		
		objectWillChange.sendOnMain()
		return new
	}
	
}

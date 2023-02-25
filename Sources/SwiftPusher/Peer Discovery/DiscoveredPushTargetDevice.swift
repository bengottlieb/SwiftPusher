//
//  DiscoveredDevice.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Foundation
import Nearby

public class DiscoveredPushTargetDevice: Identifiable {
	public let device: NearbyDevice
	public var apnsToken: String?
	
	public var id: String { device.id }
	public var name: String { device.displayName }
	
	public init(nearby: NearbyDevice) {
		device = nearby
		device.delegate = self
	}
	
	public func send(token: String?) {
		print("Trying to send token: \(token ?? "none")")
		if let token {
			device.send(message: APNSTokenMessage(token: token))
		}
	}
	
	public var pushTargetDevice: PushTargetDevice? {
		guard let apnsToken else { return nil }
		
		return .init(apnsToken: apnsToken, name: name)
	}
}

extension DiscoveredPushTargetDevice: NearbyDeviceDelegate {
	public func didReceive(message: NearbyMessage, from device: Nearby.NearbyDevice) {
		print(message)
	}
	
	public func didReceiveFirstInfo(from device: Nearby.NearbyDevice) {
		print("First: \(device.deviceInfo ?? [:])")
	}
	
	public func didChangeInfo(from: Nearby.NearbyDevice) {
	}
	
	public func didChangeState(for: Nearby.NearbyDevice) {
	}
	
	
}

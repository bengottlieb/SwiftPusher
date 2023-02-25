//
//  PushTargetDevice.swift
//  PushNow
//
//  Created by Ben Gottlieb on 2/24/23.
//

import Foundation
import Nearby

public struct PushTargetDevice: Equatable {
	public var apnsToken: String
	public var name: String
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.apnsToken == rhs.apnsToken
	}
}

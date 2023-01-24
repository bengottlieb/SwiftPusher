//
//  Pusher.APNS.swift
//  
//
//  Created by Ben Gottlieb on 1/24/23.
//

import Foundation

extension Pusher {
	struct APNS: Encodable {
		let aps: APS
		
		struct APS: Encodable {
			let alert: Alert
			let sound: String?
			
			struct Alert: Encodable {
				let title: String?
				let body: String?
			}
		}
	}
}

//
//  PusherLogView.swift
//
//
//  Created by Ben Gottlieb on 6/13/23.
//

import SwiftUI


public struct PusherLogView: View {
	@ObservedObject var pusherLog = PusherLog.instance
	
	public init() { }
	
	public var body: some View {
		ScrollView {
			Text(pusherLog.logText)
				.multilineTextAlignment(.leading)
				.lineLimit(nil)
				.font(.system(size: 14).monospaced())
		}
	}
}

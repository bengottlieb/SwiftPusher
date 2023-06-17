//
//  PusherLog.swift
//
//
//  Created by Ben Gottlieb on 6/13/23.
//

import SwiftUI
import Suite
import OSLog

public class PusherLog: ObservableObject {
	public static let instance = PusherLog()
	
	@AppStorage("pusherLogIsEnabled") public var isEnabled = false
	
	var fileURL = URL.document(named: "pusher_log.txt")
	var echo = true
	let logger = Logger(subsystem: "SwiftPusher", category: "pusher")
	
	var logText: String {
		get { (try? String(contentsOf: fileURL)) ?? "" }
		set {
			try? newValue.write(to: fileURL, atomically: true, encoding: .utf8)
		}
	}
	
	public func log(_ message: String) {
		if !isEnabled { return }
		logText = logText + "\n" + message
		if echo { print("\(message)") }
		objectWillChange.sendOnMain()
	}
	
	public func clear() {
		logText = "cleared at \(Date().formatted(date: .omitted, time: .shortened))"
		objectWillChange.sendOnMain()
	}
}

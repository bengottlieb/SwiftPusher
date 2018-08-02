//
//  AppDelegate.swift
//  SwiftPusherTest_Mac
//
//  Created by Ben Gottlieb on 8/2/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Cocoa
import SwiftPusher

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	
	var p12Key = "p12data"
	
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		self.test()
	}
	
	func test() {
		if let data = UserDefaults.standard.data(forKey: self.p12Key) {
			let cert = Pusher.Certificate(data: data, password: "")
			try! Pusher.instance.load(certificate: cert)
			
			let notification = Pusher.Notification(target: "321443ac3ccc9041eb13d6a0fadf9028f1737c38cbe7cd3369e698a29a087a43")
			notification.title = "Notification #3"
			notification.soundName = "default"
			
			
			Pusher.instance.send(notification) { error in
				if let err = error {
					print("Error when sending: \(err)")
				}
			}
		}
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
		return false
	}
	
	func application(_ sender: NSApplication, openFiles filenames: [String]) {
		if let file = filenames.first, file.hasSuffix(".p12"), let data = try? Data(contentsOf: URL(fileURLWithPath: file)) {
			UserDefaults.standard.set(data, forKey: self.p12Key)
			
			self.test()
		}
	}


}


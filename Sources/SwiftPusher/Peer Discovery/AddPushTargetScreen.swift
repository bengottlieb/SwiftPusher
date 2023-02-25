//
//  AddPushTargetScreen.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/24/23.
//

import SwiftUI

public struct AddPushTargetScreen<RowView: View>: View {
	public typealias RowBuilder = (DiscoveredPushTargetDevice, Binding<PushTargetDevice?>) -> RowView
	@ObservedObject var manager = PushTargetManager.instance
	@Binding var selected: PushTargetDevice?
	@ViewBuilder var rowBuilder: RowBuilder
	
	public init(device: Binding<PushTargetDevice?>, rowBuilder: @escaping RowBuilder) {
		_selected = device
		self.rowBuilder = rowBuilder
	}
	
	public var body: some View {
		VStack() {
			TitleBar(title: "Nearby Devices", close: Image(systemName: "xmark"))
			List {
				ForEach(manager.devices) { device in
					DeviceRow(device: device, selected: $selected) {
						rowBuilder(device, $selected)
					}
				}
			}
		}
	}
}

struct AddPushTargetScreen_Previews: PreviewProvider {
	static var previews: some View {
		AddPushTargetScreen(device: .constant(nil)) { device, selected in
			Text(device.name)
		}
	}
}

struct DeviceRow<Content: View>: View {
	let device: DiscoveredPushTargetDevice
	@Binding var selected: PushTargetDevice?
	let content: () -> Content
	
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		Button(action: {
			selected = device.pushTargetDevice
			dismiss()
		}) {
			content()
		}
	}
}


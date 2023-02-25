//
//  TitleBar.swift
//  PushNow
//
//  Created by Ben Gottlieb on 1/24/23.
//

import SwiftUI

struct TitleBar: View {
	let title: String
	var close: Image?
	var closeAction: (() -> Void)?
	
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		
		ZStack {
			Text(title)
				.font(.title2)
				.padding()
			
			if let close {
				HStack {
					Spacer()
					Button(action: {
						if let closeAction {
							closeAction()
						} else {
							dismiss()
						}
					}) {
						close
							.padding()
					}
				}
			}
		}
	}
}

struct TitleBar_Previews: PreviewProvider {
	static var previews: some View {
		TitleBar(title: "Title")
	}
}

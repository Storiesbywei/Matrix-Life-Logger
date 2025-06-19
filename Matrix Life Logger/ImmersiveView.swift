//
//  ImmersiveView.swift
//  Matrix Life Logger
//
//  Created by Weixiang Zhang on 6/19/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        TimelineRiverView()
    }
}

#Preview(immersionStyle: .progressive) {
    ImmersiveView()
        .environment(AppModel())
}

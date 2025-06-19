//
//  Matrix_Life_LoggerApp.swift
//  Matrix Life Logger
//
//  Created by Weixiang Zhang on 6/19/25.
//

import SwiftUI

@main
struct Matrix_Life_LoggerApp: App {

    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()

    var body: some Scene {
        WindowGroup {
            if avPlayerViewModel.isPlaying {
                AVPlayerView(viewModel: avPlayerViewModel)
            } else {
                ContentView()
                    .environment(appModel)
            }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    avPlayerViewModel.play()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    avPlayerViewModel.reset()
                }
        }
        .immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}

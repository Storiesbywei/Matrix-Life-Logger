//
//  ContentView.swift
//  Matrix Life Logger
//
//  Created by Weixiang Zhang on 6/19/25.
//

import SwiftUI
import RealityKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingImport = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Matrix Life Logger")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Experience your life data in spatial computing")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                ToggleImmersiveSpaceButton()
                
                Button(action: { showingImport = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Life Logger Data")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                
                HStack {
                    Image(systemName: "hand.tap")
                    Text("Tap particles to view entries")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "hand.pinch")
                    Text("Pinch to scale timeline")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "hand.drag")
                    Text("Drag particles to move them")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .sheet(isPresented: $showingImport) {
            ImportView(modelContext: modelContext)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}

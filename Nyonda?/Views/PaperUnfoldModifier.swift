//
//  PaperUnfoldModifier.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation
import SwiftUI

struct PaperUnfoldModifier: ViewModifier {
    @State private var isUnfolded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: 1,
                y: isUnfolded ? 1 : 0.03,
                anchor: .bottom
            )
            .rotation3DEffect(
                .degrees(isUnfolded ? 0 : -75),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.35
            )
            .opacity(isUnfolded ? 1 : 0.7)
            .shadow(
                color: .black.opacity(isUnfolded ? 0.18 : 0.05),
                radius: isUnfolded ? 10 : 2,
                y: isUnfolded ? 6 : 1
            )
            .task {
                do {
                    try await Task.sleep(for: .milliseconds(80))
                } catch {
                    return
                }

                withAnimation(
                    .spring(duration: 1.5, bounce: 0.12)
                ) {
                    isUnfolded = true
                }
            }
    }
}

extension View {
    func paperUnfoldOnAppear() -> some View {
        modifier(PaperUnfoldModifier())
    }
}

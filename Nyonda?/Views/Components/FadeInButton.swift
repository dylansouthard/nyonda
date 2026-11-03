//
//  FadeInButton.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/11/01.
//

import SwiftUI

struct FadeInButton: View {
    @State private var hasFadedIn = false

    var label: String
    var img: String = ""
    var delay: CGFloat = 0.5
    var disabled: Bool
    var onPress: () -> Void

    var body: some View {
        Button {
            onPress()
        } label: {
            Label (
                label,
            systemImage: img
            )
            .foregroundColor(.btnTxt)

        }
        .disabled(disabled)
        .opacity(hasFadedIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                hasFadedIn = true
            }
        }
    }
}

#Preview {
    FadeInButton(label: "取り消す", disabled: false) {}
}

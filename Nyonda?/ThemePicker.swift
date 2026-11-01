//
//  ThemePicker.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import Foundation
import SwiftUI
struct ThemePicker: View {
    @Binding var selection: CatTheme

    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CatTheme.allCases, id: \.self) { theme in
                Button {
                    withAnimation(.snappy(duration: 0.1)) {
                        selection = theme
                    }
                } label: {
                    ZStack {
                        if selection == theme {
                            Capsule()
                                .fill(.white.opacity(0.9))
                                .matchedGeometryEffect(
                                    id: "selectedTheme",
                                    in: selectionAnimation
                                )
                        }

                        Image(theme.iconName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .frame(width: 38, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background {
            Capsule()
                .fill(.black.opacity(0.1))
        }
    }
}

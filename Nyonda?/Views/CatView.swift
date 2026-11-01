//
//  CatView.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import SwiftUI

struct CatView: View {
    let theme: CatTheme
    @GestureState
    private var pillDragOffset: CGSize = .zero
    @GestureState
    private var isPillOverMouth = false
    @State
    private var mouthFrame: CGRect = .zero
    @State private var feedbackPlayer = AppFeedbackPlayer()

    let canSkipToday: Bool
    let isBusy: Bool
    let onSkipToday: () -> Void
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            catPlaceholder
            pillSlot
            Spacer()
        }
        .padding()
        .coordinateSpace(name: CoordinateSpaceName.interationArea)
        .sensoryFeedback(
            .impact(weight: .medium, intensity: 0.7),
            trigger: isPillOverMouth
        ) { oldValue, newValue in
            !oldValue && newValue
        }
    }

    private var catPlaceholder: some View {
        ZStack {
            Image(canSkipToday ? theme.openImageName : theme.closedImageName)
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth: 350,
                    maxHeight: 350
                )
            if canSkipToday {
                mouthTarget
                    .offset(y: 80)
            }
        }
        .frame(
            maxWidth: 350,
            maxHeight: 350
        )

    }

    private enum CoordinateSpaceName {
        static let interationArea = "catInteractionArea"
    }

    private var draggablePill: some View {
        Image("pill")
            .resizable()
            .scaledToFit()
            .frame(
                width: 130,
                height: 90
            )
            .contentShape(Rectangle())
            .offset(pillDragOffset)
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.7
                ),
                value: pillDragOffset
            )
            .gesture(pillDragGesture)
            .opacity(canSkipToday ? isPillOverMouth ? 0.8 : 1 : 0)
            .allowsHitTesting(canSkipToday && !isBusy)
    }
    private var pillSlot: some View {
        ZStack {
            if canSkipToday {
                draggablePill
            } else {
                PopInTxt("もうにょんだ！")
            }
            
        }
        .frame(maxWidth: .infinity)
           .frame(height: 120)
    }
    private var mouthTarget: some View {
        Ellipse()
            .fill(.clear)
            .frame(
                width: 100,
                height: 140
            )
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(
                    in: .named(
                        CoordinateSpaceName.interationArea
                    )
                )

            } action: { newFrame in
                mouthFrame = newFrame
            }
    }

    private var pillDragGesture: some Gesture {
        DragGesture(
            coordinateSpace: .named(CoordinateSpaceName.interationArea)
        )
        .updating($pillDragOffset) { value, offset, _ in
            offset = value.translation
        }
        .updating($isPillOverMouth) { value, isOverMouth, _ in
            isOverMouth = mouthFrame.contains(value.location)
        }
        .onEnded { value in
            guard !isBusy else {
                return
            }

            let dropLocation = value.location

            print(
                "Pill dropped at \(dropLocation); mouth is \(mouthFrame)"
            )

            guard mouthFrame.contains(dropLocation) else {
                print("Missed the mouth.")
                return
            }

            feedbackPlayer.play(.medicineTaken)
            feedbackPlayer.doubleImpact()
            print("Pill entered the mouth.")
            onSkipToday()
        }
    }
    
}

#Preview {
    CatView(theme: .sabi, canSkipToday: true, isBusy: false, onSkipToday: {})
}

#Preview("Active Today") {
    CatView(
        theme: .ame,
        canSkipToday: false,
        isBusy: false,
        onSkipToday: {}
    )
}

#Preview("Finished Today") {
    CatView(
        theme: .ame,
        canSkipToday: false,
        isBusy: false,
        onSkipToday: {}
    )
}

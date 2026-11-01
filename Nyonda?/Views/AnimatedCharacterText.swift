//
//  AnimatedCharacterText.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation
import SwiftUI
struct AnimatedCharacterText: View {
    let text: String

    var characterDelay: Duration = .milliseconds(60)
    var animationDuration: Double = 1
    var color:Color = .txtPrimary

    @State private var visibleCharacterCount = 0

    private var characters: [Character] {
        Array(text)
    }

    var body: some View {
        CharacterWrappingLayout(
            characters: characters,
            alignment: .center,
            horizontalSpacing: 0,
            verticalSpacing: 6
        ) {
            ForEach(characters.indices, id: \.self) { index in
                Text(String(characters[index]))
                    .font(.zenMaruRegular(16))
                    .opacity(
                        index < visibleCharacterCount ? 1 : 0
                    )
                    .scaleEffect(
                        index < visibleCharacterCount ? 1 : 0.7
                    )
                    .foregroundStyle(color)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .task(id: text) {
            visibleCharacterCount = 0

            for index in characters.indices {
                do {
                    try await Task.sleep(for: characterDelay)
                } catch {
                    return
                }

                withAnimation(
                    .easeOut(duration: animationDuration)
                ) {
                    visibleCharacterCount = index + 1
                }
            }
        }
    }
    struct CharacterWrappingLayout: Layout {
        
        
        enum LineAlignment {
            case leading
            case center
            case trailing
        }

        var characters: [Character]

         var alignment: LineAlignment = .leading
         var horizontalSpacing: CGFloat = 0
         var verticalSpacing: CGFloat = 4

         var charactersThatCannotStartLine: Set<Character> = [
             "、", "。"
         ]

        private struct Line {
            var indices: [Int] = []
            var width: CGFloat = 0
            var height: CGFloat = 0
        }

        private func makeCharacterGroups(
            sizes: [CGSize]
        ) -> [Line] {
            var groups: [Line] = []

            for index in sizes.indices {
                let character = characters[index]
                let size = sizes[index]

                if charactersThatCannotStartLine.contains(character),
                   var previousGroup = groups.popLast() {

                    let spacing = previousGroup.indices.isEmpty
                        ? 0
                        : horizontalSpacing

                    previousGroup.indices.append(index)
                    previousGroup.width += spacing + size.width
                    previousGroup.height = max(
                        previousGroup.height,
                        size.height
                    )

                    groups.append(previousGroup)
                } else {
                    groups.append(
                        Line(
                            indices: [index],
                            width: size.width,
                            height: size.height
                        )
                    )
                }
            }

            return groups
        }

        private func makeLines(
            sizes: [CGSize],
            maximumWidth: CGFloat
        ) -> [Line] {
            let groups = makeCharacterGroups(sizes: sizes)

            var lines: [Line] = []
            var currentLine = Line()

            for group in groups {
                let spacing = currentLine.indices.isEmpty
                    ? 0
                    : horizontalSpacing

                if !currentLine.indices.isEmpty,
                   currentLine.width + spacing + group.width > maximumWidth {
                    lines.append(currentLine)
                    currentLine = Line()
                }

                let actualSpacing = currentLine.indices.isEmpty
                    ? 0
                    : horizontalSpacing

                currentLine.indices.append(contentsOf: group.indices)
                currentLine.width += actualSpacing + group.width
                currentLine.height = max(
                    currentLine.height,
                    group.height
                )
            }

            if !currentLine.indices.isEmpty {
                lines.append(currentLine)
            }

            return lines
        }

        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) -> CGSize {
            let sizes = subviews.map {
                $0.sizeThatFits(.unspecified)
            }

            let maximumWidth: CGFloat

            if let proposedWidth = proposal.width,
               proposedWidth.isFinite {
                maximumWidth = proposedWidth
            } else {
                maximumWidth = .greatestFiniteMagnitude
            }

            let lines = makeLines(
                sizes: sizes,
                maximumWidth: maximumWidth
            )

            let naturalWidth = lines
                .map(\.width)
                .max() ?? 0

            let totalLineHeight = lines.reduce(CGFloat.zero) {
                $0 + $1.height
            }

            let totalSpacing =
                CGFloat(max(0, lines.count - 1)) * verticalSpacing

            return CGSize(
                width: proposal.width ?? naturalWidth,
                height: totalLineHeight + totalSpacing
            )
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) {
            let sizes = subviews.map {
                $0.sizeThatFits(.unspecified)
            }

            let lines = makeLines(
                sizes: sizes,
                maximumWidth: bounds.width
            )

            var y = bounds.minY

            for line in lines {
                var x: CGFloat

                switch alignment {
                case .leading:
                    x = bounds.minX

                case .center:
                    x = bounds.minX
                        + (bounds.width - line.width) / 2

                case .trailing:
                    x = bounds.maxX - line.width
                }

                for index in line.indices {
                    let size = sizes[index]

                    subviews[index].place(
                        at: CGPoint(x: x, y: y),
                        anchor: .topLeading,
                        proposal: ProposedViewSize(
                            width: size.width,
                            height: size.height
                        )
                    )

                    x += size.width + horizontalSpacing
                }

                y += line.height + verticalSpacing
            }
        }
    }
}

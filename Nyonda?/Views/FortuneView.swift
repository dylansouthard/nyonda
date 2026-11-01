//
//  FortuneView.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import SwiftUI

struct FortuneView: View {
    let fortune:DailyFortune
    let onReturn:()->Void
    
    init (_ fortune:DailyFortune, onReturn:@escaping() -> Void) {
        self.fortune = fortune
        self.onReturn = onReturn
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    @State private var selectedCategory:FortuneCategory?
    @State private var feedbackPlayer = AppFeedbackPlayer()
    var body: some View {
        ZStack {
            Image(fortune.paperImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack(spacing: 20) {
                HStack(spacing:20){
                    Image(fortune.level.rawValue)
                        .resizable()
                        .aspectRatio(1/1, contentMode: .fit)
                        .frame(width:100)
                    Text(fortune.text(for: .summary) ?? "")
                        .foregroundStyle(.txtPrimary)
                        .font(.zenMaruMedium(20))
                }
                LazyVGrid(columns:columns, spacing:10) {
                    ForEach(Array(FortuneCategory.allCases).dropFirst(), id: \.self) {category in

                        CategoryButton(category, currentCategory: $selectedCategory) {newCategory in
                            self.selectedCategory = newCategory
                        }
                    }
                }
                if let sc = self.selectedCategory {
                    let visibleText = fortune.texts[sc] ?? ""
                    AnimatedCharacterText(text: visibleText)
                        .id(visibleText)
                        
                }
                Spacer()
                HStack {
                    Button {
                        onReturn()
                    } label: {
                        Text("もどる")
                            .font(.zenMaruMedium(15))
                    }
                    .foregroundColor(.txtPrimary)
                    Spacer()
                 }
            
            }
            .padding(.vertical, 35)
            .padding(.horizontal, 35)
        }
        .frame(maxWidth:.infinity)
        .aspectRatio(contentMode: .fit)
        .onAppear {
            self.feedbackPlayer.play(.paper)
        }
    }
}
struct CategoryButton: View {
    let category: FortuneCategory
    let onPress: (FortuneCategory) -> Void
    @Binding var currentCategory: FortuneCategory?
    
    init(_ category: FortuneCategory, currentCategory: Binding<FortuneCategory?>, onPress: @escaping (FortuneCategory) -> Void) {
        self.category = category
        self._currentCategory = currentCategory
        self.onPress = onPress
    }
    var body: some View {
        Button  {
            onPress(category)
        } label: {
            ZStack {
                Image("fortune-category-bkg")
                    .resizable()
                    .aspectRatio(contentMode:.fit)
                Text(category.displayName)
                    .font(.zenMaruBold(17))
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
        .disabled(currentCategory == category)
        .frame(width:110)
        .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    FortuneView(DailyFortune.dummy){}
}

#Preview {
    CategoryButton(.love, currentCategory: .constant(nil)) { _ in }
}


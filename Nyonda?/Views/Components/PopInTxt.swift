//
//  PopInTxt.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import SwiftUI

struct PopInTxt: View {
    @State private var hasPoppedIn = false
    let txt:String
    let size:CGFloat
    
    init(_ txt:String = "", size:CGFloat = 45) {
        self.txt = txt
        self.size = size
    }
    
    var body: some View {
        Text(txt)
            .font(.zenMaruBlack(size)
            )
            .foregroundStyle(.txtPrimary)
            .scaleEffect(hasPoppedIn ? 1 : 0.1)
            .onAppear {
                withAnimation(
                    .spring(
                        response: 0.35,
                        dampingFraction: 0.4
                    )
                ) {
                    hasPoppedIn = true
                }
            }
    }
}

#Preview {
    PopInTxt()
}

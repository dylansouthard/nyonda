//
//  CustomFonts.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import SwiftUI

extension Font {
    static func zenMaruRegular(_ size: CGFloat) -> Font {
        .custom("ZenMaruGothic-Regular", fixedSize: size)
    }

    static func zenMaruMedium(_ size: CGFloat) -> Font {
        .custom("ZenMaruGothic-Medium", fixedSize: size)
    }

    static func zenMaruBold(_ size: CGFloat) -> Font {
        .custom("ZenMaruGothic-Bold", fixedSize: size)
    }

    static func zenMaruBlack(_ size: CGFloat) -> Font {
        .custom("ZenMaruGothic-Black", fixedSize: size)
    }
}

//
//  FontExtension.swift
//  Breath
//

import SwiftUI

extension Font {
    // Cormorant Garamond — meditative headers and display text
    static func garamond(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name = weight == .medium ? "CormorantGaramond-Medium" : "CormorantGaramond-Regular"
        return .custom(name, size: size)
    }

    // Inter — utility body text, labels, descriptions
    static func inter(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name = weight == .medium ? "Inter-Medium" : "Inter-Regular"
        return .custom(name, size: size)
    }

    // JetBrains Mono — rhythm patterns, numbers, cycle counts
    static func jbMono(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }
}

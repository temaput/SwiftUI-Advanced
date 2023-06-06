//
//  GradientText.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 22.04.23.
//

import SwiftUI

struct GradientText: View {
    public var text: String = "Lorem Ipsum"
    var body: some View {
        Text(text).gradientForeground(colors: [Color("ping-gradient-1"), Color("pink-gradient-2")])
    }
}

extension View {
    public func gradientForeground(colors: [Color]) -> some View {
        return self.overlay(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        ).mask(self)
    }
}

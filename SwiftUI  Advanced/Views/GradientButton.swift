//
//  GradientButton.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 22.04.23.
//

import SwiftUI

struct GradientButton: View {
    public var label: String = "Lorem Ipsum"
    let colors = [
        //hsba(227, 62%, 100%, 1)
        Color(hue: 227/360, saturation: 0.62, brightness: 1),
        //hsba(331, 55%, 100%, 1)
        Color(hue: 331/360, saturation: 0.55, brightness: 1),
        //hsba(300, 19%, 85%, 1)
        Color(hue: 300/360, saturation: 0.19, brightness: 0.85),
        //hsba(169, 33%, 88%, 1)
        Color(hue: 169/360, saturation: 0.33, brightness: 0.88)
    ]
  
  @State private var  angle = 0.0
    var body: some View {
        Button {
            print("Creating Account")
        }
    label: {
        
        AngularGradient(gradient: Gradient(colors: colors), center: .center, angle: .degrees(angle))
            .frame(height:50)
            .mask(RoundedRectangle(cornerRadius: 16))
            .blur(radius: 8.0)
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.7), lineWidth: 1.9)
                    .background(Color("tertiaryBackground").opacity(0.9)).blendMode(.normal)
                    .cornerRadius(16)
            )
            .overlay(GradientText(text: label).font(.headline))
            .onAppear() {
              withAnimation(.linear(duration: 7)) {
                angle += 360
              }
            }
        
    }
    }
}

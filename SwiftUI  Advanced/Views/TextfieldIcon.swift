//
//  TextfieldIcon.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 22.04.23.
//

import SwiftUI

struct TextfieldIcon: View {
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
    var isEditing: Bool
    var icon: String
    
    var body: some View {
        
        
        //        }
        Image(systemName: icon)
            .gradientForeground(colors: [Color("pink-gradient-1"), Color("pink-gradient-2")])
            .font(.system(size: 17, weight: .medium))
            .frame(width: 36, height:36)
            .background(
                RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1)
                    .background(Color("tertiaryBackground").opacity(0.8))
                    .cornerRadius(12)
                    .blendMode(.normal)
            )
        
            .background(
                Group {
                    if (isEditing) {
                        AngularGradient(gradient: Gradient(colors: isEditing ? colors : []), center: .center, angle: .degrees(0))
                        
                            .mask(RoundedRectangle(cornerRadius: 12))
                            .blur(radius: 10)
                        
                    } else {
                        EmptyView()
                    }
                    
                }
                
            )
    }
}

struct TextfieldIcon_Previews: PreviewProvider {
    static var previews: some View {
        TextfieldIcon(isEditing: false, icon: "key.fill")
    }
    
}

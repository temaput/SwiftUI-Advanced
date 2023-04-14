//
//  ContentView.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 12.04.23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    var body: some View {
        ZStack {
            Image("background-3")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.all)
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sign up")
                        .font(Font.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("Access to 120+ of cources, tutorials and livestreams")
                        .font(Font.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                    HStack(spacing: 16) {
                        Image(systemName: "envelope.open.fill")
                            .foregroundColor(.white)
                        TextField("Email", text: $email )
                            .colorScheme(.dark)
                            .textContentType(.emailAddress)
                            .foregroundColor(Color.white.opacity(0.7))
                            .autocapitalization(.none)
                        
                    }
                    .frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1.0)
                        .blendMode(.overlay))
                    .background(Color("secondaryBackground").opacity(0.8)
                    .cornerRadius(16))
                    HStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.white)
                        TextField("Password", text: $password )
                            .colorScheme(.dark)
                            .textContentType(.password)
                            .foregroundColor(Color.white.opacity(0.7))
                            .autocapitalization(.none)
                        
                    }
                    .frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1.0)
                        .blendMode(.overlay))
                    .background(Color("secondaryBackground").opacity(0.8)
                    .cornerRadius(16))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.2))
                    .background(Color("secondaryBackground")).opacity(0.5)
                    .background(VisualEffectBlur(blurStyle: .systemThinMaterialDark))
                    .shadow(
                        color: Color("shadowColor").opacity(0.5),
                        radius: 60,
                        x: 0, y: 30)
            )
            .cornerRadius(30)
            .padding(.horizontal)
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

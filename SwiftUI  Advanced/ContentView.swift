//
//  ContentView.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 12.04.23.
//

import SwiftUI
import Foundation
import CoreData

struct ContentView: View {
  @State private var email: String = ""
  @State private var password: String = ""
  @FocusState private var passwordFocused: Bool
  @FocusState private var emailFieldIsFocused: Bool
  @State private var emailBounce: Double = 0.0
  @State private var passwordBounce: Double = 0.0
  
  private let generator = UISelectionFeedbackGenerator()
  
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
            TextfieldIcon(isEditing: emailFieldIsFocused, icon: "envelope.open.fill")
              .padding(.leading, 8.0)
              .scaleEffect(emailBounce == 1 ? 1.2: 1.0)
            TextField("Email", text: $email )
              .focused($emailFieldIsFocused)
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
            
            TextfieldIcon(isEditing: passwordFocused, icon: "key.fill").padding(.leading, 8.0)
              .scaleEffect(passwordBounce == 1 ? 1.2: 1.0)
            SecureField("Password", text: $password )
              .focused($passwordFocused)
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
          
          
          
          
          Group {
            Group() {
              GradientButton()
              
            }
            .padding(.horizontal, 16.0)
            Text("By clicking on Sign up, you agree to our Terms of service and Privacy policy.")
            Rectangle().frame(height: 1).opacity(0.1)
            Button {
              print("Switch to sign in")
            } label: {
              HStack(spacing: 4) {
                Text("Already have an account?")
                GradientText(text: "Sign Up").bold()
              }
            }
            
            
          }
          .foregroundColor(Color.white.opacity(0.7))
          .font(.footnote)
          
          
          
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
      .onChange(of: emailFieldIsFocused) { newValue in
        if newValue {
          generator.selectionChanged()
          withAnimation(Animation.spring()) {
            emailBounce = 1.0
            
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.spring()) {
              emailBounce = 0
              
            }
            
          }
        }
      }
      .onChange(of: passwordFocused) { newValue in
        if newValue {
          generator.selectionChanged()
          withAnimation(Animation.spring()) {
            passwordBounce = 1.0
            
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.spring()) {
              passwordBounce = 0
              
            }
            
          }
          
        }
      }
      
    }
  }
  
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}




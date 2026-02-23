//
//  Login.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//



import SwiftUI

struct Login: View {
    
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var appState: AppState
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var animate = false
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.7),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // MARK: Glass Card
            
            VStack(spacing: 25) {
                
                Text("Welcome Back 👋")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 18) {
                    
                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "Name",
                        text: $name
                    )
                    
                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email
                    )
                    
                    CustomSecureField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password
                    )
                }
                
                Button {
                    login()
                } label: {
                    Text("Login")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
                .scaleEffect(animate ? 1 : 0.95)
                .animation(.easeInOut(duration: 0.6), value: animate)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(25)
            .padding(.horizontal, 30)
            .shadow(color: .black.opacity(0.4), radius: 20)
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Login Logic

extension Login {
    
    private func login() {
        
        guard !name.isEmpty,
              !email.isEmpty,
              !password.isEmpty else { return }
        
        userStore.user = UserModel(
            name: name,
            email: email,
            password: password
        )
        
        appState.isLoggedIn = true
    }
}


// MARK: - Custom TextField

struct CustomTextField: View {
    
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

struct CustomSecureField: View {
    
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black.opacity(0.8))
            
            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

#Preview {
    Login()
        .environmentObject(UserStore())
        .environmentObject(AppState())
}

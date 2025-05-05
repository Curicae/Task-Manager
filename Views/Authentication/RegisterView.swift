import SwiftUI
import SwiftData // <-- BU SATIRI EKLEYİN

struct RegisterView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss // Görünümü kapatmak için

    var onRegisterSuccess: () -> Void // Başarılı kayıt sonrası çağrılacak closure

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.fill.badge.plus") // Veya kendi ikonunuz
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            Text("Hesap Oluştur")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Kullanıcı Adı", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            TextField("E-posta", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            SecureField("Şifre", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            SecureField("Şifre Tekrar", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button {
                register()
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Kayıt Ol")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || !isFormValid()) // Form geçerli değilse veya yükleniyorsa butonu devredışı bırak

            Spacer()
            Spacer()
        }
        .padding()
        .navigationTitle("Kayıt Ol") // NavigationStack içinde olduğunda görünür
        .navigationBarBackButtonHidden(false) // Geri butonu görünsün
        .preferredColorScheme(.dark) // Koyu tema
        // .toolbar { // Geri butonu özelleştirmek isterseniz
        //     ToolbarItem(placement: .navigationBarLeading) {
        //         Button {
        //             dismiss()
        //         } label: {
        //             Image(systemName: "chevron.left")
        //         }
        //         .tint(.white) // Veya istediğiniz renk
        //     }
        // }
    }

    func isFormValid() -> Bool {
        // Basit kontroller: Alanlar boş olmamalı ve şifreler eşleşmeli
        !username.isEmpty && !email.isEmpty && email.contains("@") && !password.isEmpty && password == confirmPassword && password.count >= 6 // Min şifre uzunluğu
    }

    func register() {
        guard isFormValid() else {
            errorMessage = "Lütfen tüm alanları doğru doldurun. Şifreler eşleşmeli ve en az 6 karakter olmalı."
            return
        }

        isLoading = true
        errorMessage = nil
        DispatchQueue.main.async {
            do {
                let newUser = try authService.registerUser(username: username, email: email, password: password)
                // Başarılı kayıt sonrası otomatik giriş yap ve RootView'a bildir
                _ = try authService.loginUser(usernameOrEmail: newUser.username, password: password)
                onRegisterSuccess()
                // Kayıt başarılı olunca dismiss'e gerek kalmayabilir, çünkü onRegisterSuccess RootView'ı güncelleyecek.
                // dismiss()
            } catch let error as AuthError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    // Preview için container ve authService yeterli
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // Sadece User ve ilgili modeller (UserSettings gibi) yeterli olabilir
    let container = try! ModelContainer(for: Schema([User.self, UserSettings.self]), configurations: config)
    let authService = AuthService(modelContext: container.mainContext)

    // NavigationStack içinde göstermek daha iyi
    return NavigationStack {
        RegisterView(onRegisterSuccess: { print("Preview Register Success") })
    }
    .modelContainer(container)
    .environment(authService)
    .preferredColorScheme(.dark) // Koyu tema için
}

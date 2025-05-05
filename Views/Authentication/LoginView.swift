import SwiftUI
import SwiftData // <-- BU SATIRI EKLEYİN

struct LoginView: View {
    @State private var usernameOrEmail: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    // Environment'tan AuthService'i al
    @Environment(AuthService.self) private var authService
    // Environment'tan model context'i al (gerekirse)
    // @Environment(\.modelContext) private var modelContext

    var onLoginSuccess: () -> Void // Başarılı girişte çağrılacak closure

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "lock.shield.fill") // Veya kendi logo/ikonunuz
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)

                Text("Giriş Yap")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Kullanıcı Adı veya E-posta", text: $usernameOrEmail)
                    .textContentType(.username) // Otomatik doldurma için ipucu
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground)) // TextField arka planı
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )

                SecureField("Şifre", text: $password)
                    .textContentType(.password) // Otomatik doldurma için ipucu
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
                }

                Button {
                    login()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Giriş Yap")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || usernameOrEmail.isEmpty || password.isEmpty)

                NavigationLink("Hesabın yok mu? Kayıt Ol", destination: RegisterView(onRegisterSuccess: onLoginSuccess)) // Kayıt ekranına yönlendirme
                    .padding(.top)

                Spacer()
                Spacer()
            }
            .padding()
            .navigationTitle("Giriş")
            .navigationBarHidden(true) // İsterseniz başlığı gizleyebilirsiniz
            .preferredColorScheme(.dark) // Koyu tema
        }
    }

    func login() {
        isLoading = true
        errorMessage = nil
        DispatchQueue.main.async { // Asenkron işlem için
            do {
                _ = try authService.loginUser(usernameOrEmail: usernameOrEmail, password: password)
                // Başarılı giriş - RootView'a bildirim gönder
                onLoginSuccess()
            } catch let error as AuthError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false // İşlem bitince loading'i kapat
        }
    }
}

#Preview {
    // Preview için container ve authService yeterli
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // Sadece User ve ilgili modeller (UserSettings gibi) yeterli olabilir
    let container = try! ModelContainer(for: Schema([User.self, UserSettings.self]), configurations: config)
    let authService = AuthService(modelContext: container.mainContext)

    // Doğrudan LoginView döndür
    return LoginView(onLoginSuccess: { print("Preview Login Success") })
        .modelContainer(container)
        .environment(authService)
        .preferredColorScheme(.dark) // Koyu tema için
}

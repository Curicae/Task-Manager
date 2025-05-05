import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    var outlined: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                outlined 
                ? AnyShapeStyle(.clear)
                : AnyShapeStyle(Color.gradientPurple())
            )
            .foregroundColor(outlined ? Color("AccentPurple") : .white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AccentPurple"), lineWidth: outlined ? 2 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Özel buton stilleri için uzantılar
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var outlined: PrimaryButtonStyle { PrimaryButtonStyle(outlined: true) }
    static var compact: PrimaryButtonStyle { PrimaryButtonStyle(fullWidth: false) }
    static var compactOutlined: PrimaryButtonStyle { PrimaryButtonStyle(fullWidth: false, outlined: true) }
}
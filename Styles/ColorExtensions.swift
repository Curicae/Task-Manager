import SwiftUI

extension Color {
    // Yardımcı fonksiyonlar
    static func gradientPurple(_ startPoint: UnitPoint = .topLeading, _ endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color("AccentPurple"), Color("SecondaryPurple")]), 
                       startPoint: startPoint, 
                       endPoint: endPoint)
    }
}
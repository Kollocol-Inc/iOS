
import Foundation
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let dividerToRgb = 255.0
        let red = CGFloat((rgb & 0xFF0000) >> 16) / dividerToRgb
        let green = CGFloat((rgb & 0x00FF00) >> 8) / dividerToRgb
        let blue = CGFloat(rgb & 0x0000FF) / dividerToRgb
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

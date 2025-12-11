import UIKit

// MARK: - Renkler
extension UIColor {
    static var appBlueOrFallback: UIColor {
        UIColor(named: "AppBlue") ?? UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
    }
}

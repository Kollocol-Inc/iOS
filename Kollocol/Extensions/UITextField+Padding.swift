import UIKit

extension UITextField {
    func addPadding(left: CGFloat? = nil, right: CGFloat? = nil) {
        if let left = left {
            leftViewMode = .always
            leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: bounds.height))
        }
        if let right = right {
            rightViewMode = .always
            rightView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: bounds.height))
        }
    }
    
    func addPadding(side: CGFloat? = nil) {
        if let left = side {
            leftViewMode = .always
            leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: bounds.height))
        }
        if let right = side {
            rightViewMode = .always
            rightView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: bounds.height))
        }
    }
}

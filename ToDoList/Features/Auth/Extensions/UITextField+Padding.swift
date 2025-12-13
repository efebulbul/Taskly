//
//  UITextField+Padding.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

extension UITextField {
    func setLeftPadding(_ padding: CGFloat) {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 1))
        leftView = v
        leftViewMode = .always
    }
}

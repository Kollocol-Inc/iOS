//
//  UIImageView+SetImage.swift
//  Kollocol
//
//  Created by Arseniy on 28.02.2026.
//

import UIKit
import Kingfisher

extension UIImageView {
    func setImage(url: String?, placeholder: UIImage? = nil) {
        guard let urlString = url, let url = URL(string: urlString) else {
            image = placeholder
            return
        }
        
        kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.25)),
                .cacheOriginalImage
            ]
        )
    }
}

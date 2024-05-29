//
//  File.swift
//
//
//  Created by HU on 2024/4/30.
//

import Foundation
 
extension Bundle {
    func localizedString(forKey key: String) -> String {
        self.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    var localString: String {
        Bundle.module.localizedString(forKey: self)
    }
}

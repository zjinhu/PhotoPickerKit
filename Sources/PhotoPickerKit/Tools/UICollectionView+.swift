//
//  File.swift
//  
//
//  Created by FunWidget on 2024/5/24.
//

import UIKit

extension UICollectionView {
    
    func useCell<T: UICollectionViewCell>(_ cellType: T.Type = T.self, indexPath: IndexPath) -> T {
        
        let reuseIdentifier = "\(String(describing: cellType))\(indexPath.row)"
        self.register(cellType.self, forCellWithReuseIdentifier: reuseIdentifier)
        let cell = self.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let cell = cell as? T else {
            fatalError(
                "Failed to dequeue a cell with identifier \(reuseIdentifier) matching type \(cellType.self). "
            )
        }
        return cell
        
    }
}


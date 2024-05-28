//
//  QuicklookSegmentView.swift
//  
//
//  Created by FunWidget on 2024/5/23.
//

import UIKit
import SwiftUI
import Combine
class QuicklookSegmentView: UIView, UICollectionViewDelegate {
    private var cancellables: Set<AnyCancellable> = []
    let viewModel: GalleryModel
 
    init(viewModel: GalleryModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.setupView()
        
        self.viewModel.$selectedAssets
            .receive(on: RunLoop.main)
            .sink {[weak self] array in
                guard let self = self else{return}
                self.snapshot.deleteAllItems()
                self.snapshot.appendSections([.main])
                self.snapshot.appendItems(array, toSection: .main)
                self.dataSource.apply(self.snapshot, animatingDifferences: false)
            }.store(in: &cancellables)
        
        self.viewModel.$previewSelectIndex
            .receive(on: RunLoop.main)
            .sink {[weak self] index in
                guard let self = self else{return}
                let indexPath = IndexPath(item: index, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.snapshot.reloadSections([.main])
                self.dataSource.apply(self.snapshot, animatingDifferences: false)
            }.store(in: &cancellables)
    }
    
    
    lazy var snapshot = NSDiffableDataSourceSnapshot<AssetSection, SelectedAsset>()
    
    lazy var dataSource = UICollectionViewDiffableDataSource<AssetSection, SelectedAsset>(collectionView: collectionView) { collectionView, indexPath, item in
        
        let cell = collectionView.useCell(QuicklookCell.self, indexPath: indexPath)
        cell.asset = item
        if self.viewModel.previewSelectIndex == indexPath.row{
            cell.layer.borderColor = Color.mainBlue.toUIColor().cgColor
        }else{
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        cell.layer.borderWidth = 3
        cell.layer.cornerRadius = 4
        cell.clipsToBounds = true
        return cell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView()  {
        addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.itemSize = CGSize(width: 90, height: 90)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = Color.backColor.toUIColor() 
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.previewSelectIndex = indexPath.row
        collectionView.reloadData()
    }
}
 

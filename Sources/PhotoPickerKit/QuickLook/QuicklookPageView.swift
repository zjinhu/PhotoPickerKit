//
//  QuicklookPageView.swift
//  
//
//  Created by FunWidget on 2024/5/23.
//

import UIKit
import SwiftUI
import BrickKit
import Combine
class QuicklookPageView: UIView {
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

                let indexPath = IndexPath(item: index, section: 0)
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

            }.store(in: &cancellables)
    }
    
    lazy var snapshot = NSDiffableDataSourceSnapshot<AssetSection, SelectedAsset>()
    
    lazy var dataSource = UICollectionViewDiffableDataSource<AssetSection, SelectedAsset>(collectionView: collectionView) { collectionView, indexPath, item in
        
                switch item.fetchPHAssetType() {
                case .image:
                    let cell = collectionView.useCell(QuicklookImageCell.self, indexPath: indexPath)
                    cell.setSelectedAsset(asset: item)
                    return cell
                case .gif:
                    let cell = collectionView.useCell(QuicklookGifCell.self, indexPath: indexPath)
                    cell.setSelectedAsset(asset: item)
                    return cell
                case .video:
                    let cell = collectionView.useCell(QuicklookVideoCell.self, indexPath: indexPath)
                    cell.setSelectedAsset(asset: item)
                    return cell
                case .livePhoto:
                    let cell = collectionView.useCell(QuicklookLivePhotoCell.self, indexPath: indexPath)
                    cell.setSelectedAsset(asset: item)
                    return cell
                default:
                    break
                }
        
        return UICollectionViewCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView()  {
        addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
 
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = Color.backColor.toUIColor()
        return collectionView
    }()

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
                let currentIndex = indexPath.row
                viewModel.previewSelectIndex = currentIndex
            }
        }
    }
}

extension QuicklookPageView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? QuicklookVideoCell {
            videoCell.isPlaying = false
            videoCell.player.pause()
            videoCell.player.seek(to: .zero)
        }
    }
}

extension QuicklookPageView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: Screen.width, height: self.frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        // 返回指定 section 的最小行间距
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        // 返回指定 section 的最小列间距
        return 0
    }
}


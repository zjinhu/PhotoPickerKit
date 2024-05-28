//
//  GalleryViewController.swift
//
//
//  Created by HU on 2024/5/16.
//

import UIKit
import JXSegmentedView
import BrickKit
import Photos
import Combine
import SwiftUI

let cellSpace: CGFloat = 5
let numberOfCellsInRow = 4
let cellWidth = (Screen.width - cellSpace * CGFloat(numberOfCellsInRow + 1)) / CGFloat(numberOfCellsInRow)

class GalleryViewController: UIViewController {
    
    var photos: [SelectedAsset] = []
    
    lazy var snapshot = NSDiffableDataSourceSnapshot<AssetSection, SelectedAsset>()
    
    lazy var dataSource = UICollectionViewDiffableDataSource<AssetSection, SelectedAsset>(collectionView: gridCollectionView) { collectionView, indexPath, item in
        
        collectionView.register(GalleryViewCell.self, forCellWithReuseIdentifier: "cell\(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell\(indexPath.row)", for: indexPath)
        guard let cell = cell as? GalleryViewCell else {
            fatalError(
                "Failed to dequeue a cell with identifier GalleryViewCell. "
            )
        }
        cell.viewModel = self.viewModel
        cell.asset = item
        return cell
    }
    
    let album: AlbumItem
    let viewModel: GalleryModel
    init(album: AlbumItem, viewModel: GalleryModel) {
        self.album = album
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = false
        
        if viewModel.isStatic {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        }
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        album.fetchResult(options: fetchOptions)
        
        self.album.$result
            .receive(on: RunLoop.main)
            .sink {[weak self] result in
                guard let self = self, let result = result else{return}
                
                for index in 0..<result.count{
                    var photo = SelectedAsset(asset: result.object(at: index))
                    photo.isStatic = viewModel.isStatic
                    self.photos.append(photo)
                }
                self.snapshot.appendItems(self.photos, toSection: .main)
                self.dataSource.apply(self.snapshot, animatingDifferences: false)
                
            }.store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var gridCollectionView: UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = cellSpace
        layout.minimumInteritemSpacing = cellSpace
        
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        let gridCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        gridCollectionView.delegate = self
        gridCollectionView.translatesAutoresizingMaskIntoConstraints = false
        gridCollectionView.backgroundColor = Color.backColor.toUIColor()
        return gridCollectionView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        snapshot.appendSections([.main])

        view.addSubview(gridCollectionView)
        gridCollectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gridCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gridCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        gridCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !photos.isEmpty{
            snapshot.reloadItems(photos)
            dataSource.apply(snapshot, animatingDifferences: false)
        }

    }
}

extension GalleryViewController: UICollectionViewDelegate {
    
    // 选中单元格时的处理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 处理选中逻辑
        guard var item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if viewModel.maxSelectionCount == 1{
            viewModel.selectedAssets.append(item)
            viewModel.selectedAsset = item
            if viewModel.autoCrop{
                viewModel.showCrop.toggle()
            }else{
                viewModel.onSelectedDone.toggle()
            }
            return
        }
        
        if viewModel.selectedAssets.contains(where: { pic in pic.asset == item.asset }),
           let index = viewModel.selectedAssets.firstIndex(where: { picture in picture.asset == item.asset}){
            viewModel.selectedAssets.remove(at: index)
        }else{
            if viewModel.maxSelectionCount == viewModel.selectedAssets.count{
                viewModel.showToast.toggle()
                return
            }
            viewModel.selectedAssets.append(item)
        }
        snapshot.reloadItems(photos)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension GalleryViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}

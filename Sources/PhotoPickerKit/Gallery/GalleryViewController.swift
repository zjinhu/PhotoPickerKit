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
    
    var result: PHFetchResult<PHAsset>?
    
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
                self?.result = result
                self?.gridCollectionView.reloadData()
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
        gridCollectionView.dataSource = self
        gridCollectionView.translatesAutoresizingMaskIntoConstraints = false
        gridCollectionView.backgroundColor = Color.backColor.toUIColor()
        return gridCollectionView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(gridCollectionView)
        gridCollectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gridCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gridCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        gridCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gridCollectionView.reloadData()
    }
}

extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.count // 九宫格，共有9个单元格
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.register(GalleryViewCell.self, forCellWithReuseIdentifier: "cell\(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell\(indexPath.row)", for: indexPath)
        guard let cell = cell as? GalleryViewCell else {
            fatalError(
                "Failed to dequeue a cell with identifier GalleryViewCell. "
            )
        }
        if result?.count != 0, let asset = result?[indexPath.row]{
            cell.asset = SelectedAsset(asset: asset)
            cell.isStatic = viewModel.isStatic
     
            if viewModel.maxSelectionCount != 1{
                cell.isShowNumber = true
                let status = getPhotoStatus(asset: asset)
                cell.isDisabled = status.disable
                cell.setNumber(number: status.number)
            }
        }

        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegate {
    
    // 选中单元格时的处理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 处理选中逻辑
        if let asset = result?[indexPath.row]{
            if viewModel.maxSelectionCount == 1{
                let picture = SelectedAsset(asset: asset)
                viewModel.selectedAssets.append(picture)
                if viewModel.autoCrop{
                    viewModel.showCrop.toggle()
                }else{
                    viewModel.onSelectedDone.toggle()
                }
                return
            }
            
            if viewModel.selectedAssets.contains(where: { pic in pic.asset == asset }),
               let index = viewModel.selectedAssets.firstIndex(where: { picture in picture.asset == asset}){
                viewModel.selectedAssets.remove(at: index)
                viewModel.selectIndesPaths.remove(at: index)
 
                if viewModel.selectIndesPaths.count >= viewModel.maxSelectionCount - 1{
                    collectionView.reloadData()
                }else{
                    collectionView.reloadItems(at: [indexPath])
                    collectionView.reloadItems(at: viewModel.selectIndesPaths)
                }
                
            }else{
                if viewModel.maxSelectionCount == viewModel.selectedAssets.count{
                    viewModel.showToast.toggle()
                    return
                }
                let picture = SelectedAsset(asset: asset)
                viewModel.selectedAssets.append(picture)
                viewModel.selectIndesPaths.append(indexPath)
                if viewModel.selectIndesPaths.count >= viewModel.maxSelectionCount - 1{
                    collectionView.reloadData()
                }else{
                    collectionView.reloadItems(at: viewModel.selectIndesPaths)
                }
            }
        }
    }
    
    func getPhotoStatus(asset: PHAsset?) -> (number: Int?, disable: Bool){
        
        guard let asset = asset else { return (number: nil, disable: false) }
        
        var number: Int?
        if viewModel.selectedAssets.contains(where: { picture in picture.asset == asset }){
            let index = viewModel.selectedAssets.firstIndex(where: { picture in picture.asset == asset}) ?? -1
            number = index + 1
        }else{
            number = nil
        }
        var disable: Bool
        if viewModel.selectedAssets.count == viewModel.maxSelectionCount{
            disable = true
        }else{
            disable = false
        }
        
        return (number: number, disable: disable)
    }
}

extension GalleryViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}

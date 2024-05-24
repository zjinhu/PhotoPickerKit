//
//  GalleryPageViewController.swift
//
//
//  Created by HU on 2024/5/16.
//

import UIKit
import JXSegmentedView
import BrickKit
import Combine
import SwiftUI

class GalleryPageViewController: UIViewController {
 
    let viewModel: GalleryModel
 
    init(viewModel: GalleryModel) {

        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.$albums
            .receive(on: RunLoop.main)
            .sink {[weak self] array in
                self?.segmentedDataSource.titles = array.compactMap({ albumItem in
                    albumItem.title
                })
                self?.segmentedView.reloadData()
         }.store(in: &cancellables)
        
        self.viewModel.$defaultSelectIndex
            .receive(on: RunLoop.main)
            .sink {[weak self] index in
                self?.segmentedView.selectItemAt(index: index)
         }.store(in: &cancellables)
        
        self.viewModel.$selectedAssets
            .receive(on: RunLoop.main)
            .sink {[weak self] array in
                self?.doneButton.setTitle("完成".localString + (array.count > 0 ? " (\(array.count))" : ""), for: .normal)
         }.store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    lazy var segmentedDataSource: JXSegmentedTitleDataSource = {
        let segmentedDataSource = JXSegmentedTitleDataSource()
        segmentedDataSource.configuration = self
        segmentedDataSource.isTitleColorGradientEnabled = true
        segmentedDataSource.isItemSpacingAverageEnabled = false
        return segmentedDataSource
    }()
    
    lazy var indicator: JXSegmentedIndicatorLineView = {
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorWidth = JXSegmentedViewAutomaticDimension
        indicator.verticalOffset = 4
        indicator.indicatorColor = Color.textColor.toUIColor()
        return indicator
    }()
    
    lazy var listContainerView: JXSegmentedListContainerView = {
        let listContainerView = JXSegmentedListContainerView(dataSource: self)
        listContainerView.translatesAutoresizingMaskIntoConstraints = false
        return listContainerView
    }()
    
    lazy var segmentedView: JXSegmentedView = {
        let segmentedView = JXSegmentedView()
        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self
        segmentedView.listContainer = listContainerView
        segmentedView.indicators = [indicator]
        segmentedView.translatesAutoresizingMaskIntoConstraints = false
        return segmentedView
    }()
    
    lazy var backButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = Color.textColor.toUIColor()
        button.addTarget(self, action: #selector(closeVC), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        return button
    }()
 
    lazy var toolBarView: UIView = {
        let toolBarView = UIView()
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.addSeparator(color: UIColor.gray.withAlphaComponent(0.5),
                                 thickness: 0.5,
                                 position: .top)
        return toolBarView
    }()
    
    lazy var liveButton: UIButton = {
        let button = UIButton()
        button.setTitle("动态效果".localString, for: .normal)
        button.setTitleColor(Color.buttonunSelectedColor.toUIColor(), for: .normal)
        button.setTitleColor(Color.textColor.toUIColor(), for: .selected)
        button.setImage(UIImage(systemName: "circle")?.withTintColor(.black), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.black), for: .selected)
        button.tintColor = Color.textColor.toUIColor()
//        button.imageView?.size = CGSize(width: 14, height: 14)
//        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), imageTitlePadding: 5)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.addTarget(self, action: #selector(switchStatic), for: .touchUpInside)
        button.isSelected = true
        button.isHidden = viewModel.isStatic
        return button
    }()
    
    lazy var previewButton: UIButton = {
        let button = UIButton()
        button.setTitle("预览".localString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(Color.textColor.toUIColor(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), imageTitlePadding: 0)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.addTarget(self, action: #selector(quicklook), for: .touchUpInside)
//        button.isHidden = true
        return button
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("完成".localString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Color.mainBlack.toUIColor()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 12
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12), imageTitlePadding: 5)
        button.addTarget(self, action: #selector(doneSelect), for: .touchUpInside)
        return button
    }()
    
    @objc
    func switchStatic(){
        viewModel.isStatic.toggle()
        liveButton.isSelected.toggle()
    }
    
    @objc
    func quicklook(){
        viewModel.showQuicklook.toggle()
    }
    
    @objc
    func doneSelect(){
        viewModel.onSelectedDone.toggle()
    }
    
    @objc
    func closeVC(){
        dismiss(animated: true)
    }
    
    lazy var permissionBarView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.alertBackColor.toUIColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return view
    }()
    
    lazy var goButton: UIButton = {
        let button = UIButton()
        button.setTitle("管理".localString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(Color.mainBlack.toUIColor(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1
        button.layer.borderColor = Color.mainBlack.toUIColor().cgColor
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12), imageTitlePadding: 0)
        button.addTarget(self, action: #selector(goPermission), for: .touchUpInside)
        return button
    }()
    
    @objc
    func goPermission(){
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    lazy var permissionLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.text = "你已允许访问选择照片，可管理选择更多照片".localString
        view.textColor = Color.secondGray.toUIColor()
        view.textAlignment = .left
        view.numberOfLines = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.backColor.toUIColor()
        
        view.addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Screen.safeArea.top).isActive = true
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        view.addSubview(segmentedView)
        segmentedView.topAnchor.constraint(equalTo: view.topAnchor, constant: Screen.safeArea.top).isActive = true
        segmentedView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        segmentedView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor).isActive = true
        segmentedView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if viewModel.permission == .limited {
            view.addSubview(permissionBarView)
            permissionBarView.topAnchor.constraint(equalTo: segmentedView.bottomAnchor, constant: 12).isActive = true
            permissionBarView.heightAnchor.constraint(equalToConstant: 44).isActive = true
            permissionBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
            permissionBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
            
            permissionBarView.addSubview(goButton)
            goButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
            goButton.centerYAnchor.constraint(equalTo: permissionBarView.centerYAnchor).isActive = true
            goButton.trailingAnchor.constraint(equalTo: permissionBarView.trailingAnchor, constant: -12).isActive = true
            
            permissionBarView.addSubview(permissionLabel)
            permissionLabel.topAnchor.constraint(equalTo: permissionBarView.topAnchor).isActive = true
            permissionLabel.bottomAnchor.constraint(equalTo: permissionBarView.bottomAnchor).isActive = true
            permissionLabel.leadingAnchor.constraint(equalTo: permissionBarView.leadingAnchor, constant: 12).isActive = true
            permissionLabel.trailingAnchor.constraint(equalTo: goButton.leadingAnchor, constant: -2).isActive = true
        }
        
        view.addSubview(toolBarView)
        toolBarView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Screen.safeArea.bottom).isActive = true
        toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
 
        view.addSubview(listContainerView)
        if viewModel.permission == .limited {
            listContainerView.topAnchor.constraint(equalTo: permissionBarView.bottomAnchor, constant: 12).isActive = true
        }else{
            listContainerView.topAnchor.constraint(equalTo: segmentedView.bottomAnchor).isActive = true
        }
        listContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        listContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if viewModel.maxSelectionCount == 1{
            listContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            toolBarView.isHidden = true
        }else{
            listContainerView.bottomAnchor.constraint(equalTo: toolBarView.topAnchor).isActive = true
            
            toolBarView.addSubview(previewButton)
            previewButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            previewButton.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor).isActive = true
            previewButton.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
            
            toolBarView.addSubview(liveButton)
     
            liveButton.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
            liveButton.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor).isActive = true
            
            toolBarView.addSubview(doneButton)
            doneButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            doneButton.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -15).isActive = true
            doneButton.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        }

    }
}

extension GalleryPageViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        if let dotDataSource = segmentedDataSource as? JXSegmentedDotDataSource {
            //先更新数据源的数据
            dotDataSource.dotStates[index] = false
            //再调用reloadItem(at: index)
            segmentedView.reloadItem(at: index)
        }

        navigationController?.interactivePopGestureRecognizer?.isEnabled = (segmentedView.selectedIndex == 0)
    }
}

extension GalleryPageViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        if let titleDataSource = segmentedView.dataSource as? JXSegmentedBaseDataSource {
            return titleDataSource.dataSource.count
        }
        return 0
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        let album = viewModel.albums[index]
        return GalleryViewController(album: album, viewModel: viewModel)
    }
}


extension GalleryPageViewController: JXSegmentedTitleDynamicConfiguration {
    func titleNumberOfLines(at index: Int) -> Int {
        1
    }
    
    func titleNormalColor(at index: Int) -> UIColor {
        return Color.secondGray.toUIColor()
    }
    
    func titleSelectedColor(at index: Int) -> UIColor {
        return Color.textColor.toUIColor()
    }
    
    func titleNormalFont(at index: Int) -> UIFont {
        return .systemFont(ofSize: 15)
    }
    
    func titleSelectedFont(at index: Int) -> UIFont? {
        return .systemFont(ofSize: 15, weight: .medium)
    }
}


enum SeparatorPosition {
    case top
    case bottom
    case left
    case right
}

extension UIView {
    func addSeparator(color: UIColor, thickness: CGFloat, position: SeparatorPosition) {
        let separatorView = UIView()
        separatorView.backgroundColor = color
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separatorView)
        
        switch position {
        case .top:
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                separatorView.topAnchor.constraint(equalTo: self.topAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: thickness)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: thickness)
            ])
        case .left:
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                separatorView.topAnchor.constraint(equalTo: self.topAnchor),
                separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                separatorView.widthAnchor.constraint(equalToConstant: thickness)
            ])
        case .right:
            NSLayoutConstraint.activate([
                separatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                separatorView.topAnchor.constraint(equalTo: self.topAnchor),
                separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                separatorView.widthAnchor.constraint(equalToConstant: thickness)
            ])
        }
    }
}

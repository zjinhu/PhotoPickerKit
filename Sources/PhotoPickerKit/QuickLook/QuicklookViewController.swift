//
//  QuicklookViewController.swift
//
//
//  Created by FunWidget on 2024/5/23.
//

import UIKit
import BrickKit
import SwiftUI
import Combine
class QuicklookViewController: UIViewController {
    let viewModel: GalleryModel
    private var cancellables: Set<AnyCancellable> = []
    init(viewModel: GalleryModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.$previewSelectIndex
            .receive(on: RunLoop.main)
            .sink {[weak self] index in
                
                guard let count = self?.viewModel.selectedAssets.count else{return}
                self?.titleLabel.text = "\(index+1)/\(count)"
                self?.currentLabel.text = "\(index+1)"
                
            }.store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var previewView: QuicklookPageView = {
        let previewView = QuicklookPageView(viewModel: viewModel)
        previewView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        return previewView
    }()
    
    lazy var segmentView: QuicklookSegmentView = {
        let view = QuicklookSegmentView(viewModel: viewModel)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var topBarView: UIView = {
        let topBarView = UIView()
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        return topBarView
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
    
    @objc
    func closeVC(){
        viewModel.previewSelectIndex = 0
        self.navigationController?.popViewController(animated: true)
    }
    
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 18)
        view.textColor = Color.textColor.toUIColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var currentLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .medium)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = Color.mainBlue.toUIColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 14
        return view
    }()
    
    lazy var bottomBarView: UIView = {
        let toolBarView = UIView()
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.addSeparator(color: UIColor.gray.withAlphaComponent(0.5),
                                 thickness: 0.5,
                                 position: .top)
        toolBarView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return toolBarView
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton()
        button.setTitle("编辑".localString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(Color.textColor.toUIColor(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), imageTitlePadding: 0)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.addTarget(self, action: #selector(edit), for: .touchUpInside)
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
    func edit(){
        // MARK: - 点击编辑按钮开始制造数据
        Task{
            let sset = viewModel.selectedAssets[viewModel.previewSelectIndex]
            viewModel.selectedAsset = await sset.getOriginalSource()
            viewModel.isPresentedEdit.toggle()
            viewModel.resetVideoStatus.toggle()
        }
    }
    
    @objc
    func doneSelect(){
        viewModel.previewSelectIndex = 0
        viewModel.onSelectedDone.toggle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.backColor.toUIColor()
        
        view.addSubview(topBarView)
        topBarView.topAnchor.constraint(equalTo: view.topAnchor, constant: Screen.safeArea.top).isActive = true
        topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topBarView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        topBarView.addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: topBarView.topAnchor).isActive = true
        backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        topBarView.addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor).isActive = true
        
        topBarView.addSubview(currentLabel)
        currentLabel.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16).isActive = true
        currentLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor).isActive = true
        currentLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
        currentLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true
        
        view.addSubview(bottomBarView)
        bottomBarView.heightAnchor.constraint(equalToConstant: 153).isActive = true
        bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Screen.safeArea.bottom).isActive = true
        bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(previewView)
        previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: Screen.width).isActive = true
        previewView.topAnchor.constraint(equalTo: topBarView.bottomAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(Screen.safeArea.bottom+153)).isActive = true
        
        bottomBarView.addSubview(editButton)
        editButton.bottomAnchor.constraint(equalTo: bottomBarView.bottomAnchor, constant: -2).isActive = true
        editButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 16).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        bottomBarView.addSubview(doneButton)
        doneButton.bottomAnchor.constraint(equalTo: bottomBarView.bottomAnchor, constant: -2).isActive = true
        doneButton.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -16).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        bottomBarView.addSubview(segmentView)
        segmentView.topAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: 15).isActive = true
        segmentView.heightAnchor.constraint(equalToConstant: 90).isActive = true
        segmentView.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor).isActive = true
        segmentView.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor).isActive = true
        
    }
    
}


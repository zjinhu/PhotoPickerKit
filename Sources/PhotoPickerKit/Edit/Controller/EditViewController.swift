//
//  EditViewController.swift
//
//
//  Created by FunWidget on 2024/5/29.
//

import UIKit
import AVFoundation
import Photos

public extension EditViewController {
    typealias FinishHandler = (EditorAsset, EditViewController) -> Void
    typealias CancelHandler = (EditViewController) -> Void
}

public class EditViewController: UIViewController {
    
    var config: EditorConfiguration
    let assets: [EditorAsset]
    var selectedAsset: EditorAsset
    var editedResult: EditedResult?
    var finishHandler: FinishHandler?
    var cancelHandler: CancelHandler?
    weak var delegate: EditViewControllerDelegate?
    private(set) var selectedIndex: Int = 0
    
    public init(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditViewControllerDelegate? = nil,
        finish: FinishHandler? = nil,
        cancel: CancelHandler? = nil
    ) {
        self.assets = [asset]
        self.selectedAsset = asset
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        var cropTime = config.video.cropTime
        if config.isIgnoreCropTimeWhenFixedCropSizeState {
            cropTime.maximumTime = 0
        }
        videoControlView = EditorVideoControlView(config: cropTime)
        videoControlView.delegate = self
        videoControlView.alpha = 0
        videoControlView.isHidden = true
        videoControlView.translatesAutoresizingMaskIntoConstraints = false
        
        addViews()
        initAsset()
    }
    var isDismissed: Bool = false
    var isPopTransition: Bool = false
    var assetRequestID: PHImageRequestID?
    var isLoadCompletion: Bool = false
    var isLoadVideoControl: Bool = false
    
    var videoControlInfo: EditorVideoControlInfo?
    
    var backgroundInsetRect: CGRect = .zero
    var selectedOriginalImage: UIImage?
    var selectedThumbnailImage: UIImage?
    var isTransitionCompletion: Bool = true
    var loadAssetStatus: LoadAssetStatus = .loadding()
    weak var assetLoadingView: PhotoHUDProtocol?
    var firstAppear = true
    var navModalStyle: UIModalPresentationStyle?
    var navFrame: CGRect?
    var isFullScreen: Bool {
        let isFull = splitViewController?.modalPresentationStyle == .fullScreen
        if let nav = navigationController {
            return nav.modalPresentationStyle == .fullScreen || nav.modalPresentationStyle == .custom || isFull
        }else {
            if let navModalStyle {
                return navModalStyle == .fullScreen || navModalStyle == .custom || isFull
            }
            return modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom || isFull
        }
    }
    
    var videoCoverView: UIImageView?
    weak var videoTool: EditorVideoTool?
    weak var videoPlayTimer: Timer?
    
    var videoControlView: EditorVideoControlView!
    
    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        cancelButton.addTarget(self, action: #selector(didCancelButtonClick(button:)), for: .touchUpInside)
        return cancelButton
    }()
    
    lazy var finishButton: UIButton = {
        let finishButton = UIButton(type: .custom)
        finishButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        finishButton.tintColor = .white
        finishButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        finishButton.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        finishButton.isEnabled = !config.isWhetherFinishButtonDisabledInUneditedState
        return finishButton
    }()
    
    lazy var resetButton: UIButton = {
        let resetButton = UIButton(type: .custom)
        resetButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        resetButton.tintColor = .white
        resetButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        resetButton.addTarget(self, action: #selector(didResetButtonClick(button:)), for: .touchUpInside)
        return resetButton
    }()
    
    lazy var leftRotateButton: UIButton = {
        let leftRotateButton = UIButton(type: .custom)
        leftRotateButton.setImage(UIImage(systemName: "rotate.left"), for: .normal)
        leftRotateButton.tintColor = .white
        leftRotateButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        leftRotateButton.addTarget(self, action: #selector(didLeftRotateButtonClick(button:)), for: .touchUpInside)
        return leftRotateButton
    }()
    
    lazy var rightRotateButton: UIButton = {
        let rightRotateButton = UIButton(type: .custom)
        rightRotateButton.setImage(UIImage(systemName: "rotate.right"), for: .normal)
        rightRotateButton.tintColor = .white
        rightRotateButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        rightRotateButton.addTarget(self, action: #selector(didRightRotateButtonClick(button:)), for: .touchUpInside)
        return rightRotateButton
    }()
    
    lazy var backgroundView: UIScrollView = {
        let backgroundView = UIScrollView()
        backgroundView.maximumZoomScale = 1
        backgroundView.showsVerticalScrollIndicator = false
        backgroundView.showsHorizontalScrollIndicator = false
        backgroundView.clipsToBounds = false
        backgroundView.scrollsToTop = false
        backgroundView.isScrollEnabled = false
        backgroundView.bouncesZoom = false
        backgroundView.delegate = self
        backgroundView.contentInsetAdjustmentBehavior = .never
        return backgroundView
    }()
    
    lazy var editorView: EditorView = {
        let editorView = EditorView()
        editorView.editContentInset = { [weak self] _ in
            guard let self = self else {
                return .zero
            }
            if UIDevice.isPortrait {
                let top: CGFloat
                let bottom: CGFloat
                var bottomMargin = UIDevice.bottomMargin
                if !self.isFullScreen, UIDevice.isPad {
                    bottomMargin = 0
                }
                
                if self.isFullScreen {
                    top = UIDevice.isPad ? 50 : UIDevice.topMargin + 30
                }else {
                    top = UIDevice.topMargin + 40
                }
                bottom = bottomMargin + 50 + (self.editorView.type == .video ? 70 : 5)
                
                let left = UIDevice.isPad ? 30 : UIDevice.leftMargin + 15
                let right = UIDevice.isPad ? 30 : UIDevice.rightMargin + 15
                return .init(top: top, left: left, bottom: bottom, right: right)
            }else {
                
                return .init(
                    top: UIDevice.topMargin + 15,
                    left: 150,
                    bottom: UIDevice.bottomMargin + (self.editorView.type == .video ? 60 : 10),
                    right: 150
                )
            }
        }
        editorView.urlConfig = config.urlConfig
        editorView.exportScale = config.photo.scale
        editorView.initialRoundMask = config.cropSize.isRoundCrop
        editorView.initialFixedRatio = config.cropSize.isFixedRatio
        editorView.initialAspectRatio = config.cropSize.aspectRatio
        editorView.maskType = config.cropSize.maskType
        editorView.isShowScaleSize = config.cropSize.isShowScaleSize
        if config.cropSize.isFixedRatio {
            editorView.isResetIgnoreFixedRatio = config.cropSize.isResetToOriginal
        }else {
            editorView.isResetIgnoreFixedRatio = true
        }
        editorView.editDelegate = self
//        editorView.isContinuousRotation = true
//        editorView.rotate(0, animated: false)
        editorView.startEdit(true) {  }
        return editorView
    }()
    
    var orientationDidChange: Bool = true
    
    lazy var toolBarView: UIStackView = {
        let toolBarView = UIStackView()
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.alignment = .center
        toolBarView.distribution = .fillEqually
        return toolBarView
    }()
    
    lazy var portraitConstraints: [NSLayoutConstraint] = [
        toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIDevice.bottomMargin),
        toolBarView.heightAnchor.constraint(equalToConstant: 40),
        
        invertColorButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UIDevice.topMargin),
        invertColorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        invertColorButton.widthAnchor.constraint(equalToConstant: 30),
        invertColorButton.heightAnchor.constraint(equalToConstant: 30)
    ]
    
    lazy var landscapeConstraints: [NSLayoutConstraint] = [
        toolBarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
        toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIDevice.bottomMargin),
        toolBarView.widthAnchor.constraint(equalToConstant: 60),
        
        invertColorButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
        invertColorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
        invertColorButton.widthAnchor.constraint(equalToConstant: 30),
        invertColorButton.heightAnchor.constraint(equalToConstant: 30)
    ]
    
    lazy var invertColorButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "circle.lefthalf.filled.inverse"), for: .normal)
        btn.tintColor = .white
        btn.transform = CGAffineTransform(rotationAngle: .pi / 4)
        btn.addTarget(self, action: #selector(didIvertColorClick(button:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    @objc func didIvertColorClick(button: UIButton) {
        button.isSelected.toggle()
        if button.isSelected{
            view.backgroundColor = .white
        }else{
            view.backgroundColor = .black
        }
    }

    func showVideoControlView() {
        editorView.startEdit(true) {  }
        if !videoControlView.isHidden && videoControlView.alpha == 1 {
            return
        }
        videoControlView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.videoControlView.alpha = 1
        }
    }
    
    private func addViews() {
        view.clipsToBounds = true
        view.backgroundColor = .black
        
        view.addSubview(backgroundView)
        backgroundView.addSubview(editorView)
        view.addSubview(videoControlView)
        view.addSubview(toolBarView)
        view.addSubview(invertColorButton)
        toolBarView.addArrangedSubview(cancelButton)
        toolBarView.addArrangedSubview(leftRotateButton)
        toolBarView.addArrangedSubview(resetButton)
        toolBarView.addArrangedSubview(rightRotateButton)
        toolBarView.addArrangedSubview(finishButton)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if orientationDidChange {
            editorView.frame = view.bounds
            backgroundView.frame = view.bounds
            backgroundView.contentSize = view.size
        }
        
        if UIDevice.isPortrait {
            toolBarView.axis = .horizontal
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
            if orientationDidChange || firstAppear {
                videoControlView.frame = .init(x: 0, y: view.height - UIDevice.bottomMargin - 100, width: view.width, height: 50)
            }
        }else {
            toolBarView.axis = .vertical
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
            if orientationDidChange || firstAppear {
                videoControlView.frame = .init(x: 0, y: view.height - UIDevice.bottomMargin - 50, width: view.width, height: 40
                )
            }
        }
        
        if firstAppear {
            firstAppear = false
            loadVideoControl()
            editorView.layoutSubviews()
            checkLastResultState()
        }
        
        if orientationDidChange {
            editorView.update()
            orientationDidChange = false
        }
        
        updateVideoControlInfo()
        
    }
    
    public override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    public override var prefersStatusBarHidden: Bool {
        config.prefersStatusBarHidden
    }
    open override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController != self &&
            navigationController?.viewControllers.contains(self) == false {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navModalStyle = navigationController?.modalPresentationStyle
        if let isHidden = navigationController?.navigationBar.isHidden, !isHidden {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    open override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        
        deviceOrientationWillChanged()
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.deviceOrientationDidChanged()
        }
    }
    
    func deviceOrientationWillChanged() {
        orientationDidChange = true
        if editorView.type == .video {
            if ProcessInfo.processInfo.isiOSAppOnMac, editorView.isVideoPlaying {
                stopPlayVideo()
                editorView.pauseVideo()
            }
            videoControlView.stopScroll()
            videoControlView.stopLineAnimation()
            videoControlInfo = videoControlView.controlInfo
        }
    }
    
    func deviceOrientationDidChanged() {
        
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PhotoTools.removeCache()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let vcs = navigationController?.viewControllers {
            if !vcs.contains(self) {
                if !isDismissed {
                    cancelHandler?(self)
                }
                removeVideo()
            }
        }else if presentingViewController == nil {
            if !isDismissed {
                cancelHandler?(self)
            }
            removeVideo()
        }
    }
    
    deinit {
        removeVideo()
    }
    
    func removeVideo() {
        if editorView.type == .video {
            editorView.pauseVideo()
            editorView.cancelVideoCroped()
            videoTool?.cancelExport()
            videoTool = nil
        }
    }
    
    func updateVideoControlInfo() {
        if let videoControlInfo = videoControlInfo {
            videoControlView.reloadVideo()
            videoControlView.layoutIfNeeded()
            if ProcessInfo.processInfo.isiOSAppOnMac {
                videoControlView.setControlInfo(videoControlInfo)
                videoControlView.resetLineViewFrsme(at: editorView.videoPlayTime)
                updateVideoTimeRange()
            }else {
                DispatchQueue.main.async {
                    self.videoControlView.setControlInfo(videoControlInfo)
                    self.videoControlView.resetLineViewFrsme(at: self.editorView.videoPlayTime)
                    self.updateVideoTimeRange()
                }
            }
            self.videoControlInfo = nil
        }
    }
}



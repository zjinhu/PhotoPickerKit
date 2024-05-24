//
//  EditorChartletViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

class EditorChartletViewCell: UICollectionViewCell {
    private var selectedBgView: UIVisualEffectView!
    
    var imageView: ImageView!
    var editorType: EditorContentViewType = .image
    var downloadCompletion = false
    
    var titleChartlet: EditorChartletTitle! {
        didSet {
            selectedBgView.isHidden = !titleChartlet.isSelected

            setupImage(image: titleChartlet.image)
        }
    }
    
    var isSelectedTitle: Bool = false {
        didSet {
            titleChartlet.isSelected = isSelectedTitle
            selectedBgView.isHidden = !titleChartlet.isSelected
        }
    }
    
    var showSelectedBgView: Bool = false {
        didSet {
            selectedBgView.isHidden = !showSelectedBgView
        }
    }
    
    var chartlet: EditorChartlet! {
        didSet {
            selectedBgView.isHidden = true
            setupImage(image: chartlet.image)
        }
    }
    
    func setupImage(image: UIImage?, url: URL? = nil) {
        downloadCompletion = false
        imageView.image = nil
       
        if let image = image {
            imageView.image = image
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let effect = UIBlurEffect(style: .dark)
        selectedBgView = UIVisualEffectView(effect: effect)
        selectedBgView.isHidden = true
        selectedBgView.layer.cornerRadius = 5
        selectedBgView.layer.masksToBounds = true
        contentView.addSubview(selectedBgView)
        imageView = ImageView()
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBgView.frame = bounds
        if titleChartlet != nil {
            imageView.size = CGSize(width: 25, height: 25)
            imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }else {
            imageView.frame = CGRect(x: 5, y: 5, width: width - 10, height: height - 10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

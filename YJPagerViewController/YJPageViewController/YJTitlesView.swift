//
//  YJTitlesView.swift
//  YJPagerViewController
//
//  Created by ddn on 16/8/24.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

class YJTitlesView: UIScrollView {

    var selectedIdxHanlder: ((_ preIdx: Int, _ idx: Int) -> Void)?
    
    fileprivate lazy var titleBtns = [UIButton]()
    
    var titleBtnW : CGFloat = 0.0
    
    var titleBtnSpace : CGFloat = 0.3
    
    var indicatorH : CGFloat = 3.0
    
    var indicatorInset : CGFloat = 3.0
    
    var titleNormalFont : UIFont = UIFont.systemFont(ofSize: 12)
    
    var titleSelectedFont : UIFont = UIFont.systemFont(ofSize: 14)
    
    var titleNormalColor = UIColor.gray
    
    var titleSelectedColor = UIColor.white
    
    var titleNormalBackgroundColor : UIColor = UIColor.white
    
    var titleSelectedBackgroundColor : UIColor = UIColor(red: 92.0/255.0, green: 119/255.0, blue: 223/255.0, alpha: 1)
    
    var titleNormalBackgroundImage : UIImage?
    
    var titleSelectedBackgroundImage : UIImage?
    
    var titles: [String]? {
        didSet {
            if let titles = titles {
                for idx in 0..<titles.count {
                    let btn = UIButton()
                    btn.setTitle(titles[idx], for: UIControlState())
                    
                    btn.setTitleColor(titleNormalColor, for: UIControlState())
                    btn.setTitleColor(titleSelectedColor, for: .disabled)
                    
                    btn.setBackgroundImage(titleNormalBackgroundImage, for: UIControlState())
                    btn.setBackgroundImage(titleSelectedBackgroundImage, for: .disabled)
                    
                    btn.titleLabel?.font = titleNormalFont
                    
                    btn.backgroundColor = titleNormalBackgroundColor
                    
                    titleBtns.append(btn)
                    addSubview(btn)
                    
                    btn.addTarget(self, action: #selector(clickOnItem(_:)), for: .touchUpInside)
                }
            }
        }
    }
    
    var selectedIdx = -1 {
        
        willSet {
            if selectedIdx == newValue {
                return
            }
            if selectedIdx >= 0 && newValue >= 0 {
                let btn = titleBtns[selectedIdx]
                btn.isEnabled = true
                
                btn.backgroundColor = self.titleNormalBackgroundColor
                btn.titleLabel?.font = self.titleNormalFont
            }
        }
        
        didSet {
            if selectedIdx == oldValue {
                return
            }
            if selectedIdx < 0 {
                return
            }
            let btn = titleBtns[selectedIdx]
            btn.isEnabled = false
            
            btn.backgroundColor = self.titleSelectedBackgroundColor
            btn.titleLabel?.font = self.titleSelectedFont
            
            if btn.frame.maxX > contentOffset.x + bounds.size.width {
                setContentOffset(CGPoint(x: btn.frame.maxX - bounds.size.width, y: 0), animated: true)
            } else if btn.frame.minX < contentOffset.x {
                setContentOffset(CGPoint(x: btn.frame.minX, y: 0), animated: true)
            }
            
            if let hanlder = selectedIdxHanlder {
                hanlder(oldValue, selectedIdx)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        backgroundColor = UIColor.gray
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 0.3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clickOnItem(_ btn: UIButton) {
        let idx = titleBtns.index(of: btn)
        
        if selectedIdx != -1 {
            selectedIdx = idx!
        }
    }
    
    var preSize: CGSize = CGSize.zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if preSize.equalTo(bounds.size) {
            return
        }
        preSize = bounds.size
        
        if titleBtnW <= 0.5 {
            
            let w = titleBtns.reduce(0, { (result, btn) -> CGFloat in
                btn.sizeToFit()
                btn.bounds.size.width += 36
                return result + btn.bounds.size.width
            })
            if w < bounds.size.width {
                titleBtnW = (bounds.size.width - (titleBtnSpace * CGFloat(titleBtns.count - 1))) / CGFloat(titleBtns.count)
            }
            
        }
        
        lineButNotEqualLayout(titleBtns, inset: UIEdgeInsets.zero, space: titleBtnSpace) { [weak self]  (idx, view) in
            if self!.titleBtnW > 0.5 {
                view.frame.size.width = self!.titleBtnW
            }
            view.frame.size.height = self!.bounds.size.height
        }
        
        let width = titleBtns.reduce(0) { (result, btn) -> CGFloat in
            return btn.bounds.size.width + result
        } + CGFloat(titleBtns.count - 1) * titleBtnSpace
        contentSize = CGSize(width: width, height: bounds.size.height)
    }
    
    func update(_ percent: CGFloat) {
        
    }
}

func lineButNotEqualLayout(_ views: [UIView], inset: UIEdgeInsets, space: CGFloat, setting:((_ idx: Int, _ view: UIView)->())?) {
    
    var preView: UIView?
    
    for (i, view) in views.enumerated() {
        view.frame.origin.y = inset.top
        setting?(i, view)
        if i == 0 {
            view.frame.origin.x = inset.left
        } else {
            view.frame.origin.x = (preView != nil ? preView!.frame.maxX : 0) + space
        }
        
        preView = view
    }
}









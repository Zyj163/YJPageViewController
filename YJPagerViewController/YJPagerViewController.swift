//
//  YJPagerViewController.swift
//  YJPagerViewController
//
//  Created by ddn on 16/8/24.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

@objc protocol YJPageViewControllerDelegate: NSObjectProtocol {
    optional func pageViewController(didSelectedIdx index: Int)
}

@objc protocol YJPageViewControllerDataSource: NSObjectProtocol {
    func pageViewController(subVcForType: UIViewController.Type, title: String?, idx: Int) -> UIViewController
    func pageViewControllerObserveredScrollView(subVc: UIViewController, title: String?, idx: Int) -> UIScrollView?
}

struct YJSubVC {
    let vcType: UIViewController.Type
    let title: String?
    
    static func generateSome(vcs: [UIViewController.Type], titles: [String]? = nil) -> [YJSubVC]? {
        
        if vcs.isEmpty {
            return nil
        }
        
        var count = 0
        var instances = [YJSubVC]()
        
        if let titles = titles where !titles.isEmpty {
            count = min(vcs.count, titles.count)
        } else {
            count = vcs.count
        }
        
        for i in 0..<count {
            let type = vcs[i]
            let title: String? = titles == nil ? nil : titles![i]
            
            instances += [YJSubVC(vcType: type, title: title)]
        }
        
        return instances.isEmpty ? nil : instances
    }
}

class YJPagerViewController: UIViewController {

    private var vcClasses: [YJSubVC]?
    
    private var subVcsCount: Int {
        return vcClasses == nil ? 0 : vcClasses!.count
    }
    
    private var memCache: YJCacheManager?
    
    private var hasTitles: Bool = true
    
    private var _currentVc : UIViewController?
    /// 当前展示的子控制器
    var currentVc: UIViewController? {
        return _currentVc
    }
    
    private var _currentIdx: Int = 0 {
        didSet {
            if hasTitles {
                titlesView.selectedIdx = _currentIdx
            }
        }
    }
    /// 当前展示的子控制器的坐标
    var currentIdx: Int {
        return _currentIdx
    }
    
    private lazy var pageView : YJContainerView = { [weak self] in
        let pageView = YJContainerView()
        self!.view.addSubview(pageView)
        pageView.delegate = self
        return pageView
        }()
    
    private lazy var displayVcs = [Int : UIViewController]()
    
    private lazy var childViewFrames = [CGRect]()
    
    private lazy var posRecords = [Int : CGPoint]()
    
    private lazy var titlesView : YJTitlesView = { [weak self] in
        let titlesView = YJTitlesView()
        titlesView.selectedIdxHanlder = {
            self!.changeView($0, idx: $1)
            
            if let delegate = self!.delegate {
                if (delegate.respondsToSelector(#selector(YJPageViewControllerDelegate.pageViewController(didSelectedIdx:)))) {
                    delegate.pageViewController!(didSelectedIdx: $1)
                }
            }
        }
        self!.topViewContainer.addSubview(titlesView)
        return titlesView
        }()
    
    private lazy var topViewContainer : UIView = { [weak self] in
        let topViewContainer = UIView()
        self!.view.addSubview(topViewContainer)
        return topViewContainer
        }()
    
    /// 顶部分离视图
    var topView : UIView? {
        didSet {
            topView?.removeFromSuperview()
            if let topView = topView {
                topViewContainer.addSubview(topView)
            }
        }
    }
    
    /// 是否需要滚动顶部分离视图
    var needScrollTopViewIfHas = true
    private var _needScrollTopViewIfHas: Bool {
        return needScrollTopViewIfHas && hasTopView
    }
    
    private var hasTopView: Bool {
        return topView != nil
    }
    
    private lazy var observeredScrollerViews = [Int : UIScrollView]()
    
    /// 代理
    weak var delegate: YJPageViewControllerDelegate?
    weak var dataSource: YJPageViewControllerDataSource?
    
    
    /// 是否记忆位置，即当再次回到某个子控制器时，要不要恢复到之前的位置
    var remeberLocation = true
    
    /// 标题栏的高度
    var titleViewH: CGFloat = 30
    
    private lazy var topDis: [Int : CGFloat] = [Int : CGFloat]()
    
    override func loadView() {
        view = UIScrollView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var topH: CGFloat = 0
        
        if hasTitles {
            let y = hasTopView ? topView!.bounds.size.height : 0
            titlesView.frame = CGRect(x: 0, y: y, width: view.bounds.size.width, height: titleViewH)
            titlesView.scrollEnabled = titlesView.contentSize.width > titlesView.bounds.size.width
            topH += titlesView.bounds.size.height
        }
        
        if hasTopView {
            topH += topView!.bounds.size.height
            topView?.frame.size.width = view.bounds.size.width
        }
        
        if hasTitles || hasTopView {
            topViewContainer.frame = CGRect(x: 0, y: topViewContainer.frame.origin.y, width: view.bounds.size.width, height: topH)
            view.bringSubviewToFront(topViewContainer)
        }
        
        let titlesViewH = (hasTitles ? titlesView.bounds.size.height : 0)
        var height: CGFloat = view.bounds.size.height - titlesViewH
        if let scrollView = view as? UIScrollView {
            height = view.bounds.size.height - titlesViewH - scrollView.contentInset.top - scrollView.contentInset.bottom
        }
        
        pageView.frame = CGRect(x: 0, y: titlesViewH, width: view.bounds.size.width, height: height)
        pageView.contentSize = CGSize(width: pageView.bounds.size.width * CGFloat(subVcsCount), height: height)
        
        observeredScrollerViews.forEach { (idx, scrollView) in
            scrollView.contentInset.top = topH - titlesViewH
            scrollView.scrollIndicatorInsets.top = topH - titlesViewH
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for idx in 0..<vcClasses!.count {
            let fIdx = CGFloat(idx)
            let frame = CGRectMake(fIdx * pageView.bounds.size.width, 0, pageView.bounds.size.width, pageView.bounds.size.height)
            childViewFrames.append(frame)
        }
    }
    
    /**
     初始化设置，必须实现
     
     - parameter subVCs: 子控制器类型数组
     - parameter titles: 子控制器标题数组
     */
    func setup(subVCs: [UIViewController.Type], titles: [String]? = nil) {
        vcClasses = generateElements(subVCs, titles: titles)
        
        guard let _ = vcClasses else {
            return
        }
        
        memCache = YJCacheManager()
        
        hasTitles = titles == nil ? false : !titles!.isEmpty
        
        if hasTitles {
            titlesView.titles = titles
            titlesView.selectedIdx = 0
        }
        
        addVcToWindow(atIdx: 0)
    }
    
    private func generateElements(subVCs: [UIViewController.Type], titles: [String]? = nil) -> [YJSubVC]? {
        return YJSubVC.generateSome(subVCs, titles: titles)
    }
    
    private func addVcToWindow(atIdx idx: Int) {
        
        let vc = getSubVc(atIdx: idx)
        
        if let dataSource = dataSource {
            let subvc = vcClasses![idx]
            if let scrollView = dataSource.pageViewControllerObserveredScrollView(vc, title: subvc.title, idx: idx) {
                if (observeredScrollerViews[idx] != nil) {
                    return
                }
                
                observeredScrollerViews[idx] = scrollView
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.New, .Old], context: nil)
                
                let topH = hasTopView ? topView!.frame.size.height : 0
                scrollView.contentInset = UIEdgeInsets(top: topH, left: 0, bottom: 0, right: 0)
                scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topH, left: 0, bottom: 0, right: 0)
                
                if !backToPositionIfNeed(vc: vc, idx: idx) {
                    
                    var preDis = topDis[currentIdx]
                    
                    if preDis == nil {
                        preDis = (topDis.values.maxElement() ?? 0)
                    }
                    
                    scrollView.setContentOffset(CGPoint(x: 0, y: -topH - preDis!), animated: false)
                }
                scrollView.showsVerticalScrollIndicator = false
            }
        }
        
        addChildViewController(vc)
        vc.didMoveToParentViewController(self)
        pageView[idx] = vc.view
        displayVcs[idx] = vc
        
        _currentVc = vc
    }
    
    private func getSubVc(atIdx idx: Int) -> UIViewController {
        if idx > subVcsCount || idx < 0 {
            fatalError("数组越界啦！！！")
        }
        
        var vc: UIViewController? = memCache![idx] as? UIViewController
        
        if vc == nil {
            let subvc = vcClasses![idx]
            if let dataSource = dataSource {
                vc = dataSource.pageViewController(subvc.vcType, title: subvc.title, idx: idx)
            }
        }
        
        return vc!
    }
    
    private func changeView(preIdx: Int, idx: Int) {
        pageView.changeTo(idx, animation: false)
        
        let gap = labs(idx - preIdx)
        
        if gap > 1 {
            layoutChildViewControllers()
            _currentVc = displayVcs[idx]
            _currentIdx = idx
        }
    }
    
    private func layoutChildViewControllers() {
        let currentPage = Int(round(Double(pageView.contentOffset.x/pageView.bounds.size.width)))
        let start = currentPage == 0 ? currentPage : currentPage - 1
        let end = (currentPage == subVcsCount - 1) ? currentPage : currentPage + 1
        for idx in start...end {
            let frame = childViewFrames[idx]
            
            if isVisable(frame) {
                if let _ = displayVcs[idx] {
                    
                } else {
                    addVcToWindow(atIdx: idx)
                }
            }else {
                if let vc = displayVcs[idx] {
                    cacheVc(vc, idx: idx)
                }
            }
        }
    }
    
    private func isVisable(frame: CGRect) -> Bool {
        return frame.intersects(CGRect(origin: pageView.contentOffset, size: pageView.bounds.size))
    }
    
    private func cacheVc(vc: UIViewController, idx: Int) {
        
        remeberPositionIfNeed(vc: vc, idx: idx)
        
        vc.view.removeFromSuperview()
        pageView[idx] = nil
        vc.willMoveToParentViewController(nil)
        vc.removeFromParentViewController()
        vc.didMoveToParentViewController(nil)
        displayVcs.removeValueForKey(idx)
        
        memCache![idx] = vc
        
        if let scrollView = observeredScrollerViews[idx] {
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
            observeredScrollerViews.removeValueForKey(idx)
        }
    }
    
    private func backToPositionIfNeed(vc vc: UIViewController, idx: Int) ->Bool {
        if !remeberLocation {
            return false
        }
        if memCache![idx] == nil {
            return false
        }
        
        if let scrollView = isScrollViewController(vc) {
            if var location = posRecords[idx] {
                
                if _needScrollTopViewIfHas {
                    let preDis = topDis[currentIdx]
                    let nowDis = topDis[idx]
                    
                    if preDis == nil && nowDis == nil {
                        location.y = -topView!.frame.size.height - (topDis.values.maxElement() ?? 0)
                    }
                    
                    else if (preDis ?? 0) < (nowDis ?? 0) {
                        location.y = -topView!.frame.size.height - (preDis ?? 0)
                    }
                }
                
                scrollView.setContentOffset(location, animated: false)
                return true
            }
        }
        return false
    }
    
    private func remeberPositionIfNeed(vc vc:UIViewController, idx: Int) {
        if !remeberLocation {
            return
        }
        if let scrollView = isScrollViewController(vc) {
            let pos = scrollView.contentOffset
            posRecords[idx] = pos
        }
    }
    
    private func isScrollViewController(vc: UIViewController) -> UIScrollView? {
        let childView = vc.view
        
        if childView is UIScrollView {
            return childView as? UIScrollView
            
        }else {
            for subview in childView.subviews {
                if subview is UIScrollView {
                    return subview as? UIScrollView
                }
            }
        }
        return nil
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if !_needScrollTopViewIfHas {
            return
        }
        
        if let oldValue :CGPoint = change!["old"]?.CGPointValue() where oldValue.y != 0 {
            
            if let newValue: CGPoint = change!["new"]?.CGPointValue() where oldValue.y != newValue.y {
                
                let absValue = newValue.y + topView!.frame.size.height
                
                let dis = topViewContainer.frame.origin.y + absValue
                
                if (absValue >= 0) && (absValue <= topView!.frame.size.height) {
                    
                    if abs(dis) > 15 {
                        UIView.animateWithDuration(Double(dis / 1000), animations: {
                            self.topViewContainer.frame.origin.y = -absValue
                        })
                    }else {
                        topViewContainer.frame.origin.y = -absValue
                    }
                    
                } else if absValue < 0 {
                    UIView.animateWithDuration(0.2, animations: {
                        self.topViewContainer.frame.origin.y = 0
                    })
                    
                } else if absValue > topView!.frame.size.height {
                    UIView.animateWithDuration(0.2, animations: {
                        self.topViewContainer.frame.origin.y = -self.topView!.frame.size.height
                    })
                    
                }
                
                topDis[currentIdx] = topViewContainer.frame.origin.y
            }
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        memCache?.didReceiveMemoryWarning()
        posRecords.removeAll(keepCapacity: true)
    }
    
    deinit {
        memCache!.clear()
        observeredScrollerViews.forEach { (_, scrollView) in
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
        observeredScrollerViews.removeAll(keepCapacity: false)
    }
}


extension YJPagerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView === pageView {
            layoutChildViewControllers()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView === pageView {
            if pageView.contentOffset.x >= 0 {
                let idx = Int(round(Double(pageView.contentOffset.x/pageView.bounds.size.width)))
                _currentIdx = idx
                _currentVc = displayVcs[currentIdx]
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if scrollView === pageView {
            _currentVc = displayVcs[currentIdx]
        }
    }
}































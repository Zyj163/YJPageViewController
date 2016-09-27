//
//  YJPagerViewController.swift
//  YJPagerViewController
//
//  Created by ddn on 16/8/24.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

@objc protocol YJPageViewControllerDelegate: NSObjectProtocol {
    @objc optional func pageViewController(didSelectedIdx index: Int)
    @objc optional func pageViewController(didScroll contentOffset: CGPoint)
}

@objc protocol YJPageViewControllerDataSource: NSObjectProtocol {
    func pageViewController(_ subVcForType: UIViewController.Type, title: String?, idx: Int) -> UIViewController
    func pageViewControllerObserveredScrollView(_ subVc: UIViewController, title: String?, idx: Int) -> UIScrollView?
}

private struct YJSubVC {
    let vcType: UIViewController.Type
    let title: String?
    
    static func generateSome(_ vcs: [UIViewController.Type], titles: [String]? = nil) -> [YJSubVC]? {
        
        if vcs.isEmpty {
            return nil
        }
        
        var count = 0
        var instances = [YJSubVC]()
        
        if let titles = titles , !titles.isEmpty {
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
    
    //MARK: 公共属性及方法
    
    /// 当前展示的子控制器
    var currentVc: UIViewController? {
        return _currentVc
    }
    
    /// 当前展示的子控制器的坐标
    var currentIdx: Int {
        return _currentIdx
    }
    
    /// 标题视图
    var titlesView : YJTitlesView? {
        didSet {
            titlesView?.removeFromSuperview()
            if let titlesView = titlesView {
                topViewContainer.addSubview(titlesView)
            }
        }
    }
    
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
    
    /// 代理
    weak var delegate: YJPageViewControllerDelegate?
    /// 数据源
    weak var dataSource: YJPageViewControllerDataSource?
    
    /// 是否记忆位置，即当再次回到某个子控制器时，要不要恢复到之前的位置
    var remeberLocation = true
    
    /// 标题栏的高度
    var titleViewH: CGFloat = 30
    
    /**
     根视图为UIScrollView
     */
    override func loadView() {
        view = UIScrollView()
    }
    
    /**
     初始化设置，必须调用
     
     - parameter subVCs: 子控制器类型数组
     - parameter titles: 用来标记子控制器的名字
     */
    func setup(_ subVCs: [UIViewController.Type], titles: [String]? = nil) {
        vcClasses = generateElements(subVCs, titles: titles)
        
        guard let _ = vcClasses else {
            return
        }
        
        memCache = YJCacheManager()
        
        addVcToWindow(atIdx: 0)
    }
    
    /**
     切换子控制器
     
     - parameter preIdx:    上一个展示的控制器
     - parameter idx:       要展示的控制器
     - parameter animation: 切换是是否带有动画效果（紧邻的两个之间可用）
     */
    func changeView(_ preIdx: Int, idx: Int, animation: Bool) {
        pageView.changeTo(idx, animation: animation)
        
        let gap = labs(idx - preIdx)
        
        if gap > 1 {
            layoutChildViewControllers()
            _currentVc = displayVcs[idx]
            _currentIdx = idx
        }
    }
    
    /**
     这里是监听屏幕滚动的核心代码，如果子类重写，需要调用super方法
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "contentOffset" {
            if !_needScrollTopViewIfHas {
                return
            }
            
            if let oldValue: CGPoint = (change![.oldKey] as? NSValue)?.cgPointValue , oldValue.y != 0 {
                
                if let newValue: CGPoint = (change![.newKey] as? NSValue)?.cgPointValue , oldValue.y != newValue.y {
                    
                    let absValue = newValue.y + topView!.frame.size.height
                    
                    let dis = topViewContainer.frame.origin.y + absValue
                    
                    if -newValue.y >= topViewContainer.frame.maxY - (hasTitles ? titleViewH : 0) {
                        posRecords.removeValue(forKey: currentIdx)
                    }
                    if let _ = posRecords[currentIdx] {
                        return
                    }
                    
                    if (absValue >= 0) && (absValue <= topView!.frame.size.height) {
                        
                        if abs(dis) > 15 {
                            UIView.animate(withDuration: Double(dis / 1000), animations: {
                                self.topViewContainer.frame.origin.y = -absValue
                            })
                        }else {
                            topViewContainer.frame.origin.y = -absValue
                        }
                        
                    } else if absValue < 0 {
                        UIView.animate(withDuration: 0.2, animations: {
                            self.topViewContainer.frame.origin.y = 0
                        })
                        
                    } else if absValue > topView!.frame.size.height {
                        UIView.animate(withDuration: 0.2, animations: {
                            self.topViewContainer.frame.origin.y = -self.topView!.frame.size.height
                        })
                        
                    }
                    
                    topDis[currentIdx] = topViewContainer.frame.origin.y
                }
            }
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var topH: CGFloat = 0
        
        if hasTitles {
            let y = hasTopView ? topView!.bounds.size.height : 0
            titlesView!.frame = CGRect(x: 0, y: y, width: view.bounds.size.width, height: titleViewH)
            titlesView!.isScrollEnabled = titlesView!.contentSize.width > titlesView!.bounds.size.width
            topH += titlesView!.bounds.size.height
        }
        
        if hasTopView {
            topH += topView!.bounds.size.height
            topView?.frame.size.width = view.bounds.size.width
        }
        
        if hasTitles || hasTopView {
            topViewContainer.frame = CGRect(x: 0, y: topViewContainer.frame.origin.y, width: view.bounds.size.width, height: topH)
            view.bringSubview(toFront: topViewContainer)
        }
        
        let titlesViewH = (hasTitles ? titlesView!.bounds.size.height : 0)
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
            let frame = CGRect(x: fIdx * pageView.bounds.size.width, y: 0, width: pageView.bounds.size.width, height: pageView.bounds.size.height)
            childViewFrames.append(frame)
        }
    }
    
    /**
     内存管理
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        memCache?.didReceiveMemoryWarning()
        posRecords.removeAll(keepingCapacity: true)
    }
    
    deinit {
        memCache!.clear()
        observeredScrollerViews.forEach { (_, scrollView) in
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
        observeredScrollerViews.removeAll(keepingCapacity: false)
    }
    
    //MARK: 私有属性及方法
    
    fileprivate lazy var topDis: [Int : CGFloat] = [Int : CGFloat]()
    
    fileprivate var vcClasses: [YJSubVC]?
    
    fileprivate var subVcsCount: Int {
        return vcClasses == nil ? 0 : vcClasses!.count
    }
    
    fileprivate var memCache: YJCacheManager?
    
    fileprivate var _currentVc : UIViewController?
    
    fileprivate var _currentIdx: Int = 0 {
        didSet {
            if _currentIdx == oldValue {
                return
            }
            self.changeView(oldValue, idx: _currentIdx, animation: false)
            
            if let delegate = self.delegate {
                if (delegate.responds(to: #selector(YJPageViewControllerDelegate.pageViewController(didSelectedIdx:)))) {
                    delegate.pageViewController!(didSelectedIdx: _currentIdx)
                }
            }
        }
    }
    
    fileprivate lazy var pageView : YJContainerView = { [weak self] in
        let pageView = YJContainerView()
        self!.view.addSubview(pageView)
        pageView.delegate = self
        return pageView
        }()
    
    fileprivate lazy var displayVcs = [Int : UIViewController]()
    
    fileprivate lazy var childViewFrames = [CGRect]()
    
    fileprivate lazy var posRecords = [Int : CGPoint]()
    
    fileprivate var hasTitles: Bool {
        return titlesView != nil
    }
    
    fileprivate lazy var topViewContainer : UIView = { [weak self] in
        let topViewContainer = UIView()
        self!.view.addSubview(topViewContainer)
        return topViewContainer
        }()
    
    fileprivate var _needScrollTopViewIfHas: Bool {
        return needScrollTopViewIfHas && hasTopView
    }
    
    fileprivate var hasTopView: Bool {
        return topView != nil
    }
    
    fileprivate lazy var observeredScrollerViews = [Int : UIScrollView]()
    
    fileprivate func generateElements(_ subVCs: [UIViewController.Type], titles: [String]? = nil) -> [YJSubVC]? {
        return YJSubVC.generateSome(subVCs, titles: titles)
    }
    
    fileprivate func addObserverFor(vc:UIViewController, atIdx idx: Int) {
        if let dataSource = dataSource {
            let subvc = vcClasses![idx]
            if let scrollView = dataSource.pageViewControllerObserveredScrollView(vc, title: subvc.title, idx: idx) {
                
                if (observeredScrollerViews[idx] != nil) {
                    return
                }
                
                let topH = hasTopView ? topView!.frame.size.height : 0
                scrollView.contentInset = UIEdgeInsets(top: topH, left: 0, bottom: 0, right: 0)
                scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topH, left: 0, bottom: 0, right: 0)
                
                if !backToPositionIfNeed(vc: vc, idx: idx) {
                    
                    var preDis = topDis[currentIdx]
                    
                    if preDis == nil {
                        preDis = (topDis.values.max() ?? 0)
                    }
                    
                    scrollView.setContentOffset(CGPoint(x: 0, y: -topH - preDis!), animated: false)
                }
                
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.new, .old], context: nil)
                observeredScrollerViews[idx] = scrollView
            }
        }
    }
    
    fileprivate func addVcToWindow(atIdx idx: Int) {
        
        let vc = getSubVc(atIdx: idx)
        
        vc.willMove(toParentViewController: self)
        addChildViewController(vc)
        vc.didMove(toParentViewController: self)
        
        pageView[idx] = vc.view
        displayVcs[idx] = vc
        
        _currentVc = vc
        
        addObserverFor(vc: vc, atIdx: idx)
    }
    
    fileprivate func getSubVc(atIdx idx: Int) -> UIViewController {
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
    
    fileprivate func layoutChildViewControllers() {
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
    
    fileprivate func isVisable(_ frame: CGRect) -> Bool {
        return frame.intersects(CGRect(origin: pageView.contentOffset, size: pageView.bounds.size))
    }
    
    fileprivate func cacheVc(_ vc: UIViewController, idx: Int) {
        
        remeberPositionIfNeed(vc: vc, idx: idx)
        
        vc.view.removeFromSuperview()
        pageView[idx] = nil
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
        vc.didMove(toParentViewController: nil)
        displayVcs.removeValue(forKey: idx)
        
        memCache![idx] = vc
        
        if let scrollView = observeredScrollerViews[idx] {
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
            observeredScrollerViews.removeValue(forKey: idx)
        }
    }
    
    fileprivate func backToPositionIfNeed(vc: UIViewController, idx: Int) ->Bool {
        if !remeberLocation {
            return false
        }
        if memCache![idx] == nil {
            return false
        }
        
        if let scrollView = scrollViewOf(subVc: vc, idx: idx) {
            
            if var location = posRecords[idx] {
                
                if _needScrollTopViewIfHas {
                    let preDis = topDis[currentIdx]
                    let nowDis = topDis[idx]
                    
                    if preDis == nil && nowDis == nil {
                        location.y = -topView!.frame.size.height - (topDis.values.max() ?? 0)
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
    
    fileprivate func remeberPositionIfNeed(vc:UIViewController, idx: Int) {
        if !remeberLocation {
            return
        }
        if let scrollView = scrollViewOf(subVc: vc, idx: idx) {
            
            if (-scrollView.contentOffset.y < topViewContainer.frame.maxY - (hasTitles ? titleViewH : 0)) {
                let pos = scrollView.contentOffset
                posRecords[idx] = pos
            }
        }
    }
    
    fileprivate func scrollViewOf(subVc vc: UIViewController, idx: Int) -> UIScrollView? {
        if let dataSource = self.dataSource , dataSource.responds(to: #selector(YJPageViewControllerDataSource.pageViewControllerObserveredScrollView(_:title:idx:))) {
            return dataSource.pageViewControllerObserveredScrollView(vc, title: vcClasses![idx].title, idx: idx)
        }
        return nil
    }
    
    fileprivate func topViewFrame() -> CGRect {
        if !hasTopView {
            return CGRect.zero
        }
        let frame = topView!.convert(topView!.bounds, to: view)
        return frame
    }
}


extension YJPagerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === pageView {
            layoutChildViewControllers()
            if let delegate = self.delegate , delegate.responds(to: #selector(YJPageViewControllerDelegate.pageViewController(didScroll:))) {
                delegate.pageViewController!(didScroll: scrollView.contentOffset)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === pageView {
            if pageView.contentOffset.x >= 0 {
                let idx = Int(round(Double(pageView.contentOffset.x/pageView.bounds.size.width)))
                _currentIdx = idx
                _currentVc = displayVcs[currentIdx]
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView === pageView {
            _currentVc = displayVcs[currentIdx]
        }
    }
}
































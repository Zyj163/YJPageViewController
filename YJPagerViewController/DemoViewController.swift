//
//  DemoViewController.swift
//  YJPagerViewController
//
//  Created by ddn on 16/8/25.
//  Copyright © 2016年 张永俊. All rights reserved.
//

/// 随机数
var random: CGFloat {
    return CGFloat(arc4random_uniform(256))
}

/**随机色*/
func randomColor() -> UIColor {
    return UIColor(red: random/255.0, green: random/255.0, blue: random/255.0, alpha: 1)
}

import UIKit

/*标记有描述的为外部可用方法、属性*/
class DemoViewController: YJPagerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //dataSource必须提供
        dataSource = self
        delegate = self
        
        setup([TempTableViewController.self, TempCollectionViewController2.self, TempScrollViewController.self, TempTableViewController2.self, TempCollectionViewController2.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self], titles: ["321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321"])
        //topView可以不添加如果不需要
        topView = UIView()
        topView?.backgroundColor = UIColor(red: 0.3, green: 0.2, blue: 0.5, alpha: 1)
        topView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 250)
        //如果有topView但不需要滚动，可修改为false
//        needScrollTopViewIfHas = false
        
        titlesView = YJTitlesView()
        
        titleViewH = 40
        
        titlesView?.titles = ["tableView1", "collectionView", "scrollView", "tableView2", "collectionView2", "noScroll", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321"]
        titlesView!.selectedIdx = 0
        
        titlesView!.selectedIdxHanlder = {
            self.changeView($0, idx: $1, animation: true)
        }
    }

}

extension DemoViewController: YJPageViewControllerDataSource {
    //提供每个子控制器的初始化方法
    func pageViewController(_ subVcForType: UIViewController.Type, title: String?, idx: Int) -> UIViewController {
        if subVcForType is TempTableViewController.Type {
            return TempTableViewController()
        }else if subVcForType is TempScrollViewController.Type {
            return TempScrollViewController()
        }else if subVcForType is TempTableViewController2.Type {
            return TempTableViewController2()
        }else if subVcForType is TempCollectionViewController2.Type {
            return TempCollectionViewController2()
        }
        else {
            return UIViewController()
        }
    }
    //提供子控制器中需要监听的UIScrollView
    func pageViewControllerObserveredScrollView(_ subVc: UIViewController, title: String?, idx: Int) -> UIScrollView? {
        if subVc.self is TempTableViewController {
            let subVc = subVc as! TempTableViewController
            return subVc.tableView
        }else if subVc.self is TempScrollViewController {
            let subVc = subVc as! TempScrollViewController
            return subVc.scrollView
        }else if subVc.self is TempTableViewController2 {
            let subVc = subVc as! TempTableViewController2
            return subVc.tableView
        }else if subVc.self is TempCollectionViewController2 {
            let subVc = subVc as! TempCollectionViewController2
            return subVc.collectionView
        }
        else {
            return nil
        }
    }
}

extension DemoViewController: YJPageViewControllerDelegate {
    //切换子控制器后的回调
    func pageViewController(didSelectedIdx index: Int) {
        self.titlesView!.selectedIdx = index
    }
    
    //当前pageView的contentOffset，如果想给titlesView加动画，可以在这里加，或者在这里更早的选择selectedIdx
    func pageViewController(didScroll contentOffset: CGPoint) {
        
    }
}


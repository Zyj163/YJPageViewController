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
        
        setup([TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self, TempTableViewController.self], titles: ["321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321", "123", "321"])
        //topView可以不添加如果不需要
        topView = UIView()
        topView?.backgroundColor = UIColor(red: 0.3, green: 0.2, blue: 0.5, alpha: 1)
        topView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 250)
        //如果有topView但不需要滚动，可修改为false
//        needScrollTopViewIfHas = false
        
        titleViewH = 40
    }

}

extension DemoViewController: YJPageViewControllerDataSource {
    //提供每个子控制器的初始化方法
    func pageViewController(subVcForType: UIViewController.Type, title: String?, idx: Int) -> UIViewController {
        return TempTableViewController()
    }
    //提供子控制器中需要监听的UIScrollView
    func pageViewControllerObserveredScrollView(subVc: UIViewController, title: String?, idx: Int) -> UIScrollView? {
        let subVc = subVc as! TempTableViewController
        return subVc.tableView
    }
}

extension DemoViewController: YJPageViewControllerDelegate {
    //切换子控制器后的回调
    func pageViewController(didSelectedIdx index: Int) {
        print(index)
    }
}


//
//  TempScrollViewController.swift
//  YJPagerViewController
//
//  Created by ddn on 16/9/5.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

class TempScrollViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: 500, height: 1000)
    }

}

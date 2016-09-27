//
//  TempTableViewController2.swift
//  YJPagerViewController
//
//  Created by ddn on 16/9/6.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

class TempTableViewController2: UIViewController {

    var tableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView()
        tableView!.dataSource = self
        tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView!)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        tableView?.frame = view.bounds
    }

}


extension TempTableViewController2: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = randomColor()
        cell.textLabel?.text = "commonViewControllerWhichHasTableView"
        
        return cell
    }
}

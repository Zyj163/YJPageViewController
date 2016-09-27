//
//  TempCollectionViewController2.swift
//  YJPagerViewController
//
//  Created by ddn on 16/9/6.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

class TempCollectionViewController2: UIViewController {

    var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.white
        view.addSubview(collectionView!)
    }

}

extension TempCollectionViewController2: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = randomColor()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}

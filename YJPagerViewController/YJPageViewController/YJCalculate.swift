//
//  YJCalculate.swift
//  YJPagerViewController
//
//  Created by zhangyongjun on 16/9/3.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import UIKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

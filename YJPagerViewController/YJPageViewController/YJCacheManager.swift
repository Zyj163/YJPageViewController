//
//  YJCacheManager.swift
//  YJPagerViewController
//
//  Created by ddn on 16/8/24.
//  Copyright © 2016年 张永俊. All rights reserved.
//

import Foundation

enum YJCachePolicy {
    case none
    case lowMemory
    case balanced
    case high
    
    var limitCount: Int {
        switch self {
        case .none:
            return 0
        case .lowMemory:
            return 1
        case .balanced:
            return 3
        case .high:
            return 5
        }
    }
}

class YJCacheManager: NSObject {
    var cachePolicy: YJCachePolicy = YJCachePolicy.balanced {
        didSet {
            memCache.countLimit = self.cachePolicy.limitCount
        }
    }
    
    var memoryWarningCount = 0
    
    fileprivate lazy var memCache : NSCache<NSNumber, AnyObject> = { [weak self] in
        let memCache = NSCache<NSNumber, AnyObject>()
        memCache.countLimit = self!.cachePolicy.limitCount
        return memCache
        }()
    
    subscript(idx: Int) -> AnyObject? {
        get {
            return memCache.object(forKey: NSNumber(value: idx))
        }
        
        set {
            if let newValue = newValue {
                memCache.setObject(newValue, forKey: NSNumber(value: idx))
            }
        }
    }
    
    func didReceiveMemoryWarning() {
        
        memoryWarningCount += 1
        
        cachePolicy = YJCachePolicy.lowMemory
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(growCachePolicyToHigh), object: nil)
        
        clear()
        
        //如果收到内存警告次数小于 3，一段时间后切换到模式 Balanced
        if memoryWarningCount < 3 {
            perform(#selector(growCachePolicyAfterMemoryWarning), with: nil, afterDelay: 3.0, inModes: [RunLoopMode.commonModes])
        }
    }
    
    func growCachePolicyAfterMemoryWarning() {
        cachePolicy = YJCachePolicy.balanced
        perform(#selector(growCachePolicyToHigh), with: nil, afterDelay: 2.0, inModes: [RunLoopMode.commonModes])
    }
    
    func growCachePolicyToHigh() {
        cachePolicy = YJCachePolicy.high
    }
    
    func clear() {
        memCache.removeAllObjects()
    }
}











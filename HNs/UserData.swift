//
//  UserData.swift
//  HNs
//
//  Created by 姚舜禹 on 2022/1/3.
//

import Foundation
import UIKit

class UserData{
    // 三个不同的list
    var toplist:Storylist = loadListData(type: .top, withCancel: nil)
    var newlist:Storylist = loadListData(type: .new, withCancel: nil)
    var showlist:Storylist = loadListData(type: .show, withCancel: nil)
    
    
    // 读取的数量
    var topLimitation: UInt = 30
    var newLimitation: UInt = 30
    var showLimitation: UInt = 30
    
    var limitationinterval:UInt = 10
    
    
    // refresh
    var refreshControl:UIRefreshControl!
    // load more

    var loadingStory:Bool! // load more flag
    var loadmoreLimitaion:UInt!
    var isLoadingMore:Bool! // 是否正在loadmore
    
}

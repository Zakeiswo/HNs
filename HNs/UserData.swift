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
    var toplist:Storylist
    var newlist:Storylist
    var showlist:Storylist
    
    var defaulttype:StoryType
    // 记录不同的移动位置
    
    var toplocation:CGPoint
    var newlocation:CGPoint
    var showlocation:CGPoint
    
    // 读取的数量
    var topLimitation: UInt = 30
    var newLimitation: UInt = 30
    var showLimitation: UInt = 30
    var limitationinterval:UInt = 10
    
    
    // load more

    var loadmoreLimitaion:UInt!
    // 防止重复加载
    var isLoadingMore:Bool! // 是否正在loadmore
    // 防止重复刷新
    var isretrievingStory:Bool! // 是否正在refresh
//    // 方式未加载完数据就使用
//    var allListLoaded:Bool!
    
    //dic
//    let listTypeMap:[StoryType:Storylist]
    
    required init(){
        defaulttype = .top
        isretrievingStory = false
        loadmoreLimitaion = 0 // 最初这个加载更多的限制值为0
        
    
        toplist = Storylist()
        newlist = Storylist()
        showlist = Storylist()
        
        toplocation = CGPoint.init(x: 0, y: 0)
        newlocation = CGPoint.init(x: 0, y: 0)
        showlocation = CGPoint.init(x: 0, y: 0)
//        listTypeMap = [StoryType.top: toplist, StoryType.new: newlist, StoryType.show: showlist]
    }
    
    func loadList(completionHandler: @escaping ()->Void, withCancel:((Error) -> Void)? = nil){
        self.toplist = loadListData(type: .top,storyLimitation: topLimitation,completionHandler: completionHandler,withCancel: withCancel)
        self.newlist = loadListData(type: .new,storyLimitation: newLimitation, completionHandler: completionHandler,withCancel: withCancel)
        self.showlist = loadListData(type: .show, storyLimitation: showLimitation ,completionHandler: completionHandler,withCancel: withCancel)
    }
    // fail
    func loadingDataFailded(){
        self.defaulttype = .top
        self.isretrievingStory = false
        self.isLoadingMore = false
        // 清楚干净
        self.toplist.clearer()
        self.newlist.clearer()
        self.showlist.clearer()
    }
    
    // set default list
    func setdefaultList(type:StoryType){
        self.defaulttype = type
    }
    // get default list
    func getdefaultList()->Storylist{
        switch self.defaulttype {
        case .top:
            return self.toplist
        case .new:
            return self.newlist
        case .show:
            return self.showlist
        }
    }
    func setdefaultList(loadlist:[Story] ){
        switch self.defaulttype {
        case .top:
            self.toplist.list = loadlist
        case .new:
            self.newlist.list = loadlist
        case .show:
            self.showlist.list = loadlist
        }
    }
    // get default limitaion
    func getdefaultlimit()->UInt{
        switch self.defaulttype {
        case .top:
            return self.topLimitation
        case .new:
            return self.newLimitation
        case .show:
            return self.showLimitation
        }
    }
    // get default limitaion
    func setdefaultlimit(withInterval:UInt)->UInt{
        switch self.defaulttype {
        case .top:
            self.topLimitation += withInterval
            return self.topLimitation
        case .new:
            self.newLimitation += withInterval
            return self.newLimitation
        case .show:
            self.showLimitation += withInterval
            return self.showLimitation
        }
    }
    // init default limitaion
    func initdefaultlimit(initLimit:UInt){
        switch self.defaulttype {
        case .top:
            self.topLimitation = initLimit
        case .new:
            self.newLimitation = initLimit
        case .show:
            self.showLimitation = initLimit
        }
    }
    // set defalt loaction
    func setdefaultloaction(location:CGPoint){
        switch self.defaulttype {
        case .top:
            self.toplocation = location
        case .new:
            self.newlocation = location
        case .show:
            self.showlocation = location
        }
    }
    
    // get defalt loaction
    func getdefaultloaction() -> CGPoint{
        switch self.defaulttype {
        case .top:
            return self.toplocation
        case .new:
            return self.newlocation
        case .show:
            return self.showlocation
        }
    }
    // refresh init corresponding list
    func initWhileRefresh(){
        // init the limitaion
        self.initdefaultlimit(initLimit: 30)
        // init the position
        self.setdefaultloaction(location: CGPoint.init(x: 0, y: 0))
    }
    
    
    
    
    // get the count of default story
    func getDefaultStoryCount() -> Int{
        return self.getdefaultList().getcount()
    }
    // default refresh
    func retrievedefault(completionHandler: @escaping ()->Void ,withCancel:((Error) -> Void)? = nil){
//        let listTemp = self.getdefaultList()
        BaseManager.shared.retrieveStories(loadList: self.getdefaultList(), storyLimitaion: self.getdefaultlimit(),completionHandler: completionHandler, withCancel: withCancel)
//        self.setdefaultList(loadlist: result)
    }

    // default loadmore
    func loadmoredefault(completionHandler: @escaping ()->Void, withCancel:((Error) -> Void)? = nil){
        let limitaionTemp = self.setdefaultlimit(withInterval: self.limitationinterval)
        BaseManager.shared.loadmore(loadList: self.getdefaultList(), storyLimitaion: limitaionTemp,withInterval: self.limitationinterval ,completionHandler: completionHandler, withCancel: withCancel)
    }
    
    func loadfinished() -> Bool{
        if (self.toplist.list.isEmpty || self.newlist.list.isEmpty || self.showlist.list.isEmpty){
            return false
        }
        else{
            return true
        }
    }
    
    
}

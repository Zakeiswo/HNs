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
    
    
    // 读取的数量
    var topLimitation: UInt = 30
    var newLimitation: UInt = 30
    var showLimitation: UInt = 30
    
    var limitationinterval:UInt = 10
    
    
    // load more

    var loadingStory:Bool! // load more flag
    var loadmoreLimitaion:UInt!
    var isLoadingMore:Bool! // 是否正在loadmore
    var retrievingStory:Bool! // refresh flag
    
    //dic
    let listTypeMap:[StoryType:Storylist]
    
    required init(){
        defaulttype = .top
        retrievingStory = false
        loadingStory = false
        loadmoreLimitaion = 0 // 最初这个加载更多的限制值为0
        isLoadingMore = false
        
    
        toplist = Storylist()
        newlist = Storylist()
        showlist = Storylist()
        
        listTypeMap = [StoryType.top: toplist, StoryType.new: newlist, StoryType.show: showlist]
    }
    
    func loadList(completionHandler: @escaping ()->Void, withCancel:((Error) -> Void)? = nil){
        self.toplist = loadListData(type: .top,storyLimitation: topLimitation,completionHandler: completionHandler,withCancel: withCancel)
        self.newlist = loadListData(type: .new,storyLimitation: newLimitation, completionHandler: completionHandler,withCancel: withCancel)
        self.showlist = loadListData(type: .show, storyLimitation: showLimitation ,completionHandler: completionHandler,withCancel: withCancel)
    }
    // fail
    func loadingDataFailded(){
        self.defaulttype = .top
        self.retrievingStory = false
        self.isLoadingMore = false
        self.loadingStory = false
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
        return self.listTypeMap[self.defaulttype]!
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
    // get the count of default story
    func getDefaultStoryCount() -> Int{
        return self.getdefaultList().getcount()
    }
    // default refresh
    func retrievedefault(completionHandler: @escaping ()->Void ,withCancel:((Error) -> Void)? = nil){
        
        let listTemp = self.getdefaultList()
        print(listTemp)
        BaseManager.shared.retrieveStories(loadList: self.getdefaultList(), storyLimitaion: self.getdefaultlimit(),completionHandler: completionHandler, withCancel: withCancel)
        print(self.getdefaultList().list.count)
    }

    // default loadmore
    func loadmoredefault(completionHandler:(()->Void)? = nil, withCancel:((Error) -> Void)? = nil){
        BaseManager.shared.loadmore(loadList: self.getdefaultList(), storyLimitaion: self.getdefaultlimit(),completionHandler: completionHandler, withCancel: withCancel)
    }
    
    
}

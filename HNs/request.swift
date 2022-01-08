//
//  request.swift
//  HNs
//
//  Created by 姚舜禹 on 2022/1/3.
//

import Foundation
import Firebase
import FirebaseDatabase


class BaseManager{
    // 单例
    static let shared = BaseManager()
    // realtime database
    var ref: DatabaseReference!
    
    // URL
    let fireBaseRef = "https://hacker-news.firebaseio.com/"
    let v0ChildRef = "v0"
    let itemChildRef = "item"

    
    //init
    init(){
        // 指定要向其中写入数据的位置
        self.ref = Database.database(url:self.fireBaseRef).reference()
        
    }
    
    //refresh
    // 通过逃逸闭包写入list
    func retrieveStories(loadList:Storylist,storyLimitaion:UInt, completionHandler: @escaping ()->Void, withCancel:((Error) -> Void)? = nil){
        var count = storyLimitaion
//        var resultList:[Story] = []
        var storiesMap = [Int:Story]()
        let query = ref.child(self.v0ChildRef).child(loadList.StoryTypeChildRefMap[loadList.type]!).queryLimited(toFirst:count )
        // 通过observeSingleEvent监听,single的话返回后就立刻取消
        query.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists(){
                print("Fail to loading the data of the snapshot during func retrieve")
                return
            }
            var storyIds = snapshot.value as! [Int]
            for (i, storyId) in storyIds.enumerated() {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                // 有时候可以获得id,但是snapshot是null
                q.observeSingleEvent(of: .value, with: { snapshot in
                    // 不为空的靠exists判断
                    if snapshot.exists(){
                        storiesMap[storyId] = self.snapshot2Story(snapshot)
                    }
                    else{
                        // 为空的时候减去这个部分
                        count = count - 1
                        storyIds.remove(at:i)
                        print("Missing the data of the snapshot during func retrieveStories")
                    }
                    
                    if storiesMap.count == Int(count){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        // 在这执行逃逸闭包
                        print(sortedStories.count)
//                        resultList = sortedStories
                        loadList.list = sortedStories
                        completionHandler()
                        
                    }
                    // TODO with Error
                }, withCancel: withCancel)
            }
        }, withCancel: withCancel)
//        return resultList
    }
    
    // load more
    func loadmore(loadList:Storylist,storyLimitaion:UInt, completionHandler: @escaping ()->Void,withCancel:((Error) -> Void)? = nil){
        var storiesMap = [Int:Story]()
        var count = storyLimitaion
        // 需要通过
        let query = ref.child(self.v0ChildRef).child(loadList.StoryTypeChildRefMap[loadList.type]!).queryLimited(toFirst: storyLimitaion)
        query.observeSingleEvent(of: .value, with: { snapshot in
            // 要是开始就没有
            if !snapshot.exists(){
                print("Fail to loading the data of the snapshot during func loadmore")
                return
            }
            let storyIds = snapshot.value as! [Int]
            for storyId in storyIds {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                q.observeSingleEvent(of: .value, with: { snapshot in
                    // snapshot可能出现原本的id非空,但是snapshot为空的情况
                    if snapshot.exists() {
                        storiesMap[storyId] = self.snapshot2Story(snapshot)
                    }
                    else{
                        count = count - 1
                        print("Missing the data of the snapshot during func loadmore")
                    }
                    if storiesMap.count == Int(storyLimitaion){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        // 赋值上去
                        loadList.list = sortedStories
                        print(sortedStories.count)
                        // 在这执行逃逸闭包
                        completionHandler()
                    }
                    // TODO with Error
                },withCancel: withCancel)
            }
        },withCancel: withCancel)
    }
    
    
    // snapshot to story
    func snapshot2Story(_ snapshot: DataSnapshot) -> Story{
        let data = snapshot.value as! Dictionary<String, Any>
        let id = data["id"] as! Int
        let title = data["title"] as! String
        let url = data["url"] as? String
        let by = data["by"] as! String
        let score = data["score"] as! Int
        let text = data["text"] as? String
        let time = data["time"] as! Int
        let type = data["type"] as! String
        let kids = data["kids"] as? [Int]
        let descendants = data["descendants"] as? Int
        
        return Story(id: id,title: title, url: url, by: by, score: score, text: text,time: time,type: type,kids: kids, descendants: descendants)
    }
    
    
}

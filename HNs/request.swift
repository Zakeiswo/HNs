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
    @objc func retrieveStories(loadList:Storylist,storyLimitaion:UInt ,withCancel:((Error) -> Void)? = nil){

        var storiesMap = [Int:Story]()
        let query = ref.child(self.v0ChildRef).child(loadList.StoryTypeChildRefMap[loadList.type]!).queryLimited(toFirst:storyLimitaion )
        // 通过observeSingleEvent监听,single的话返回后就立刻取消
        query.observeSingleEvent(of: .value, with: { snapshot in
            let storyIds = snapshot.value as! [Int]
            for storyId in storyIds {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                q.observeSingleEvent(of: .value, with: { snapshot in
                    storiesMap[storyId] = self.snapshot2Story(snapshot)
                    if storiesMap.count == Int(storyLimitaion){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        loadList.list = sortedStories

                    }
                    // TODO with Error
                }, withCancel: withCancel)
            }
        }, withCancel: withCancel)
        
    }
    
    // load more
    func loadmore(loadList:Storylist,storyLimitaion:UInt, withCancel:((Error) -> Void)? = nil){
        var storiesMap = [Int:Story]()
        // 需要通过
        let query = ref.child(self.v0ChildRef).child(loadList.StoryTypeChildRefMap[loadList.type]!).queryLimited(toFirst: storyLimitaion)
        query.observeSingleEvent(of: .value, with: { snapshot in
            let storyIds = snapshot.value as! [Int]
            for storyId in storyIds {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                q.observeSingleEvent(of: .value, with: { snapshot in
                    storiesMap[storyId] = self.snapshot2Story(snapshot)
                    if storiesMap.count == Int(storyLimitaion){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        // 赋值上去
                        loadList.list = sortedStories
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
        let descendants = data["descendants"] as! Int
        return Story(id: id,title: title, url: url, by: by, score: score, text: text,time: time,type: type,kids: kids, descendants: descendants)
    }
    
    
}

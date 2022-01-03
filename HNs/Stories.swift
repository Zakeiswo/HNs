//
//  Story.swift
//  HNs
//
//  Created by 姚舜禹 on 2022/1/3.
//

import Foundation
// 数据模型

struct Storylist{
    var type:StoryType!
    var list:[Story]
}


// 枚举
enum StoryType{
    case top, new, show
}

// 结构体
struct Story{
    let id: Int //
    let title: String // The title of the story
    let url: String? // The URL of the story.
    let by: String // author
    let score: Int // The story's score
    let text: String? // 感觉大多数没有文本
    let time: Int
    let type: String
    let kids: [Int] // The ids of the item's comments, in ranked display order.
    let descendants: Int // 评论数量 the total comment count.
}

// 扩展
extension Story: Equatable{
    // 这通过继承Equatable协议实现了一个自定义类型的比较 ==
    static func == (lhs:Self, rhs:Self) -> Bool{ // 自定义相等的条件
        lhs.id == rhs.id // id相等的时候两个post就相等
    }
}

extension Story{
    // 显示评论数
    var commentCountText: String {
        // 要是是一个无评论的就是显示字
        if descendants <= 0 { return "评论" }
        // 要是小于1k就显示数量
        if descendants < 1000 { return "\(descendants)" }
        // 要是大于1k就是缩写
        return String(format: "%.1fK", Double(descendants) / 1000)
        // 这里强制转化保证是个小数,要不然除了之后还是一个整数
    }
}

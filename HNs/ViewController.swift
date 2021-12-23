//
//  ViewController.swift
//  HNs
//
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreMIDI
import SafariServices
import AuthenticationServices
class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,SFSafariViewControllerDelegate{
    // str
    let cellIdentifier = "PostCell"
    let pullToRefreshStr = "Loading..."
    
    // story
    let storyLimitaion:UInt = 30 // queryLimited 只能为Unsigned的
    var retrievingStory:Bool! // refresh flag
    var stories: [Story]! = []
    var storytype: StoryType!
    let StoryTypeChildRefMap = [StoryType.top: "topstories", .new: "newstories", .show: "showstories"]
    let DefaultStoryType = StoryType.top
    // refresh
    var refreshControl:UIRefreshControl!
    // load more
    let loadthrehold:CGFloat = 120 // 上拉加载的阈值
    var loadingStory:Bool! // load more flag
    var loadmoreLimitaion:UInt!
    var isLoadingMore:Bool! // 是否正在loadmore
    
    
    // firebase
    var ref: DatabaseReference!
    let fireBaseRef = "https://hacker-news.firebaseio.com/"
    let v0ChildRef = "v0"
    let itemChildRef = "item"
    
    // tabelview
    var tableView:UITableView!
    
    
    // Error
    var errorMessageLabel: UILabel!
    let FetchErrorMessage = "Could Not Fetch Posts"
    let ErrorMessageLabelTextColor = UIColor.gray
    let ErrorMessageFontSize: CGFloat = 16
    
    // 枚举
    enum StoryType{
        case top, new, show
    }
    
    
    // 结构体
    struct Story{
        let title: String
        let url: String?
        let by: String
        let score: Int
        // type
    }
    
    // init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        // 指定要向其中写入数据的位置
        self.ref = Database.database(url:self.fireBaseRef).reference()
        stories = []
        storytype = DefaultStoryType
        retrievingStory = false
        refreshControl = UIRefreshControl()
        loadingStory = false
        loadmoreLimitaion = 0 // 最初这个加载更多的限制值为0
        isLoadingMore = false
    }
    
    // tableview
    //返回一组单元格的行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    // 创建一个cell的样子
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let story = stories[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as UITableViewCell?
        // 如果是空的
        if(cell == nil){
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: self.cellIdentifier);
        }
        cell?.textLabel?.text = story.title
        cell?.detailTextLabel?.text = "\(story.score) points by \(story.by)"
        return cell!
    }
    // UITableViewDelegate
    // 代理模式展示web
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let story = stories[indexPath.row]
        if let url = story.url {
            let webViewController = SFSafariViewController(url: URL(string:url)!)
            webViewController.delegate = self
            // 展示web
            present(webViewController, animated: true, completion: nil)
        }
    }
    
    // didload
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //  UI
        configureUI()
        // 开始的时候就应该检索一次
        self.retrievingStory = true
        retrieveStories()
    }
    
    // Functions
    
    // 配置UI
    func configureUI(){
        
        // tableview
        tableView = UITableView.init(frame: UIScreen.main.bounds, style: .plain)
        tableView.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        tableView.delegate = self
        tableView.dataSource = self
        // 注册cell
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        // 取出分隔线
//        tableView.separatorStyle = .none
        // 这是干嘛
//        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
        // segment
        let segment = UISegmentedControl(items: ["top","new","show"])
        segment.frame = CGRect(x:0,y:50,width: 250,height: 40)
        segment.center.x = self.view.center.x // 对齐
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(ViewController.changeStoryType(_:)), for: .valueChanged)
        // 设置style
        self.view.addSubview(segment)
        
        // refreshControl
        
        refreshControl.addTarget(self, action: #selector(ViewController.retrieveStories), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: pullToRefreshStr) // refreshControl 上展示的文字
        tableView.insertSubview(refreshControl, at: 0)// 插到最上面
        
        // Error
        errorMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        errorMessageLabel.textColor = ErrorMessageLabelTextColor
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.font = UIFont.systemFont(ofSize: ErrorMessageFontSize)
    }
    //scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //let space = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.height
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let space = scrollOffset + scrollViewHeight - scrollContentSizeHeight
        //space <= self.loadthrehold
//        print("A")
//        print(scrollOffset + scrollViewHeight)
//        print("B")
//        print(scrollContentSizeHeight)
        
        //初始情况scrollContentSizeHeight为0,也会通过这个if,得判断不为0时候
        // 还需要判断是否是离开了手指,不然会触发三次
        if space >= self.loadthrehold && scrollContentSizeHeight != 0.0 && scrollView.isDecelerating{
            // TODO
            if self.isLoadingMore == false{
                
                self.loadingStory = true
                // 加载更多数据
                loadmore()
                
                
                print(self.stories.count)
            }
        }
    }
    
    //refresh
    @objc func retrieveStories(){
        // 要是不是检索的时候直接终止
        if retrievingStory! == false{
            return
        }
        // 开始加载
        //isLoadingMore = true
//        print(retrievingStory!)
        // 小菊花开始转动
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
//        retrievingStory = true
        // 刷新的时候需要将之前loadmore的数量复原
        loadmoreLimitaion = 0
        // 开始刷新
        refreshControl.beginRefreshing()
        var storiesMap = [Int:Story]()
        let query = ref.child(self.v0ChildRef).child(StoryTypeChildRefMap[self.storytype]!).queryLimited(toFirst: self.storyLimitaion)
        // 通过observeSingleEvent监听,single的话返回后就立刻取消
        query.observeSingleEvent(of: .value, with: { snapshot in
            let storyIds = snapshot.value as! [Int]
            for storyId in storyIds {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                q.observeSingleEvent(of: .value, with: { snapshot in
                    storiesMap[storyId] = self.snapshot2Story(snapshot)
                    if storiesMap.count == Int(self.storyLimitaion){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        self.stories = sortedStories
                        self.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                        // 设置flag 为false
                        self.retrievingStory = false
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    // TODO with Error
                }, withCancel: self.loadingFailed(_:))
            }
        }, withCancel: self.loadingFailed(_:))
        
    }
    // load more
    func loadmore(){
        if loadingStory! == false{
            return
        }
        self.isLoadingMore = true
        // 将原先的数量加10
        self.loadmoreLimitaion += 10
        var storiesMap = [Int:Story]()
        // 需要通过
        let query = ref.child(self.v0ChildRef).child(StoryTypeChildRefMap[self.storytype]!).queryLimited(toFirst: self.storyLimitaion + self.loadmoreLimitaion)
        query.observeSingleEvent(of: .value, with: { snapshot in
            let storyIds = snapshot.value as! [Int]
            for storyId in storyIds {
                let q = self.ref.child(self.v0ChildRef).child(self.itemChildRef).child(String(storyId))
                q.observeSingleEvent(of: .value, with: { snapshot in
                    storiesMap[storyId] = self.snapshot2Story(snapshot)
                    if storiesMap.count == Int(self.storyLimitaion + self.loadmoreLimitaion){
                        var sortedStories = [Story]()
                        // 将字典转化为数组
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        // 在这里不能直接覆盖
                        self.stories = sortedStories
                        //
                        self.tableView.reloadData()
                        // 设置flag 为false
                        self.loadingStory = false
                        self.isLoadingMore = false
                    }
                    // TODO with Error
                },withCancel: self.loadingFailed(_:))
            }
        },withCancel: self.loadingFailed(_:))
    }
    
    // snapshot to story
    func snapshot2Story(_ snapshot: DataSnapshot) -> Story{
        let data = snapshot.value as! Dictionary<String, Any>
        let title = data["title"] as! String
        let url = data["url"] as? String
        let by = data["by"] as! String
        let score = data["score"] as! Int
        return Story(title: title, url: url, by: by, score: score)
    }
    
    // web SFSafariViewControllerDelegate对应的
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) { // 这里应该是为了断开,完成的时候
      controller.dismiss(animated: true, completion: nil)
    }
    
    // segment change the type
    @objc func changeStoryType(_ sender: UISegmentedControl){
        if sender.selectedSegmentIndex == 0{
            storytype = .top
        } else if sender.selectedSegmentIndex == 1{
            storytype = .new
        } else if sender.selectedSegmentIndex == 2{
            storytype = .show
        } else {
            print{"Segment Error!"}
        }
        // 完事会触发刷新
        self.retrievingStory = true
        retrieveStories()
    }
    // fail
    func loadingFailed(_ error: Error?) -> Void {
        self.retrievingStory = false
        self.isLoadingMore = false
        self.loadingStory = false
        self.stories.removeAll()
        self.tableView.reloadData()
        self.showErrorMessage(self.FetchErrorMessage) //Error
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    // Error
    //展示了对应的错误信息
    func showErrorMessage(_ message: String) {
      errorMessageLabel.text = message
      self.tableView.backgroundView = errorMessageLabel
      self.tableView.separatorStyle = .none
    }
}


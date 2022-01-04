//
//  ViewController.swift
//  HNs
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
    
    // UserData
    var userData:UserData!
    
    // refresh
    var refreshControl:UIRefreshControl!
    // load more
    let loadthrehold:CGFloat = 120 // 上拉加载的阈值
    
    // tabelview
    var tableView:UITableView!
    
    
    // Error
    var errorMessageLabel: UILabel!
    let FetchErrorMessage = "Could Not Fetch Posts"
    let ErrorMessageLabelTextColor = UIColor.gray
    let ErrorMessageFontSize: CGFloat = 16

    // init
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder:aDecoder)
//        // 指定要向其中写入数据的位置
//        refreshControl = UIRefreshControl()
//        self.userData = UserData(withCancel: loadingFailed)
//
//    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        refreshControl = UIRefreshControl()
        userData = UserData(withCancel: loadingFailed(_:))
       }
//
//    required init?(coder: NSCoder) {
//        refreshControl = UIRefreshControl()
//    }
//
//    convenience init() {
//        self.init()
//        userData = UserData(withCancel: loadingFailed(_:))
//
//    }
    
    // tableview
    //返回一组单元格的行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userData.getDefaultStoryCount()
    }
    // 创建一个cell的样子
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 这个是控制哪里
        let story = userData.getdefaultList().list[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as UITableViewCell?
        // 如果是空的
        if(cell == nil){
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: self.cellIdentifier);
        }
        cell?.textLabel?.text = story.title
        cell?.detailTextLabel?.text = "\(story.score) points by \(story.by)"
        return cell!
        // TODO 丰富cell
    }
    
    // UITableViewDelegate
    // 代理模式展示web
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let story = userData.getdefaultList().list[indexPath.row]
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
        userData!.retrievingStory = true
    }

    
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
        
        refreshControl.addTarget(self, action: #selector(viewRetrievedefault), for: .valueChanged)
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
            if userData.isLoadingMore == false{
                userData.loadingStory = true
                userData.loadmoredefault(withCancel: nil)
                print(userData.getDefaultStoryCount())
            }
        }
        
        //refresh
        // 查看是否是在刷新
        if self.refreshControl.isRefreshing == true && scrollView.isDecelerating{
            userData.retrievingStory = true
            userData.retrievedefault(withCancel: nil)
        }
    }
    

    
    // web SFSafariViewControllerDelegate对应的
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) { // 这里应该是为了断开,完成的时候
      controller.dismiss(animated: true, completion: nil)
    }
    
    // segment change the type
    @objc func changeStoryType(_ sender: UISegmentedControl){
        if sender.selectedSegmentIndex == 0{
            userData.defaulttype = .top
        } else if sender.selectedSegmentIndex == 1{
            userData.defaulttype = .new
        } else if sender.selectedSegmentIndex == 2{
            userData.defaulttype = .show
        } else {
            print{"Segment Error!"}
        }
        // 完事会触发刷新
        userData.retrievingStory = true
        userData.retrievedefault(withCancel: nil)
    }
    // fail
    func loadingFailed(_ error: Error?) -> Void {
        // Data clear
        userData.loadingDataFailded()
        self.tableView.reloadData()
        self.showErrorMessage(self.FetchErrorMessage) //Error
        guard #available(iOS 13.0, *) else{
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    // Error
    //展示了对应的错误信息
    @objc func showErrorMessage(_ message: String) {
      errorMessageLabel.text = message
      self.tableView.backgroundView = errorMessageLabel
      self.tableView.separatorStyle = .none
    }
    
    // 包裹refresh
    @objc func viewRetrievedefault(withCancel:((Error) -> Void)? = nil){
        userData.retrievedefault(withCancel: withCancel)
    }
}


# YJPageViewController
带头视图的分页控制器

使用方法：
1.添加数据源代理并实现代理方法:YJPageViewControllerDataSource

    dataSource = self
    //提供每个子控制器的初始化方法
    func pageViewController(subVcForType: UIViewController.Type, title: String?, idx: Int) -> UIViewController
    //提供子控制器中需要监听的UIScrollView
    func pageViewControllerObserveredScrollView(subVc: UIViewController, title: String?, idx: Int) -> UIScrollView?
    
2.添加代理并实现代理方法（可选）:YJPageViewControllerDelegate

    delegate = self
    //切换子控制器后的回调
    func pageViewController(didSelectedIdx index: Int)
    
    //当前pageView的contentOffset，如果想给titlesView加动画，可以在这里加，或者在这里更早的选择selectedIdx
    func pageViewController(didScroll contentOffset: CGPoint)
4.
    /**
     初始化设置，必须调用
     - parameter subVCs: 子控制器类型数组
     - parameter titles: 用来标记子控制器的名字
     */
    func setup(subVCs: [UIViewController.Type], titles: [String]? = nil)
    
5.设置透视图（可选，可自定义）

    topView = UIView()
    //必须设置高度
    topView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 250)
    //如果有topView但不需要滚动，可修改needScrollTopViewIfHas为false
    needScrollTopViewIfHas = false
    
6.设置标题栏视图（可选，可自定义）

    titlesView = YJTitlesView()
    //设置高度    
    titleViewH = 40
    //设置文字
    titlesView?.titles = ["tableView1", "collectionView", "scrollView", "tableView2", "collectionView2"]
    //设置初始选中按钮
    titlesView!.selectedIdx = 0
    //添加按钮回调
    titlesView!.selectedIdxHanlder = {
        //切换子控制器
        self.changeView($0, idx: $1, animation: true)
    }
    

其他一些可用的属性及方法

    /// 当前展示的子控制器
    var currentVc: UIViewController?
    /// 当前展示的子控制器的坐标
    var currentIdx: Int
    /// 是否记忆位置，即当再次回到某个子控制器时，要不要恢复到之前的位置
    var remeberLocation = true
    
注意点：

    1.该控制器的根视图为UIScrollView
    2.func setup(subVCs: [UIViewController.Type], titles: [String]? = nil)必须调用
    3./**
     这里是监听屏幕滚动的核心代码，如果子类重写，需要调用super方法
     */
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    
具体使用可查看DemoViewController.

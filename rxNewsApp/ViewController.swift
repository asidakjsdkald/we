//
//  ViewController.swift
//  rxNewsApp
//
//  Created by Shakugan on 15/10/3.
//  Copyright (c) 2015年 Shakugan. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UIScrollViewDelegate{

    var newsArray = Array<AnyObject>()
    var slideArray = Array<AnyObject>()
    var articleID = Int()
    @IBOutlet weak var newsTable: UITableView!
    @IBOutlet weak var scrollview: UIScrollView!
    var slidetitle=UILabel()
    var pageControl=UIPageControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsTable.estimatedRowHeight = 114
        self.newsTable.rowHeight = UITableViewAutomaticDimension
        // Do any additional setup after loading the view, typically from a nib.
        self.newsTable.header = MJRefreshNormalHeader(refreshingBlock: { () -> Void in
            self.requestData()
        })
        self.newsTable.footer = MJRefreshAutoNormalFooter(refreshingBlock: { () -> Void in
            self.loadMoreData(self.articleID)
        })
        self.newsTable.header.beginRefreshing()
        let cell = newsTable.dequeueReusableCellWithIdentifier("pageCell")
        scrollview = cell!.viewWithTag(1) as! UIScrollView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "rxNews" {
            let cell = sender as! UITableViewCell
            let vc = segue.destinationViewController as! WebViewController
            vc.id = cell.tag
        }
        if segue.identifier == "rxPageNews" {
            let vc = segue.destinationViewController as! WebViewController
            vc.id = (slideArray[pageControl.currentPage].objectForKey("id") as? Int)!
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = newsTable.dequeueReusableCellWithIdentifier("pageCell")
//            if cell == nil {
//                cell = UITableViewCell()
//                cell.
//                cell.frame = CGRectMake(0,0,self.view.frame.width,16/9*self.view.frame.width)
//            }
            self.scrollview = cell!.viewWithTag(1) as! UIScrollView
            scrollview.scrollEnabled=true
            scrollview.pagingEnabled=true
            scrollview.scrollsToTop = false
            scrollview.delegate=self
            if cell?.viewWithTag(112) == nil{
                pageControl=UIPageControl(frame: CGRectMake(self.view.frame.width-90,0,100,(cell?.viewWithTag(111)!.frame.height)!))
                pageControl.currentPageIndicatorTintColor=UIColor.blackColor()
                pageControl.hidesForSinglePage=true
                pageControl.backgroundColor=UIColor.clearColor()
                pageControl.numberOfPages=3
                pageControl.pageIndicatorTintColor=UIColor.lightGrayColor()
                pageControl.hidesForSinglePage=true
                pageControl.tag=112
                cell?.viewWithTag(111)?.addSubview(pageControl)
            }
            for i in 0...2 {
                var view = UIImageView()
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "click"))
                view.userInteractionEnabled=true
                if scrollview.viewWithTag(i+2) == nil {
                    self.slidetitle = cell!.viewWithTag(11) as! UILabel
                    slidetitle.text = slideArray[indexPath.row].objectForKey("title") as? String
                    scrollview.addSubview(view)
                } else {
                    view = scrollview.viewWithTag(i+2) as! UIImageView
                }
                let url = slideArray[i].objectForKey("thumb") as! String
                view.sd_setImageWithURL(NSURL(string:url), completed: { (uiImage:UIImage!, error:NSError!, cacheType:SDImageCacheType, nsurl:NSURL!) -> Void in
                    view.frame = CGRectMake(CGFloat(Int(cell!.frame.width)*i),
                        CGFloat(0),cell!.frame.width,cell!.frame.width/uiImage.size.width*uiImage.size.height)
                    self.scrollview.contentSize = CGSizeMake(CGFloat(Int(cell!.frame.width)*3),0)
                })

            }
            return cell!
        } else {
            let cell = newsTable.dequeueReusableCellWithIdentifier("rxCell")
            cell!.tag = newsArray[indexPath.row-1].objectForKey("id") as! Int
            let title = cell!.contentView.viewWithTag(1) as! UITextView
            let click = cell!.contentView.viewWithTag(2) as! UILabel
            let info = cell!.contentView.viewWithTag(3) as! UILabel
            let image = cell!.contentView.viewWithTag(4) as! UIImageView
            title.text = newsArray[indexPath.row-1].objectForKey("title") as? String
            title.font = UIFont.boldSystemFontOfSize(16)
            click.text = String(stringInterpolationSegment: newsArray[indexPath.row-1].objectForKey("click") as! Int)
            info.text = newsArray[indexPath.row-1].objectForKey("info") as? String
            let url = newsArray[indexPath.row-1].objectForKey("thumb") as! String
            image.sd_setImageWithURL(NSURL(string:url))
            return cell!
        }
    }

    func requestData() {
        let afManager = AFHTTPRequestOperationManager()
        let op =  afManager.GET("http://app.ecjtu.net/api/v1/index",
            parameters:nil,
            success: {  (operation: AFHTTPRequestOperation,
                responseObject: AnyObject) in
                let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(responseObject as! NSData, options:NSJSONReadingOptions() )
                let normal: AnyObject? = json?.objectForKey("normal_article")
                let slide: AnyObject? = json?.objectForKey("slide_article")
                self.newsArray = normal?.objectForKey("articles") as! Array<AnyObject>
                self.slideArray = slide?.objectForKey("articles") as! Array<AnyObject>
                self.articleID = self.newsArray[self.newsArray.count-1].objectForKey("id") as! Int
                for index in 0...self.newsArray.count-1 {
                    let id:AnyObject! = self.newsArray[index].objectForKey("id")
                    print(id)
                }
                self.newsTable.reloadData()
                self.newsTable.header.endRefreshing()
            },
            failure: {  (operation: AFHTTPRequestOperation,
                error: NSError) in
                self.newsTable.header.endRefreshing()
        })
        op!.responseSerializer = AFHTTPResponseSerializer()
        op!.start()
    }
    
    func loadMoreData(id:Int) {
        let afManager = AFHTTPRequestOperationManager()
        let op = afManager.GET("http://app.ecjtu.net/api/v1/index?until=\(id)", parameters: nil,
            success: { (operation:AFHTTPRequestOperation, response:AnyObject) -> Void in
                let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(response as! NSData , options:NSJSONReadingOptions() )
                let lang: AnyObject? = json?.objectForKey("normal_article")
                let count = lang?.objectForKey("count") as! Int
                if count==0 {
                    self.newsTable.footer.endRefreshing()
                    return
                }
                var array = lang?.objectForKey("articles") as! Array<AnyObject>
                for index in 0...count-1 {
                    self.newsArray.append(array[index])
                }
                self.articleID = self.newsArray[self.newsArray.count-1].objectForKey("id") as! Int
                for index in 0...self.newsArray.count-1 {
                    let id:AnyObject! = self.newsArray[index].objectForKey("id")
                    print(id)
                }
                self.newsTable.reloadData()
                self.newsTable.footer.endRefreshing()
            },
            failure:{ (operation:AFHTTPRequestOperation, error:NSError) -> Void in
                self.newsTable.footer.endRefreshing()
        })
        op!.responseSerializer = AFHTTPResponseSerializer()
        op!.start()
    }
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        let pageWidth = scrollview.frame.size.width
        let page = Int(floor((scrollview.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        pageControl.currentPage=page
        self.slidetitle.text = slideArray[page].objectForKey("title") as? String
        print(page)
    }
    func click()
    {
        let wv=WebViewController1()
        wv.id=(slideArray[pageControl.currentPage].objectForKey("id") as? Int)!
        self.navigationController?.pushViewController(wv, animated: true)
    }
}


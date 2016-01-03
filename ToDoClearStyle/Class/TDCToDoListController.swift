//
//  TDCToDoListController.swift
//  ToDoClearStyle
//
//  Created by LuanMa on 16/1/2.
//  Copyright © 2016年 luanma. All rights reserved.
//
//  参考 https://github.com/ColinEberhardt/iOS-ClearStyle
//

import UIKit

class TDCToDoListController: UITableViewController {

    var items = [
        TDCToDoItem(text: "Feed the cat"),
        TDCToDoItem(text: "Buy eggs"),
        TDCToDoItem(text: "Pack bags for WWDC"),
        TDCToDoItem(text: "Rule the web"),
        TDCToDoItem(text: "Buy a new iPhone"),
        TDCToDoItem(text: "Find missing socks"),
        TDCToDoItem(text: "Write a new tutorial"),
        TDCToDoItem(text: "Master Objective-C"),
        TDCToDoItem(text: "Remember your wedding anniversary!"),
        TDCToDoItem(text: "Drink less beer"),
        TDCToDoItem(text: "Learn to draw"),
        TDCToDoItem(text: "Take the car to the garage"),
        TDCToDoItem(text: "Sell things on eBay"),
        TDCToDoItem(text: "Learn to juggle"),
        TDCToDoItem(text: "Give up")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let pinch = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")

        tableView.addGestureRecognizer(pinch)
        tableView.addGestureRecognizer(longPress)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backgroundColor(indexPath: NSIndexPath) -> UIColor {
        let val: CGFloat = CGFloat(indexPath.row) / CGFloat(items.count - 1) * 0.6
        return UIColor(red: 1, green: val, blue: 0, alpha: 1)
    }
    
    /*
    // 简单删除
    func deleteToDoItem(indexPath: NSIndexPath) {
        tableView.beginUpdates()
        items.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    */

    // 更漂亮视觉效果的删除
    func deleteToDoItem(indexPath: NSIndexPath) {
        let item = items.removeAtIndex(indexPath.row)
        var animationEnabled = false
        let lastCell = tableView.visibleCells.last
        var delay: NSTimeInterval = 0
        for cell in tableView.visibleCells {
            let cell = cell as! TDCToDoItemCell
            if animationEnabled {
                UIView.animateWithDuration(0.25, delay: delay, options: .CurveEaseInOut,
                    animations: { () -> Void in
                        cell.frame = CGRectOffset(cell.frame, 0, -CGRectGetHeight(cell.frame))
                    }, completion: { (completed) -> Void in
                        if cell == lastCell {
                            self.tableView.reloadData()
                        }
                })
                delay += 0.03
            }

            if cell.toDoItem == item {
                animationEnabled = true
                cell.hidden = true
            }
        }
    }
    
    // MARK: - Pinch

    private var pinchIndexPath: NSIndexPath?
    private var placheHolderCell: TDCPlaceHolderView?
    private var sourcePoints: (upperPoint: CGPoint, downPoint: CGPoint)?
    private var pinchInsertEnabled = false

    func handlePinch(pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .Began:
            pinchBegan(pinch)
        case .Changed:
            pinchChanged(pinch)
        default:
            pinchEnd(pinch)
        }
    }
    
    func pinchBegan(pinch: UIPinchGestureRecognizer) {
        pinchIndexPath = nil
        sourcePoints = nil
        pinchInsertEnabled = false

        let (upperPoint, downPoint) = pointsOfPinch(pinch)
        if let upperIndexPath = tableView.indexPathForRowAtPoint(upperPoint),
            let downIndexPath = tableView.indexPathForRowAtPoint(downPoint) {
                if downIndexPath.row - upperIndexPath.row == 1 {
                    let upperCell = tableView.cellForRowAtIndexPath(upperIndexPath)!
                    let placheHolder = NSBundle.mainBundle().loadNibNamed("TDCPlaceHolderView", owner: tableView, options: nil).first as! TDCPlaceHolderView
                    placheHolder.frame = CGRectOffset(upperCell.frame, 0, CGRectGetHeight(upperCell.frame) / 2)
                    tableView.insertSubview(placheHolder, atIndex: 0)
                    
                    sourcePoints = (upperPoint, downPoint)
                    pinchIndexPath = upperIndexPath
                    placheHolderCell = placheHolder
                }
        }
    }

    func pinchChanged(pinch: UIPinchGestureRecognizer) {
        if let pinchIndexPath = pinchIndexPath, let originPoints = sourcePoints, let placheHolderCell = placheHolderCell {
            let points = pointsOfPinch(pinch)

            let upperDistance = points.0.y - originPoints.upperPoint.y
            let downDistance = originPoints.downPoint.y - points.1.y
            let distance = -min(0, min(upperDistance, downDistance))
            NSLog("distance=\(distance)")
            
            // 移动两边的Cell
            for cell in tableView.visibleCells {
                let indexPath = tableView.indexPathForCell(cell)!
                if indexPath.row <= pinchIndexPath.row {
                    cell.transform = CGAffineTransformMakeTranslation(0, -distance)
                } else {
                    cell.transform = CGAffineTransformMakeTranslation(0, distance)
                }
            }
            
            // 插入的Cell变形
            let scaleY = min(64, fabs(distance) * 2) / CGFloat(64)
            placheHolderCell.transform = CGAffineTransformMakeScale(1, scaleY)
            
            placheHolderCell.lblTitle.text = scaleY <= 0.5 ? "张开双指插入新项目": "松手可以插入新项目"
            
            pinchInsertEnabled = scaleY >= 1
        }
    }
    
    func pinchEnd(pinch: UIPinchGestureRecognizer) {
        if let pinchIndexPath = pinchIndexPath, let placheHolderCell = placheHolderCell {
            placheHolderCell.transform = CGAffineTransformIdentity
            placheHolderCell.removeFromSuperview()
            self.placheHolderCell = nil
            
            if pinchInsertEnabled {
                for cell in self.tableView.visibleCells {
                    cell.transform = CGAffineTransformIdentity
                }

                let index = pinchIndexPath.row + 1
                items.insert(TDCToDoItem(text: ""), atIndex: index)
                tableView.reloadData()
                
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! TDCToDoItemCell
                cell.txtField.becomeFirstResponder()
            } else {
                UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseInOut, animations: { [unowned self] () -> Void in
                    for cell in self.tableView.visibleCells {
                        cell.transform = CGAffineTransformIdentity
                    }
                    }, completion: { [unowned self] (completed) -> Void in
                        self.tableView.reloadData()
                })
            }
        }

        sourcePoints = nil
        pinchIndexPath = nil
        pinchInsertEnabled = false
    }

    func pointsOfPinch(pinch: UIPinchGestureRecognizer) -> (CGPoint, CGPoint) {
        if pinch.numberOfTouches() > 1 {
            let point1 = pinch.locationOfTouch(0, inView: tableView)
            let point2 = pinch.locationOfTouch(1, inView: tableView)
            if point1.y <= point2.y {
                return (point1, point2)
            } else {
                return (point2, point1)
            }
        } else {
            let point = pinch.locationOfTouch(0, inView: tableView)
            return (point, point)
        }
    }

    // MARK: - Drag & Drop

    private var sourceIndexPath: NSIndexPath?
    private var snapView: UIView?

    func handleLongPress(longPress: UILongPressGestureRecognizer) {
        let point = longPress.locationInView(tableView)
        NSLog("point = \(point)")
        if let indexPath = tableView.indexPathForRowAtPoint(point) {
            NSLog("state=\(longPress.state), indexPath=\(indexPath), sourceIndexPath=\(sourceIndexPath)")
            switch longPress.state {
            case .Began:
                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                    sourceIndexPath = indexPath
                    let snapView = self.snapView(cell)
                    snapView.alpha = 0

                    self.snapView = snapView

                    tableView.addSubview(snapView)
                    
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        snapView.alpha = 0.95
                        snapView.center = CGPointMake(cell.center.x, point.y)
                        snapView.transform = CGAffineTransformMakeScale(1.05, 1.05)

                        cell.alpha = 0
                        }, completion: { (completed) -> Void in
                            cell.hidden = true
                            cell.alpha = 1
                    })
                } else {
                    sourceIndexPath = nil
                    snapView = nil
                    break
                }
            case .Changed:
                if let snapView = snapView {
                    snapView.center = CGPointMake(snapView.center.x, point.y)
                }

                if let fromIndexPath = sourceIndexPath {
                    if fromIndexPath != indexPath {
                        tableView.beginUpdates()
                        let temp = items[indexPath.row]
                        items[indexPath.row] = items[fromIndexPath.row]
                        items[fromIndexPath.row] = temp
                        tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: indexPath)
                        tableView.endUpdates()
                        sourceIndexPath = indexPath
                    }
                }

                let step: CGFloat = 64
                if let parentView = tableView.superview {
                    let parentPos = tableView.convertPoint(point, toView: parentView)
                    if parentPos.y > parentView.bounds.height - step {
                        var offset = tableView.contentOffset
                        offset.y += (parentPos.y - parentView.bounds.height + step)
                        if offset.y > tableView.contentSize.height - tableView.bounds.height {
                            offset.y = tableView.contentSize.height - tableView.bounds.height
                        }
                        tableView.setContentOffset(offset, animated: false)
                    } else if parentPos.y <= step {
                        var offset = tableView.contentOffset
                        offset.y -= (step - parentPos.y)
                        if offset.y < 0 {
                            offset.y = 0
                        }
                        tableView.setContentOffset(offset, animated: false)
                    }
                }
            default:
                if let snapView = snapView, let fromIndexPath = sourceIndexPath, let cell = tableView.cellForRowAtIndexPath(fromIndexPath) {
                    cell.alpha = 0
                    cell.hidden = false

                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        snapView.center = cell.center
                        snapView.alpha = 0
                        
                        cell.alpha = 1
                        }, completion: { [unowned self] (completed) -> Void in
                            snapView.removeFromSuperview()
                            self.snapView = nil
                            self.sourceIndexPath = nil

                            self.tableView.performSelector("reloadData", withObject: nil, afterDelay: 0.5)
                    })
                }
            }
        }
    }

    // UIView截图为UIImageView
    func snapView(view: UIView) -> UIImageView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapShot = UIImageView(image: image)
        snapShot.layer.masksToBounds = false;
        snapShot.layer.cornerRadius = 0;
        snapShot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
        snapShot.layer.shadowOpacity = 0.4;
        snapShot.layer.shadowRadius = 5;
        snapShot.frame = view.frame
        return snapShot
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TDCToDoItemCell.cellId, forIndexPath: indexPath) as! TDCToDoItemCell
        let toDoItem = items[indexPath.row]
        cell.toDoItem = toDoItem
        cell.centerPannel.backgroundColor = toDoItem.completed ? UIColor(red: 0, green: 0.6, blue: 0, alpha: 1): backgroundColor(indexPath)

        cell.onDelete = { [unowned self] cell in
            if let indexPath = tableView.indexPathForCell(cell) {
                self.deleteToDoItem(indexPath)
            }
        }

        cell.onComplete = { [unowned self] cell in
            if let indexPath = tableView.indexPathForCell(cell) {
                let toDoItem = self.items[indexPath.row]
                toDoItem.completed = !toDoItem.completed
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }

        return cell
    }

}

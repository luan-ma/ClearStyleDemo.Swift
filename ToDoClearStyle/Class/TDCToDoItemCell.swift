//
//  TDCToDoItemCell.swift
//  ToDoClearStyle
//
//  Created by LuanMa on 16/1/2.
//  Copyright © 2016年 luanma. All rights reserved.
//

import UIKit

class TDCToDoItemCell: UITableViewCell, UITextFieldDelegate {
    
    static let cellId = "ToDoItemCell"

    @IBOutlet weak var centerPannel: UIView!
    @IBOutlet weak var leftPannel: UIView!
    @IBOutlet weak var rightPannel: UIView!

    @IBOutlet weak var txtField: UITextField!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    private var originConstant: CGFloat = 0

    var toDoItem: TDCToDoItem! {
        didSet {
            if let item = toDoItem {
                txtField.text = item.text
            } else {
                txtField.text = ""
                selected = false
            }
        }
    }

    var onDelete: ((TDCToDoItemCell) -> Void)?
    var onComplete: ((TDCToDoItemCell) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        leftLabel.text = "\u{2713}"     //对号
        rightLabel.text = "\u{2717}"    //叉号

        // add a layer that overlays the cell adding a subtle gradient effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = centerPannel.bounds
        gradientLayer.colors = [UIColor(white: 1, alpha: 0.2).CGColor,
            UIColor(white: 1, alpha: 0.1).CGColor,
            UIColor.clearColor().CGColor,
            UIColor(white: 0, alpha: 0.1).CGColor
        ]
        gradientLayer.locations = [NSNumber(float: 0), NSNumber(float: 0.01), NSNumber(float: 0.95), NSNumber(float: 1)]
        centerPannel.layer.insertSublayer(gradientLayer, atIndex: 0)

        // 添加Pan手势
        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        recognizer.delegate = self
        self.addGestureRecognizer(recognizer)
    }

    // 如果是划动手势，仅支持左右划动；如果是其它手势，则有父类负责
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGesture.translationInView(self.superview)
            return fabs(translation.x) > fabs(translation.y)
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }

    private var deleteOnDragRelease: Bool = false
    private var completeOnDragRelease: Bool = false

    func handlePan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .Began:
            originConstant = centerConstraint.constant
        case .Changed:
            let translation = panGesture.translationInView(self)
            centerConstraint.constant = translation.x

            // 划动移动1/3宽度为有效划动
            let finished = fabs(translation.x) > CGRectGetWidth(bounds) / 3
            if translation.x < originConstant { // 右划
                if finished {
                    deleteOnDragRelease = true
                    rightLabel.textColor = UIColor.redColor()
                } else {
                    deleteOnDragRelease = false
                    rightLabel.textColor = UIColor.whiteColor()
                }
            } else { // 左划
                if finished {
                    completeOnDragRelease = true
                    leftLabel.textColor = UIColor.greenColor()
                } else {
                    completeOnDragRelease = false
                    leftLabel.textColor = UIColor.whiteColor()
                }
            }
        case .Ended:
            centerConstraint.constant = originConstant

            if deleteOnDragRelease {
                deleteOnDragRelease = false
                if let onDelete = onDelete {
                    onDelete(self)
                }
            }

            if completeOnDragRelease {
                completeOnDragRelease = false
                if let onComplete = onComplete {
                    onComplete(self)
                }
            }
        default:
            break
        }
    }

    func hideKeyboard() {
        txtField.resignFirstResponder()
        txtField.text = toDoItem.text
    }
    
    // Mark - UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return !toDoItem.completed
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        toDoItem.text = textField.text!
        return false
    }
}

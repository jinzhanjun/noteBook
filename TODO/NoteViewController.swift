//
//  NoteViewController.swift
//  TODO
//
//  Created by 金占军 on 2019/10/18.
//  Copyright © 2019 金占军. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// 键盘出现/ 消失
    enum KeyBoardAppearence {
        case appear
        case disappear
    }
    /// textView的最大高度 // 100是随意设置的
    var textViewMaxHeight: CGFloat = 100
    /// textView的文本高度
    var textViewTextHeight: CGFloat = 44
    /// 已完成段落的高度
    var paragraphHeight: CGFloat = 0
    
    /// 创建内容模型
    lazy var textModleArray: [TextModel] = []
    
    var textViewShowHeight: CGFloat {
        return (textViewTextHeight > textViewMaxHeight) ? textViewMaxHeight : textViewTextHeight
    }
    
    /// 键盘高度
    var keyBoardHeight: CGFloat?
    
    /// 记事本内容
    @objc var noteTitle: String?
    
    var block: ((String) -> Void)?
    
    var alertController: UIAlertController?
    // 设置字体大小
    var textFont = UIFont.systemFont(ofSize: 23)
    /// 设置输入字体属性
    var typingAttri: [NSAttributedString.Key: Any] = [:]
    /// 设置光标所在位置
    var lastParagraphRange: NSRange?
    
    var range: NSRange = NSMakeRange(0, 1)
    /// 文本框视图
    let noteTextView: NoteTextView = NoteTextView(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.width, height: 44))
    /// 工具栏
    let toolBar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 44, width: UIScreen.main.bounds.width, height: 44))
    /// 记录键盘出现与消失
    var keyBoardAppearence = KeyBoardAppearence.disappear {
        didSet {
            switch keyBoardAppearence {
            case .appear:
                textViewMaxHeight = UIScreen.main.bounds.height - (keyBoardHeight ?? 0) - toolBar.bounds.height - 64
            case .disappear:
                textViewMaxHeight = UIScreen.main.bounds.height - toolBar.bounds.height - 64
            }
        }
    }
    /// 段落标志模型数组
    var lineStyleLabelModelArray: [lineStyleLabelModel]? = [] {
        didSet {
            guard let newArray = lineStyleLabelModelArray else {return}
            noteTextView.lineStyleLabelModelArray = newArray
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 监听键盘发出的通知（通知的名称为：UIResponder.keyboardWillChangeFrameNotification）
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let titleText = NoteTextView.getParagraphText(in: noteTextView)?.first else {return}
        block?(titleText)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        noteTextView.becomeFirstResponder()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if noteTextView.isFirstResponder { noteTextView.resignFirstResponder() }
    }
    // 设置界面
    private func setupUI() {
        noteTextView.text = noteTitle
        noteTextView.isScrollEnabled = true
        noteTextView.delegate = self
        noteTextView.backgroundColor = UIColor.green
        // 设置为默认文字属性
        typingAttri = noteTextView.defaultAttributes
        // 避免闪烁问题
        noteTextView.layoutManager.allowsNonContiguousLayout = false
        view.addSubview(noteTextView)
        setupToolBar()
    }
    // 设置工具栏
    private func setupToolBar() {
        toolBar.backgroundColor = UIColor.red
        let addTextBtn = UIBarButtonItem(title: "完成", style: .plain, target: self, action: Selector(("completed")))
        let lineBtn = UIBarButtonItem(title: "标题", style: .plain, target: self, action: Selector(("lineText")))
        let addPic = UIBarButtonItem(title: "图片", style: .plain, target: self, action: Selector(("showAlert")))
        toolBar.setItems([addTextBtn, lineBtn, addPic], animated: true)
        view.addSubview(toolBar)
    }
    
    // 文本变化后调用该方法
    func textViewDidChange(_ textView: UITextView) {
        // 获取最新段落的文字
        guard let textStr = NoteTextView.getNewParagraphString(in: textView) else {return}
        print(textStr)
        let size = NoteTextView.getStringRect(with: textStr, inTextView: textView, withAttributes: typingAttri)
//        print(size.height)
        
        let testSize = NoteTextView.getStringRect(with: textView.text, inTextView: textView, withAttributes: typingAttri)
        textViewTextHeight = size.height + paragraphHeight
        print("上一段的高度：\(paragraphHeight)")
        print("本行的高度：\(size.height)")
        print("计算的高度\(textViewShowHeight)")
        print("应该的高度：\(testSize.height)")
//        print(textView.typingAttributes)
        // 更新textView的框架
        refreshViewFrame(withSize: CGSize(width: UIScreen.main.bounds.width, height: textViewShowHeight), toView: textView)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            var model = TextModel()
            guard let textArray = NoteTextView.getParagraphText(in: textView),
                let paragraphString = textArray.last
                else { return false }
            // 记录上一段文字内容
            model.paragraphString = paragraphString
            model.attributeArray = textView.typingAttributes
            // 记录上一段文字的高度
            let height = NoteTextView.getTextRect(with: paragraphString, in: textView, withAttributes: model.attributeArray!).height
//            print(height)
            model.paragraphHeight = height
            paragraphHeight += height
            textModleArray.append(model)
//            print(model.attributeArray)
        }
        return true
    }
    
    // 更新textView的框架
    private func refreshViewFrame(withSize size: CGSize, toView textView: UITextView) {
        var frame = textView.frame
        frame.size = size
        textView.frame = frame
    }
    
    private func lineCountsOfString(string: String, constrainedToWidth: Double, font: UIFont) -> Double {
        let textSize = NSString(string: string).size(withAttributes: [NSAttributedString.Key.font: font])
        let lineCount = ceil(Double(textSize.width) / Double(constrainedToWidth))
        return lineCount
    }
    
    // alert
    @objc private func showAlert() {
        // 收回键盘，防止点击相册时键盘再次弹出
        noteTextView.resignFirstResponder()
        // 创建控制器
        alertController = UIAlertController()
        // 创建动作
        let cancelAction = UIAlertAction(title: "取消", style: .destructive) { (_) in
            self.alertController = nil
        }
        let addPicAction = UIAlertAction(title: "相册", style: .default) { [weak self](_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = true
                self?.present(imagePicker, animated: true) {
                }
            } else {
                print("读取相册错误")
            }
        }
        
        let addCameraPicAction = UIAlertAction(title: "相机", style: .default) { [weak self] (_) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let cameraPicker = UIImagePickerController()
                cameraPicker.delegate = self
                cameraPicker.sourceType = .camera
                cameraPicker.allowsEditing = true
                self?.present(cameraPicker, animated: true) { }
            }
        }
        
        alertController?.addAction(addCameraPicAction)
        alertController?.addAction(addPicAction)
        alertController?.addAction(cancelAction)
        
        present(alertController!, animated: true, completion: nil)
    }
    
    @objc private func completed() {
        noteTextView.completed()
    }
    
    // 从系统相册选择照片后执行
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {return}
        picker.dismiss(animated: true) {[weak self] in
            self?.noteTextView.insertPic(img, mode: .fitTextView)
        }
    }
    // 下划线
    @objc private func lineText() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 20
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = noteTextView.textContainer.lineBreakMode
        typingAttri = [NSAttributedString.Key.underlineStyle: 1, NSAttributedString.Key.font: textFont, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        noteTextView.typingAttributes = typingAttri
    }
    
    // 键盘出现消失动画
    @objc private func keyboardWillChangeFrame(notification: NSNotification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            else {return}
        
        // 键盘消失
        if frame.origin.y == UIScreen.main.bounds.size.height {
            keyBoardAppearence = .disappear
            UIView.animate(withDuration: duration){
                self.toolBar.transform = CGAffineTransform(translationX: 0, y: 0)
                // 更新textView的frame
                self.refreshViewFrame(withSize: CGSize(width: UIScreen.main.bounds.width, height: self.textViewShowHeight), toView: self.noteTextView)
            }
        }
        // 键盘出现
        else {
            // 获取键盘高度
            if keyBoardHeight == nil {keyBoardHeight = frame.height}
            keyBoardAppearence = .appear
            UIView.animate(withDuration: duration){
                self.toolBar.transform = CGAffineTransform(translationX: 0, y: -frame.size.height)
                // 更新textView的frame
                self.refreshViewFrame(withSize: CGSize(width: UIScreen.main.bounds.width, height: self.textViewShowHeight), toView: self.noteTextView)
            }
        }
    }
}


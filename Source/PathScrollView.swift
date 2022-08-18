//
//  MIT License
//
//  Copyright (c) 2022 Daniel
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  PathScrollViewDemo
//
//  Created by Daniel.Hu on 2022/8/17.
//
//  NOTE:
//  U R NEVER WRONG TO DO THE RIGHT THING.
//
//  Copyright (c) 2022 Daniel.Hu. All rights reserved.
//
    

import SwiftUI

/// 文字滚动视图
struct PathScrollViewWrapper: NSViewRepresentable {
    /// 完整路径
    let path: String
    /// 分割符
    var separator: String = "/"
    /// 视图高度
    /// - attention: 此高度切勿设置为0，为0时会显示不出来
    var height: CGFloat = 20
    /// 默认文字字体
    var defaultTextFont: NSFont = .systemFont(ofSize: 14)
    /// 鼠标经过时文字字体
    /// - attention: 切勿改变字体大小，不然over时显示会稍微不准确
    var overTextFont: NSFont? = nil
    /// 默认文字颜色
    var defaultTextColor: NSColor = .textColor
    /// 鼠标经过时颜色
    var overTextColor: NSColor? = .lightGray
    
    func makeNSView(context: Context) -> PathNSScrollView {
        // 宽度似乎能够自适应，高度限定就限定可识别滚动的区域
        PathNSScrollView(path,
                         separator: separator,
                         height: height,
                         defaultTextFont: defaultTextFont,
                         overTextFont: overTextFont,
                         defaultTextColor: defaultTextColor,
                         overTextColor: overTextColor)
    }
    
    func updateNSView(_ nsView: PathNSScrollView, context: Context) { }
    
}

class PathNSScrollView: NSScrollView {
    convenience init(_ path: String,
                     separator: String,
                     height: CGFloat,
                     defaultTextFont: NSFont,
                     overTextFont: NSFont?,
                     defaultTextColor: NSColor,
                     overTextColor: NSColor?) {
        let frameRect = NSMakeRect(0, 0, 0, height)
        self.init(frame: frameRect)
        
        setupDocumentView(path,
                          separator: separator,
                          defaultTextFont: defaultTextFont,
                          overTextFont: overTextFont,
                          defaultTextColor: defaultTextColor,
                          overTextColor: overTextColor)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        drawsBackground = false
        
        setupTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 不调用super就屏蔽了手势滚动
    override func scrollWheel(with event: NSEvent) {}
    
    // MARK: - Mouse Event
    override func mouseEntered(with event: NSEvent) {
        let offset = convert(event.locationInWindow, from: nil).x
        scrollByMouse(offset)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let offset = convert(event.locationInWindow, from: nil).x
        scrollByMouse(offset)
    }
    
    override func mouseExited(with event: NSEvent) {
        contentView.scroll(to: NSPointFromCGPoint(.zero))
    }
    
    /// 监听鼠标事件
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
    
    
    // MARK: - Private
    
    /// 鼠标偏移滚动内容
    private func scrollByMouse(_ offset: CGFloat) {
        guard let documentView = documentView else { return }
        
        let contentWidth = contentSize.width
        let documentWidth = documentView.frame.size.width
        guard documentWidth > contentWidth else { return }
        // documentWidth - contentWidth 表示总共可移动的实际偏移值
        let ret = offset * (documentWidth - contentWidth) / contentWidth
        
        contentView.scroll(to: NSMakePoint(ret, 0))
    }
    
    
    /// 通过文字内容构建documentView
    private func setupDocumentView(_ content: String,
                                   separator: String,
                                   defaultTextFont: NSFont,
                                   overTextFont: NSFont?,
                                   defaultTextColor: NSColor,
                                   overTextColor: NSColor?) {
        let contents = stringToArray(content, separator: separator)
        
        documentView = NSView(frame: bounds)
        
        var x: CGFloat = 0
        let height = bounds.size.height
        
        contents.forEach { content in
            let size = size(content, font: defaultTextFont)
            let frame = NSMakeRect(x, 0, size.width, size.height)
            // 字符为空或者为separator时 将不监听鼠标事件
            let trackable = trackable(content, separator: separator)
            
            let text = TextContainerNSView(frame: frame,
                                           content: content,
                                           trackable: trackable,
                                           defaultTextFont: defaultTextFont,
                                           overTextFont: overTextFont,
                                           defaultTextColor: defaultTextColor,
                                           overTextColor: overTextColor)
            
            documentView?.addSubview(text)
            
            x += size.width
        }
        // 内容视图更新实际尺寸
        documentView?.frame = NSMakeRect(0, 0, x, height)
    }
    
    /// 字符串通过此类的文字属性得到的完整显示所需宽度
    /// - Parameters:
    ///    - content: 显示内容呢
    ///    - font: 文字字体
    /// - Returns: 文字尺寸
    private func size(_ content: String, font: NSFont) -> NSSize {
        let size = NSString(string: content).size(withAttributes: [.font: font])
        // ceilf作用是将浮点数取整数+1，比如 ceilf(12.1)=13
        // 直接取size.width可能导致宽度不够，从而文字需换行显示
        return .init(width: CGFloat(ceilf(Float(size.width))), height: CGFloat(ceilf(Float(size.height))))
    }
    
    /// /User/someon/Documents => ["/", "Users", "/",  "someone",  "/", "Documents"]
    private func stringToArray(_ string: String, separator: String) -> [String] {
        let sep = separator
        let ret = string.components(separatedBy: sep)
        
        return ret.compactMap({ [$0] }).joined(separator: [sep]).filter({ !$0.isEmpty })
    }
    
    /// 是否可跟踪鼠标
    private func trackable(_ string: String, separator: String) -> Bool {
        !(string.isEmpty || string == separator)
    }
}

/// 文字视图
class TextContainerNSView: NSView {
    /// 默认文字属性
    private var defaultAttributes: [NSAttributedString.Key: Any] = [:]
    /// 鼠标经过时的文字属性
    private var overAttributes: [NSAttributedString.Key: Any] = [:]
    /// 显示内容
    private var content: NSString = NSString()
    /// 是否监听鼠标事件
    private var isMouseTrackable: Bool = false
    /// 鼠标是否经过
    private var isMouseOver: Bool = false
    
    /// 初始化
    /// - Parameters:
    ///   - frameRect: 布局
    ///   - content: 显示内容
    ///   - trackable: 是否监听鼠标事件
    ///   - textSize: 文字大小
    convenience init(frame frameRect: NSRect,
                     content: String,
                     trackable: Bool,
                     defaultTextFont: NSFont,
                     overTextFont: NSFont?,
                     defaultTextColor: NSColor,
                     overTextColor: NSColor?) {
        self.init(frame: frameRect)
        
        self.isMouseTrackable = trackable
        self.content = NSString(string: content)
        self.defaultAttributes = [.font: defaultTextFont, .foregroundColor: defaultTextColor]
        self.overAttributes = [.font: overTextFont ?? defaultTextFont, .foregroundColor: overTextColor ?? defaultTextColor]
        
        if trackable { setupTrackingArea() }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制文本——用NSText似乎太过厚重
        content
            .draw(in: dirtyRect,
                  withAttributes: isOver ? overAttributes : defaultAttributes)
    }
    
    override func mouseEntered(with event: NSEvent) {
        isMouseOver = true
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isMouseOver = false
        needsDisplay = true
    }
    
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
    
    /// 鼠标可监听并经过
    private var isOver: Bool { isMouseTrackable && isMouseOver }
}

struct PathScrollView_Previews: PreviewProvider {
    static var previews: some View {
        PathScrollViewWrapper(path: "/Users/daniel/Documents/iProjects/iGithub/DHCode/iProjects/iGithub/DHCode")
    }
}


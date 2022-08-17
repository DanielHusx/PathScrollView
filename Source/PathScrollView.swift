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
struct PathScrollView: View {
    /// 完整路径
    let path: String
    /// 视图高度
    var height: CGFloat = 20
    /// 文字大小
    var textSize: CGFloat = 14
    
    var body: some View {
        PathScrollViewWrapper(path: path, height: height, textSize: textSize)
    }
    
}

struct PathScrollViewWrapper: NSViewRepresentable {
    let path: String
    var height: CGFloat
    var textSize: CGFloat
    
    func makeNSView(context: Context) -> PathNSScrollView {
        // 宽度似乎能够自适应，高度限定就限定可识别滚动的区域
        PathNSScrollView(path: path, height: height, textSize: textSize)
    }
    
    func updateNSView(_ nsView: PathNSScrollView, context: Context) { }
    
}

class PathNSScrollView: NSScrollView {
    convenience init(path: String, height: CGFloat, textSize: CGFloat) {
        let frameRect = NSMakeRect(0, 0, 0, height)
        self.init(frame: frameRect)
        
        setupDocumentView(path, textSize: textSize)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        setupTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    /// 不调用super就屏蔽了手势滚动
    override func scrollWheel(with event: NSEvent) {}
    
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
    // MARK: - Private
    /// 监听鼠标事件
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
    
    /// /User/someon/Documents => ["/", "Users", "/",  "someone",  "/", "Documents"]
    private func stringToArray(_ string: String) -> [String] {
        let sep = "/"
        let ret = string.components(separatedBy: sep)
        
        return ret.compactMap({ [$0] }).joined(separator: [sep]).filter({ !$0.isEmpty })
    }
    
    private func setupDocumentView(_ string: String, textSize: CGFloat) {
        let source = stringToArray(string)
        setupDocumentView(source, textSize: textSize)
    }
    
    /// 通过文字内容构建documentView
    private func setupDocumentView(_ contents: [String], textSize: CGFloat) {
        documentView = NSView(frame: bounds)
        
        var x: CGFloat = 0
        let height = bounds.size.height
        
        contents.forEach { content in
            let width = TextContainerNSView.width(content, textSize: textSize)
            // 字符为空或者为/时 将不监听鼠标事件
            let trackable = !(content.isEmpty || content == "/")
            let text = TextContainerNSView(frame: NSMakeRect(x, 0, width, height), content: content, trackable: trackable, textSize: textSize)
            
            documentView?.addSubview(text)
            
            x += width
        }
        // 内容视图更新实际尺寸
        documentView?.frame = NSMakeRect(0, 0, x, height)
    }
}

/// 文字视图
class TextContainerNSView: NSView {
    /// 文字尺寸
    private var textSize: CGFloat = 14
    /// 显示内容
    private var content: NSString = NSString()
    /// 是否监听鼠标事件
    private var isMouseTrackable: Bool = false
    /// 鼠标是否经过
    private var isMouseOver: Bool = false
    
    convenience init(frame frameRect: NSRect, content: String, trackable: Bool, textSize: CGFloat) {
        self.init(frame: frameRect)
        
        self.isMouseTrackable = trackable
        self.content = NSString(string: content)
        self.textSize = textSize
        
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
        
        // 绘制文本
        content
            .draw(in: dirtyRect,
                  withAttributes: Self.attribute(isMouseTrackable, mouseOver: isMouseOver, textSize: textSize))
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
    
    /// 文字属性
    /// - Parameters:
    ///   - mouseTrackable: 是否监听鼠标事件
    ///   - mouseOver: 鼠标是否在上
    ///   - textSize: 文字大小
    /// - Returns: 文字属性
    static func attribute(_ mouseTrackable: Bool, mouseOver: Bool, textSize size: CGFloat) -> [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: size),
            .foregroundColor: mouseTrackable && mouseOver ? NSColor.black : NSColor.gray
        ]
    }
    
    /// 字符串通过此类的文字属性得到的完整显示所需宽度
    /// - Parameter content: 显示内容呢
    /// - Returns: 宽度
    static func width(_ content: String, textSize: CGFloat) -> CGFloat {
        let size = NSString(string: content).size(withAttributes: Self.attribute(false, mouseOver: false, textSize: textSize))
        // ceilf作用是将浮点数取整数+1，比如 ceilf(12.1)=13
        // 直接取size.width可能导致宽度不够，从而文字需换行显示
        return CGFloat(ceilf(Float(size.width)))
    }
}

struct PathScrollView_Previews: PreviewProvider {
    static var previews: some View {
        PathScrollView(path: "/Users/daniel/Documents/iProjects/iGithub/DHCode/iProjects/iGithub/DHCode")
    }
}


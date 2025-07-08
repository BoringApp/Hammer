import Hammer
import UIKit

/// 展示如何在特权进程中使用Hammer的三种后端模式
class HammerIntegrationExample {
    
    /// 方式1: 直接使用PrivilegedTouch (推荐用于特权进程)
    func exampleDirectPrivilegedTouch() {
        do {
            // 初始化特权触摸系统
            try PrivilegedTouch.initialize()
            
            // 执行点击 - 使用屏幕物理像素坐标
            try PrivilegedTouch.tap(x: 585, y: 1266) // iPhone 12 Pro屏幕中心
            
            // 执行拖拽
            try PrivilegedTouch.drag(fromX: 100, fromY: 200, toX: 500, toY: 600, duration: 0.5)
            
            print("✅ 特权触摸操作完成")
            
        } catch {
            print("❌ 特权触摸失败: \(error)")
        }
    }
    
    /// 方式2: 通过EventGenerator使用特权后端
    func exampleEventGeneratorPrivileged() {
        do {
            // 创建一个虚拟view用于坐标计算
            let view = UIView(frame: UIScreen.main.bounds)
            
            // 使用特权后端创建EventGenerator
            let eventGenerator = try EventGenerator(view: view, backend: .privileged)
            
            // 使用熟悉的Hammer API
            try eventGenerator.fingerTap(at: view.center)
            
            // 执行拖拽
            let startPoint = CGPoint(x: 100, y: 200)
            let endPoint = CGPoint(x: 300, y: 400)
            try eventGenerator.fingerDrag(from: startPoint, to: endPoint, duration: 0.5)
            
            // 多点触控
            try eventGenerator.twoFingerTap(at: view.center)
            
            print("✅ EventGenerator特权模式操作完成")
            
        } catch {
            print("❌ EventGenerator特权模式失败: \(error)")
        }
    }
    
    /// 方式3: 根据环境自动选择最佳后端
    func exampleAdaptiveBackend() {
        let backend = detectBestBackend()
        
        do {
            let view = UIView(frame: UIScreen.main.bounds)
            let eventGenerator = try EventGenerator(view: view, backend: backend)
            
            print("🔧 使用后端: \(backend)")
            
            // 执行测试操作
            try eventGenerator.fingerTap(at: view.center)
            
            print("✅ 自适应后端操作完成")
            
        } catch {
            print("❌ 自适应后端失败: \(error)")
        }
    }
    
    /// 检测当前环境支持的最佳后端
    private func detectBestBackend() -> EventSenderBackend {
        // 首先尝试特权模式
        do {
            _ = try PrivilegedSystemEventSender()
            print("💪 检测到HID特权，使用privileged后端")
            return .privileged
        } catch {
            print("⚠️ 无HID特权: \(error)")
        }
        
        // 降级到传统模式
        print("📱 使用标准application后端")
        return .application
    }
    
    /// 复杂手势示例：缩放
    func exampleComplexGesture() {
        do {
            // 使用特权模式进行精确控制
            let sender = try PrivilegedSystemEventSender()
            
            let centerX: CGFloat = 585  // iPhone 12 Pro中心X
            let centerY: CGFloat = 1266 // iPhone 12 Pro中心Y
            
            // 执行捏合缩小手势
            try performPinchGesture(
                sender: sender,
                centerX: centerX,
                centerY: centerY,
                startDistance: 200,
                endDistance: 100,
                duration: 0.5
            )
            
            print("✅ 复杂手势完成")
            
        } catch {
            print("❌ 复杂手势失败: \(error)")
        }
    }
    
    /// 执行捏合手势
    private func performPinchGesture(sender: PrivilegedSystemEventSender, 
                                   centerX: CGFloat, centerY: CGFloat,
                                   startDistance: CGFloat, endDistance: CGFloat,
                                   duration: TimeInterval) throws {
        
        // 计算两个手指的起始和结束位置
        let finger1StartX = centerX - startDistance/2
        let finger1StartY = centerY
        let finger2StartX = centerX + startDistance/2
        let finger2StartY = centerY
        
        let finger1EndX = centerX - endDistance/2
        let finger1EndY = centerY
        let finger2EndX = centerX + endDistance/2
        let finger2EndY = centerY
        
        // 同时按下两个手指
        let finger1Down = sender.createTouchDownEvent(fingerIndex: 0, x: finger1StartX, y: finger1StartY)
        let finger2Down = sender.createTouchDownEvent(fingerIndex: 1, x: finger2StartX, y: finger2StartY)
        let downEvent = sender.createHandEvent(fingerEvents: [finger1Down, finger2Down])
        try sender.sendEvent(downEvent)
        
        // 渐进移动
        let steps = Int(duration * 60) // 60 FPS
        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let finger1X = finger1StartX + (finger1EndX - finger1StartX) * progress
            let finger2X = finger2StartX + (finger2EndX - finger2StartX) * progress
            
            let finger1Move = sender.createTouchMoveEvent(fingerIndex: 0, x: finger1X, y: finger1StartY)
            let finger2Move = sender.createTouchMoveEvent(fingerIndex: 1, x: finger2X, y: finger2StartY)
            let moveEvent = sender.createHandEvent(fingerEvents: [finger1Move, finger2Move])
            try sender.sendEvent(moveEvent)
            
            Thread.sleep(forTimeInterval: duration / TimeInterval(steps))
        }
        
        // 抬起两个手指
        let finger1Up = sender.createTouchUpEvent(fingerIndex: 0, x: finger1EndX, y: finger1EndY)
        let finger2Up = sender.createTouchUpEvent(fingerIndex: 1, x: finger2EndX, y: finger2EndY)
        let upEvent = sender.createHandEvent(fingerEvents: [finger1Up, finger2Up])
        try sender.sendEvent(upEvent)
    }
}

/// 使用示例
func runHammerExamples() {
    let example = HammerIntegrationExample()
    
    print("🚀 开始Hammer集成示例")
    
    // 1. 直接特权触摸
    print("\n1️⃣ 测试直接特权触摸")
    example.exampleDirectPrivilegedTouch()
    
    Thread.sleep(forTimeInterval: 1)
    
    // 2. EventGenerator特权模式
    print("\n2️⃣ 测试EventGenerator特权模式")
    example.exampleEventGeneratorPrivileged()
    
    Thread.sleep(forTimeInterval: 1)
    
    // 3. 自适应后端
    print("\n3️⃣ 测试自适应后端选择")
    example.exampleAdaptiveBackend()
    
    Thread.sleep(forTimeInterval: 1)
    
    // 4. 复杂手势
    print("\n4️⃣ 测试复杂手势")
    example.exampleComplexGesture()
    
    print("\n✨ 所有示例完成!")
}

/*
使用方法:

1. 确保你的进程具有正确的entitlements:
   - com.apple.private.hid.client.event-dispatch
   - com.apple.private.hid.client.service-protected  
   - com.apple.private.hid.manager.client

2. 在你的代码中调用:
   runHammerExamples()

3. 根据你的需求选择适当的方式:
   - 直接使用PrivilegedTouch: 最简单，适合简单的触摸操作
   - EventGenerator特权模式: 保持Hammer API的熟悉感
   - 自适应模式: 自动根据环境选择最佳后端
*/
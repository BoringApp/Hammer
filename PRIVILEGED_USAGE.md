# 特权进程HID事件发送使用指南

## 概述

针对拥有HID相关entitlements的特权进程，我们提供了`PrivilegedSystemEventSender`，可以直接向系统发送触摸事件。

## 所需Entitlements

```xml
<key>com.apple.private.hid.client.event-dispatch</key>
<true/>
<key>com.apple.private.hid.client.service-protected</key>
<true/>
<key>com.apple.private.hid.manager.client</key>
<true/>
```

## 使用方式

### 1. 快速开始

```swift
import Hammer

// 初始化特权触摸系统
try PrivilegedTouch.initialize()

// 执行点击 (像素坐标)
try PrivilegedTouch.tap(x: 100, y: 200)

// 执行拖拽
try PrivilegedTouch.drag(fromX: 100, fromY: 200, toX: 300, toY: 400, duration: 0.5)
```

### 2. 详细控制

```swift
// 创建特权事件发送器
let sender = try PrivilegedSystemEventSender()

// 单点点击
try sender.performTap(x: 100, y: 200, fingerIndex: 0)

// 多点操作
let finger1Down = sender.createTouchDownEvent(fingerIndex: 0, x: 100, y: 100)
let finger2Down = sender.createTouchDownEvent(fingerIndex: 1, x: 200, y: 200)
let multiTouchEvent = sender.createHandEvent(fingerEvents: [finger1Down, finger2Down])
try sender.sendEvent(multiTouchEvent)
```

### 3. 复杂手势

```swift
// 双指捏合
func performPinch(centerX: CGFloat, centerY: CGFloat, startDistance: CGFloat, endDistance: CGFloat) throws {
    let sender = try PrivilegedSystemEventSender()
    
    // 计算两个手指的起始位置
    let finger1StartX = centerX - startDistance/2
    let finger1StartY = centerY
    let finger2StartX = centerX + startDistance/2
    let finger2StartY = centerY
    
    // 计算结束位置
    let finger1EndX = centerX - endDistance/2
    let finger1EndY = centerY
    let finger2EndX = centerX + endDistance/2
    let finger2EndY = centerY
    
    // 同时按下两个手指
    let finger1Down = sender.createTouchDownEvent(fingerIndex: 0, x: finger1StartX, y: finger1StartY)
    let finger2Down = sender.createTouchDownEvent(fingerIndex: 1, x: finger2StartX, y: finger2StartY)
    let downEvent = sender.createHandEvent(fingerEvents: [finger1Down, finger2Down])
    try sender.sendEvent(downEvent)
    
    // 移动到结束位置
    let steps = 30
    for i in 1...steps {
        let progress = CGFloat(i) / CGFloat(steps)
        let finger1X = finger1StartX + (finger1EndX - finger1StartX) * progress
        let finger2X = finger2StartX + (finger2EndX - finger2StartX) * progress
        
        let finger1Move = sender.createTouchMoveEvent(fingerIndex: 0, x: finger1X, y: finger1StartY)
        let finger2Move = sender.createTouchMoveEvent(fingerIndex: 1, x: finger2X, y: finger2StartY)
        let moveEvent = sender.createHandEvent(fingerEvents: [finger1Move, finger2Move])
        try sender.sendEvent(moveEvent)
        
        Thread.sleep(forTimeInterval: 0.016) // 60 FPS
    }
    
    // 抬起两个手指
    let finger1Up = sender.createTouchUpEvent(fingerIndex: 0, x: finger1EndX, y: finger1EndY)
    let finger2Up = sender.createTouchUpEvent(fingerIndex: 1, x: finger2EndX, y: finger2EndY)
    let upEvent = sender.createHandEvent(fingerEvents: [finger1Up, finger2Up])
    try sender.sendEvent(upEvent)
}
```

## 技术特点

### 1. 系统级权限
- 直接使用IOHIDEventSystemClient
- 无需依赖UIApplication
- 可以跨App工作

### 2. 精确控制
- 像素级坐标精度
- 支持多点触控
- 可控制触摸时序

### 3. 高性能
- 直接系统调用
- 最小延迟
- 60 FPS流畅操作

## 坐标系统

使用**物理像素坐标**：
```swift
// 获取屏幕尺寸（包含scale）
let screen = UIScreen.main
let physicalWidth = screen.bounds.width * screen.scale    // 例如：1170 (iPhone 12 Pro)
let physicalHeight = screen.bounds.height * screen.scale  // 例如：2532

// 直接使用物理坐标
try PrivilegedTouch.tap(x: 585, y: 1266) // 屏幕中心
```

## 错误处理

```swift
do {
    try PrivilegedTouch.initialize()
    try PrivilegedTouch.tap(x: 100, y: 200)
} catch HammerError.unableToAccessPrivateApi(let type, let method) {
    print("无法访问私有API: \(type).\(method)")
    print("检查进程是否具有正确的entitlements")
} catch HammerError.systemEventSenderNotReady(let message) {
    print("系统事件发送器未就绪: \(message)")
} catch {
    print("其他错误: \(error)")
}
```

## 最佳实践

### 1. 初始化检查
```swift
// 在应用启动时检查权限
func checkHIDPrivileges() -> Bool {
    do {
        let testSender = try PrivilegedSystemEventSender()
        return true
    } catch {
        print("缺少HID权限: \(error)")
        return false
    }
}
```

### 2. 合理的延迟
```swift
// 点击后适当延迟，确保系统处理
try PrivilegedTouch.tap(x: 100, y: 200)
Thread.sleep(forTimeInterval: 0.1)
```

### 3. 资源管理
```swift
// 长期使用时重用sender实例
class TouchController {
    private let sender: PrivilegedSystemEventSender
    
    init() throws {
        self.sender = try PrivilegedSystemEventSender()
    }
    
    func performActions() throws {
        try sender.performTap(x: 100, y: 200)
        // 更多操作...
    }
}
```

## 调试技巧

### 1. 坐标验证
```swift
// 先点击四个角确认坐标系统
let screen = UIScreen.main
let width = screen.bounds.width * screen.scale
let height = screen.bounds.height * screen.scale

try PrivilegedTouch.tap(x: 0, y: 0)           // 左上角
try PrivilegedTouch.tap(x: width, y: 0)       // 右上角  
try PrivilegedTouch.tap(x: 0, y: height)      // 左下角
try PrivilegedTouch.tap(x: width, y: height)  // 右下角
```

### 2. 事件监控
```swift
// 可以通过日志查看事件发送状态
print("发送触摸事件: (\(x), \(y))")
try sender.sendEvent(event)
print("事件发送完成")
```

这个实现专门为你的特权进程设计，充分利用了HID entitlements的能力，提供了真正的系统级触摸控制！🎯
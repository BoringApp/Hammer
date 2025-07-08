# Hammer 系统级事件模拟使用说明

## 概述

基于ZXTouch的实现，我们为Hammer添加了系统级事件模拟功能。这允许你绕过UIApplication层，直接向iOS系统的HID事件系统发送触摸事件。

## 主要特性

### 1. 系统级事件发送
- 使用 `IOHIDEventSystemClientDispatchEvent` 直接发送事件到系统级别
- 绕过UIApplication的事件队列，避免被App监听
- 支持跨App的事件模拟

### 2. 双后端支持
```swift
// 传统方式 - App内部事件模拟
let appEventGenerator = try EventGenerator(view: view, backend: .application)

// 新系统级方式 - 系统级事件模拟  
let systemEventGenerator = try EventGenerator(view: view, backend: .systemClient)
```

### 3. 自动SenderID管理
- 自动获取和缓存系统级SenderID
- 支持设备重启后的ID恢复
- 降级到默认ID以确保兼容性

## 核心组件

### EventSenderBackend
```swift
public enum EventSenderBackend {
    case application    // 传统UIApplication方式
    case systemClient   // 新系统级方式
}
```

### SystemEventSender
负责根据后端类型分发事件：
- `.application`: 使用UIApplication.enqueue()
- `.systemClient`: 使用IOHIDEventSystemClientDispatchEvent()

### SystemSenderIDManager
管理系统级SenderID：
- 缓存机制避免重复获取
- 自动检测设备重启
- 提供默认fallback ID

### SystemEventSynchronizer
系统级事件同步机制：
- 替代UIApplication监听的同步方法
- 基于时间和运行循环的等待机制
- 支持动画状态检测

## 使用示例

### 基本点击事件
```swift
// 创建系统级事件生成器
let eventGenerator = try EventGenerator(window: window, backend: .systemClient)

// 等待准备就绪
try eventGenerator.waitUntilWindowIsReady()

// 执行点击
try eventGenerator.fingerTap(at: CGPoint(x: 100, y: 100))
```

### 拖拽事件
```swift
let eventGenerator = try EventGenerator(view: view, backend: .systemClient)

// 执行拖拽
try eventGenerator.fingerDrag(
    from: CGPoint(x: 100, y: 100),
    to: CGPoint(x: 200, y: 200),
    duration: 0.5
)
```

### 多点触控
```swift
let eventGenerator = try EventGenerator(view: view, backend: .systemClient)

// 双指点击
try eventGenerator.twoFingerTap(at: view.center)

// 捏合手势
try eventGenerator.fingerPinchClose(at: view.center, duration: 0.3)
```

## 架构对比

| 特性 | Application Backend | SystemClient Backend |
|------|-------------------|---------------------|
| 事件范围 | 当前App内 | 系统级别 |
| 发送方式 | UIApplication.enqueue | IOHIDEventSystemClientDispatchEvent |
| 监听检测 | 容易被检测 | 更难检测 |
| 同步机制 | UIApplication监听 | 时间/状态基准 |
| 跨App支持 | ❌ | ✅ |
| 系统权限 | 不需要 | 可能需要 |

## 技术细节

### 事件发送流程（SystemClient模式）
1. **初始化**: 创建IOHIDEventSystemClient
2. **SenderID**: 获取或使用缓存的SenderID
3. **事件创建**: 使用IOHID API创建事件
4. **设置标志**: 配置系统级事件标志位
5. **直接分发**: 通过IOHIDEventSystemClientDispatchEvent发送
6. **同步等待**: 使用SystemEventSynchronizer等待完成

### 坐标系统
- 系统级事件使用归一化坐标 (0.0-1.0)
- 自动转换屏幕像素坐标到归一化坐标
- 支持不同屏幕尺寸和方向

### 错误处理
```swift
do {
    let eventGenerator = try EventGenerator(view: view, backend: .systemClient)
    try eventGenerator.fingerTap(at: tapPoint)
} catch HammerError.systemEventSenderNotReady {
    // SenderID未就绪，可能需要等待或降级
} catch HammerError.unableToAccessPrivateApi(let type, let method) {
    // 私有API访问失败
} catch {
    // 其他错误
}
```

## 注意事项

### 兼容性
- iOS 11.0+ (基于ZXTouch的兼容性)
- 需要相应的系统权限（根据使用场景）
- 在模拟器中可能有限制

### 权限要求
- 某些功能可能需要accessibility权限
- 跨App功能可能需要更高权限
- 建议在测试环境中使用

### 性能考虑
- 系统级事件延迟更低
- 但同步机制相对简单
- 建议在密集操作时添加适当延迟

## 迁移指南

### 从Application后端迁移
```swift
// 旧代码
let eventGenerator = try EventGenerator(view: view)

// 新代码 - 只需添加backend参数
let eventGenerator = try EventGenerator(view: view, backend: .systemClient)

// API保持不变
try eventGenerator.fingerTap(at: point)
```

### 渐进式采用
```swift
// 可以在运行时选择后端
let backend: EventSenderBackend = useSystemEvents ? .systemClient : .application
let eventGenerator = try EventGenerator(view: view, backend: backend)
```

## 调试和监控

### 日志输出
系统会输出关键事件信息：
```
Hammer: Using cached senderID: 0x123456789
Hammer: System tap completed successfully
```

### 性能监控
可以通过时间测量来比较两种后端的性能：
```swift
let startTime = Date()
try eventGenerator.fingerTap(at: point)
let duration = Date().timeIntervalSince(startTime)
print("Event duration: \\(duration)s")
```

这个实现提供了从Hammer原有架构到ZXTouch系统级事件模拟的平滑迁移路径，保持了API的一致性同时添加了强大的系统级功能。
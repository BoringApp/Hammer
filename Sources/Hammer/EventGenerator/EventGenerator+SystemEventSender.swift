import Foundation
import CoreFoundation
import UIKit

// MARK: - System Event Sending
extension EventGenerator {
    
    /// Sends event via application backend
    func sendEventViaApplication(_ event: IOHIDEvent, wait: Bool) throws {
        guard let window = self.window as? UIWindow & UIWindowPrivate else {
            throw HammerError.unableToAccessPrivateApi(type: "UIWindow", method: "Protocol")
        }
        
        guard let app = UIApplication.shared as? UIApplication & UIApplicationPrivate else {
            throw HammerError.unableToAccessPrivateApi(type: "UIApplication", method: "Protocol")
        }
        
        BackBoardServices.shared.eventSetDigitizerInfo(event, window.contextId, false, false, nil, 0, 0)
        app.enqueue(event)
    }
    
    /// Sends event via privileged backend
    func sendEventViaPrivileged(_ event: IOHIDEvent, wait: Bool) throws {
        // 设置事件标志
        setEventFlags(event)
        
        // 设置固定SenderID用于特权进程
        let senderID: UInt64 = 0x8000000817319372
        IOHID.shared.eventSetSenderID(event, senderID)
        
        // 创建IOHIDEventSystemClient用于系统级事件分发
        let ioSystemClient = IOHID.shared.eventSystemClientCreate(kCFAllocatorDefault)
        
        // 分发事件到系统
        IOHID.shared.eventSystemClientDispatchEvent(ioSystemClient, event)
        
        // 类似ZXTouch，不添加额外等待，依赖EventGenerator+Hand的时间控制
        // 系统会异步处理事件队列
    }
    
    /// Sets event flags for privileged backend
    private func setEventFlags(_ event: IOHIDEvent) {
        IOHID.shared.eventSetIntegerValue(event, IOHID.EventField.Digitizer.isDisplayIntegrated.rawValue, 1)
        IOHID.shared.eventSetIntegerValue(event, 0x4, 1)
        IOHID.shared.eventSetIntegerValue(event, 0xb0007, 0x23)
        IOHID.shared.eventSetIntegerValue(event, 0xb0008, 0x1)
        IOHID.shared.eventSetIntegerValue(event, 0xb0009, 0x1)
    }
}

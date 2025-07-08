# Hammer System-Level Touch Events Implementation

## Project Summary
Adding system-level touch event dispatch functionality to Hammer project based on ZXTouch architecture, specifically for processes with HID entitlements.

## Key Requirements
- Target: Process with HID entitlements (com.apple.private.hid.client.event-dispatch, etc.)
- No SpringBoard hook solutions needed
- Use Hammer's existing IOHID APIs
- Direct system-level event dispatch via IOHIDEventSystemClient

## Architecture
- Multi-backend system: `.application` (existing) and `.privileged` (new)
- EventGenerator supports backend parameter for initialization
- SystemEventSender handles both backends
- PrivilegedSystemEventSender for HID-privileged processes

## SenderID Analysis (Critical)
### What is SenderID
- Unique identifier in iOS HID system for event validation
- Security mechanism to ensure events come from authorized input sources
- Each physical input device has unique SenderID
- Required for synthetic events to be accepted by system

### ZXTouch SenderID Implementation
```objective-c
// Global variable
unsigned long long int senderID = 0x0;

// Acquisition through SpringBoard hook monitoring
static void setSenderIdCallback(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    if (IOHIDEventGetType(event) == kIOHIDEventTypeDigitizer && senderID == 0x0) {
        senderID = IOHIDEventGetSenderID(event);  // Extract from real touch event
        // Cache to file with reboot time validation
    }
}

// Usage in event dispatch
if (senderID != 0)
    IOHIDEventSetSenderID(event, senderID);
else
    return; // Refuse to send events without valid SenderID
```

### ZXTouch Limitations
- **Dependency on real touch**: Must wait for user to manually touch screen
- **SpringBoard dependency**: Requires hooking SpringBoard to monitor system events
- **First-use problem**: User must touch screen before synthetic events work

### Our Privileged Approach
- **Fixed SenderID**: Use `0x8000000817319372` directly
- **No waiting required**: Works immediately without real touch events
- **HID entitlements**: System trusts processes with proper entitlements
- **Bypass validation**: Direct HID access bypasses SpringBoard validation layer

## Implementation Status
- ✅ EventGenerator modified to support backend parameter
- ✅ SystemEventSender supports .application and .privileged backends
- ✅ Removed duplicate IOHID APIs (use Hammer's existing ones)
- ✅ Removed SpringBoard hook backend (.systemClient)
- ✅ SystemSenderIDManager deleted (unnecessary for privileged approach)
- ⚠️ PrivilegedSystemEventSender created but needs testing

## Critical SenderID Decision
Using fixed SenderID for privileged processes instead of ZXTouch's dynamic acquisition because:
1. HID entitlements provide necessary authorization
2. No dependency on user interaction
3. More reliable and immediate functionality
4. If synthetic events fail, SenderID validation is likely the cause

## Files Modified
- `Sources/Hammer/EventGeneration/EventGenerator.swift`
- `Sources/Hammer/EventGeneration/SystemEventSender.swift`
- `Sources/Hammer/AppleInternal/AppleInternal+IOHID.swift`

## Files Created
- `Sources/Hammer/EventGeneration/PrivilegedSystemEventSender.swift`

## Next Steps
1. Test PrivilegedSystemEventSender implementation
2. Verify SenderID works correctly with fixed value
3. Debug any event dispatch issues (likely SenderID-related)
4. Add PrivilegedSystemEventSender to Xcode project if needed

## Test Commands
不要测试，有些代码需要越狱你没有办法测试（除非我明确说让你测试）。
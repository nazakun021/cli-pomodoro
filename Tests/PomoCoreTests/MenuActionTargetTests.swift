import AppKit
import XCTest

@testable import PomoAgentKit

final class MenuActionTargetTests: XCTestCase {
    @MainActor
    func testMenuItemRetainsItsActionTarget() {
        let application = NSApplication.shared
        let menu = NSMenu()
        var item: NSMenuItem?
        weak var retainedTarget: MenuActionTarget?
        var invoked = false

        autoreleasepool {
            let target = MenuActionTarget {
                invoked = true
            }
            retainedTarget = target
            item = makeMenuActionItem(
                in: menu,
                title: "Pause",
                keyEquivalent: "",
                target: target)
        }

        guard let retainedTarget else {
            XCTFail("NSMenuItem released its action target")
            return
        }
        if let action = item?.action {
            application.sendAction(action, to: retainedTarget, from: item)
        }
        XCTAssertTrue(invoked)
    }
}

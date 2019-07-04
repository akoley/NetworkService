import Foundation

struct TestingManager {
    // Method to check whether you are on testing mode or not.
    static let isInTestingMode: Bool = {
        return false //Replace with actual actions
    }()

    static func operationBlock(_ disabled: Bool, block: @escaping () -> Void) {
        if TestingManager.isInTestingMode && disabled == false {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

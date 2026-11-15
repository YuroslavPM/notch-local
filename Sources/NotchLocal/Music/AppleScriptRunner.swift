import Foundation

struct AppleScriptOutcome: Sendable {
    var text: String?
    var data: Data?
    var errorNumber: Int?
}

final class AppleScriptRunner: @unchecked Sendable {
    private let queue = DispatchQueue(label: "notchlocal.applescript")

    func run(_ source: String) async -> AppleScriptOutcome {
        await withCheckedContinuation { continuation in
            queue.async {
                var error: NSDictionary?
                let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
                if let error {
                    let number = (error["NSAppleScriptErrorNumber"] as? NSNumber)?.intValue
                    continuation.resume(
                        returning: AppleScriptOutcome(text: nil, data: nil, errorNumber: number)
                    )
                    return
                }
                continuation.resume(
                    returning: AppleScriptOutcome(
                        text: result?.stringValue,
                        data: result?.data,
                        errorNumber: nil
                    )
                )
            }
        }
    }
}

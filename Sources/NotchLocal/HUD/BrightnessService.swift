import Foundation
import IOKit
import IOKit.graphics

enum BrightnessService {
    static func level() -> Double? {
        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            var brightness: Float = 0
            let key = "brightness" as CFString
            let result = IODisplayGetFloatParameter(service, 0, key, &brightness)
            IOObjectRelease(service)
            if result == kIOReturnSuccess {
                return min(1, max(0, Double(brightness)))
            }
            service = IOIteratorNext(iterator)
        }
        return nil
    }
}

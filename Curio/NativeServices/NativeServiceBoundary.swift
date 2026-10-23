import Foundation

/// Capability implementation flags; permission/device availability is checked at use.
/// No model response, backend event, or arbitrary command can be passed here.
/// Permission prompts and approved operations must live in a separate adapter.
protocol NativeServiceAvailability: Sendable {
    var attachmentsAvailable: Bool { get }
    var dictationAvailable: Bool { get }
    var executionAvailable: Bool { get }
}
struct LocalNativeServices: NativeServiceAvailability {
    let attachmentsAvailable = true
    let dictationAvailable = true
    let executionAvailable = false
}

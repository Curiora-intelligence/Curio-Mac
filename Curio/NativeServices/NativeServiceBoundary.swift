import Foundation

/// Reserved for future, explicit user-initiated native integrations.
/// No model response, backend event, or arbitrary command can be passed here.
/// Permission prompts and approved operations must live in a separate adapter.
protocol NativeServiceAvailability: Sendable {
    var attachmentsAvailable: Bool { get }
    var dictationAvailable: Bool { get }
    var executionAvailable: Bool { get }
}
struct UnconnectedNativeServices: NativeServiceAvailability {
    let attachmentsAvailable = false
    let dictationAvailable = false
    let executionAvailable = false
}

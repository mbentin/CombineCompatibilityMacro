import Combine
import CombineCompatibility

@ProtocolCombineCompatibility
protocol MyP {
    func foobar() async throws -> String
}

struct My: MyP {
    func foobar() async throws -> String {
        await withCheckedContinuation { body in
            body.resume(returning: "Async call")
        }
    }
}

@main
struct Main {
    static func main() async throws {
        let my = My()
        print(try await my.foobar())
        let _ = my.foobar()
            .sink(
                receiveCompletion: { print("Combine: \($0)") },
                receiveValue: { print("Combine: \($0)") }
            )
    }
}

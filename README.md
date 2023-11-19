# Combine compability macro

This swift macro synthetizes the combine calls from async await calls.

## Protocols

Define the protocol with the annotation

```swift 
@ProtocolCombineCompatibility
protocol MyP {
    func foobar() async throws -> String
}
```

Implement the async call.

```swift
struct My : MyP {
    func foobar() async throws -> String {
        await withCheckedContinuation { body in
            body.resume(returning: "Async call")
        }
    }
}
```

Get the Combine call with `Future` automatically

```swift
let my = My()
print(try await my.foobar())
let _ = my.foobar()
    .sink(
        receiveCompletion: { print("Combine: \($0)") },
        receiveValue: { print("Combine: \($0)") }
    )
```


import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CombineCompatibilityMacros)
    import CombineCompatibilityMacros

    let testMacros: [String: Macro.Type] = [
        "ProtocolCombineCompatibility": ProtocolCombineCompatibility.self
    ]
#endif

final class CombineCompatibilityTests: XCTestCase {
    func test_ProtocolCC_invariantVar() {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    var foo: String { get }
                }
                """#,
                expandedSource:
                    #"""
                    protocol MyTest {
                        var foo: String { get }
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ProtocolCC_invariantFunc() {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    func foo() -> String
                    func foo() throws -> String
                    func foo(bar: Int) -> String
                }
                """#,
                expandedSource:
                    #"""
                    protocol MyTest {
                        func foo() -> String
                        func foo() throws -> String
                        func foo(bar: Int) -> String
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ProtocolCC_nonThrowingFunc() {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    func foo() async -> String
                }
                """#,
                expandedSource:
                    #"""
                    protocol MyTest {
                        func foo() async -> String

                        func foo() -> Future<String, Never>
                    }

                    extension MyTest {
                        func foo() -> Future<String, Never> {
                            Future { promise in
                                Task {
                                    let output = await self.foo()
                                    promise(.success(output))
                                }
                            }
                        }
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ProtocolCC_nonThrowingNonReturningFunc() {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    func foo() async
                }
                """#,
                expandedSource:
                    #"""
                    protocol MyTest {
                        func foo() async

                        func foo() -> Future<Void, Never>
                    }

                    extension MyTest {
                        func foo() -> Future<Void, Never> {
                            Future { promise in
                                Task {
                                    await self.foo()
                                    promise(.success(()))
                                }
                            }
                        }
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ProtocolCC_throwingNonReturningFunc() {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    func foo() async throws
                }
                """#,
                expandedSource:
                    #"""
                    protocol MyTest {
                        func foo() async throws

                        func foo() -> Future<Void, Error>
                    }

                    extension MyTest {
                        func foo() -> Future<Void, Error> {
                            Future { promise in
                                Task {
                                    do {
                                        try await self.foo()
                                        promise(.success(()))
                                    } catch {
                                        promise(.failure(error))
                                    }
                                }
                            }
                        }
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_ProtocolCC_multilines() throws {
        #if canImport(CombineCompatibilityMacros)
            assertMacroExpansion(
                #"""
                @ProtocolCombineCompatibility
                protocol MyTest {
                    var foo: String { get }
                    func bar() async throws -> String
                    func foobar(param: Int) async throws -> (Int, String)
                    func foobar(param: Int, param2: Double) async throws -> (Int, String)
                }
                """#,
                expandedSource: #"""
                    protocol MyTest {
                        var foo: String { get }
                        func bar() async throws -> String
                        func foobar(param: Int) async throws -> (Int, String)
                        func foobar(param: Int, param2: Double) async throws -> (Int, String)

                        func bar() -> Future<String, Error>

                        func foobar(param: Int) -> Future<(Int, String), Error>

                        func foobar(param: Int, param2: Double) -> Future<(Int, String), Error>
                    }

                    extension MyTest {
                        func bar() -> Future<String, Error> {
                            Future { promise in
                                Task {
                                    do {
                                        let output = try await self.bar()
                                        promise(.success(output))
                                    } catch {
                                        promise(.failure(error))
                                    }
                                }
                            }
                        }
                        func foobar(param: Int) -> Future<(Int, String), Error> {
                            Future { promise in
                                Task {
                                    do {
                                        let output = try await self.foobar(param: param)
                                        promise(.success(output))
                                    } catch {
                                        promise(.failure(error))
                                    }
                                }
                            }
                        }
                        func foobar(param: Int, param2: Double) -> Future<(Int, String), Error> {
                            Future { promise in
                                Task {
                                    do {
                                        let output = try await self.foobar(param: param, param2: param2)
                                        promise(.success(output))
                                    } catch {
                                        promise(.failure(error))
                                    }
                                }
                            }
                        }
                    }
                    """#,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct CombineCompatibilityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtocolCombineCompatibility.self
    ]
}

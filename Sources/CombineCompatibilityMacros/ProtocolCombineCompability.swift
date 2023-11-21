import Combine
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ProtocolCombineCompatibility: MemberMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let prot = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        var declarations = [DeclSyntax]()
        for member in prot.memberBlock.members {
            if let function = member.decl.as(FunctionDeclSyntax.self),
                function.isAsync
            {
                declarations.append(.init(stringLiteral: FunctionBuilder(function: function).signature))
            }
        }
        return declarations
    }
}

extension ProtocolCombineCompatibility: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let prot = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        var funcString = "extension \(prot.name.trimmedDescription) {"
        var additions: Int = 0
        for member in prot.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                function.isAsync
            else {
                continue
            }

            additions += 1
            funcString.append(FunctionBuilder(function: function).full)
        }

        let declarations: [ExtensionDeclSyntax] =
            if additions > 0 {
                try [.init("\(raw: funcString)}")]
            } else {
                []
            }

        return declarations
    }
}

import Combine
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ProtocolCombineCompatibility: MemberMacro {

    static private func funcSignature(function: FunctionDeclSyntax) -> String {
        let identifier = function.name.text
        let signature = function.signature
        let parameters = signature.parameterClause.parameters
            .map(\.trimmedDescription)
            .joined()

        let parametersString =
            if signature.parameterClause.parameters.count == 0 {
                "()"
            } else {
                "(\(parameters))"
            }

        let returnClauseType = signature.returnClause?.type.trimmedDescription ?? "Void"

        return "func \(identifier)\(parametersString) -> Future<\(returnClauseType), Error>"
    }

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
                declarations.append(.init(stringLiteral: Self.funcSignature(function: function)))
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
            var parameters = ""
            for (index, parameter) in function.signature.parameterClause.parameters.map(\.firstName).enumerated() {
                if index > 0 {
                    parameters.append(",")
                }
                parameters.append("\(parameter): \(parameter)")
            }

            funcString.append(
                """
                \(Self.funcSignature(function: function)) {
                    Future { promise in
                        Task {
                            do {
                                let output = try await self.\(function.name)(\(parameters))
                                promise(.success(output))
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                }
                """
            )
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

extension FunctionDeclSyntax {
    var isAsync: Bool {
        self.signature.effectSpecifiers?.asyncSpecifier != nil
    }
}

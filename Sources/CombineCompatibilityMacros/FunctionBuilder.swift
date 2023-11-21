import SwiftSyntax
import SwiftSyntaxBuilder

struct FunctionBuilder {
    let function: FunctionDeclSyntax

    private var name: String { function.name.text }
    private var parameters: String {
        var parameters = ""
        for (index, parameter) in function.signature.parameterClause.parameters.map(\.firstName).enumerated() {
            if index > 0 {
                parameters.append(",")
            }
            parameters.append("\(parameter): \(parameter)")
        }
        return parameters
    }

    var signature: String {
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

        let errorClauseType = function.isThrowing ? "Error" : "Never"

        return "func \(name)\(parametersString) -> Future<\(returnClauseType), \(errorClauseType)>"
    }

    private func outputLine(isThrowing: Bool) -> String {
        "let output = \(isThrowing ? "try" : "") await self.\(name)(\(parameters))"
    }

    private var throwingBlock: String {
        """
        do {
                        let output = try await self.\(name)(\(parameters))
                        promise(.success(output))
        } catch {
                        promise(.failure(error))
        }
        """
    }

    private var throwingNonReturningBlock: String {
        """
        do {
                        try await self.\(name)(\(parameters))
                        promise(.success(()))
        } catch {
                        promise(.failure(error))
        }
        """
    }

    private var nonThrowingBlock: String {
        """
        let output = await self.\(name)(\(parameters))
        promise(.success(output))
        """
    }

    private var nonThrowingNonReturningBlock: String {
        """
        await self.\(name)(\(parameters))
        promise(.success(()))
        """
    }

    private func returnBblock(isReturning: Bool, isThrowing: Bool) -> String {
        switch (isReturning, isThrowing) {
        case (false, false): nonThrowingNonReturningBlock
        case (false, true): throwingNonReturningBlock
        case (true, false): nonThrowingBlock
        case (true, true): throwingBlock
        }
    }

    var full: String {
        return """
            \(signature) {
                Future { promise in
                    Task {
                        \(returnBblock(isReturning: function.isReturning, isThrowing: function.isThrowing))
                    }
                }
            }
            """
    }
}

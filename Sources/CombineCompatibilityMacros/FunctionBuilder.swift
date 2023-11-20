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

        return "func \(name)\(parametersString) -> Future<\(returnClauseType), Error>"
    }
    
    var full: String {
        """
        \(signature) {
            Future { promise in
                Task {
                    do {
                        let output = try await self.\(name)(\(parameters))
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        """
    }
}

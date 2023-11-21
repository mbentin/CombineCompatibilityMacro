import SwiftSyntax

extension FunctionDeclSyntax {
    var isAsync: Bool {
        self.signature.effectSpecifiers?.asyncSpecifier != nil
    }
    var isThrowing: Bool {
        self.signature.effectSpecifiers?.throwsSpecifier != nil
    }
    var isReturning: Bool {
        self.signature.returnClause != nil
    }
}

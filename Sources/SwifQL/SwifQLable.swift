//
//  SwifQLable.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public protocol SwifQLable: CustomStringConvertible {
    var parts: [SwifQLPart] { get }
}

extension SwifQLable {
    public var description: String { prepare(.psql).plain }
}

public struct SwifQLableParts: SwifQLable {
    public var parts: [SwifQLPart]
    public init (parts: SwifQLPart...) {
        self.init(parts: parts)
    }
    public init (parts: [SwifQLPart]) {
        self.parts = parts
    }
}

public protocol SwifQLPart {}

public protocol SwifQLKeyPathable: SwifQLPart {
    var schema: String? { get }
    var table: String? { get }
    var paths: [String] { get }
}

extension SwifQLable {
    /// Good choice only for super short and universal queries like `BEGIN;`, `ROLLBACK;`, `COMMIT;`
    public func prepare() -> SwifQLPrepared {
        prepare(.any)
    }
    
    public func prepare(_ dialect: SQLDialect) -> SwifQLPrepared {
      return SwifQLPrepared.prepare(self, dialect)
    }

}

//
//  Prepared.swift
//
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

public struct SwifQLPrepared {

  // MARK: - Properties

    public var _dialect: SQLDialect
    public var _query: String
    public var _values: [Encodable]
    public var _formattedValues: [String]


  // MARK: - Computed Properties

  public var plain: String {
    guard _values.count > 0 else { return _query }
    let formatter = SwifQLFormatter(_dialect, mode: .plain)
    return formatter.string(from: _query, with: _formattedValues)
  }

  public var splitted: SwifQLSplittedQuery {
    guard _values.count > 0 else { return .init(query: _query, values: _values) }
    let formatter = SwifQLFormatter(_dialect, mode: .binded)
    let result = formatter.string(from: _query, with: _formattedValues)
    return .init(query: result, values: _values)
  }

  // MARK: - Initialiers

    public init(dialect: SQLDialect, query: String, values: [Encodable], formattedValues: [String]) {
        _dialect = dialect
        _query = query
        _values = values
        _formattedValues = formattedValues
    }

  // MARK: - Prepare

  public static func prepare(_ container: SwifQLable,  _ dialect: SQLDialect) -> SwifQLPrepared {
    var values: [Encodable] = []
    var formattedValues: [String] = []

    let query = container.parts.map { part in
      switch part {
        case let v as SwifQLPartArray:
          guard v.elements.count > 0 else {
            return dialect.emptyArrayStart + dialect.emptyArrayEnd
          }
          var string = dialect.arrayStart
          v.elements.enumerated().forEach { i, v in
            if i > 0 {
              string += dialect.arraySeparator
            }
            let prepared = v.prepare(dialect)
            values.append(contentsOf: prepared._values)
            formattedValues.append(contentsOf: prepared._formattedValues)
            string += prepared._query
          }
          return string + dialect.arrayEnd
        case let v as SwifQLPartBool:
          return dialect.boolValue(v.value)
        case is SwifQLPartNull:
          return dialect.null
        case let v as SwifQLPartSchema:
          guard let schema = v.schema else { return "" }
          return dialect.schemaName(schema)
        case let v as SwifQLPartTable:
          if let schema = v.schema {
            return dialect.schemaName(schema) + "." + dialect.tableName(v.table)
          }
          return dialect.tableName(v.table)
        case let v as SwifQLPartTableWithAlias:
          if let schema = v.schema {
            return dialect.schemaName(schema) + "." + dialect.tableName(v.table, andAlias: v.alias)
          }
          return dialect.tableName(v.table, andAlias: v.alias)
        case let v as SwifQLPartAlias:
          return dialect.alias(v.alias)
        case let v as SwifQLPartKeyPath:
          return dialect.keyPath(v)
        case let v as SwifQLPartColumn:
          return dialect.column(v.name)
        case let v as SwifQLPartOperator:
          return v._value
        case let v as SwifQLPartDate:
          return dialect.date(v.date)
        case let v as SwifQLPartSafeValue:
          return dialect.safeValue(v.safeValue)
        case let v as SwifQLPartUnsafeValue:
          values.append(v.unsafeValue)
          formattedValues.append(dialect.safeValue(v.unsafeValue))
          return dialect.bindSymbol
        case let v as SwifQLPartRegexValue:
          guard let regexDialect = dialect.regexDialect else { return "" }

          var string = ""
          v.elements.enumerated().forEach { i, v in
            let prepared = v.prepare(regexDialect)
            values.append(contentsOf: prepared._values)
            formattedValues.append(contentsOf: prepared._formattedValues)
            string += prepared._query
          }

          return string

        default: return ""

      }
    }.joined(separator: "")

    return SwifQLPrepared(dialect: dialect, query: query, values: values, formattedValues: formattedValues)
  }

}

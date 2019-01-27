import CSQLite
import class Foundation.NSError

final class PreparedStatement {
  enum Result<Row> {
    case row(Row)
    case done
  }

  private var statement: OpaquePointer?

  init(connection: OpaquePointer, sql: String) throws {
    let status = sqlite3_prepare_v2(connection, sql, -1, &statement, nil)
    guard status == SQLITE_OK else {
      throw NSError(domain: SQLiteError.errorDomain, code: Int(status))
    }
  }

  func decodeNext<Row: Decodable>(_: Row.Type) throws -> Result<Row> {
    guard let statement = statement else { return .done }

    switch sqlite3_step(statement) {
    case SQLITE_DONE:
      return .done
    case SQLITE_ROW:
      break
    case let error:
      throw NSError(domain: SQLiteError.errorDomain, code: Int(error))
    }

    let decoder = SQLiteDecoder(statement: statement)
    let row = try Row(from: decoder)
    return .row(row)
  }

  func finalize() throws {
    let status = sqlite3_finalize(statement)
    statement = nil
    guard status == SQLITE_OK else {
      throw NSError(domain: SQLiteError.errorDomain, code: Int(status))
    }
  }

  deinit {
    try? finalize()
  }
}

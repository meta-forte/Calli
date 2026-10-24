import Foundation
import SQLite3

final class PracticeStorageService: ObservableObject {
    static let shared = PracticeStorageService()

    private var db: OpaquePointer?

    init(databasePath: String? = nil) {
        let path = databasePath ?? Self.defaultDatabasePath()
        openDatabase(at: path)
        createTable()
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    private static func defaultDatabasePath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0]
        return directory.appendingPathComponent("practice.sqlite").path
    }

    private func openDatabase(at path: String) {
        if sqlite3_open(path, &db) != SQLITE_OK {
            db = nil
        }
    }

    private func createTable() {
        guard let db = db else { return }
        let query = """
        CREATE TABLE IF NOT EXISTS practice_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character TEXT NOT NULL,
            date TEXT NOT NULL,
            practice_count INTEGER NOT NULL DEFAULT 1,
            UNIQUE(character, date)
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }

    @discardableResult
    func recordPractice(character: String, date: String = currentDateString()) -> Int {
        guard let db = db else { return 0 }
        let query = """
        INSERT INTO practice_log (character, date, practice_count)
        VALUES (?, ?, 1)
        ON CONFLICT(character, date) DO UPDATE SET practice_count = practice_count + 1;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, character, -1, transient)
            sqlite3_bind_text(statement, 2, date, -1, transient)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)

        return getPracticeCount(character: character, date: date)
    }

    func getPracticeCount(character: String, date: String = currentDateString()) -> Int {
        guard let db = db else { return 0 }
        let query = "SELECT practice_count FROM practice_log WHERE character = ? AND date = ?;"
        var statement: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, character, -1, transient)
            sqlite3_bind_text(statement, 2, date, -1, transient)
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        return count
    }

    func getTotalPracticeCount(character: String) -> Int {
        guard let db = db else { return 0 }
        let query = "SELECT SUM(practice_count) FROM practice_log WHERE character = ?;"
        var statement: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, character, -1, transient)
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        return count
    }

    func getAllPracticeCountsForToday() -> [String: Int] {
        guard let db = db else { return [:] }
        let date = PracticeStorageService.currentDateString()
        let query = "SELECT character, practice_count FROM practice_log WHERE date = ?;"
        var statement: OpaquePointer?
        var results: [String: Int] = [:]
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, date, -1, transient)
            while sqlite3_step(statement) == SQLITE_ROW {
                if let charPtr = sqlite3_column_text(statement, 0) {
                    let charStr = String(cString: charPtr)
                    let count = Int(sqlite3_column_int(statement, 1))
                    results[charStr] = count
                }
            }
        }
        sqlite3_finalize(statement)
        return results
    }
}

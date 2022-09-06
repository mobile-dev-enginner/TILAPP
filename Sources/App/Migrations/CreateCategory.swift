//
//  CreateCategory.swift
//
//  Created by Nguyễn Trường Thịnh on 15/07/2022.
//
import Fluent

struct CreateCategory: Migration {
    /// Create the categories table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v18082022.schemaName)
            .id()
            .field(Category.v18082022.name, .string, .required)
            .create()
    }
    /// Deletes the table named categories
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v18082022.schemaName).delete()
    }
}

extension Category {
    enum v18082022 {
        static let schemaName = "categories"
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
    }
}

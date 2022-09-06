//
//  CreateTermCatePivot.swift
//
//  Created by Nguyễn Trường Thịnh on 15/07/2022.
//
import Fluent

struct CreateTermCatePivot: Migration {
    /// Create the terminology-category-pivot table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TermCatePivot.v18082022.schemaName)
            .id()
            .field(TermCatePivot.v18082022.terminologyID, .uuid, .required,
                   .references(Terminology.v19082022.schemaName, Terminology.v19082022.id, onDelete: .cascade))
            .field(TermCatePivot.v18082022.categoryID, .uuid, .required,

                    .references(Category.v18082022.schemaName, Category.v18082022.id, onDelete: .cascade))
            .create()
    }
    /// Deletes the table named terminology-category-pivot
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TermCatePivot.v18082022.schemaName).delete()
    }
}

extension TermCatePivot {
    enum v18082022 {
        static let schemaName = "terminology-category-pivot"
        static let id = FieldKey(stringLiteral: "id")
        static let terminologyID = FieldKey(stringLiteral: "terminologyID")
        static let categoryID = FieldKey(stringLiteral: "categoryID")
    }
}

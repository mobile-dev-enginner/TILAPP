//
//  CreateToken.swift
//
//
//  Created by Nguyễn Trường Thịnh on 13/08/2022.
//

import Fluent

struct CreateToken: Migration {
    /// Create the tokens table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.v18082022.schemaName)
            .id()
            .field(Token.v18082022.value, .string, .required)
            .field(Token.v18082022.userID, .uuid, .required, .references(User.v18082022.schemaName, User.v18082022.id, onDelete: .cascade))
            .create()
    }
    /// Deletes the table named tokens
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tokens").delete()
    }
}

extension Token {
    enum v18082022 {
        static let schemaName = "tokens"
        static let id = FieldKey(stringLiteral: "id")
        static let value = FieldKey(stringLiteral: "value")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}

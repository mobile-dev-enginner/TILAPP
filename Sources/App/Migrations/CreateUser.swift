//
//  CreateUser.swift
//
//  Created by Nguyễn Trường Thịnh on 13/07/2022.
//
import Fluent

struct CreateUser: Migration {
    /// Create the users table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .id()
            .field(User.v18082022.name, .string, .required)
            .field(User.v18082022.username, .string, .required)
            .field(User.v18082022.password, .string, .required)
            .field(User.v18082022.email, .string, .required)
            .field(User.v18082022.profileImage, .string)
            .unique(on: User.v18082022.username)
            .unique(on: User.v18082022.email)
            .create()
    }
    /// Deletes the table named users
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName).delete()
    }
}

extension User {
    enum v18082022 {
        static let schemaName = "users"
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
        static let email = FieldKey(stringLiteral: "email")
        static let profileImage = FieldKey(stringLiteral: "profileImage")
    }
    enum v19082022 {
        static let faceBookURL = FieldKey(stringLiteral: "faceBookURL")
    }
    enum v29082022 {
        static let deleted_at = FieldKey(stringLiteral: "deleted_at")
        static let userType = FieldKey(stringLiteral: "userType")
    }
}

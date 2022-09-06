//
//  CreateResetPasswordToken.swift
//
//  Created by Nguyễn Trường Thịnh on 17/08/2022.
//

import Fluent

struct CreateResetPasswordToken: Migration {
    /// Create the esetPasswordTokens table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("resetPasswordTokens")
            .id()
            .field("token", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .unique(on: "token")
            .create()
    }
    /// Deletes the table named resetPasswordTokens
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("resetPasswordTokens").delete()
    }
}

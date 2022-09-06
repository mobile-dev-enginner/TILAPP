//
//  19-08-22-AddFacebookToUser.swift
//
//
//  Created by Nguyễn Trường Thịnh on 18/08/2022.
//

import Fluent

struct AddFacebookURLToUser: Migration {
    /// Create the faceBookURL column in the users table
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .field(User.v19082022.faceBookURL, .string)
            .update()
    }
    /// Deletes the column named faceBookURL in the users table
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .deleteField(User.v19082022.faceBookURL)
            .update()
    }
}

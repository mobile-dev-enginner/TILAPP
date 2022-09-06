//
//  29-08-22-AddDeletedAtToUser.swift
//
//
//  Created by Nguyễn Trường Thịnh on 29/08/2022.
//

import Fluent

struct AddDeletedAtToUser: Migration {
    /// Create the deleted_at column in the users table
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .field(User.v29082022.deleted_at, .datetime)
            .update()
    }
    /// Deletes the column named deleted_at in the users table
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .deleteField(User.v29082022.deleted_at)
            .update()
    }
}

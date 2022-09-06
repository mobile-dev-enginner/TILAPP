//
//  29-08-22-AddUserTypeToUser.swift
//
//
//  Created by Nguyễn Trường Thịnh on 29/08/2022.
//

import Fluent

struct AddUserTypeToUser: Migration {
    /// Add the userType columns in the users table
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("userType")
            .case("admin")
            .case("standard")
            .case("restricted")
            .create().flatMap { userType in
                database.schema(User.v18082022.schemaName)
                    .field(User.v29082022.userType, userType, .required)
                    .update()
            }
    }
    /// Deletes the column named userType in the users table
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v18082022.schemaName)
            .deleteField(User.v29082022.userType)
            .update()
    }
}

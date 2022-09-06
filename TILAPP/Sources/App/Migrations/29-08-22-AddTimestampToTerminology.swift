//
//  29-08-22-AddTimestampToTerminology.swift
//
//
//  Created by Nguyễn Trường Thịnh on 29/08/2022.
//

import Fluent

struct AddTimestampToTerminology: Migration {
    /// Create Timestamps columns in the terminologies table
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Terminology.v19082022.schemaName)
            .field(Terminology.v29082022.created_at, .string)
            .field(Terminology.v29082022.updated_at, .string)
            .update()
    }
    /// Deletes the column named deleted_at, updated_at in the terminologies table
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Terminology.v19082022.schemaName)
            .deleteField(Terminology.v29082022.created_at)
            .deleteField(Terminology.v29082022.updated_at)
            .update()
    }
}


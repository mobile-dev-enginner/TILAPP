//
//  CreateTerminology.swift
//
//  Created by Nguyễn Trường Thịnh on 12/07/2022.
//
import Fluent

struct CreateTerminology: Migration {
    /// Create the terminologies table in the database with columns
    func prepare(on databse: Database) -> EventLoopFuture<Void> {
        databse.schema(Terminology.v19082022.schemaName)
            .id()
            .field(Terminology.v19082022.short, .string, .required)
            .field(Terminology.v19082022.long, .string, .required)
            .field(Terminology.v19082022.userID, .uuid, .required,
                    .references(User.v18082022.schemaName, User.v18082022.id)
            ) // the users-terminologies foreign key constraint
            .create()
    }
    /// Deletes the table named terminologies
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Terminology.v19082022.schemaName).delete()
    }
}

extension Terminology {
    enum v19082022 {
        static let schemaName = "terminologies"
        static let id = FieldKey(stringLiteral: "id")
        static let short = FieldKey(stringLiteral: "short")
        static let long = FieldKey(stringLiteral: "long")
        static let userID = FieldKey(stringLiteral: "userID")
    }

    enum v29082022 {
        static let created_at = FieldKey(stringLiteral: "created_at")
        static let updated_at = FieldKey(stringLiteral: "updated_at")
    }
}

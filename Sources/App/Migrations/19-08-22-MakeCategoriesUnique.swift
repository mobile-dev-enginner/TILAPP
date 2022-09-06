//
//  19-08-22-MakeCategoriesUnique.swift
//
//
//  Created by Nguyễn Trường Thịnh on 18/08/2022.
//

import Fluent

struct MakeCategoriesUnique: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v18082022.schemaName)
            .unique(on: Category.v18082022.name)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v18082022.schemaName)
            .deleteUnique(on: Category.v18082022.name)
            .update()
    }
}

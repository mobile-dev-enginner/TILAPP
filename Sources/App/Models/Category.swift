//
//  Categogy.swift
//
//  Created by Nguyễn Trường Thịnh on 15/07/2022.
//
import Fluent
import Vapor

final class Category: Model, Content {
//    static let schema = "categories"
    static let schema = Category.v18082022.schemaName

    @ID
    var id: UUID?

//    @Field(key: "name")
    @Field(key: Category.v18082022.name)
    var name: String

    @Siblings(through: TermCatePivot.self, from: \.$category, to: \.$terminology)
    var terminologies: [Terminology]

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

/// Allow users to manage categories
extension Category {
    static func addCategory(_ name: String, to terminology: Terminology, on req: Request) ->
    EventLoopFuture<Void> {
        Category
            .query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { fCategory in
                if let eCategory = fCategory {
                    return terminology.$categories.attach(eCategory, on: req.db)
                } else {
                    let category = Category(name: name)
                    return category.save(on: req.db).flatMap {
                        terminology.$categories.attach(category, on: req.db)
                    }
                }
            }
    }
}

//
//  TermCatePivot.swift
//
//  Created by Nguyễn Trường Thịnh on 15/07/2022.
//
import Fluent
import Foundation

final class TermCatePivot: Model {
//    static let schema = "terminology-category-pivot"
    static let schema = TermCatePivot.v18082022.schemaName

    @ID
    var id: UUID?

//    @Parent(key: "terminologyID")
    @Parent(key: TermCatePivot.v18082022.terminologyID)
    var terminology: Terminology

//    @Parent(key: "categoryID")
    @Parent(key: TermCatePivot.v18082022.categoryID)
    var category: Category

    init() { }

    init (id: UUID? = nil, term: Terminology, cate: Category) throws {
        self.id = id
        self.$terminology.id = try term.requireID()
        self.$category.id = try cate.requireID()
    }
}

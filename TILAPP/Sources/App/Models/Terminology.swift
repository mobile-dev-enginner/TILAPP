//
//  Terminology.swift
//
//  Created by Nguyễn Trường Thịnh on 12/07/2022.
//
import Vapor
import Fluent

final class Terminology: Model {
//    static let schema = "terminologies"
    static let schema = Terminology.v19082022.schemaName

    @ID
    var id: UUID?

//    @Field(key: "short")
    @Field(key: Terminology.v19082022.short)
    var short: String

    @Field(key: Terminology.v19082022.long)
    var long: String

    @Parent(key: Terminology.v19082022.userID)
    var user: User

    @Siblings(
        through: TermCatePivot.self,
        from: \.$terminology,
        to: \.$category
    )
    var categories: [Category]

    @Timestamp(key: Terminology.v29082022.created_at, on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: Terminology.v29082022.updated_at, on: .update, format: .iso8601)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
        self.id = id
        self.short = short
        self.long = long
        self.$user.id = userID
    }
}

extension Terminology: Content {}

//
//  Token.swift
//
//
//  Created by Nguyễn Trường Thịnh on 12/08/2022.
//

import Vapor
import Fluent
import Foundation

/// Token authentication
final class Token: Model, Content {
    static let schema = "tokens"

    @ID
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "userID")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension Token: ModelTokenAuthenticatable {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    typealias User = App.User
    var isValid: Bool {
        true
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userID: user.requireID())
    }
}

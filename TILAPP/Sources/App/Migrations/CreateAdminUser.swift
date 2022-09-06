//
//  CreateAdminUser.swift
//
//
//  Created by Nguyễn Trường Thịnh on 13/08/2022.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
    /// Create the admin table in the database with columns
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String

        do {
            passwordHash = try Bcrypt.hash("password")
        } catch {
            return database.eventLoop.future(error: error)
        }

        let user = User(name: "Super Admin", username: "admin", password: passwordHash, email: "admin@localhost.local", userType: .admin)
        return user.save(on: database)
    }
    /// Deletes the table named admin
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$username == "admin").delete()
    }
}

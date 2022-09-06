//
//  UserMiddleware.swift
//
//  Created by Nguyễn Trường Thịnh on 29/08/2022.
//

import Fluent
import Vapor

struct UserMiddleware: ModelMiddleware {
    func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        User
            .query(on: db).filter(\.$username == model.username).count()
            .flatMap { i in
                guard i == 0 else {
                    return db.eventLoop.future(error: Abort(.badRequest, reason: "Username already exists!"))
                }
                return next.create(model, on: db).map {
                    db.logger.debug("Created user with username \(model.username)")
                }
            }
    }
}

//
//  TerminologiesController.swift
//
//  Created by Nguyễn Trường Thịnh on 13/07/2022.
//
import Vapor
import Fluent
import SQLKit

struct TerminologiesController: RouteCollection {
    /// Register route handlers
    func boot(routes: RoutesBuilder) throws {
        // A route group for the path /api/terminologies.
        let terminologiesRoutes = routes.grouped("api", "terminologies")
        // A basic authentication middleware
        let tokenAuthMiddleware = Token.authenticator()
        // Ensures that requests contain valid authorization
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = terminologiesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

        // Register a new authenticated route at /api/terminologies for create a single terminology
        tokenAuthGroup.post(use: createHandler)
        // Register a new authenticated route at /api/terminologies/<ID> for remove a single terminology.
        tokenAuthGroup.delete(":terminologyID", use: deleteHandler)
        // Register a new authenticated route at /api/terminologies/<ID> for update a single terminology.
        tokenAuthGroup.put(":terminologyID", use: updateHandler)
        // Register a new authenticated route at /api/terminologies/<term_id>/categories/<cate_id> for setting up
        // the relationship between terminology & category.
        tokenAuthGroup.post(":terminologyID", "categoies", ":categoryID", use: addCategoriesHandler)
        // Register a new authenticated route at /api/terminologies/<term_id>/categories/<cate_id>
        // for remove the relationship between terminology & category.
        tokenAuthGroup.delete(":terminologyID", "categories", ":categoryID", use: removeCategoriesHandler)
        // Register a new route at /api/terminologies for retrieve all terminologies.
        terminologiesRoutes.get(use: getAllHandler)
        // Register a new route at /api/terminologies/<ID> for retrieve a single terminology.
        terminologiesRoutes.get(":terminologyID", use: getHandler)
        // Register a new route at /api/terminologies/search for retrieve the search term (search all the terminologies).
        terminologiesRoutes.get("search", use: searchHandler)
        // Register a new route at /api/terminologies/first for retrieve the first result.
        terminologiesRoutes.get("first", use: getFirstHandler)
        // Register a new route at /api/terminologies/sorted for sort the results of queries before returning them.
        terminologiesRoutes.get("sorted", use: sortedHandler)
        // Register a new route at /api/terminologies/<id>/user for retrieve the user
        terminologiesRoutes.get(":terminologyID", "user", use: getUserHandler)
        // Register a new route at /api/terminologies/<id>/categories for retrieve the categories list.
        terminologiesRoutes.get(":terminologyID", "categories", use: getCategoriesHandler)
        // Register a new route at /api/terminologies/mostRecent for retrieve most recent terminologies.
        terminologiesRoutes.get("mostRecent", use: getMostRecent)
        // Register a new route at /api/terminologies/raw for retrieve terminologies with raw query.
        terminologiesRoutes.get("raw", use: getAllTerminologiesRaw)
    }
    /// A route handler: Makes a GET request to /api/terminologies
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Terminology]> {
        Terminology.query(on: req.db).all()
    }
    /// A route handler: Makes a POST request to /api/terminologies
    func createHandler(_ req: Request) throws -> EventLoopFuture<Terminology> {
//        let term = try req.content.decode(Terminology.self)
//        return term.save(on: req.db).map { term }

        let termData = try req.content.decode(CreateTermData.self)
        let user = try req.auth.require(User.self)
        let term = try Terminology(
            short: termData.short,
            long: termData.long,
            userID: user.requireID()
        )
        return term.save(on: req.db).map{ term }
    }
    /// A route handler: Makes a GET request to /api/terminologies/<ID>
    func getHandler(_ req: Request) throws -> EventLoopFuture<Terminology> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    /// A route handler: Makes a GET request to /api/terminologies/mostRecent
    func getMostRecent(_ req: Request) -> EventLoopFuture<[Terminology]> {
        Terminology.query(on: req.db).sort(\.$updatedAt, .descending).all()
    }
    /// A route handler: Makes a GET request to /api/terminologies/raw
    func getAllTerminologiesRaw(_ req: Request) throws -> EventLoopFuture<[Terminology]> {
        guard let query = req.db as? SQLDatabase else {
            throw Abort(.internalServerError)
        }
        return query.raw("SELECT * FROM terminologies").all(decoding: Terminology.self)
    }
    /// A route handler: Makes a PUT request to /api/terminologies/<ID>
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Terminology> {
        let updateData = try req.content.decode(CreateTermData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap{ term in
                term.short = updateData.short
                term.long = updateData.long
                term.$user.id = userID
                return term.save(on: req.db).map { term }
            }
//        let updatedTerm = try req.content.decode(Terminology.self)
//        return Terminology
//            .find(req.parameters.get("terminologyID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//            .flatMap { term in
//                term.short = updatedTerm.short
//                term.long = updatedTerm.long
//                return term.save(on: req.db).map { term }
//            }
    }
    /// A route handler: Makes a DELETE request to /api/terminologies/<ID>
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                term.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    /// A route handler: Makes a GET request to /api/terminologies/search
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Terminology]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Terminology
            .query(on: req.db)
            .group(.or) { or in
                or.filter(\.$short == searchTerm)
                or.filter(\.$long == searchTerm)
            }.all()
    }
    /// A route handler: Makes a GET request to /api/terminologies/first
    func getFirstHandler(_ req: Request) throws -> EventLoopFuture<Terminology> {
        return Terminology
            .query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    /// A route handler: Makes a GET request to /api/terminologies/sorted
    func sortedHandler(_ req: Request) throws -> EventLoopFuture<[Terminology]> {
        return Terminology
            .query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }
    /// A route handler: Makes a GET request to /api/terminologies/<id>/user
    func getUserHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                term.$user.get(on: req.db).convertToPublic()
            }
    }
    /// A route handler: Makes a POST request to /api/terminologies/<term_id>/categories/<cate_id>
    func addCategoriesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let termQuery = Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let cateQuery = Category
            .find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return termQuery.and(cateQuery)
            .flatMap { term, cate in
                term
                    .$categories
                    .attach(cate, on: req.db)
                    .transform(to: .created)
            }
    }
    /// A route handler: Makes a GET request to /api/terminologies/<ID>/categories
    func getCategoriesHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                term.$categories.query(on: req.db).all()
            }
    }
    /// A route handler: Makes a DELETE request to /api/terminologies/<termID>/categories/<cateID>
    func removeCategoriesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let termQuery = Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let cateQuery = Category
            .find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return termQuery.and(cateQuery).flatMap { term, cate in
            term
                .$categories
                .detach(cate, on: req.db)
                .transform(to: .noContent)
        }
    }
}

/// A  DTO will be converted into something by a route handler
struct CreateTermData: Content {
    let short: String
    let long: String
//    let userID: UUID
}

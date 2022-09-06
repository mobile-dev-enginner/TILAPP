//
//  UsersController.swift
//
//  Created by Nguyễn Trường Thịnh on 13/07/2022.
//
import Vapor
import Fluent

struct UsersController: RouteCollection {
    /// Register route handlers
    func boot(routes: RoutesBuilder) throws {
        // A route group for the path /api/users.
        let usersRoutes = routes.grouped("api", "users")
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

        // Register a new authenticated route at /api/users for create a single user.
        tokenAuthGroup.post(use: createHandler)
        // Register a new authenticated route at /api/users/<id> for soft delete a single user.
        tokenAuthGroup.delete(":userID", use: deleteHandler)
        // Register a new authenticated route at /api/users/<id>/force for force delete a single user.
        tokenAuthGroup.delete(":userID", "force", use: forceDeleteHandler)
        // Register a new authenticated route at /api/users/<UUID> for restore a single user.
        tokenAuthGroup.post(":userID", "restore", use: restoreHandler)
        // Register a new route at /api/users for retrieve all users.
        usersRoutes.get(use: getAllHandler)
        // Register a new route at /api/users/<id> for retrieve a single user.
        usersRoutes.get(":userID", use: getHandler)
        // Register a new route at /api/users/<id>/terminologies for retrieve terminologies list.
        usersRoutes.get(":userID", "terminologies", use: getTermsHandler)

        // API version 2 Routes
        let usersV2Routes = routes.grouped("api", "v2", "users")
        // Register a new route at /api/v3/users/<id> for retrieve a single user.
        usersV2Routes.get(":userID", use: getV2Handler)

        // API version 3 Routes
        let usersV3Routes = routes.grouped("api", "v3", "users")
        // Register a new route at /api/v3/users/<id> for retrieve a single user.
        usersV3Routes.get(":userID", use: getV3Handler)
        // Register a new route at /api/v3/users/<id>/terminologies/mostRecentTerminology for retrieve a single user with most recent terminologies.
        usersV3Routes.get("mostRecentTerminology", use: getUserWithMostRecentTerminology)
    }
    /// A route handler: for logging a user in.
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }
    /// A route handler: Makes a GET request to /api/users
    func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }
    /// A route handler: Makes a POST request to /api/users
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: req.db).map { user.convertToPublic() }
    }
    /// A route handler: Makes a GET request to /api/users/<ID>
    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }
    /// A route handler: Makes a GET request to /api/v2/users/<ID>
    func getV2Handler(_ req: Request) -> EventLoopFuture<User.PublicV2> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublicV2()
    }
    /// A route handler: Makes a GET request to /api/v3/users/<ID>
    func getV3Handler(_ req: Request) -> EventLoopFuture<User.PublicV3> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublicV3()
    }
    /// A route handler: Makes a GET request to /api/users/<ID>/terminologies
    func getTermsHandler(_ req: Request) -> EventLoopFuture<[Terminology]> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$terminologies.get(on: req.db)
            }
    }
    /// A route handler: Makes a GET request to /api/v3/users/<ID>/terminologies/mostRecentTerminology
    func getUserWithMostRecentTerminology(_ req: Request) -> EventLoopFuture<User.PublicV3> {
        User.query(on: req.db)
            .join(Terminology.self, on: \Terminology.$user.$id == \User.$id)
            .sort(Terminology.self, \Terminology.$createdAt, .descending)
            .first()
            .unwrap(or: Abort(.internalServerError)).convertToPublicV3()
    }
    /// A route handler: Makes a DELETE request to /api/users/<id>
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let reqUser = try req.auth.require(User.self)
        guard reqUser.userType == .admin else {
            throw Abort(.forbidden)
        }

        return User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.delete(on: req.db).transform(to: .noContent)
            }
    }
    /// A route handler: Makes a DELETE request to /api/users/<id>/force
    func forceDeleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.delete(force: true, on: req.db).transform(to: .noContent)
            }
    }
    /// A route handler: Makes a POST request to /api/users/<UUID>/restore
    func restoreHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userID = try req.parameters.require("userID", as: UUID.self)
        return User
            .query(on: req.db)
            .withDeleted()
            .filter(\.$id == userID).first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
            user.restore(on: req.db).transform(to: .ok)
        }
    }
}

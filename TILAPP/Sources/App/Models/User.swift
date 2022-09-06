//
//  User.swift
//
//  Created by Nguyễn Trường Thịnh on 13/07/2022.
//
import Vapor
import Fluent

final class User: Model, Content {
//    static let schema = "users"
    static let schema = User.v18082022.schemaName

    @ID
    var id: UUID?

//    @Field(key: "name")
    @Field(key: User.v18082022.name)
    var name: String

    @Field(key: User.v18082022.username)
    var username: String

    @Field(key: User.v18082022.password)
    var password: String

    @Children(for: \Terminology.$user)
    var terminologies: [Terminology]

    @Field(key: User.v18082022.email)
    var email: String

    @OptionalField(key: User.v18082022.profileImage)
    var profileImage: String?

    @OptionalField(key: User.v19082022.faceBookURL)
    var faceBookURL: String?

    @Timestamp(key: User.v29082022.deleted_at, on: .delete)
    var deletedAt: Date?

    @Enum(key: User.v29082022.userType)
    var userType: UserType

    init() { }

    init(id: UUID? = nil, name: String, username: String, password: String, email: String, userType: UserType = .standard, profileImage: String? = nil, faceBookURL: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.email = email
        self.userType = userType
        self.profileImage = profileImage
        self.faceBookURL = faceBookURL
    }
    /// An inner class to represent a public view of User.
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String

        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }

    final class PublicV2: Content {
        var id: UUID?
        var name: String
        var username: String
        var profileImage: String?
        var faceBookURL: String?

        init(id: UUID?, name: String, username: String, profileImage: String? = nil, faceBookURL: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            self.profileImage = profileImage
            self.faceBookURL = faceBookURL
        }
    }

    final class PublicV3: Content {
        var id: UUID?
        var name: String
        var username: String
        var userType: UserType
        var profileImage: String?
        var faceBookURL: String?

        init(id: UUID?, name: String, username: String, userType: UserType, profileImage: String? = nil, faceBookURL: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            self.userType = userType
            self.profileImage = profileImage
            self.faceBookURL = faceBookURL
        }
    }
}

extension User: ModelSessionAuthenticatable {}

extension User: ModelCredentialsAuthenticatable {}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        return self.map { $0.convertToPublic() }
    }

    func convertToPublicV2() -> EventLoopFuture<[User.PublicV2]> {
        return self.map { $0.convertToPublicV2() }
    }

    func convertToPublicV3() -> EventLoopFuture<[User.PublicV3]> {
        return self.map { $0.convertToPublicV3() }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic()}
    }

    func convertToPublicV2() -> [User.PublicV2] {
        return self.map { $0.convertToPublicV2() }
    }

    func convertToPublicV3() -> [User.PublicV3] {
        return self.map { $0.convertToPublicV3() }
    }
}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { user in
            return user.convertToPublic()
        }
    }

    func convertToPublicV2() -> EventLoopFuture<User.PublicV2> {
        return self.map { user in
            return user.convertToPublicV2()
        }
    }

    func convertToPublicV3() -> EventLoopFuture<User.PublicV3> {
        return self.map { user in
            return user.convertToPublicV3()
        }
    }
}

extension User {
    /// Return User.Public (a public verison of the current object)
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
    /// Return User.PublicV2 (the 2nd  public verison of the current object)
    func convertToPublicV2() -> User.PublicV2 {
        return User.PublicV2(id: id, name: name, username: username, profileImage: profileImage, faceBookURL: faceBookURL)
    }

    /// Return User.PublicV3 (the 3rd  public verison of the current object)
    func convertToPublicV3() -> User.PublicV3 {
        return User.PublicV3(id: id, name: name, username: username, userType: userType, profileImage: profileImage, faceBookURL: faceBookURL)
    }
}



//
//  WebsiteController.swift
//
//  Created by Nguyễn Trường Thịnh on 22/07/2022.
//
import Vapor
import Fluent
import SendGrid

/// Hold all the website routes
struct WebsiteController: RouteCollection {
    let imageFolder = "ProfileImages/"

    func boot(routes: RoutesBuilder) throws {
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        // Register a new route at /register for render the register template (registration page)
        authSessionsRoutes.get("register", use: registerHandler)
        // Register a new route at /register for automatically logs users in when they register (signing up with the site)
        authSessionsRoutes.post("register", use: registerPostHandler)
        // Register a new route at /login for render the login template
        authSessionsRoutes.get("login", use: loginHandler)
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        // Register a new route at /login for Vapor persists authentication (verify & save the authenticated User into the request's session) when a user logs in
        credentialsAuthRoutes.post("login", use: loginPostHandler)
        // Register a new route at /logout for Vapor persists authentication (deletes the user from the session) when a user logs out
        authSessionsRoutes.post("logout", use: logoutHandler)
        // Register a new route at /forgottenPassword for render the forgottenPassword template
        authSessionsRoutes.get("forgottenPassword", use: forgottenPasswordHandler)
        // Register a new route at /forgottenPassword for the POST request to send emails, that returns a view
        authSessionsRoutes.post("forgottenPassword", use: forgottenPasswordPostHandler)
        // Register a new route at /resetPassword for render the resetPassword template
        authSessionsRoutes.get("resetPassword", use: resetPasswordHandler)
        // Register a new route at /resetPassword for the POST request to handle the POST request from the form
        authSessionsRoutes.post("resetPassword", use: resetPasswordPostHandler)

        // Register a new route at / for render the index template
        authSessionsRoutes.get(use: indexHandler)
        // Register a new route at /terminologies/<id>/ for render the terminolgy template
        authSessionsRoutes.get("terminologies", ":terminologyID", use: termHandler)
        // Register a new route at /user/<id>/ for render the user template
        authSessionsRoutes.get("users", ":userID", use: userHandler)
        // Register a new route at /user/<id>/profileImage to serve the image back to the browser
        authSessionsRoutes.get("users", ":userID", "profileImage", use: getUsersProfileImageHandler)
        // Register a new route at /user/for render the allUsers template
        authSessionsRoutes.get("users", use: allUsersHandler)
        // Register a new route at /categories/ for render the allCategories template
        authSessionsRoutes.get("categories", use: allCatesHandler)
        // Register a new route at /categories/<id> for render the category template
        authSessionsRoutes.get("categories", ":categoryID", use: cateHandler)

        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        // Register a new route at /terminologies/ for render the createTerminology template
        protectedRoutes.get("terminologies", "create", use: createTermHandler)
        // Register a new route at /terminologies/ for create a terminology & render terminolgy template
        protectedRoutes.post("terminologies", "create", use: createTermPostHandler)
        // Register a new route at /terminologies/ for render the editTerminology template
        protectedRoutes.get("terminologies", ":terminologyID", "edit", use: editTermHandler)
        // Register a new route at /terminologies/ for edit a terminology & render the terminolgy template
        protectedRoutes.post("terminologies", ":terminologyID", "edit", use: editTermPostHandler)
        // Register a new route at /terminologies/ for delete a terminology & render the index template
        protectedRoutes.post("terminologies", ":terminologyID", "delete", use: deleteTermHandler)
        // Register a new route at /users/<id>/addProfileImage for render the addProfileImage.leaf template
        protectedRoutes.get("users", ":userID", "addProfileImage", use: addProfileImageHandler)
        // Register a new route at /users/<id>/addProfileImage for save the update user with profile image & render the user's page
        protectedRoutes.on(.POST, "users", ":userID", "addProfileImage", body: .collect(maxSize: "7mb"), use: addProfileImagePostHandler)
    }
    /// A route handler: Makes a GET request to /register
    func registerHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return req.view.render("register", context)
    }
    /// A route handler: Makes a POST request to /register & redirct to the home page
    func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        do {
            try RegisterData.validate(content: req)
        } catch let error as ValidationsError {
            let message = error
                .description
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
            return req.eventLoop.future(req.redirect(to: "/register?message=\(message)"))
        }

        let data = try req.content.decode(RegisterData.self)
        let password = try Bcrypt.hash(data.password)
        var faceBookURL: String?
        if let facebook = data.faceBookURL, !facebook.isEmpty {
            faceBookURL = facebook
        }
        let user = User(
            name: data.name,
            username: data.username,
            password: password,
            email: data.emailAddress,
            faceBookURL: faceBookURL
        )
        return user.save(on: req.db).map {
            req.auth.login(user)
            return req.redirect(to: "/")
        }
    }


    /// A route handler: Makes a GET request to /login
    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return req.view.render("login", context)
    }
    /// A route handler: Makes a POST request to /login & redirct to the home page
    func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            let context = LoginContext(loginError: true)
            return req.view.render("login", context).encodeResponse(for: req)
        }
    }
    /// A route handler: Makes a POST request to returns Response & redirct to the home page
    func logoutHandler(_ req: Request) -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
    /// A route handler: Makes a GET request to /forgottenPassword
    func forgottenPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
        req.view.render("forgottenPassword", ["title": "Reset Your Password"])
    }
    /// A route handler: Makes a POST request to /forgottenPassword & return the forgottenPasswordConfirmed template
    func forgottenPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let email = try req.content.get(String.self, at: "email")
        return User.query(on: req.db).filter(\.$email == email).first().flatMap { user in
            guard let user = user else {
                return req.view.render("forgottenPasswordConfirmed", ["title": "Password Reset Email Sent"])
            }
            let resetTokenString = Data([UInt8].random(count: 32)).base32EncodedString()
            let resetToken: ResetPasswordToken
            do {
                resetToken = try ResetPasswordToken(token: resetTokenString, userID: user.requireID())
            } catch {
                return req.eventLoop.future(error: error)
            }
            return resetToken.save(on: req.db).flatMap {
                let emailContent = """
                <p>
                    You've requested to reset your password.
                    <a href="http://localhost:8080/resetPassword?\token=\(resetTokenString)">
                    Click here
                    </a> to reset your password.
                </p>
                """
                let emailAddress = EmailAddress(email: user.email, name: user.name)
                let fromEmail = EmailAddress(email: "nguyentruongthinhvn2020@gmail.com", name: "TIL Microservices")
                let emailConfig = Personalization(to: [emailAddress], subject: "Reset Your Password")
                let email = SendGridEmail(
                    personalizations: [emailConfig],
                    from: fromEmail,
                    content: [["type": "text/html", "value": emailContent]])
                let emailSend: EventLoopFuture<Void>
                do {
                    emailSend = try req.application.sendgrid.client.send(email: email, on: req.eventLoop)
                } catch {
                    return req.eventLoop.future(error: error)
                }
                return emailSend.flatMap {
                    req.view.render("forgottenPasswordConfirmed", ["title": "Password Reset Email Sent"])
                }
            }
        }
    }
    /// A route handler: Makes a GET request to /resetPassword to handle the link from the email
    func resetPasswordHandler(_ req: Request) -> EventLoopFuture<View> {
        guard let token = try? req.query.get(String.self, at: "token") else {
            return req.view.render("resetPassword", ResetPasswordContext(error: true))
        }
        return ResetPasswordToken.query(on: req.db).filter(\.$token == token).first()
            .unwrap(or: Abort.redirect(to: "/"))
            .flatMap { token in
                token.$user.get(on: req.db).flatMap { user in
                    do {
                        try req.session.set("ResetPasswordUser", to: user)
                    } catch {
                        return req.eventLoop.future(error: error)
                    }
                    return token.delete(on: req.db)
                }
            }.flatMap {
                req.view.render("resetPassword", ResetPasswordContext())
            }
    }
    /// A route handler: To handle the POST request from the form
    func resetPasswordPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(ResetPasswordData.self)
        guard data.password == data.confirmPassword else {
            return req.view.render("resetPassword", ResetPasswordContext(error: true))
                .encodeResponse(for: req)
        }
        let resetPassworduser = try req.session.get("ResetPasswordUser", as: User.self)
        req.session.data["ResetPasswordUser"] = nil
        let newPassword = try Bcrypt.hash(data.password)
        return try User
            .query(on: req.db)
            .filter(\.$id == resetPassworduser.requireID())
            .set(\.$password, to: newPassword)
            .update()
            .transform(to: req.redirect(to: "/login"))
    }
    /// A route handler: Makes a GET request to /users/<ID>/profileImage
    func getUsersProfileImageHandler(_ req: Request) -> EventLoopFuture<Response> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { user in
                guard let filename = user.profileImage else {
                    throw Abort(.notFound)
                }
                let path = req.application.directory.workingDirectory + imageFolder + filename
                return req.fileio.streamFile(at: path)
            }
    }
    /// A route handler: Makes a GET request to /users/<ID>/addProfileImage
    func addProfileImageHandler(_ req: Request) -> EventLoopFuture<View> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                req.view.render("addProfileImage", ["title": "Add Profile Image", "username": user.name])
            }
    }
    /// A route handler: To handle the POST request for upadate the user with the profile image file name
    func addProfileImagePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(ImageUploadData.self)
        return User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                let userID: UUID
                do {
                    userID = try user.requireID()
                } catch {
                    return req.eventLoop.future(error: error)
                }
                let name = "\(userID)-\(UUID()).jpg"
                let path = req.application.directory.workingDirectory + imageFolder + name
                user.profileImage = name
                return req.fileio.writeFile(.init(data: data.picture), at: path).flatMap {
                    let redirect = req.redirect(to: "/users/\(userID)")
                    return user.save(on: req.db).transform(to: redirect)
                }
            }
    }
    /// A route handler: Makes a GET request to / (root path)
    func indexHandler (_ req: Request) -> EventLoopFuture<View> {
        Terminology
            .query(on: req.db)
            .all()
            .flatMap { terms in
                let userLoggedIn = req.auth.has(User.self)
                let showCookieMessage = req.cookies["cookies-accepted"] == nil
                let context = IndexContext(title: "Home", terminologies: terms,
                                           userLoggedIn: userLoggedIn, showCookieMessage: showCookieMessage)
                return  req.view.render("index", context)
        }
    }
    /// A route handler: Makes a GET request to /terminologies/<id>/
    func termHandler(_ req: Request) -> EventLoopFuture<View> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                let userFuture = term.$user.get(on: req.db)
                let categoriesFuture = term.$categories.query(on: req.db).all()
                return  userFuture.and(categoriesFuture).flatMap { user, categories in
                    let context = TermContext(
                        title: term.short,
                        terminology: term,
                        user: user,
                        categories: categories)
                    return req.view.render("terminology", context)
                }
        }
    }
    /// A route handler: Makes a GET request to /users/<id>/
    func userHandler(_ req: Request) -> EventLoopFuture<View> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$terminologies.get(on: req.db).flatMap { terms in
                    let loggedInUser = req.auth.get(User.self)
                    let context = UserContext(
                        title: user.name,
                        user: user,
                        terminologies: terms,
                        authenticatedUser: loggedInUser
                    )
                    return req.view.render("user", context)
                }
            }
    }
    /// A route handler: Makes a GET request to /users/
    func allUsersHandler(_ req: Request) -> EventLoopFuture<View> {
        User
            .query(on: req.db)
            .all()
            .flatMap { users in
                let context = AllUsersContext(
                    title: "All Users", users: users
                )
                return req.view.render("allUsers", context)
            }
    }
    /// A route handler: Makes a GET request to /categories/
    func allCatesHandler(_ req: Request) -> EventLoopFuture<View> {
        Category
            .query(on: req.db)
            .all()
            .flatMap { cates in
                let context = AllCatesContext(categories: cates)
                return req.view.render("allCategories", context)
            }
    }
    /// A route handler: Makes a GET request to /categories/<id>/
    func cateHandler(_ req: Request) -> EventLoopFuture<View> {
        Category
            .find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { cate in
                cate.$terminologies.get(on: req.db).flatMap { terms in
                    let context = CateContext(title: cate.name, category: cate, terminologies: terms)
                    return req.view.render("category", context)
                }
            }
    }
    /// A route handler: Makes a GET request to /terminologies/
    func createTermHandler(_ req: Request) -> EventLoopFuture<View> {
        let token = [UInt8].random(count: 16).base64
        let context = CreateTermContext(csrfToken: token)
        req.session.data["CSRF_TOKEN"] = token
        return req.view.render("createTerminology", context)
//        User
//            .query(on: req.db)
//            .all()
//            .flatMap { users in
//                let context = CreateTermContext(users: users)
//                return req.view.render("createTerminology", context)
//            }
    }
    /// A route handler: Makes a POST request to /terminologies/
    func createTermPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
//        let data = try req.content.decode(CreateTermData.self)
        let data = try req.content.decode(CreateTermFormData.self)
        let user = try req.auth.require(User.self)
        let expectedToken = req.session.data["CSRF_TOKEN"]

        req.session.data["CSRF_TOKEN"] = nil

        guard
            let csrfToken = data.csrfToken,
            expectedToken == csrfToken
        else {
            throw Abort(.badRequest)
        }

        let term = try Terminology(short: data.short, long: data.long, userID: user.requireID())

        return term.save(on: req.db).flatMap {
            guard let id = term.id else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            /// An array of EventLoopFuture to store the save operations
            var categoryStores: [EventLoopFuture<Void>] = []
            for cate in data.categories ?? [] {
                categoryStores.append(Category.addCategory(cate, to: term, on: req))
            }
            let redirect = req.redirect(to: "/terminologies/\(id)")
            /// Flatten the array to complete all the Fluent operations & transform the result to
            /// a response. Redirect the page to the new terminology's page.
            return categoryStores.flatten(on: req.eventLoop).transform(to: redirect)
        }
    }
    /// A route handler: Makes a GET request to /terminologies/<id>/
    func editTermHandler(_ req: Request) -> EventLoopFuture<View> {
//        let termFuture = Terminology
//            .find(req.parameters.get("terminologyID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//        let userQuery = User.query(on: req.db).all()
//        return termFuture.and(userQuery).flatMap { term, users in
//            term.$categories.get(on: req.db).flatMap { categories in
//                let context = EditTermContext(terminology: term, users: users, categories: categories)
//                return req.view.render("createTerminology", context)
//            }
//        }
        return Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                term.$categories.get(on: req.db).flatMap { categories in
                    let context = EditTermContext(terminology: term, categories: categories)
                    return req.view.render("createTerminology", context)
                }
            }
      }
     /// A route handler: Makes a POST request to /terminologies/<id>/
      func editTermPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
//        let updateData = try req.content.decode(CreateTermData.self)
          let user = try req.auth.require(User.self)
          let userID = try user.requireID()
          let updateData = try req.content.decode(CreateTermFormData.self)
        return Terminology
              .find(req.parameters.get("terminologyID"), on: req.db)
              .unwrap(or: Abort(.notFound))
              .flatMap { term in
                  term.short = updateData.short
                  term.long = updateData.long
                  term.$user.id = userID
                  guard let id = term.id else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                  }
                  return term.save(on: req.db).flatMap {
                      term.$categories.get(on: req.db)
                  }.flatMap { existCategories in
                      let existStringArray = existCategories.map {
                          $0.name
                      }
                      let existSet = Set<String>(existStringArray)
                      let newSet = Set<String>(updateData.categories ?? [])

                      let categoriesToAdd = newSet.subtracting(existSet)
                      let categoriesToRemove = existSet.subtracting(newSet)

                      var categoryResults: [EventLoopFuture<Void>] = []
                      for newCate in categoriesToAdd {
                          categoryResults.append(Category.addCategory(newCate, to: term, on: req))
                      }

                      for cateNameToRemove in categoriesToRemove {
                          let cateToRemove = existCategories.first {
                              $0.name == cateNameToRemove
                          }
                          if let cate = cateToRemove {
                              categoryResults.append(term.$categories.detach(cate, on: req.db))
                          }
                      }
                      let redirect = req.redirect(to: "/terminologies/\(id)")
                      return categoryResults.flatten(on: req.eventLoop).transform(to: redirect)
                  }
        }
      }
    /// A route handler: Makes a POST request to /terminologies/<id>/
    func deleteTermHandler(_ req: Request) -> EventLoopFuture<Response> {
        Terminology
            .find(req.parameters.get("terminologyID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { term in
                term.delete(on: req.db).transform(to: req.redirect(to: "/"))
            }
    }
}

struct RegisterContext: Encodable {
    let title = "Sign Up"
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }
}

struct RegisterData: Content {
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
    let emailAddress: String
    let faceBookURL: String?
}
/// Use Vapor's validation library
/// Apply validation to our models & other types
extension RegisterData: Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .ascii) // except for China, ...
        validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("zipCode", as: String.self, is: .zipCode, required: false)
        validations.add("emailAddress", as: String.self, is: .email)
    }
}

extension ValidatorResults {
    struct ZipCode {
        let isValidZipCode: Bool
    }
}

extension ValidatorResults.ZipCode: ValidatorResult {
    var isFailure: Bool {
        !isValidZipCode
    }

    var successDescription: String? {
        "is a valid zip code"
    }

    var failureDescription: String? {
        "is not a valid zip code"
    }
}

extension Validator where T == String {
    private static var zipCodeRegex: String {
        "^\\d{5}(?:[-\\s]\\d{4})?$"
    }

    public static var zipCode: Validator<T> {
        Validator { input -> ValidatorResult in
            guard
                let range = input.range(of: zipCodeRegex, options: [.regularExpression]),
                range.lowerBound == input.startIndex && range.upperBound == input.endIndex
            else {
                return ValidatorResults.ZipCode(isValidZipCode: false)
            }
            return ValidatorResults.ZipCode(isValidZipCode: true)
        }
    }
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool

    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct ResetPasswordContext: Encodable {
    let title = "Reset Password"
    let error: Bool?

    init(error: Bool? = false) {
        self.error = error
    }
}

struct ResetPasswordData: Content {
    let password: String
    let confirmPassword: String
}

struct ImageUploadData: Content {
    var picture: Data
}

struct IndexContext: Encodable {
    let title: String
    let terminologies: [Terminology]
    let userLoggedIn: Bool
    let showCookieMessage: Bool
}

struct TermContext: Encodable {
    let title: String
    let terminology: Terminology
    let user: User
    let categories: [Category]
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let terminologies: [Terminology]
    let authenticatedUser: User?
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCatesContext: Encodable {
    let title = "All Categories"
    let categories: [Category]
}

struct CateContext: Encodable {
    let title: String
    let category: Category
    let terminologies: [Terminology]
}

struct CreateTermContext: Encodable {
    let title = "New Terminology"
    let csrfToken: String
//    let users: [User]
}

struct EditTermContext: Encodable {
    let title = "Edit Terminology"
    let terminology: Terminology
//    let users: [User]
    let editing = true
    let categories: [Category]
}

struct CreateTermFormData: Content {
//    let userID: UUID
    let short: String
    let long: String
    let categories: [String]?
    let csrfToken: String?
}

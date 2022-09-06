import ImperialGoogle
import Vapor
import Fluent
import Foundation

/// Integrating with Web Authentication
struct AuthorLoginController: RouteCollection {
    /// Setting up the Imperial routes
    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
            fatalError("Google callback URL not set!")
        }
        // Triggers the OAuth flow
        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["email", "profile"],
            completion: processGoogleLogon
        )
    }
    /// Handle the Google login
    func processGoogleLogon(req: Request, token: String) throws ->
    EventLoopFuture<ResponseEncodable> {
        try Google.getUser(on: req).flatMap { userInfo in
            User.query(on: req.db).filter(\.$username == userInfo.email).first().flatMap { thisUser in
                guard let exsitingUser = thisUser else {
                    let user = User(
                        name: userInfo.name,
                        username: userInfo.email,
                        password: UUID().uuidString,
                        email: userInfo.email)
                    return user.save(on: req.db).flatMap {
                        req.session.authenticate(user)
                        return generateRedirect(on: req, for: user)
                    }
                }
                req.session.authenticate(exsitingUser)
                return generateRedirect(on: req, for: exsitingUser)
            }
        }
    }

    func generateRedirect(on req: Request, for user: User) -> EventLoopFuture<ResponseEncodable> {
        let redirectURL: EventLoopFuture<String>
        redirectURL = req.eventLoop.future("/")
        req.session.data["oauth_login"] = nil
        return redirectURL.map { url in
            req.redirect(to: url)
        }
    }
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {
    static func getUser(on req: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: req.accessToken())

        let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        return req.client.get(googleAPIURL, headers: headers).flatMapThrowing { res in
            guard res.status == .ok else {
                if res.status == .unauthorized {
                    throw Abort.redirect(to: "/login-google")
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return try res.content.decode(GoogleUserInfo.self)
        }
    }
}

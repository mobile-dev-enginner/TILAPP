import Vapor

struct ServerInfoResponse: Content {
    let startDate: Date
    let platform: String
    let appEnvironment: String
}

struct ServerInfoController: RouteCollection {
    let startDate = Date()

    private let platform: String = {
        #if os(Linux)
        return "Linux"
        #else
        return "macOS"
        #endif
    }()

    func boot(routes: RoutesBuilder) throws {
        routes.get("server-info", use: status)
    }

    func status(_ req: Request) -> ServerInfoResponse {
        ServerInfoResponse(startDate: startDate, platform: platform, appEnvironment: Environment.get("APP_ENVIRONMENT") ?? "unknown")
    }
}

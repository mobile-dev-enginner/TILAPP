import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import SendGrid
//import FluentSQLiteDriver

/// Configures your remote application's database
func configureDatabase(with url: URL, for app: Application) {
    guard let host = url.host, let user = url.user else {
        return
    }

    var config = TLSConfiguration.makeClientConfiguration()
    config.certificateVerification = .none

    let db = url.path.split(separator: "/").last.flatMap(String.init)
    app.databases.use(.postgres(configuration: .init(hostname: host, username: user, password: url.password, database: db, tlsConfiguration: config)), as: .psql)

    if let db = db {
        app.logger.info("Using Postgres DB \(db) at \(host)")
    }
}
/// Configures your local application's database
func configureLocalDatabase(for app: Application) {
    // Support testing
    let databaseName: String
    let databasePort: Int

    if (app.environment == .testing) {
        databaseName = "vapor-test"

        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = "vapor_database"
        databasePort = 5432

    }

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: databasePort,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? databaseName
    ), as: .psql)
}

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)

    if let dbURLString = Environment.get("DATABASE_URL"),
       let url = URL(string: dbURLString) {
        configureDatabase(with: url, for: app)
    } else {
        configureLocalDatabase(for: app)
    }


//    app.databases.use(.sqlite(.memory), as: .sqlite)

    // The migration list in the correct order
    app.migrations.add(CreateUser())
    app.migrations.add(AddDeletedAtToUser())
    app.migrations.add(AddFacebookURLToUser())
    app.migrations.add(AddUserTypeToUser())
    app.migrations.add(CreateTerminology())
    app.migrations.add(AddTimestampToTerminology())
    app.migrations.add(CreateCategory())
    app.migrations.add(MakeCategoriesUnique())
    app.migrations.add(CreateTermCatePivot())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateResetPasswordToken())

    switch app.environment {
        case .development, .testing:
            app.migrations.add(CreateAdminUser())

            if app.environment == .development {
                app.logger.logLevel = .debug
            }
        default:
            break
    }

    app.databases.middleware.use(UserMiddleware(), on: .psql)

    app.http.server.configuration.hostname = "0.0.0.0"

    if let port = Environment.get("PORT").flatMap(Int.init(_:)) {
      app.http.server.configuration.port = port
    }

    try app.autoMigrate().wait()

    app.views.use(.leaf)

    // register routes
    try routes(app)

    app.sendgrid.initialize()
}

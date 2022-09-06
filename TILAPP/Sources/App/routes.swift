import Fluent
import Vapor

func routes(_ app: Application) throws {
    let usersController = UsersController()
    let terminologiesController = TerminologiesController()
    let categoriesController = CategoriesController()
    let websiteController = WebsiteController()
    let authorLoginController = AuthorLoginController()
    let serverInfoController = ServerInfoController()
    // To hook up the routes
    try app.register(collection: usersController)
    try app.register(collection: terminologiesController)
    try app.register(collection: categoriesController)
    try app.register(collection: websiteController)
    try app.register(collection: authorLoginController)
    try app.register(collection: serverInfoController)
}

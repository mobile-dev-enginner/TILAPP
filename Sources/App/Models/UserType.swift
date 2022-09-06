//
//  UserType.swift
//
//  Created by Nguyễn Trường Thịnh on 29/08/2022.
//

/// An UserType enumeration with three types of user access for use in the Vapor application
enum UserType: String, Codable {
    case admin
    case standard
    case restricted
}

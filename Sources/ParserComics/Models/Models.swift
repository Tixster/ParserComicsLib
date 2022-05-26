//
//  Models.swift
//  
//
//  Created by Кирилл Тила on 26.05.2022.
//

import Foundation

public protocol MangaStorage {
    var titles: [Title] { get }
    var nextPage: URL { get }
}

public protocol Title: Codable {
    var title: String { get }
    var cover: URL { get }
    var description: String? { get }
    var author: String { get }
    var link: URL { get }
    var likes: Int { get }
    var views: Int { get }
    var pages: Int { get }
}

public struct MangaData: MangaStorage {
    public let titles: [Title]
    public let nextPage: URL
}

public struct TitleModel: Title {
    public let title: String
    public let cover: URL
    public let description: String?
    public let author: String
    public let link: URL
    public let likes: Int
    public let views: Int
    public let pages: Int
}

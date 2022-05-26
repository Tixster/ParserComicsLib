//
//  ParserComics.swift
//
//
//  Created by Кирилл Тила on 26.05.2022.
//

import Foundation
import SwiftSoup

enum ParseError: Error {
    case linksPageIsNill(String)
    case mangaLinstIsNill(String)
}

extension ParseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .linksPageIsNill(let string):
            return string
        case .mangaLinstIsNill(let string):
            return string
        }
    }
}

public final class ParserComics {

    public init(base url: URL) {
        self.baseURL = url
    }

    private let baseURL: URL
    
    private var session: URLSession = .shared

    /// Получение списка тайтлов
    public func fecthMangaList(url: URL) async throws -> MangaStorage {
        do {
            let data = try await getData(with: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            let content = try doc.select("div[id=content]")
            let titleCount = try content.select("div.content_row")
            var curTitles = [Title]()
            for curTitle in titleCount {
                let titleManga = try curTitle.select("a.title_link").text()
                let coverManga = try curTitle.select("div.manga_images img").attr("src")
                let descriptionManga = try curTitle.select("div.tags").text()
                let author = try curTitle.select("h3.item2").text()
                let titleLink = try curTitle.select("a").attr("href")
                let titleInfo = try curTitle.select("div.row4_left").text()
                let likes = titleInfo.getNumbers(pattern: "\\d+(?=\\s*плюсик)")
                let views = titleInfo.getNumbers(pattern: "\\d+(?=\\s*просмотр)")
                let pages = titleInfo.getNumbers(pattern: "\\d+(?=\\s*страниц)")
                let originalBlurCover = coverManga.replacingOccurrences(of: "_thumbs_blur\\w*",
                                                                        with: "",
                                                                        options: [.regularExpression])
                let originalCover = originalBlurCover.replacingOccurrences(of: "_thumbs\\w*",
                                                                           with: "",
                                                                           options: [.regularExpression])
                curTitles.append(TitleModel(title: titleManga,
                                            cover: URL(string: originalCover)!,
                                            description: descriptionManga,
                                            author: author,
                                            link: URL(string: baseURL.absoluteString + titleLink)!,
                                            likes: likes,
                                            views: views,
                                            pages: pages))
            }
            let nextPage = try doc.select("div[id=pagination] a:contains(Вперед)").attr("href")
            let nextPageURL = url.absoluteString.replacingOccurrences(of: "\\?offset=\\w+", with: "", options: .regularExpression) + nextPage
            let mangaData = MangaData(titles: curTitles, nextPage: URL(string: nextPageURL)!)
            return mangaData
        } catch Exception.Error(type: let type, Message: let message) {
            print("type: \(type), message: \(message)")
        } catch {
            print(error.localizedDescription)
            throw error
        }
        throw ParseError.mangaLinstIsNill("Список манги пустой")
    }
    
    /// Получение следующей страницы с тайтлами
    public func fetchNextPageTitles(url: URL) async throws -> MangaStorage? {
        return try? await fecthMangaList(url: url)
    }
    
    public func fecthDetailTitleInfo(for url: URL) {
        
    }
    
    /**
     Получение ссылок на сканы
     - parameter url: Ссылка на вкладку, октрывающую читалку со страницами.
     - returns: Возвращает массив ссылок на сканы из главы
     */
    public func fetchMangaPagesLink(url: URL) -> [URL]? {
        var str = url.absoluteString
        str = str.replacingOccurrences(of: "/manga/", with: "/online/")
        let newUrl = URL(string: str)!
        
        //  let html = try! String(contentsOf: newUrl, encoding: .utf8)
        do {
            return try fetchPagesLink(url: newUrl)
            //            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            //            let urlReader = try doc.select("div[id=manga_images] a").attr("href")
            //            print("Manga Pages Link: \(urlReader)")
            //            if let url = URL(string: urlReader) {
            //            }
        } catch Exception.Error(type: let type, Message: let message) {
            print("type: \(type), message: \(message)")
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    

}

private extension ParserComics {
    
    func getData(with url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation({ continuaion in
            DispatchQueue.global(qos: .userInteractive).async {
                let task = self.session.dataTask(with: self.createRequest(at: url)) { data, response, error in
                    if let error = error {
                        continuaion.resume(throwing: error)
                    }
                    if let data = data {
                        print("📨 Data: -", data)
                        continuaion.resume(returning: data)
                    }
                }
                task.resume()
            }
        })
    }
    
    func createRequest(at url: URL) -> URLRequest {
        var reuqest: URLRequest = .init(url: url)
        reuqest.timeoutInterval = 120
        reuqest.httpMethod = "GET"
        reuqest.allowsCellularAccess = true
        return reuqest
    }
    
    /// Получение ссылок на страницы из манги по ссылке со страницы тайтла
    func fetchPagesLink(url: URL) throws -> [URL] {
        let html = try! String(contentsOf: url, encoding: .utf8)
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            let shtml = try doc.getElementsByTag("script").get(2).outerHtml()
            
            let pattern = #"\{[\w\W]+?"fullimg":\s*(\[[^\]]+\])\s*\}"#
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            if let match = regex?.firstMatch(in: shtml, options: [], range: NSRange(location: 0, length: shtml.utf16.count)) {
                if let links = Range(match.range(at: 1), in: shtml) {
                    let link = String(shtml[links])
                    let linksArray = link.replacingOccurrences(of: "[\'\\[\\]]",
                                                               with: "",
                                                               options: [.regularExpression, .caseInsensitive])
                        .components(separatedBy: ", ")
                        .compactMap { URL(string: $0) }
                    return linksArray
                }
            }
        } catch Exception.Error(type: let type, Message: let message) {
            print("type: \(type), message: \(message)")
        } catch {
            print(error.localizedDescription)
        }
        throw ParseError.linksPageIsNill("Ссылки на страницы не найдены")
    }

}

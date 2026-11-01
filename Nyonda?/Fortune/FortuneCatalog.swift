//
//  FortuneCatalog.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation


struct FortuneCatalog: Decodable {
    private let storage: [String: [String: [String]]]
    init (from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        storage = try container.decode([String: [String: [String]]].self)
    }
    
    func options(for category:FortuneCategory, level:FortuneLevel) -> [String] {
        storage[category.rawValue]?[level.rawValue] ?? []
    }
}

enum FortuneCatalogLoader {
    static func load(named resourceName: String = "omikuji", bundle: Bundle = .main) throws -> FortuneCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw FortuneCatalogLoadingError.resourceNotFound(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FortuneCatalog.self, from: data)
    }
}

enum FortuneCatalogLoadingError: LocalizedError {
    case resourceNotFound(String)
    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let resourceName):
            return "Could not find \(resourceName).json in the app bundle."
        }
    }
}

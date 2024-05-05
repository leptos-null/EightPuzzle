//
//  Tile.swift
//  EightPuzzle
//
//  Created by Leptos on 4/21/23.
//

import Foundation

enum Tile: String, Hashable, CaseIterable {
    case blank  = " "
    case one    = "1"
    case two    = "2"
    case three  = "3"
    case four   = "4"
    case five   = "5"
    case six    = "6"
    case seven  = "7"
    case eight  = "8"
}

extension Tile: ExpressibleByStringLiteral {
    init(stringLiteral value: RawValue) {
        guard let typed = Self.init(rawValue: value) else {
            fatalError("Invalid Tile value: \(value)")
        }
        self = typed
    }
}

extension Tile: CustomStringConvertible {
    var description: String { rawValue }
}

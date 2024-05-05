//
//  GameBoard.swift
//  EightPuzzle
//
//  Created by Leptos on 4/21/23.
//

import Foundation

struct GameBoard: Hashable {
    var topLeft: Tile
    var topMid: Tile
    var topRight: Tile
    
    var midLeft: Tile
    var midMid: Tile
    var midRight: Tile
    
    var botLeft: Tile
    var botMid: Tile
    var botRight: Tile
    
    static func neighbors(to source: KeyPath<Self, Tile>) -> [WritableKeyPath<Self, Tile>] {
        switch source {
        case \.topLeft:
            return [\.midLeft, \.topMid]
        case \.topMid:
            return [\.topLeft, \.midMid, \.topRight]
        case \.topRight:
            return [\.topMid, \.midRight]
            
        case \.midLeft:
            return [\.topLeft, \.midMid, \.botLeft]
        case \.midMid:
            return [\.midLeft, \.topMid, \.midRight, \.botMid]
        case \.midRight:
            return [\.topRight, \.midMid, \.botRight]
            
        case \.botLeft:
            return [\.midLeft, \.botMid]
        case \.botMid:
            return [\.botLeft, \.midMid, \.botRight]
        case \.botRight:
            return [\.botMid, \.midRight]
        default:
            fatalError("Unknown reference: \(source)")
        }
    }
    
    var isValid: Bool {
        // there are 9 Tile values and 9 positions on the board.
        // because there's a 1:1 relationship between these two
        // sets, we can express a valid board as either:
        // - every tile on the board is unique
        // - every tile type exists on the board
        // we use the second definition here.
        var all: Set = [
            topLeft, topMid, topRight,
            midLeft, midMid, midRight,
            botLeft, botMid, botRight,
        ]
        // note: `remove` is mutating - block has side-effects
        return Tile.allCases.allSatisfy { tile in
            all.remove(tile) == tile
        }
    }
    /// A board that's a copy of this board, but with the tiles at `lhs` and `rhs` swapped
    func swapping(_ lhs: WritableKeyPath<Self, Tile>, with rhs: WritableKeyPath<Self, Tile>) -> Self {
        var copy = self
        copy[keyPath: rhs] = self[keyPath: lhs]
        copy[keyPath: lhs] = self[keyPath: rhs]
        return copy
    }
    /// An array of GameBoards that can be reached with 1 move on this board
    var validTransitions: [Self] {
        // order is not particularly important here
        let knownPaths: [WritableKeyPath<Self, Tile>] = [
            \.topLeft, \.topMid, \.topRight,
             \.midLeft, \.midMid, \.midRight,
             \.botLeft, \.botMid, \.botRight,
        ]
        guard let blankTile = knownPaths.first(where: { self[keyPath: $0] == .blank }) else {
            fatalError("Invalid board: no blank tile")
        }
        
        return Self.neighbors(to: blankTile).map { path in
            self.swapping(blankTile, with: path)
        }
    }
}

extension GameBoard {
    var asciiRepresentation: String {
"""
|---|---|---|
| \(topLeft) | \(topMid) | \(topRight) |
|---|---|---|
| \(midLeft) | \(midMid) | \(midRight) |
|---|---|---|
| \(botLeft) | \(botMid) | \(botRight) |
|---|---|---|
"""
    }
    
    var unicodeRepresentation: String {
"""
┌───┬───┬───┐
│ \(topLeft) │ \(topMid) │ \(topRight) │
├───┼───┼───┤
│ \(midLeft) │ \(midMid) │ \(midRight) │
├───┼───┼───┤
│ \(botLeft) │ \(botMid) │ \(botRight) │
└───┴───┴───┘
"""
    }
}

// not used, but helpful to understand how we could encode a GameBoard compactly
extension GameBoard {
    init(compactEncoding: Int) {
        var tiles = Tile.allCases
        
        let factors = (1...9)
        var product = factors.reduce(1, *) // multiply all together
        
        var encoding = compactEncoding % product // mod off anything larger than we expect
        
        // note: block has side-effects
        let orderedTiles: [Tile] = factors.reversed()
            .map { factor in
                product /= factor
                let (index, remainder) = encoding.quotientAndRemainder(dividingBy: product)
                encoding = remainder
                return tiles.remove(at: index)
            }
        
        topLeft  = orderedTiles[0]
        topMid   = orderedTiles[1]
        topRight = orderedTiles[2]
        
        midLeft  = orderedTiles[3]
        midMid   = orderedTiles[4]
        midRight = orderedTiles[5]
        
        botLeft  = orderedTiles[6]
        botMid   = orderedTiles[7]
        botRight = orderedTiles[8]
    }
    
    var compactEncoding: Int {
        var tiles = Tile.allCases
        
        let factors = (1...9)
        var product = factors.reduce(1, *) // multiply all together
        
        let orderedTiles = [
            topLeft, topMid, topRight,
            midLeft, midMid, midRight,
            botLeft, botMid, botRight,
        ]
        
        // note: block has side-effects
        return zip(orderedTiles, factors.reversed())
            .reduce(into: 0) { partialResult, tileFactorPair in
                let (tile, factor) = tileFactorPair
                guard let index = tiles.firstIndex(of: tile) else {
                    fatalError("Invalid board: tile missing")
                }
                tiles.remove(at: index)
                
                product /= factor
                partialResult += index * product
            }
    }
}

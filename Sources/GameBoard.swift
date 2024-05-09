//
//  GameBoard.swift
//  EightPuzzle
//
//  Created by Leptos on 4/21/23.
//

import Foundation

protocol TileProtocol: Hashable {
    var isBlank: Bool { get }
}

protocol PrintableTile {
    var tileCharacter: Character { get }
}

struct GameBoard<Tile: TileProtocol>: Hashable {
    struct Location: Hashable {
        let column: Int
        let row: Int
    }
    
    // array of rows
    private var grid: [Tile]
    private let meta: GridMeta
    
    init(_ grid: [[Tile]]) {
        var rowCount: Int?
        for row in grid {
            if let rowCount {
                assert(row.count == rowCount, "All rows must of equal count")
            } else {
                rowCount = row.count
            }
        }
        
        self.grid = grid.flatMap { $0 }
        self.meta = .init(columns: grid.count, rows: rowCount ?? 0)
    }
    
    var isValid: Bool {
        // there are `k` Tile values and `k` positions on the board.
        // because there's a 1:1 relationship between these two
        // sets, we can express a valid board as either:
        // - every tile on the board is unique
        // - every tile type exists on the board
        // we use the first definition here.
        let allElements = grid
        let uniqueElements = Set(allElements)
        return allElements.count == uniqueElements.count
    }
    
    @inlinable subscript(location: Location) -> Tile {
        _read {
            let rows = meta.rows
            yield grid[location.column * rows + location.row]
        }
        set(newValue) {
            let rows = meta.rows
            grid[location.column * rows + location.row] = newValue
        }
    }
    
    /// A board that's a copy of this board, but with the tiles at `lhs` and `rhs` swapped
    func swapping(_ lhs: Location, with rhs: Location) -> Self {
        var copy = self
        copy[rhs] = self[lhs]
        copy[lhs] = self[rhs]
        return copy
    }
    /// An array of GameBoards that can be reached with 1 move on this board
    var validTransitions: [Self] {
        // order is not particularly important here
        guard let blankTile = meta.allLocations.first(where: { self[$0].isBlank }) else {
            fatalError("Invalid board: no blank tile")
        }
        guard let neighbors = meta.neighborMap[blankTile] else { return [] }
        return neighbors.map { swapping(blankTile, with: $0) }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.grid == rhs.grid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(grid)
    }
}

private extension GameBoard {
    class GridMeta: Hashable {
        let columns: Int
        let rows: Int
        
        let allLocations: [Location]
        let neighborMap: [Location: [Location]]
        
        private static func neighbors(to location: Location, columns: Int, rows: Int) -> [Location] {
            func dimensionNeighbors<T: FixedWidthInteger>(to index: T, magnitude: T) -> [T] {
                let validIndices = T.zero..<magnitude
                var neighbors: [T] = []
                let before = index - 1
                let after = index + 1
                if validIndices.contains(before) { neighbors.append(before) }
                if validIndices.contains(after) { neighbors.append(after) }
                return neighbors
            }
            
            let columnNeighbors = dimensionNeighbors(to: location.column, magnitude: columns)
                .map { Location(column: $0, row: location.row) }
            
            let rowNeighbors = dimensionNeighbors(to: location.row, magnitude: rows)
                .map { Location(column: location.column, row: $0) }
            
            return columnNeighbors + rowNeighbors
        }
        
        init(columns: Int, rows: Int) {
            let locations = (0..<columns).flatMap { columnIndex in
                (0..<rows).map { rowIndex in
                    Location(column: columnIndex, row: rowIndex)
                }
            }
            
            self.columns = columns
            self.rows = rows
            self.allLocations = locations
            self.neighborMap = locations.reduce(into: [:]) { partialResult, location in
                partialResult[location] = Self.neighbors(to: location, columns: columns, rows: rows)
            }
        }
        
        static func == (lhs: GridMeta, rhs: GridMeta) -> Bool {
            return lhs.allLocations.last == rhs.allLocations.last
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(allLocations.last)
        }
    }
}


extension GameBoard where Tile: PrintableTile {
    var asciiRepresentation: String {
        let rowCount = meta.rows
        let lastValidRow = rowCount - 1
        
        var ret: String = ""
        for (tile, tileIndex) in zip(grid, grid.indices) {
            let (_, row) = tileIndex.quotientAndRemainder(dividingBy: rowCount)
            if row == 0 {
                ret.append("|")
                
                (0..<rowCount).forEach { seperatorRow in
                    ret.append("---")
                    
                    if seperatorRow != lastValidRow {
                        ret.append("|")
                    }
                }
                
                ret.append("|")
                ret.append("\n|")
            }
            ret.append(" ")
            ret.append(tile.tileCharacter)
            ret.append(" |")
            
            if row == lastValidRow {
                ret.append("\n")
            }
        }
        
        ret.append("|")
        (0..<rowCount).forEach { seperatorRow in
            ret.append("---")
            
            if seperatorRow != lastValidRow {
                ret.append("|")
            }
        }
        ret.append("|")
        return ret
    }
    
    var unicodeRepresentation: String {
        let rowCount = meta.rows
        let lastValidRow = rowCount - 1
        
        var ret: String = ""
        for (tile, tileIndex) in zip(grid, grid.indices) {
            let (column, row) = tileIndex.quotientAndRemainder(dividingBy: rowCount)
            if row == 0 {
                if column == 0 {
                    ret.append("┌")
                } else {
                    ret.append("├")
                }
                
                (0..<rowCount).forEach { seperatorRow in
                    ret.append("───")
                    
                    if seperatorRow != lastValidRow {
                        if column == 0 {
                            ret.append("┬")
                        } else {
                            ret.append("┼")
                        }
                    }
                }
                
                if column == 0 {
                    ret.append("┐")
                } else {
                    ret.append("┤")
                }
                ret.append("\n│")
            }
            ret.append(" ")
            ret.append(tile.tileCharacter)
            ret.append(" │")
            
            if row == lastValidRow {
                ret.append("\n")
            }
        }
        
        ret.append("└")
        (0..<rowCount).forEach { seperatorRow in
            ret.append("───")
            if seperatorRow != lastValidRow {
                ret.append("┴")
            }
        }
        ret.append("┘")
        return ret
    }
}

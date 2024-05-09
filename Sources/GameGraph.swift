//
//  GameGraph.swift
//  EightPuzzle
//
//  Created by Leptos on 4/21/23.
//

import Foundation

// adapted from https://www.fivestars.blog/articles/dijkstra-algorithm-swift/
private class Node<T> {
    let state: T
    var visited = false
    var connections: [Node<T>] = []
    
    init(state: T) {
        self.state = state
    }
}

private class Path<T> {
    let cumulativeWeight: Int
    let node: Node<T>
    let previousPath: Path<T>?
    
    init(to node: Node<T>, previousPath: Path<T>? = nil) {
        if let previousPath {
            self.cumulativeWeight = 1 + previousPath.cumulativeWeight
        } else {
            self.cumulativeWeight = 0
        }
        
        self.node = node
        self.previousPath = previousPath
    }
}

extension Path: Sequence {
    func makeIterator() -> UnfoldFirstSequence<Path> {
        sequence(first: self, next: \.previousPath)
    }
}

extension Path {
    static func shortest(from source: Node<T>, to destination: Node<T>) -> Path<T>? {
        // the frontier is made by a path that starts nowhere and ends in the source
        var frontier = [Path(to: source)]
        
        // use indices so we don't have to move any elements
        var headIndex = frontier.startIndex
        while headIndex != frontier.endIndex { // getting the cheapest path available
            let cheapestPathInFrontier = frontier[headIndex]
            frontier.formIndex(after: &headIndex)
            
            let lastNode = cheapestPathInFrontier.node
            guard !lastNode.visited else { continue } // making sure we haven't visited the node already
            
            if lastNode === destination {
                return cheapestPathInFrontier // found the cheapest path
            }
            
            lastNode.visited = true
            
            let connectionPaths = lastNode.connections
                .filter { !$0.visited }
                .map { Path(to: $0, previousPath: cheapestPathInFrontier) }
            
            frontier.append(contentsOf: connectionPaths)
        }
        return nil // we didn't find a path
    }
}
// end of code from https://www.fivestars.blog/articles/dijkstra-algorithm-swift

class GameGraph<Tile: TileProtocol> {
    typealias TypedBoard = GameBoard<Tile>
    
    let source: TypedBoard
    
    private var internTable: [TypedBoard: Node<TypedBoard>] = [:]
    
    private func node(for gameBoard: TypedBoard) -> Node<TypedBoard> {
        if let existing = internTable[gameBoard] {
            return existing
        }
        let node = Node(state: gameBoard)
        internTable[gameBoard] = node
        return node
    }
    
    private func connectSiblings(for gameBoard: TypedBoard) -> [TypedBoard] {
        let root = node(for: gameBoard)
        let siblings = gameBoard.validTransitions
        root.connections = siblings.map(self.node(for:)) // side-effects
        return siblings
    }
    
    init(source: TypedBoard) {
        self.source = source
        
        var boardList = [source]
        while let boardState = boardList.popLast() {
            // we want the nodes to be empty, otherwise we've handled this node already
            guard node(for: boardState).connections.isEmpty else { continue }
            boardList += connectSiblings(for: boardState)
        }
    }
    
    /// Create a graph that includes `source` and `destination`
    ///
    /// This initializer is generally more efficent than `init(source:)`
    /// if you only need to inspect 1 destination because
    /// the graph created in this initializer only requires the nodes
    /// needed to connect `source` and `destination`.
    /// The graph may contain more nodes than the nodes required.
    init(source: TypedBoard, destination: TypedBoard) {
        self.source = source
        
        var boardList = [source]
        // use indices so we don't have to move any elements
        var headIndex = boardList.startIndex
        while headIndex != boardList.endIndex, internTable[destination] == nil {
            let boardState = boardList[headIndex]
            boardList.formIndex(after: &headIndex)
            // we want the nodes to be empty, otherwise we've handled this node already
            guard node(for: boardState).connections.isEmpty else { continue }
            boardList.append(contentsOf: connectSiblings(for: boardState))
        }
    }
    
    func leastMoves(to gameBoard: TypedBoard) -> [TypedBoard]? {
        // we haven't seen this node before - there's no path to it
        guard let destNode = internTable[gameBoard] else { return nil }
        
        let sourceNode = node(for: source)
        
        // if we've visited any nodes, unvisit them before
        // running the shortest path algorithm
        var visitedNodes = [sourceNode]
        while let node = visitedNodes.popLast() {
            guard node.visited else { continue }
            node.visited = false
            visitedNodes += node.connections
        }
        
        guard let path = Path.shortest(from: sourceNode, to: destNode) else { return nil }
        return path.map(\.node.state)
    }
}

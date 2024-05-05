import Foundation

private func formattedDuration(interval: DispatchTimeInterval) -> String {
    let measurement: Measurement<UnitDuration>
    switch interval {
    case .seconds(let seconds):
        measurement = Measurement(value: Double(seconds), unit: .seconds)
    case .milliseconds(let milliseconds):
        measurement = Measurement(value: Double(milliseconds), unit: .milliseconds)
    case .microseconds(let microseconds):
        measurement = Measurement(value: Double(microseconds), unit: .microseconds)
    case .nanoseconds(let nanoseconds):
        measurement = Measurement(value: Double(nanoseconds), unit: .nanoseconds)
    case .never:
        assertionFailure("Measured intervals should not be `never`")
        measurement = Measurement(value: .infinity, unit: .nanoseconds)
    @unknown default:
        assertionFailure("@unknown DispatchTimeInterval case")
        measurement = Measurement(value: .nan, unit: .nanoseconds)
    }
    
    let magnitudeOrder: [UnitDuration] = [.microseconds, .milliseconds, .seconds]
    let unitSelection = zip(magnitudeOrder.dropLast(), magnitudeOrder.dropFirst())
        .first { smallUnit, largeUnit in
            measurement.converted(to: largeUnit).value.magnitude <= 1
        }
        .map(\.0) ?? .seconds
    
    return measurement
        .converted(to: unitSelection)
        .formatted(.measurement(
            width: .wide,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(2))
        ))
}

// Clock.measure is macOS 13.0 +
private func timeBlock<R>(_ block: () -> R) -> (R, DispatchTimeInterval) {
    let start: DispatchTime = .now()
    let result = block()
    let end: DispatchTime = .now()
    return (result, start.distance(to: end))
}

let solutionBoard = GameBoard(
    topLeft: "1", topMid: "2", topRight: "3",
    midLeft: "4", midMid: "5", midRight: "6",
    botLeft: "7", botMid: "8", botRight: " "
)

// 31 moves is the _most_ amount of moves any given game board
// can be solved in, if solved in the least amount of moves.
// In other words, there does not exist a game board such that
// the least amount of moves to solve it is greater than 31

let question = GameBoard(
    topLeft: " ", topMid: "5", topRight: "7",
    midLeft: "6", midMid: "8", midRight: "4",
    botLeft: "1", botMid: "2", botRight: "3"
)

let (graph, graphBuildInterval) = timeBlock {
    GameGraph(source: solutionBoard)
}

print("Built graph in \(formattedDuration(interval: graphBuildInterval))")

let (path, pathFindInterval) = timeBlock {
    graph.leastMoves(to: question)
}

if let path {
    print("Found shortest path in \(formattedDuration(interval: pathFindInterval))")
    
    for item in path.enumerated() {
        print("State \(item.offset)")
        print(item.element.unicodeRepresentation)
    }
} else {
    print("No path found")
}

import Foundation
import Testing

@testable import supacode

struct BaguaWorkingIndicatorTests {
  @Test func perimeterTracesTheRingClockwise() {
    #expect(
      BaguaWorkingIndicator.perimeter.map { [$0.row, $0.col] }
        == [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [1, 0]]
    )
  }

  @Test func centerDotStaysAtBaseOpacity() {
    // The middle cell is never part of the pulse, regardless of phase.
    #expect(BaguaWorkingIndicator.opacity(row: 1, col: 1, phase: 0) == BaguaWorkingIndicator.baseOpacity)
    #expect(BaguaWorkingIndicator.opacity(row: 1, col: 1, phase: 4) == BaguaWorkingIndicator.baseOpacity)
  }

  @Test func pulseHeadIsFullyLit() {
    // When phase aligns with a perimeter index, that dot reaches full intensity.
    let head = BaguaWorkingIndicator.perimeter[0]
    #expect(BaguaWorkingIndicator.opacity(row: head.row, col: head.col, phase: 0) == 1)
  }

  @Test func opacityFallsOffWithPerimeterDistance() {
    // Neighbors of the pulse head are dimmer, and dots far away sit at base.
    let head = BaguaWorkingIndicator.perimeter[0]
    let neighbor = BaguaWorkingIndicator.perimeter[1]
    let opposite = BaguaWorkingIndicator.perimeter[4]

    let headOpacity = BaguaWorkingIndicator.opacity(row: head.row, col: head.col, phase: 0)
    let neighborOpacity = BaguaWorkingIndicator.opacity(row: neighbor.row, col: neighbor.col, phase: 0)
    let oppositeOpacity = BaguaWorkingIndicator.opacity(row: opposite.row, col: opposite.col, phase: 0)

    #expect(headOpacity > neighborOpacity)
    #expect(neighborOpacity > oppositeOpacity)
    #expect(oppositeOpacity == BaguaWorkingIndicator.baseOpacity)
  }

  @Test func pulseWrapsAcrossTheSeam() {
    // Distance is measured the short way around, so the last dot lights up
    // as the pulse approaches the wrap point from index 0.
    let last = BaguaWorkingIndicator.perimeter.count - 1
    let lastDot = BaguaWorkingIndicator.perimeter[last]
    let opacityNearSeam = BaguaWorkingIndicator.opacity(
      row: lastDot.row,
      col: lastDot.col,
      phase: 0
    )
    #expect(opacityNearSeam > BaguaWorkingIndicator.baseOpacity)
  }
}

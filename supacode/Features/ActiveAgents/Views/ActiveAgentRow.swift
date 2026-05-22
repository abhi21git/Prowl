import ComposableArchitecture
import SwiftUI

struct ActiveAgentRow: View {
  let entry: ActiveAgentEntry
  let repositoryName: String
  let branchName: String
  let repositoryColor: RepositoryColorChoice?
  let isDimmed: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: 8) {
      agentIcon
      VStack(alignment: .leading, spacing: 2) {
        title
        Text(branchName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 8)
      statusPill
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .contentShape(.rect)
    .opacity(isDimmed ? 0.7 : 1)
  }

  private var title: some View {
    HStack(alignment: .firstTextBaseline, spacing: 3) {
      Text(entry.agent.displayName)
        .font(.body.weight(.medium))
        .foregroundStyle(.primary)
      Text("·")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
      Text(repositoryName)
        .font(.callout.weight(.medium))
        .foregroundStyle(repositoryColor?.color ?? .secondary)
    }
    .lineLimit(1)
  }

  private var agentIcon: some View {
    Group {
      if let icon = CommandIconMap.iconForFirstToken(entry.agent.iconLookupToken) {
        TabIconImage(rawName: icon.storageString, pointSize: 16)
      } else {
        Image(systemName: "sparkle")
      }
    }
    .frame(width: 20, height: 20)
    .accessibilityHidden(true)
  }

  private var statusPill: some View {
    HStack(spacing: 4) {
      if entry.displayState == .working {
        if reduceMotion {
          statusText
        } else {
          BaguaWorkingIndicator()
        }
      } else {
        statusText
      }
    }
    .foregroundStyle(entry.displayState.foregroundStyle)
  }

  private var statusText: some View {
    Text(entry.displayState.label)
      .font(.caption2.weight(.semibold))
      .lineLimit(1)
  }
}

struct BaguaWorkingIndicator: View {
  static let cycleDuration: Double = 1.0

  static let perimeter: [(row: Int, col: Int)] = [
    (0, 0), (0, 1), (0, 2),
    (1, 2),
    (2, 2), (2, 1), (2, 0),
    (1, 0),
  ]

  var body: some View {
    TimelineView(.animation) { context in
      let elapsed = context.date.timeIntervalSinceReferenceDate
      let phase =
        (elapsed / Self.cycleDuration).truncatingRemainder(dividingBy: 1)
        * Double(Self.perimeter.count)

      VStack(spacing: 2) {
        ForEach(0..<3, id: \.self) { row in
          HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { col in
              dot(opacity: Self.opacity(row: row, col: col, phase: phase))
            }
          }
        }
      }
      .frame(width: 20, height: 18)
      .accessibilityHidden(true)
    }
  }

  // Dimmest opacity for off-pulse dots (and the always-static center).
  static let baseOpacity: Double = 0.18

  static func opacity(row: Int, col: Int, phase: Double) -> Double {
    if row == 1 && col == 1 { return baseOpacity }
    guard
      let index = perimeter.firstIndex(where: { $0.row == row && $0.col == col })
    else {
      return baseOpacity
    }
    let count = Double(perimeter.count)
    let raw = abs(Double(index) - phase)
    // Wrap the distance so the pulse stays continuous across the seam.
    let distance = min(raw, count - raw)
    let intensity = max(0, 1 - distance / 3)
    return baseOpacity + intensity * (1 - baseOpacity)
  }

  private func dot(opacity: Double) -> some View {
    Circle()
      .fill(.foreground)
      .frame(width: 4, height: 4)
      .opacity(opacity)
  }
}

extension AgentDisplayState {
  fileprivate var label: String {
    switch self {
    case .working:
      return "Working"
    case .blocked:
      return "Blocked"
    case .done:
      return "Done"
    case .idle:
      return "Idle"
    }
  }

  fileprivate var foregroundStyle: Color {
    switch self {
    case .working:
      return .orange
    case .blocked:
      return .red
    case .done:
      return .blue
    case .idle:
      return .secondary
    }
  }
}

#Preview {
  BaguaWorkingIndicator()
    .foregroundStyle(.orange)
    .frame(width: 100, height: 100)
}

//
//  LandingOrbitHeroView.swift
//  Helpdecks
//
//  Eight icons placed evenly on a circular path around a central hero, with
//  smooth pseudo-random motion (drift) instead of rigid orbit rotation.
//

import SwiftUI

struct LandingOrbitHeroView: View {
    /// Brand green from app UI (#00bf63).
    private let brandGreen = Color(red: 0, green: 191 / 255, blue: 99 / 255)

    /// Order matches design: top → clockwise.
    private let orbitIcons: [(String, Color)] = [
        ("hands.sparkles.fill", .blue),
        ("heart.fill", .red),
        ("person.3.fill", .blue),
        ("lightbulb.fill", .yellow),
        ("graduationcap.fill", .green),
        ("briefcase.fill", .orange),
        ("car.fill", .indigo),
        ("book.fill", Color(red: 0.15, green: 0.65, blue: 0.62)),
    ]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let side = min(width, height)
            /// Orbit radius: distance from center to each icon’s anchor.
            let orbitRadius = side * 0.38
            /// Icon “tile” size on the path.
            let tile: CGFloat = 48

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    SwiftUI.Circle()
                        .stroke(Color(.systemGray5).opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                        .frame(width: orbitRadius * 2, height: orbitRadius * 2)

                    ForEach(Array(orbitIcons.enumerated()), id: \.offset) { index, item in
                        let baseAngle = -CGFloat.pi / 2 + (2 * CGFloat.pi * CGFloat(index) / CGFloat(orbitIcons.count))
                        let bx = CGFloat(cos(Double(baseAngle))) * orbitRadius
                        let by = CGFloat(sin(Double(baseAngle))) * orbitRadius

                        let di = Double(index)
                        let freqX = 1.15 + 0.18 * (di.truncatingRemainder(dividingBy: 5))
                        let freqY = 0.95 + 0.22 * (di.truncatingRemainder(dividingBy: 7))
                        let amp: CGFloat = 10 + CGFloat(4 * sin(t * 0.4 + di * 0.7))
                        let wx = CGFloat(sin(t * freqX + di * 1.37 + 0.2 * sin(t * 0.6))) * amp
                        let wy = CGFloat(cos(t * freqY + di * 1.09 + 0.15 * sin(t * 0.85))) * amp * 0.9

                        let rot = sin(t * (0.9 + 0.05 * di) + di) * 8
                        let scale = 1 + 0.06 * sin(t * (1.4 + 0.1 * di) + di * 0.5)

                        orbitIconTile(systemName: item.0, tint: item.1, size: tile)
                            .rotationEffect(.degrees(rot))
                            .scaleEffect(scale)
                            .offset(x: bx + wx, y: by + wy)
                    }

                    centerHero(side: min(side, 260))
                }
                .frame(width: width, height: height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func orbitIconTile(systemName: String, tint: Color, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(tint.opacity(0.14))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.hierarchical)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func centerHero(side: CGFloat) -> some View {
        let handSize = min(side * 0.34, 120)

        return VStack(spacing: 14) {
            ZStack {
                Image(systemName: "wave.3.right")
                    .font(.system(size: handSize * 0.35, weight: .ultraLight))
                    .foregroundStyle(Color(.systemGray4).opacity(0.65))
                    .offset(x: -handSize * 0.38, y: -handSize * 0.06)
                    .rotationEffect(.degrees(-12))

                Image(systemName: "hand.wave.fill")
                    .font(.system(size: handSize, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [brandGreen, brandGreen.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(height: handSize * 1.05)

            VStack(spacing: 4) {
                Text("Help people in")
                    .font(.system(size: min(side * 0.075, 22), weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
                Text("your community")
                    .font(.system(size: min(side * 0.075, 22), weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }
}

#Preview {
    LandingOrbitHeroView()
        .padding(24)
        .background(Color.white)
}

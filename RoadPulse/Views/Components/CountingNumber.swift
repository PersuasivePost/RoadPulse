import SwiftUI

// MARK: - Counting number

/// A number SwiftUI can animate: while `value` changes every frame shows the in-between number.
struct CountingNumber: View, Animatable {
    var value: Double
    var decimals = 0
    var suffix = ""

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(String(format: "%.\(decimals)f", value) + suffix)
            .monospacedDigit()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CountingNumber(value: 25)
        CountingNumber(value: 2.75, decimals: 1)
        CountingNumber(value: 48, suffix: "%")
    }
    .font(.title.weight(.heavy))
    .padding()
    .background(Color.asphalt)
}

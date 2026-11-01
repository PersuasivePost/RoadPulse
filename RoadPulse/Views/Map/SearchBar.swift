import SwiftUI

// MARK: - Floating search bar

struct SearchBar: View {
    // @Binding: the view model owns the text so it can debounce it
    @Binding var text: String
    let state: MapViewModel.SearchState
    let onSubmit: () -> Void

    // @FocusState: lets the clear button keep the keyboard up
    @FocusState private var isFocused: Bool
    // @Environment: animations are skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                leadingIcon
                TextField("Search a road or area", text: $text)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit(onSubmit)
                    .foregroundStyle(Color.ink)
                if !text.isEmpty {
                    Button {
                        text = ""
                        isFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.inkMuted)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.surfaceRaised))
            .overlay(Capsule().stroke(Color.inkMuted.opacity(0.12), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 2)

            if let message = state.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.surfaceRaised))
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: state)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if state == .searching {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.inkMuted)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SearchBar(text: .constant("Thane"), state: .found("Thane, Maharashtra"), onSubmit: {})
        SearchBar(text: .constant(""), state: .notFound, onSubmit: {})
    }
    .padding()
    .background(Color.asphalt)
}

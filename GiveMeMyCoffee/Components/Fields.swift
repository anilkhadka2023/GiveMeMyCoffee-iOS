import SwiftUI

private struct FieldBox: ViewModifier {
    let isError: Bool
    let isFocused: Bool

    func body(content: Content) -> some View {
        let stroke: Color = isError ? Palette.errorRed : (isFocused ? Palette.coffeeBrown : Palette.divider)
        content
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(stroke, lineWidth: isFocused || isError ? 1.5 : 1))
    }
}

private struct FieldChrome<Field: View>: View {
    let label: String
    let error: String?
    @ViewBuilder let field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(error != nil ? Palette.errorRed : Palette.textGrey)
            field
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Palette.errorRed)
            }
        }
    }
}

/// Labelled text field with an error line (Material `OutlinedTextField`).
struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var error: String?
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .never
    var contentType: UITextContentType?

    @FocusState private var focused: Bool

    var body: some View {
        FieldChrome(label: label, error: error) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .focused($focused)
            .keyboardType(keyboard)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .foregroundStyle(Palette.textDark)
            .modifier(FieldBox(isError: error != nil, isFocused: focused))
        }
    }
}

/// Read-only field that opens a picker when tapped (the date of birth fields).
struct TappableField: View {
    let label: String
    let value: String
    var placeholder: String = ""
    var systemImage: String = "calendar"
    var error: String?
    let onTap: () -> Void

    var body: some View {
        FieldChrome(label: label, error: error) {
            Button(action: onTap) {
                HStack {
                    Text(value.isEmpty ? placeholder : value)
                        .foregroundStyle(value.isEmpty ? Palette.textGrey.opacity(0.7) : Palette.textDark)
                    Spacer()
                    Image(systemName: systemImage).foregroundStyle(Palette.coffeeBrown)
                }
                .modifier(FieldBox(isError: error != nil, isFocused: false))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Drop-down field (Material `ExposedDropdownMenuBox`).
struct SelectField: View {
    let label: String
    let value: String
    let options: [String]
    var error: String?
    let onSelect: (String) -> Void

    var body: some View {
        FieldChrome(label: label, error: error) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { onSelect(option) }
                }
            } label: {
                HStack {
                    Text(value.isEmpty ? "Select" : value)
                        .foregroundStyle(value.isEmpty ? Palette.textGrey.opacity(0.7) : Palette.textDark)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundStyle(Palette.textGrey)
                }
                .modifier(FieldBox(isError: error != nil, isFocused: false))
                .contentShape(Rectangle())
            }
        }
    }
}

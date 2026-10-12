import SwiftUI

/// Date of birth picker (Android `DatePickerDialog`). Returns DD/MM/YYYY.
struct DateOfBirthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    private let onSelect: (String) -> Void

    init(initial: String, onSelect: @escaping (String) -> Void) {
        _date = State(initialValue: DateOfBirthFormat.date(from: initial) ?? Date())
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Date of birth", selection: $date, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Palette.coffeeBrown)
                    .padding()
                Spacer(minLength: 0)
            }
            .navigationTitle("Date of birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(DateOfBirthFormat.string(from: date))
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// Pickup time picker (Android `TimePickerDialog`). Returns hour and minute.
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    let onSelect: (_ hour: Int, _ minute: Int) -> Void

    var body: some View {
        NavigationStack {
            DatePicker("Pickup time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .navigationTitle("Pickup time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                            onSelect(parts.hour ?? 0, parts.minute ?? 0)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.height(320)])
    }
}

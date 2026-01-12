import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                DatePicker("Select Month", selection: .constant(Date()), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .onChange(of: selectedDate) { _ in }
                // Note: For marked days, we'd need a custom calendar view, but for simplicity, use built-in and list below.
                
                if let date = selectedDate {
                    let recordsForDay = dataManager.records.filter {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }
                    if !recordsForDay.isEmpty {
                        Section(header: Text("Records on \(date, style: .date)")) {
                            ForEach(recordsForDay) { record in
                                Text("\(record.species) - \(record.location)")
                            }
                        }
                        .padding()
                    } else {
                        Text("No records on this day")
                            .padding()
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
}

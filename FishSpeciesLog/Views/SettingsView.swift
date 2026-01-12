import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingExport = false
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var showingResetAlert = false
    @State private var dateFormat = "Medium"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total Species")
                        Spacer()
                        Text("\(dataManager.totalSpecies())")
                    }
                    if let mostCommon = dataManager.mostCommonSpecies() {
                        HStack {
                            Text("Most Common Species")
                            Spacer()
                            Text(mostCommon)
                        }
                    }
                    if let mostFreqLoc = dataManager.mostFrequentLocation() {
                        HStack {
                            Text("Most Frequent Location")
                            Spacer()
                            Text(mostFreqLoc)
                        }
                    }
                    if let first = dataManager.firstRecordedSpecies() {
                        HStack {
                            Text("First Recorded Species")
                            Spacer()
                            Text(first)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Picker("Date Format", selection: $dateFormat) {
                        Text("Short").tag("Short")
                        Text("Medium").tag("Medium")
                        Text("Long").tag("Long")
                    }
                }
                
                Section(header: Text("Data")) {
                    Button("Export Records") { showingExport = true }
                    Button("Reset Data", role: .destructive) { showingResetAlert = true }
                }
                
                Section(header: Text("About")) {
                    Text("Fish Species Log v1.0")
                    Text("Privacy Policy: No data is collected or shared.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExport) {
                ExportView(startDate: $startDate, endDate: $endDate, dataManager: dataManager)
            }
            .alert("Reset Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    dataManager.resetData()
                }
            } message: {
                Text("All records will be deleted permanently.")
            }
        }
    }
}

struct ExportView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var csvData = ""
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("From Date", selection: Binding(get: { startDate ?? Date.distantPast }, set: { startDate = $0 }), displayedComponents: .date)
                DatePicker("To Date", selection: Binding(get: { endDate ?? Date.distantFuture }, set: { endDate = $0 }), displayedComponents: .date)
            }
            .navigationTitle("Export Options")
            .toolbar {
                Button("Export") {
                    csvData = dataManager.exportCSV(from: startDate, to: endDate)
                    // Share the CSV
                    let activityVC = UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
                    dismiss()
                }
            }
        }
    }
}

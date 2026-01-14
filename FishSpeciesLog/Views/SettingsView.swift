import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @AppStorage("dateFormat") private var dateFormat = "MMM d, yyyy"
    @State private var showResetAlert = false
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                List {
                    Section(header: Text("General")) {
                        NavigationLink(destination: DateFormatView(dateFormat: $dateFormat)) {
                            HStack {
                                Label("Date Format", systemImage: "calendar")
                                Spacer()
                                Text(dateFormat)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Statistics")) {
                        NavigationLink(destination: StatsView()) {
                            Label("View Statistics", systemImage: "chart.bar.fill")
                        }
                    }
                    
                    Section(header: Text("Data")) {
                        Button(action: {
                            showExportSheet = true
                        }) {
                            Label("Export Records", systemImage: "square.and.arrow.up")
                                .foregroundColor(Theme.primaryBlue)
                        }
                        
                        Button(action: {
                            showResetAlert = true
                        }) {
                            Label("Reset All Data", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section(header: Text("About")) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.1.0")
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://fishspecieslog.com/privacy-policy.html")!)
                        }) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundColor(Theme.primaryBlue)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    firebaseService.resetAllData()
                }
            } message: {
                Text("This will permanently delete all your species and records. This action cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView()
                    .environmentObject(firebaseService)
            }
        }
    }
}

struct DateFormatView: View {
    @Binding var dateFormat: String
    @Environment(\.presentationMode) var presentationMode
    
    let formats = [
        "MMM d, yyyy",
        "dd/MM/yyyy",
        "MM/dd/yyyy",
        "yyyy-MM-dd"
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundAqua
                .ignoresSafeArea()
            
            List(formats, id: \.self) { format in
                Button(action: {
                    dateFormat = format
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(Date().toString(format: format))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        if dateFormat == format {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.primaryBlue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Date Format")
    }
}

struct StatsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    
    var totalSpecies: Int {
        firebaseService.species.count
    }
    
    var totalRecords: Int {
        firebaseService.records.count
    }
    
    var mostCommonSpecies: String {
        firebaseService.species.max(by: { $0.recordCount < $1.recordCount })?.name ?? "N/A"
    }
    
    var mostFrequentLocation: String {
        let locations = firebaseService.records.map { $0.location }
        let locationCounts = Dictionary(grouping: locations, by: { $0 }).mapValues { $0.count }
        return locationCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    var firstRecordedSpecies: String {
        firebaseService.species.min(by: { $0.firstRecordedDate < $1.firstRecordedDate })?.name ?? "N/A"
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundAqua
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    StatCard(
                        title: "Total Species Recorded",
                        value: "\(totalSpecies)",
                        icon: "🐟",
                        color: Theme.primaryBlue
                    )
                    
                    StatCard(
                        title: "Total Records",
                        value: "\(totalRecords)",
                        icon: "📝",
                        color: Theme.secondaryGreen
                    )
                    
                    StatCard(
                        title: "Most Common Species",
                        value: mostCommonSpecies,
                        icon: "⭐",
                        color: Theme.accentCoral
                    )
                    
                    StatCard(
                        title: "Most Frequent Location",
                        value: mostFrequentLocation,
                        icon: "📍",
                        color: Theme.primaryBlue
                    )
                    
                    StatCard(
                        title: "First Recorded Species",
                        value: firstRecordedSpecies,
                        icon: "🎣",
                        color: Theme.secondaryGreen
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Statistics")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(icon)
                    .font(.system(size: 40))
                
                Spacer()
                
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Theme.sfProRounded(14))
                    .foregroundColor(Theme.textSecondary)
                
                Text(value)
                    .font(Theme.avenirBold(24))
                    .foregroundColor(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct ExportView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.presentationMode) var presentationMode
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.primaryBlue)
                    
                    Text("Export Your Records")
                        .font(Theme.avenirBold(24))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Export all your fishing records as a CSV file")
                        .font(Theme.sfProRounded(16))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: exportRecords) {
                        Text("Export as CSV")
                            .font(Theme.avenirBold(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.oceanGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.primaryBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportRecords() {
        if let url = ExportService.exportRecordsToCSV(records: firebaseService.records) {
            exportURL = url
            showShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import SwiftUI

struct SpeciesDetailsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddRecord = false
    @State private var showingEditName = false
    @State private var newName = ""
    @State private var showingDeleteAlert = false
    
    let species: SpeciesData
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                HStack {
                    Text("Records")
                    Spacer()
                    Text("\(species.count)")
                }
                if let first = species.firstDate {
                    HStack {
                        Text("First Appearance")
                        Spacer()
                        Text(first, style: .date)
                    }
                }
                if let last = species.lastDate {
                    HStack {
                        Text("Last Appearance")
                        Spacer()
                        Text(last, style: .date)
                    }
                }
            }
            
            Section(header: Text("Locations")) {
                ForEach(species.locations, id: \.self) { location in
                    Text(location)
                }
            }
            
            Section(header: Text("Records History")) {
                ForEach(species.records.sorted(by: { $0.date > $1.date })) { record in
                    VStack(alignment: .leading) {
                        Text(record.date, style: .date)
                            .font(.headline)
                        Text("Location: \(record.location)")
                        Text("Result: \(record.result.rawValue)")
                    }
                }
            }
            
            Section(header: Text("Notes")) {
                ForEach(species.records) { record in
                    if !record.notes.isEmpty {
                        Text(record.notes)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle(species.name)
        .toolbar {
            Menu {
                Button("Add Record") { showingAddRecord = true }
                Button("Edit Species Name") {
                    newName = species.name
                    showingEditName = true
                }
                Button("Delete Species", role: .destructive) { showingDeleteAlert = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(record: nil)
                .environmentObject(dataManager)
        }
        .alert("Edit Species Name", isPresented: $showingEditName) {
            TextField("New Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let lowerNew = newName.lowercased()
                dataManager.records = dataManager.records.map { record in
                    var rec = record
                    if rec.species.lowercased() == species.id {
                        rec.species = newName
                    }
                    return rec
                }
                dataManager.saveRecords()
            }
        }
        .alert("Delete Species?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataManager.records.removeAll { $0.species.lowercased() == species.id }
                dataManager.saveRecords()
            }
        } message: {
            Text("All records for this species will be deleted.")
        }
    }
}

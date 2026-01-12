import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var speciesFilter: String? = nil
    @State private var resultFilter: ResultType? = nil
    @State private var waterFilter: WaterType? = nil
    @State private var showingFilters = false
    
    var filteredRecords: [FishRecord] {
        dataManager.records.sorted(by: { $0.date > $1.date }).filter { record in
            (speciesFilter == nil || record.species.lowercased() == speciesFilter?.lowercased()) &&
            (resultFilter == nil || record.result == resultFilter) &&
            (waterFilter == nil || record.waterType == waterFilter)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRecords) { record in
                    NavigationLink(destination: AddRecordView(record: record)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(record.date, style: .date)
                                Spacer()
                                Text(record.result.rawValue)
                                    .foregroundColor(record.result == .caught ? .green : .blue)
                            }
                            Text(record.species)
                                .font(.headline)
                            Text(record.location)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { indices in
                    indices.forEach { dataManager.deleteRecord(filteredRecords[$0]) }
                }
            }
            .navigationTitle("Records")
            .toolbar {
                Button("Filter") { showingFilters = true }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(speciesFilter: $speciesFilter, resultFilter: $resultFilter, waterFilter: $waterFilter)
            }
        }
    }
}

struct FilterView: View {
    @Binding var speciesFilter: String?
    @Binding var resultFilter: ResultType?
    @Binding var waterFilter: WaterType?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var speciesList: [String] {
        Array(Set(dataManager.records.map { $0.species })).sorted()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Species")) {
                    Picker("Species", selection: $speciesFilter) {
                        Text("All").tag(String?.none)
                        ForEach(speciesList, id: \.self) { sp in
                            Text(sp).tag(String?.some(sp))
                        }
                    }
                }
                
                Section(header: Text("Result")) {
                    Picker("Result", selection: $resultFilter) {
                        Text("All").tag(ResultType?.none)
                        ForEach(ResultType.allCases) { res in
                            Text(res.rawValue).tag(ResultType?.some(res))
                        }
                    }
                }
                
                Section(header: Text("Water Type")) {
                    Picker("Water Type", selection: $waterFilter) {
                        Text("All").tag(WaterType?.none)
                        ForEach(WaterType.allCases) { wt in
                            Text(wt.rawValue).tag(WaterType?.some(wt))
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

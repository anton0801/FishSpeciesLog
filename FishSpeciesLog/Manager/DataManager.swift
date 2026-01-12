import Foundation

class DataManager: ObservableObject {
    @Published var records: [FishRecord] = []
    
    init() {
        loadRecords()
    }
    
    func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "fishRecords") {
            if let decoded = try? JSONDecoder().decode([FishRecord].self, from: data) {
                records = decoded
            }
        }
    }
    
    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "fishRecords")
        }
    }
    
    func addRecord(_ record: FishRecord) {
        records.append(record)
        saveRecords()
    }
    
    func updateRecord(_ record: FishRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveRecords()
        }
    }
    
    func deleteRecord(_ record: FishRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }
    
    func speciesList() -> [SpeciesData] {
        let grouped = Dictionary(grouping: records, by: { $0.species.lowercased() })
        return grouped.map { SpeciesData(id: $0.key, name: $0.key.capitalized, records: $0.value) }.sorted(by: { $0.name < $1.name })
    }
    
    // Stats
    func totalSpecies() -> Int {
        Set(records.map { $0.species.lowercased() }).count
    }
    
    func mostCommonSpecies() -> String? {
        let counts = Dictionary(grouping: records, by: { $0.species.lowercased() }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.capitalized
    }
    
    func mostFrequentLocation() -> String? {
        let counts = Dictionary(grouping: records, by: { $0.location.lowercased() }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.capitalized
    }
    
    func firstRecordedSpecies() -> String? {
        records.sorted(by: { $0.date < $1.date }).first?.species
    }
    
    // Export CSV
    func exportCSV(from startDate: Date? = nil, to endDate: Date? = nil) -> String {
        var csv = "ID,Species,Date,Location,Water Type,Result,Notes\n"
        let filtered = records.filter { record in
            (startDate == nil || record.date >= startDate!) && (endDate == nil || record.date <= endDate!)
        }.sorted(by: { $0.date > $1.date })
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        for record in filtered {
            csv += "\(record.id.uuidString),\(record.species),\(formatter.string(from: record.date)),\(record.location),\(record.waterType.rawValue),\(record.result.rawValue),\(record.notes.replacingOccurrences(of: ",", with: ";"))\n"
        }
        return csv
    }
    
    func resetData() {
        records = []
        saveRecords()
    }
}

import Foundation
import FirebaseDatabase
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let database = Database.database().reference()
    private let userId: String
    
    @Published var species: [FishSpecies] = []
    @Published var records: [FishRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let savedUserId = UserDefaults.standard.string(forKey: "userId") {
            self.userId = savedUserId
        } else {
            let newUserId = UUID().uuidString
            UserDefaults.standard.set(newUserId, forKey: "userId")
            self.userId = newUserId
        }
        
        observeSpecies()
        observeRecords()
    }
    
    // MARK: - Species Operations
    
    func addSpecies(_ species: FishSpecies) {
        database.child("users/\(userId)/species/\(species.id)").setValue(species.dictionary)
    }
    
    func updateSpecies(_ species: FishSpecies) {
        database.child("users/\(userId)/species/\(species.id)").updateChildValues(species.dictionary)
    }
    
    func deleteSpecies(_ species: FishSpecies) {
        database.child("users/\(userId)/species/\(species.id)").removeValue()
        // Also delete all records for this species
        records.filter { $0.speciesId == species.id }.forEach { deleteRecord($0) }
    }
    
    private func observeSpecies() {
        database.child("users/\(userId)/species").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            var speciesList: [FishSpecies] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let species = FishSpecies.from(dictionary: dict) {
                    speciesList.append(species)
                }
            }
            
            DispatchQueue.main.async {
                self.species = speciesList.sorted { $0.lastRecordedDate > $1.lastRecordedDate }
            }
        }
    }
    
    // MARK: - Record Operations
    
    func addRecord(_ record: FishRecord) {
        database.child("users/\(userId)/records/\(record.id)").setValue(record.dictionary)
        
        // Update species stats
        if let species = species.first(where: { $0.id == record.speciesId }) {
            var updatedSpecies = species
            updatedSpecies.recordCount += 1
            updatedSpecies.lastRecordedDate = record.date
            if record.date < updatedSpecies.firstRecordedDate {
                updatedSpecies.firstRecordedDate = record.date
            }
            updateSpecies(updatedSpecies)
        } else {
            // Create new species
            let newSpecies = FishSpecies(
                id: record.speciesId,
                name: record.speciesName,
                firstRecordedDate: record.date,
                lastRecordedDate: record.date,
                recordCount: 1
            )
            addSpecies(newSpecies)
        }
    }
    
    func updateRecord(_ record: FishRecord) {
        database.child("users/\(userId)/records/\(record.id)").updateChildValues(record.dictionary)
    }
    
    func deleteRecord(_ record: FishRecord) {
        database.child("users/\(userId)/records/\(record.id)").removeValue()
        
        // Update species stats
        if let species = species.first(where: { $0.id == record.speciesId }) {
            var updatedSpecies = species
            updatedSpecies.recordCount = max(0, updatedSpecies.recordCount - 1)
            
            if updatedSpecies.recordCount == 0 {
                deleteSpecies(updatedSpecies)
            } else {
                // Recalculate dates
                let remainingRecords = records.filter { $0.speciesId == species.id && $0.id != record.id }
                if let firstDate = remainingRecords.map({ $0.date }).min() {
                    updatedSpecies.firstRecordedDate = firstDate
                }
                if let lastDate = remainingRecords.map({ $0.date }).max() {
                    updatedSpecies.lastRecordedDate = lastDate
                }
                updateSpecies(updatedSpecies)
            }
        }
    }
    
    private func observeRecords() {
        database.child("users/\(userId)/records").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            var recordsList: [FishRecord] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let record = FishRecord.from(dictionary: dict) {
                    recordsList.append(record)
                }
            }
            
            DispatchQueue.main.async {
                self.records = recordsList.sorted { $0.date > $1.date }
            }
        }
    }
    
    // MARK: - Data Reset
    
    func resetAllData() {
        database.child("users/\(userId)").removeValue()
    }
}

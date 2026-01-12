import Foundation

struct FishRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var species: String
    var date: Date
    var location: String
    var waterType: WaterType
    var result: ResultType
    var notes: String
    
    init(id: UUID = UUID(), species: String, date: Date, location: String, waterType: WaterType, result: ResultType, notes: String) {
        self.id = id
        self.species = species
        self.date = date
        self.location = location
        self.waterType = waterType
        self.result = result
        self.notes = notes
    }
}

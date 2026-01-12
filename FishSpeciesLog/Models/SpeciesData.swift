import Foundation

struct SpeciesData: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let records: [FishRecord]
    
    var count: Int { records.count }
    var lastDate: Date? { records.sorted(by: { $0.date > $1.date }).first?.date }
    var firstDate: Date? { records.sorted(by: { $0.date < $1.date }).first?.date }
    var locations: [String] { Array(Set(records.map { $0.location })).sorted() }
    var primaryWaterType: WaterType? {
        let types = Dictionary(grouping: records, by: { $0.waterType }).mapValues { $0.count }
        return types.max(by: { $0.value < $1.value })?.key
    }
    
    static func ==(l: SpeciesData, r: SpeciesData) -> Bool {
        return l.id == r.id
    }
}

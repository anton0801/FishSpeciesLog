import Foundation
import FirebaseDatabase

struct FishSpecies: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var firstRecordedDate: Date
    var lastRecordedDate: Date
    var recordCount: Int
    var localNotes: String
    
    init(id: String = UUID().uuidString,
         name: String,
         firstRecordedDate: Date = Date(),
         lastRecordedDate: Date = Date(),
         recordCount: Int = 0,
         localNotes: String = "") {
        self.id = id
        self.name = name
        self.firstRecordedDate = firstRecordedDate
        self.lastRecordedDate = lastRecordedDate
        self.recordCount = recordCount
        self.localNotes = localNotes
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "firstRecordedDate": firstRecordedDate.timeIntervalSince1970,
            "lastRecordedDate": lastRecordedDate.timeIntervalSince1970,
            "recordCount": recordCount,
            "localNotes": localNotes
        ]
    }
    
    static func from(dictionary: [String: Any]) -> FishSpecies? {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let firstTimestamp = dictionary["firstRecordedDate"] as? TimeInterval,
              let lastTimestamp = dictionary["lastRecordedDate"] as? TimeInterval,
              let recordCount = dictionary["recordCount"] as? Int else {
            return nil
        }
        
        let localNotes = dictionary["localNotes"] as? String ?? ""
        
        return FishSpecies(
            id: id,
            name: name,
            firstRecordedDate: Date(timeIntervalSince1970: firstTimestamp),
            lastRecordedDate: Date(timeIntervalSince1970: lastTimestamp),
            recordCount: recordCount,
            localNotes: localNotes
        )
    }
}

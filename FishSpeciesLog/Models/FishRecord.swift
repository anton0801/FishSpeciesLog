import Foundation

struct FishRecord: Identifiable, Codable {
    var id: String
    var speciesId: String
    var speciesName: String
    var date: Date
    var location: String
    var waterType: WaterType
    var result: ResultType
    var notes: String
    
    init(id: String = UUID().uuidString,
         speciesId: String,
         speciesName: String,
         date: Date = Date(),
         location: String,
         waterType: WaterType,
         result: ResultType,
         notes: String = "") {
        self.id = id
        self.speciesId = speciesId
        self.speciesName = speciesName
        self.date = date
        self.location = location
        self.waterType = waterType
        self.result = result
        self.notes = notes
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "speciesId": speciesId,
            "speciesName": speciesName,
            "date": date.timeIntervalSince1970,
            "location": location,
            "waterType": waterType.rawValue,
            "result": result.rawValue,
            "notes": notes
        ]
    }
    
    static func from(dictionary: [String: Any]) -> FishRecord? {
        guard let id = dictionary["id"] as? String,
              let speciesId = dictionary["speciesId"] as? String,
              let speciesName = dictionary["speciesName"] as? String,
              let timestamp = dictionary["date"] as? TimeInterval,
              let location = dictionary["location"] as? String,
              let waterTypeRaw = dictionary["waterType"] as? String,
              let waterType = WaterType(rawValue: waterTypeRaw),
              let resultRaw = dictionary["result"] as? String,
              let result = ResultType(rawValue: resultRaw) else {
            return nil
        }
        
        let notes = dictionary["notes"] as? String ?? ""
        
        return FishRecord(
            id: id,
            speciesId: speciesId,
            speciesName: speciesName,
            date: Date(timeIntervalSince1970: timestamp),
            location: location,
            waterType: waterType,
            result: result,
            notes: notes
        )
    }
}

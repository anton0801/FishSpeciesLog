import Foundation

class ExportService {
    static func exportRecordsToCSV(records: [FishRecord]) -> URL? {
        var csvText = "Date,Species,Location,Water Type,Result,Notes\n"
        
        for record in records {
            let dateString = record.date.toString(format: "yyyy-MM-dd HH:mm")
            let row = "\(dateString),\(record.speciesName),\(record.location),\(record.waterType.rawValue),\(record.result.rawValue),\"\(record.notes)\"\n"
            csvText.append(row)
        }
        
        let fileName = "fish_records_\(Date().toString(format: "yyyyMMdd_HHmmss")).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error creating CSV: \(error)")
            return nil
        }
    }
}

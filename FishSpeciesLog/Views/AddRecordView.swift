import SwiftUI

struct AddRecordView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var species: String
    @State private var date = Date()
    @State private var location = ""
    @State private var waterType: WaterType = .river
    @State private var result: ResultType = .seen
    @State private var notes = ""
    
    let record: FishRecord?
    
    init(record: FishRecord?) {
        self.record = record
        _species = State(initialValue: record?.species ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _location = State(initialValue: record?.location ?? "")
        _waterType = State(initialValue: record?.waterType ?? .river)
        _result = State(initialValue: record?.result ?? .seen)
        _notes = State(initialValue: record?.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fish Species")) {
                    TextField("Species name", text: $species)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
                
                Section(header: Text("Location")) {
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Water Type")) {
                    Picker("Water Type", selection: $waterType) {
                        ForEach(WaterType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Result")) {
                    Picker("Result", selection: $result) {
                        ForEach(ResultType.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(record == nil ? "Add Record" : "Edit Record")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newRecord = FishRecord(
                            id: record?.id ?? UUID(),
                            species: species,
                            date: date,
                            location: location,
                            waterType: waterType,
                            result: result,
                            notes: notes
                        )
                        if record != nil {
                            dataManager.updateRecord(newRecord)
                        } else {
                            dataManager.addRecord(newRecord)
                        }
                        dismiss()
                    }
                    .disabled(species.isEmpty)
                }
            }
        }
    }
}


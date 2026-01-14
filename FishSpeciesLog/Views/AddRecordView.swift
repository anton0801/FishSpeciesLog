import SwiftUI

struct AddRecordView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var firebaseService: FirebaseService
    
    @State private var speciesName = ""
    @State private var selectedSpecies: FishSpecies?
    @State private var date = Date()
    @State private var location = ""
    @State private var waterType: WaterType = .river
    @State private var result: ResultType = .caught
    @State private var notes = ""
    @State private var showSpeciesPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Species selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fish Species")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            Button(action: {
                                showSpeciesPicker = true
                            }) {
                                HStack {
                                    Text(speciesName.isEmpty ? "Select or enter species" : speciesName)
                                        .font(Theme.sfProRounded(16))
                                        .foregroundColor(speciesName.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Theme.primaryBlue)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Date picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Location")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            TextField("Enter location", text: $location)
                                .font(Theme.sfProRounded(16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        // Water type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Water Type")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(WaterType.allCases, id: \.self) { type in
                                    WaterTypeButton(
                                        waterType: type,
                                        isSelected: waterType == type,
                                        action: { waterType = type }
                                    )
                                }
                            }
                        }
                        
                        // Result
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Result")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(ResultType.allCases, id: \.self) { type in
                                    ResultTypeButton(
                                        resultType: type,
                                        isSelected: result == type,
                                        action: { result = type }
                                    )
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(Theme.textPrimary)
                            
                            TextEditor(text: $notes)
                                .font(Theme.sfProRounded(16))
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        // Save button
                        Button(action: saveRecord) {
                            Text("Save Record")
                                .font(Theme.avenirBold(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.oceanGradient)
                                .cornerRadius(16)
                                .shadow(color: Theme.primaryBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(speciesName.isEmpty || location.isEmpty)
                        .opacity(speciesName.isEmpty || location.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.primaryBlue)
                }
            }
            .sheet(isPresented: $showSpeciesPicker) {
                SpeciesPickerView(
                    selectedSpeciesName: $speciesName,
                    selectedSpecies: $selectedSpecies,
                    isPresented: $showSpeciesPicker
                )
                .environmentObject(firebaseService)
            }
        }
    }
    
    private func saveRecord() {
        let speciesId = selectedSpecies?.id ?? UUID().uuidString
        
        let record = FishRecord(
            speciesId: speciesId,
            speciesName: speciesName,
            date: date,
            location: location,
            waterType: waterType,
            result: result,
            notes: notes
        )
        
        firebaseService.addRecord(record)
        isPresented = false
    }
}

struct WaterTypeButton: View {
    let waterType: WaterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(waterType.icon)
                    .font(.system(size: 28))
                
                Text(waterType.rawValue)
                    .font(Theme.sfProRounded(12))
                    .foregroundColor(isSelected ? .white : Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Theme.primaryBlue : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.primaryBlue, lineWidth: isSelected ? 2 : 0)
            )
        }
    }
}

struct ResultTypeButton: View {
    let resultType: ResultType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(resultType.rawValue)
                .font(Theme.avenirBold(16))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isSelected ? Theme.secondaryGreen : Color.white)
                .cornerRadius(12)
        }
    }
}

struct SpeciesPickerView: View {
    @Binding var selectedSpeciesName: String
    @Binding var selectedSpecies: FishSpecies?
    @Binding var isPresented: Bool
    @EnvironmentObject var firebaseService: FirebaseService
    
    @State private var searchText = ""
    @State private var customName = ""
    
    var filteredSpecies: [FishSpecies] {
        if searchText.isEmpty {
            return firebaseService.species
        } else {
            return firebaseService.species.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchBar(text: $searchText)
                        .padding()
                    
                    // Custom entry
                    if !searchText.isEmpty && filteredSpecies.isEmpty {
                        Button(action: {
                            selectedSpeciesName = searchText
                            selectedSpecies = nil
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.primaryBlue)
                                Text("Add \"\(searchText)\"")
                                    .font(Theme.sfProRounded(16))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    List(filteredSpecies) { species in
                        Button(action: {
                            selectedSpeciesName = species.name
                            selectedSpecies = species
                            isPresented = false
                        }) {
                            HStack {
                                Text("🐟")
                                    .font(.system(size: 24))
                                Text(species.name)
                                    .font(Theme.sfProRounded(16))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Species")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.primaryBlue)
                }
            }
        }
    }
}

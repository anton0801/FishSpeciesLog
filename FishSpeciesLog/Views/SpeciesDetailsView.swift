import SwiftUI

struct SpeciesDetailView: View {
    let species: FishSpecies
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    
    var speciesRecords: [FishRecord] {
        firebaseService.records.filter { $0.speciesId == species.id }
    }
    
    var uniqueLocations: [String] {
        Array(Set(speciesRecords.map { $0.location })).sorted()
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundAqua
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    VStack(spacing: 16) {
                        Text("🐟")
                            .font(.system(size: 80))
                        
                        Text(species.name)
                            .font(Theme.avenirBold(28))
                            .foregroundColor(Theme.textPrimary)
                        
                        HStack(spacing: 30) {
                            StatItem(
                                value: "\(species.recordCount)",
                                label: "Records",
                                color: Theme.primaryBlue
                            )
                            
                            StatItem(
                                value: "\(uniqueLocations.count)",
                                label: "Locations",
                                color: Theme.secondaryGreen
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Theme.cardBackground]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Theme.primaryBlue.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Info section
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(
                            icon: "calendar",
                            title: "First Recorded",
                            value: species.firstRecordedDate.toString()
                        )
                        
                        InfoRow(
                            icon: "clock.fill",
                            title: "Last Recorded",
                            value: species.lastRecordedDate.toString()
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Locations
                    if !uniqueLocations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Locations")
                                .font(Theme.avenirBold(20))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(uniqueLocations, id: \.self) { location in
                                        LocationTag(location: location)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Records history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Records")
                            .font(Theme.avenirBold(20))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)
                        
                        ForEach(speciesRecords.prefix(10)) { record in
                            RecordRowCompact(record: record)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showEditSheet = true
                        }) {
                            Label("Edit Species Name", systemImage: "pencil")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.primaryBlue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete Species", systemImage: "trash")
                                .font(Theme.avenirBold(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Species", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                firebaseService.deleteSpecies(species)
            }
        } message: {
            Text("This will delete all \(species.recordCount) records for this species. This action cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            EditSpeciesView(species: species, isPresented: $showEditSheet)
                .environmentObject(firebaseService)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.avenirBold(32))
                .foregroundColor(color)
            
            Text(label)
                .font(Theme.sfProRounded(14))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryBlue)
                .frame(width: 30)
            
            Text(title)
                .font(Theme.sfProRounded(16))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(Theme.avenirMedium(16))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

struct LocationTag: View {
    let location: String
    
    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(Theme.secondaryGreen)
            Text(location)
                .font(Theme.sfProRounded(14))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecordRowCompact: View {
    let record: FishRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date.toString())
                    .font(Theme.avenirMedium(14))
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 8) {
                    Text(record.waterType.icon)
                    Text(record.location)
                        .font(Theme.sfProRounded(12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            Text(record.result.rawValue)
                .font(Theme.sfProRounded(12))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(record.result == .caught ? Theme.secondaryGreen : Theme.textSecondary)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct EditSpeciesView: View {
    var species: FishSpecies
    @Binding var isPresented: Bool
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var newName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Species Name", text: $newName)
                        .font(Theme.sfProRounded(18))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Button(action: {
                        var updatedSpecies = species
                        updatedSpecies.name = newName
                        firebaseService.updateSpecies(updatedSpecies)
                        isPresented = false
                    }) {
                        Text("Save")
                            .font(Theme.avenirBold(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.primaryBlue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(newName.isEmpty)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Edit Species")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                newName = species.name
            }
        }
    }
}

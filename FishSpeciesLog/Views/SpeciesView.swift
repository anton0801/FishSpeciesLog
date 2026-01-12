import SwiftUI

struct SpeciesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    
    var filteredSpecies: [SpeciesData] {
        let species = dataManager.speciesList()
        if searchText.isEmpty {
            return species
        } else {
            return species.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredSpecies) { species in
                        NavigationLink(destination: SpeciesDetailsView(species: species)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "fish.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 50)
                                    .foregroundColor(species.primaryWaterType?.color ?? .blue)
                                
                                Text(species.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Records: \(species.records.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let lastDate = species.lastDate {
                                    Text("Last: \(lastDate, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(species.primaryWaterType?.color.opacity(0.3) ?? Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search species")
            .navigationTitle("My Fish Species")
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.green.opacity(0.05)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    SpeciesView()
}

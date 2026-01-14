import SwiftUI

struct SpeciesListView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var searchText = ""
    @State private var selectedSpecies: FishSpecies?
    
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
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if filteredSpecies.isEmpty {
                        EmptyStateView(
                            icon: "🐟",
                            title: "No Species Yet",
                            description: searchText.isEmpty ?
                                "Start logging your fishing adventures by adding your first record!" :
                                "No species match your search"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredSpecies) { species in
                                    NavigationLink(destination: SpeciesDetailView(species: species)) {
                                        SpeciesCard(species: species)
                                    }
                                    .buttonStyle(CardButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("My Fish Species")
        }
        .environmentObject(firebaseService)
    }
}

struct SpeciesCard: View {
    let species: FishSpecies
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Fish icon
            ZStack {
                Circle()
                    .fill(Theme.primaryBlue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("🐟")
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(species.name)
                    .font(Theme.avenirBold(18))
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Label("\(species.recordCount)", systemImage: "doc.text.fill")
                        .font(Theme.sfProRounded(14))
                        .foregroundColor(Theme.textSecondary)
                    
                    Label(species.lastRecordedDate.toString(), systemImage: "clock.fill")
                        .font(Theme.sfProRounded(14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.primaryBlue)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Theme.primaryBlue.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animate = true
            }
        }
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

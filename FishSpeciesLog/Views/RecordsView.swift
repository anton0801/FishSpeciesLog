import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var searchText = ""
    @State private var filterResult: ResultType?
    @State private var filterWaterType: WaterType?
    @State private var showFilters = false
    
    var filteredRecords: [FishRecord] {
        var records = firebaseService.records
        
        if !searchText.isEmpty {
            records = records.filter {
                $0.speciesName.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let result = filterResult {
            records = records.filter { $0.result == result }
        }
        
        if let waterType = filterWaterType {
            records = records.filter { $0.waterType == waterType }
        }
        
        return records
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filter
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterButton(
                                    title: "All Results",
                                    isSelected: filterResult == nil,
                                    action: { filterResult = nil }
                                )
                                
                                ForEach(ResultType.allCases, id: \.self) { result in
                                    FilterButton(
                                        title: result.rawValue,
                                        isSelected: filterResult == result,
                                        action: { filterResult = result }
                                    )
                                }
                                
                                Divider()
                                    .frame(height: 30)
                                
                                FilterButton(
                                    title: "All Waters",
                                    isSelected: filterWaterType == nil,
                                    action: { filterWaterType = nil }
                                )
                                
                                ForEach(WaterType.allCases, id: \.self) { water in
                                    FilterButton(
                                        title: "\(water.icon) \(water.rawValue)",
                                        isSelected: filterWaterType == water,
                                        action: { filterWaterType = water }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    if filteredRecords.isEmpty {
                        EmptyStateView(
                            icon: "📝",
                            title: "No Records",
                            description: "Start adding records to build your fishing log"
                        )
                    } else {
                        List(filteredRecords) { record in
                            RecordRow(record: record)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        firebaseService.deleteRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Records")
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.sfProRounded(14))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.primaryBlue : Color.white)
                .cornerRadius(20)
        }
    }
}

struct RecordRow: View {
    let record: FishRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.speciesName)
                        .font(Theme.avenirBold(18))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(record.date.toString(format: "MMM d, yyyy 'at' HH:mm"))
                        .font(Theme.sfProRounded(12))
                        .foregroundColor(Theme.textSecondary)
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
            
            HStack(spacing: 16) {
                Label(record.location, systemImage: "mappin.circle.fill")
                    .font(Theme.sfProRounded(14))
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 4) {
                    Text(record.waterType.icon)
                    Text(record.waterType.rawValue)
                        .font(Theme.sfProRounded(14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(Theme.sfProRounded(14))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

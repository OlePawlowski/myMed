//
//  ContentView.swift
//  MyMed
//
//  Created by Ole Pawlowski on 09.02.26.
//

import SwiftUI
import Combine

// ✅ Externes Enum für Tabs („AppTab“ um Namenskonflikt mit SwiftUI.Tab zu vermeiden)
@available(iOS 26, *)
enum AppTab: Hashable, CaseIterable {
    case records, appointments, devices, chat
}


// MARK: - Brand (harmonische Palette: Blau-Familie)
private extension Color {
    static let brandAccent = Color(red: 0/255, green: 136/255, blue: 255/255)
    // Zurückhaltende Abstufungen für Kategorien/Typen – alle in einer Farbfamilie
    static let palettePrimary   = Color(red: 0/255, green: 136/255, blue: 255/255)   // Blau
    static let paletteSecondary = Color(red: 0/255, green: 160/255, blue: 200/255)   // Blau-Teal
    static let paletteTertiary  = Color(red: 60/255, green: 120/255, blue: 220/255)  // Indigo
    static let paletteQuaternary = Color(red: 0/255, green: 180/255, blue: 180/255)  // Teal
    static let paletteAccent    = Color(red: 220/255, green: 100/255, blue: 80/255)   // dezentes Rot nur für Notfall
}

// MARK: - Geteilte Dokumente (Akte + Chat)
@Observable
final class DocumentsStore {
    struct DocumentItem: Identifiable {
        let id: UUID
        var title: String
        var subtitle: String
        var date: Date
        var typeIcon: String
        var isFavorite: Bool

        var category: String {
            switch typeIcon {
            case "waveform.path.ecg.rectangle": return "Röntgen"
            case "testtube.2": return "Labor"
            case "receipt": return "Rechnung"
            case "document.fill": return "Befund"
            case "note.text": return "Notiz"
            case "cross.case.fill": return "Notfalldaten"
            default: return "Sonstige"
            }
        }
    }

    var documents: [DocumentItem] = {
        let cal = Calendar.current
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: Date()) ?? Date() }
        return [
            DocumentItem(id: UUID(), title: "Röntgenbilder 6-fach", subtitle: "Dr. Bruch, Anton", date: daysAgo(0), typeIcon: "waveform.path.ecg.rectangle", isFavorite: false),
            DocumentItem(id: UUID(), title: "Ergebnisse Großes Blutbild", subtitle: "Dr. Holler, René", date: daysAgo(0), typeIcon: "testtube.2", isFavorite: true),
            DocumentItem(id: UUID(), title: "Rechnung Zahnreinigung", subtitle: "Gestern", date: daysAgo(1), typeIcon: "receipt", isFavorite: false),
            DocumentItem(id: UUID(), title: "Telemedizinisches Monitoring", subtitle: "Musterfrau, Maria", date: daysAgo(3), typeIcon: "document.fill", isFavorite: false),
            DocumentItem(id: UUID(), title: "Meine Notiz: Symptome", subtitle: "Eigene Notiz", date: daysAgo(10), typeIcon: "note.text", isFavorite: false),
            DocumentItem(id: UUID(), title: "Notfalldaten aktualisiert", subtitle: "Allergien, Medikamente", date: daysAgo(15), typeIcon: "cross.case.fill", isFavorite: false)
        ]
    }()
}

// MARK: - ContentView

@available(iOS 26, *)
struct ContentView: View {
    @State private var selectedTab: AppTab = .records
    @State private var documentsStore = DocumentsStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.records) {
                NavigationStack { DokumenteView(selectedTab: $selectedTab) }
            } label: {
                Label("Meine Akte", systemImage: "folder")
                    .environment(\.symbolVariants, .none)
            }
            Tab(value: AppTab.appointments) {
                NavigationStack { AppointmentsView() }
            } label: {
                Label("Termine", systemImage: "calendar")
                    .environment(\.symbolVariants, .none)
            }
            Tab(value: AppTab.devices) {
                NavigationStack { DevicesView() }
            } label: {
                Label("Health", systemImage: "waveform.path.ecg")
                    .environment(\.symbolVariants, .none)
            }

            Tab(value: AppTab.chat, role: .search) {
                NavigationStack { AIChatView(documentsStore: documentsStore) }
            } label: {
                Label("Frage stellen", systemImage: "message")
                    .environment(\.symbolVariants, .none)
            }
        }
        .tint(Color.brandAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .statusBarHidden(false)
    }
}

// MARK: - Preview

@available(iOS 26, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




// MARK: - Records (Akte) – direkte Dokumenten-Übersicht
struct DokumenteView: View {
    @Binding var selectedTab: AppTab
    // MARK: Model
    enum DocumentType: String, CaseIterable, Identifiable {
        case xray = "Röntgen"
        case lab = "Labor"
        case invoice = "Rechnung"
        case note = "Notiz"
        case emergency = "Notfalldaten"
        case report = "Befund"
        case prescription = "Rezept"
        case hospitalReport = "Krankenhausbericht"
        case vaccination = "Impfpass"
        case referral = "Überweisung"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .xray: return "waveform.path.ecg.rectangle"  // Röntgenbild
            case .lab: return "testtube.2"
            case .invoice: return "receipt"     // Rechnung
            case .note: return "note.text"
            case .emergency: return "cross.case.fill"
            case .report: return "document.fill"  // Arztbrief
            case .prescription: return "pills"
            case .hospitalReport: return "cross.case"
            case .vaccination: return "syringe"
            case .referral: return "arrow.right.circle"
            }
        }
        /// Einheitliche Farbe – Kategorien unterscheiden sich nur über das Icon.
        var color: Color { Color.palettePrimary }
    }

    enum Category: String, CaseIterable, Identifiable {
        case arztbrief = "Arztbrief"
        case laborbefund = "Laborbefund"
        case roentgen = "Röntgen"
        case rezept = "Rezept"
        case krankenhausbericht = "Krankenhausbericht"
        case impfpass = "Impfpass"
        case ueberweisung = "Überweisung"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .arztbrief: return "document.fill"
            case .laborbefund: return "testtube.2"
            case .roentgen: return "waveform.path.ecg.rectangle"
            case .rezept: return "pills"
            case .krankenhausbericht: return "cross.case.fill"
            case .impfpass: return "syringe"
            case .ueberweisung: return "arrow.right.circle"
            }
        }
        /// Einheitliche Farbe – Kategorien unterscheiden sich nur über das Icon.
        var tint: Color { Color.palettePrimary }
        func matches(_ type: DocumentType) -> Bool {
            switch self {
            case .arztbrief: return type == .report
            case .laborbefund: return type == .lab
            case .roentgen: return type == .xray
            case .rezept: return type == .prescription
            case .krankenhausbericht: return type == .hospitalReport
            case .impfpass: return type == .vaccination
            case .ueberweisung: return type == .referral
            }
        }
    }

    struct Document: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let date: Date
        let type: DocumentType
        var isFavorite: Bool
    }

    // MARK: Sample Data
    @State private var all: [Document] = {
        let cal = Calendar.current
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: Date()) ?? Date() }
        return [
            .init(title: "Röntgenbilder 6-fach", subtitle: "Dr. Bruch, Anton", date: daysAgo(0), type: .xray, isFavorite: false),
            .init(title: "Ergebnisse Großes Blutbild", subtitle: "Dr. Holler, René", date: daysAgo(0), type: .lab, isFavorite: true),
            .init(title: "Rechnung Zahnreinigung", subtitle: "Gestern", date: daysAgo(1), type: .invoice, isFavorite: false),
            .init(title: "Telemedizinisches Monitoring", subtitle: "Musterfrau, Maria", date: daysAgo(3), type: .report, isFavorite: false),
            .init(title: "Meine Notiz: Symptome", subtitle: "Eigene Notiz", date: daysAgo(10), type: .note, isFavorite: false),
            .init(title: "Notfalldaten aktualisiert", subtitle: "Allergien, Medikamente", date: daysAgo(15), type: .emergency, isFavorite: false)
        ]
    }()

    // MARK: Filters
    @State private var search: String = ""
    @State private var showFavorites: Bool = false
    @State private var showEmergency: Bool = false
    @State private var showMedicationSheet: Bool = false
    @State private var selectedCategory: Category? = nil

    private var baseFiltered: [Document] {
        var docs = all
        if showFavorites { docs = docs.filter { $0.isFavorite } }
        if showEmergency { docs = docs.filter { $0.type == .emergency } }
        if let cat = selectedCategory { docs = docs.filter { cat.matches($0.type) } }
        if !search.isEmpty {
            let q = search.lowercased()
            docs = docs.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
        }
        return docs.sorted { $0.date > $1.date }
    }

    private var sectioned: [(title: String, items: [Document])] {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        let grouped = Dictionary(grouping: baseFiltered) { (doc: Document) in
            df.string(from: doc.date)
        }
        let sortedKeys = grouped.keys.sorted { (a, b) -> Bool in
            df.date(from: a) ?? .distantFuture > df.date(from: b) ?? .distantFuture
        }
        return sortedKeys.map { key in (title: key, items: grouped[key]!.sorted { $0.date > $1.date }) }
    }

    // MARK: Tile subtitles
    private var favoritesSubtitle: String { "\(all.filter { $0.isFavorite }.count) Dokumente" }
    private var emergencySubtitle: String {
        if let last = all.filter({ $0.type == .emergency }).sorted(by: { $0.date > $1.date }).first {
            let cal = Calendar.current
            if cal.isDateInToday(last.date) { return "Heute aktualisiert" }
            if cal.isDateInYesterday(last.date) { return "Gestern aktualisiert" }
            let df = DateFormatter(); df.dateStyle = .short; return "Aktualisiert: \(df.string(from: last.date))"
        }
        return "Noch keine Daten"
    }

    var body: some View {
        dokumenteList
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(16))
            .listRowSpacing(14)
            .contentMargins(.top, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(BackgroundGradient())
            .safeAreaInset(edge: .top, spacing: 0) {
                headerBar
            }
            .sheet(isPresented: $showMedicationSheet) { medicationSheet }
    }

    private var headerBar: some View {
        ThemedNavigationHeader("myMed") {
            HStack(spacing: 10) {
                Menu {
                    Button { /* Scanner */ } label: { Label("Scannen", systemImage: "camera.viewfinder") }
                    Button { /* Upload */ } label: { Label("Hochladen", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.plain)
                Button(action: { /* Benachrichtigungen */ }) {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.plain)
                Button(action: { /* Einstellungen */ }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect()
            .clipShape(Capsule())
        }
    }

    private var dokumenteList: some View {
        List {
            tilesSection
            searchSection
            documentSections
        }
    }

    private var tilesSection: some View {
        Section {
            LiquidGlassCard(contentPadding: EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    Button {
                        withAnimation { showFavorites.toggle(); if showFavorites { showEmergency = false } }
                    } label: {
                        FeatureTile(title: "Favoriten", subtitle: favoritesSubtitle, systemImage: "heart.fill", tint: Color.palettePrimary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation { showEmergency.toggle(); if showEmergency { showFavorites = false } }
                    } label: {
                        FeatureTile(title: "Notfalldaten", subtitle: emergencySubtitle, systemImage: "cross.case.fill", tint: Color.paletteAccent)
                    }
                    .buttonStyle(.plain)

                    Button { showMedicationSheet = true } label: {
                        FeatureTile(title: "Medikation", subtitle: "Bald verfügbar", systemImage: "pills", tint: Color.paletteQuaternary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.white)
    }

    private var searchSection: some View {
        Section {
            LiquidGlassCard(contentPadding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Suche nach Dokumenten", text: $search)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    Menu {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            Label("Alle", systemImage: selectedCategory == nil ? "checkmark" : "circle")
                        }
                        ForEach(Category.allCases) { cat in
                            Button {
                                withAnimation { selectedCategory = cat }
                            } label: {
                                Label(cat.rawValue, systemImage: selectedCategory == cat ? "checkmark" : cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(selectedCategory != nil ? Color.palettePrimary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.white)
    }

    @ViewBuilder
    private var documentSections: some View {
        ForEach(sectioned, id: \.title) { section in
            Section(section.title) {
                ForEach(section.items) { doc in
                    documentRow(doc)
                }
            }
        }
    }

    private func documentRow(_ doc: Document) -> some View {
        DocumentListRow(doc: doc)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { delete(doc) } label: { Label("Löschen", systemImage: "trash") }
                Button { toggleFavorite(doc) } label: { Label("Favorit", systemImage: doc.isFavorite ? "heart.slash" : "heart") }
                    .tint(Color.palettePrimary)
            }
    }

    private var medicationSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills").font(.largeTitle).foregroundStyle(.green)
            Text("Medikationsplan").font(.title2).bold()
            Text("Diese Funktion wird bald verfügbar sein.").foregroundStyle(.secondary)
            Button("Schließen") { showMedicationSheet = false }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
        }
        .padding()
        .presentationDetents([.medium])
    }

    // MARK: Actions
    private func toggleFavorite(_ doc: Document) {
        if let idx = all.firstIndex(where: { $0.id == doc.id }) {
            all[idx].isFavorite.toggle()
        }
    }
    private func delete(_ doc: Document) {
        all.removeAll { $0.id == doc.id }
    }
}

struct DocumentListRow: View {
    let doc: DokumenteView.Document

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(doc.type.color.opacity(0.15))
                Image(systemName: doc.type.icon).foregroundStyle(doc.type.color)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(doc.title).font(.subheadline).fontWeight(.semibold)
                Text(doc.subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 5) {
                Text(dateShort(doc.date)).font(.caption2).foregroundStyle(.secondary)
                if doc.isFavorite {
                    Image(systemName: "heart.fill").foregroundStyle(Color.palettePrimary)
                }
            }
        }
    }

    private func dateShort(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) {
            let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: d)
        } else if cal.isDateInYesterday(d) {
            return "Gestern"
        } else {
            let df = DateFormatter(); df.dateStyle = .short; return df.string(from: d)
        }
    }
}

struct CategoryChip: View {
    var title: String
    var systemImage: String
    var tint: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: .capsule)
            .overlay(Capsule().stroke(isSelected ? tint : Color.white.opacity(0.25), lineWidth: 1))
            .foregroundStyle(isSelected ? tint : .primary)
        }
        .buttonStyle(.plain)
    }
}

// Updated FeatureTile with single-line title and subtitle, scaling, and smaller subtitle font
struct FeatureTile: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.15))
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 65, height: 48)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .allowsTightening(true)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// Removed FilterChip and StatPill structs

// MARK: - Devices (Geräte) – HealthKit-Integration
struct DevicesView: View {
    @State private var healthManager = HealthManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !healthManager.isHealthKitAvailable {
                    simulatorPlaceholder
                } else if !healthManager.isAuthorized && !healthManager.isDenied {
                    healthConnectHero
                } else if healthManager.isDenied {
                    healthDeniedView
                } else {
                    healthInDevelopmentView
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottom) {
            if healthManager.isHealthKitAvailable && !healthManager.isAuthorized && !healthManager.isDenied {
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color.brandAccent.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ThemedNavigationHeader("Health")
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await healthManager.loadAll() }
        .task {
            if healthManager.isHealthKitAvailable && healthManager.isAuthorized {
                await healthManager.loadAll()
            }
        }
    }

    // MARK: - Simulator-Platzhalter
    private var simulatorPlaceholder: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandAccent.opacity(0.6))
            Text("Health nur auf echtem Gerät")
                .font(.title2.weight(.semibold))
            Text("Verbinde dein iPhone mit Apple Watch und Health, um deine Geräte und Gesundheitsdaten hier zu sehen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer().frame(height: 40)
            // Platzhalter-Geräte für Preview
            VStack(spacing: 12) {
                DeviceRow(name: "Apple Watch", detail: "Verbinde Health für echte Daten", systemImage: "applewatch")
                DeviceRow(name: "iPhone", detail: "Schritte, Aktivität", systemImage: "iphone")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Health verbinden (Hero)
    private var healthConnectHero: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)
            VStack(spacing: 28) {
                Image("Icon_-_Apple_Health")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                VStack(spacing: 10) {
                    Text("Health verbinden")
                        .font(.title2.weight(.bold))
                    Text("Zeige Apple Watch, Schritte, Herzfrequenz und Schlaf aus deiner Health App.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 28)
                }
                Button {
                    Task { await healthManager.requestAuthorizationAndLoad() }
                } label: {
                    Text("Mit Health verbinden")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
                .controlSize(.regular)
                if healthManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
            Spacer().frame(height: 80)
        }
    }

    // MARK: - Zugriff verweigert
    private var healthDeniedView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Health-Zugriff verweigert")
                .font(.title2.weight(.semibold))
            Text("Öffne Einstellungen → MyMed → Health, um den Zugriff zu erlauben.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let msg = healthManager.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
            }
            Spacer().frame(height: 40)
        }
    }

    // MARK: - In Entwicklung (nach Health-Anmeldung)
    private var healthInDevelopmentView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 80)
            Image(systemName: "hammer.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.brandAccent.opacity(0.7))
            VStack(spacing: 8) {
                Text("In Entwicklung")
                    .font(.title2.weight(.bold))
                Text("Die Geräte-Übersicht wird bald verfügbar sein.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    // MARK: - Hauptinhalt (verbunden) – vorerst nicht genutzt
    private var healthContent: some View {
        VStack(spacing: 24) {
            // Stat-Karten
            healthStatsSection

            // Verbundene Geräte aus Health
            if !healthManager.connectedDevices.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Verbundene Geräte")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    VStack(spacing: 0) {
                        ForEach(healthManager.connectedDevices) { device in
                            DeviceRow(
                                name: device.name,
                                detail: formatLastSync(device.lastSync),
                                systemImage: device.icon
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            if device.id != healthManager.connectedDevices.last?.id {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 20)
                }
            }

            // Weitere Geräte (Placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Weitere Geräte")
                    .font(.headline)
                    .padding(.horizontal, 20)
                VStack(spacing: 0) {
                    DeviceRow(name: "Waage", detail: "Noch nicht verbunden", systemImage: "scalemass")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    Divider().padding(.leading, 52)
                    DeviceRow(name: "Thermometer", detail: "Noch nicht verbunden", systemImage: "thermometer")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: 32)
        }
        .padding(.top, 20)
    }

    private var healthStatsSection: some View {
        let s = healthManager.stats
        let cards: [(String, String, String, Color)] = [
            ("Schritte heute", formatSteps(s.stepsToday), "figure.walk", Color.palettePrimary),
            ("Herzfrequenz", s.latestHeartRate.map { "\($0) bpm" } ?? "—", "heart.fill", Color.paletteAccent),
            ("Schlaf", s.lastNightSleepHours.map { String(format: "%.1f h", $0) } ?? "—", "bed.double.fill", Color.paletteQuaternary),
            ("Aktivität", formatKcal(s.activeEnergyToday), "flame.fill", Color.paletteSecondary)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(cards, id: \.0) { title, value, icon, tint in
                HealthStatCard(title: title, value: value, icon: icon, tint: tint)
            }
        }
        .padding(.horizontal, 20)
    }

    private func formatLastSync(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return "Heute \(f.string(from: date))"
        } else if cal.isDateInYesterday(date) {
            return "Gestern"
        } else {
            let f = DateFormatter()
            f.dateStyle = .short
            return f.string(from: date)
        }
    }

    private func formatSteps(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fK", Double(n) / 1000) }
        return "\(n)"
    }

    private func formatKcal(_ n: Double) -> String {
        if n >= 1000 { return String(format: "%.1fK", n / 1000) }
        return "\(Int(n)) kcal"
    }
}

// MARK: - Health Stat Card
private struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Meine Therapie (Termine + Medikationsplan)
enum TherapySegment: String, CaseIterable {
    case kalender = "Kalender"
    case medikationsplan = "Medikationsplan"
}

struct TherapyMedication: Identifiable {
    let id: UUID
    let name: String
    let dosage: String
    let time: String
    let status: String // "geplant", "eingenommen", "verpasst"
    let iconColor: Color
}

struct AppointmentsView: View {
    @State private var selectedSegment: TherapySegment = .kalender
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var therapyMedications: [TherapyMedication] = [
        TherapyMedication(id: UUID(), name: "Simagri Forte 10 MG", dosage: "1 Stück", time: "09:00 Uhr", status: "geplant", iconColor: Color.palettePrimary),
        TherapyMedication(id: UUID(), name: "Innomab 100 MG", dosage: "1 Tablette", time: "20:00 Uhr", status: "geplant", iconColor: Color.palettePrimary)
    ]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    Picker("", selection: $selectedSegment) {
                        ForEach(TherapySegment.allCases, id: \.self) { seg in
                            Text(seg.rawValue).tag(seg)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    if selectedSegment == .kalender {
                        therapyCalendarSection
                        therapyDailyScheduleSection
                    } else {
                        medicationPlanOverviewSection
                    }
                }
        }
        .background(BackgroundGradient())
        .safeAreaInset(edge: .top, spacing: 0) {
            ThemedNavigationHeader("Meine Therapie") {
                Button { } label: {
                    Label("Buchen", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.plain)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Kalender (weißer Hintergrund wie Favoriten/Notfalldaten/Medikation)
    private var therapyCalendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandAccent)
                }
                Spacer()
                Text(monthYearString(displayedMonth))
                    .font(.headline)
                Spacer()
                Button { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ForEach(daysInMonth(displayedMonth), id: \.self) { date in
                    if let d = date {
                        therapyDayCell(date: d)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(20)
            .background(Color.white, in: .rect(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 20)
        }
    }

    private func therapyDayCell(date: Date) -> some View {
        let status = dayStatus(for: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(foregroundForDay(status: status, isSelected: isSelected))
                .frame(width: 36, height: 36)
                .background(backgroundColorForDay(status: status, isSelected: isSelected), in: .circle)
        }
        .buttonStyle(.plain)
    }

    private func dayStatus(for date: Date) -> DayStatus {
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let displayMonth = calendar.component(.month, from: displayedMonth)
        if month != displayMonth { return .otherMonth }
        if date > Date() { return .future }
        if day == 5 { return .missed }
        if day == 8 { return .pending }
        if [1, 2, 3, 4, 6, 7, 10].contains(day) { return .completed }
        return .future
    }

    private enum DayStatus { case completed, missed, pending, future, otherMonth }

    private func backgroundColorForDay(status: DayStatus, isSelected: Bool) -> Color {
        if isSelected { return Color.brandAccent }
        switch status {
        case .completed: return Color.brandAccent.opacity(0.2)
        case .missed: return Color.paletteAccent.opacity(0.25)
        case .pending: return Color.paletteSecondary.opacity(0.25)
        case .future: return Color.gray.opacity(0.15)
        case .otherMonth: return Color.gray.opacity(0.08)
        }
    }

    private func foregroundForDay(status: DayStatus, isSelected: Bool) -> Color {
        if isSelected { return .white }
        switch status {
        case .completed: return Color.brandAccent
        case .missed: return Color.paletteAccent
        case .pending: return Color.paletteSecondary
        case .future, .otherMonth: return .secondary
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return df.string(from: date)
    }

    private func daysInMonth(_ month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let firstWeekday = (calendar.component(.weekday, from: first) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: first) { days.append(date) }
        }
        days.append(contentsOf: Array(repeating: nil, count: max(0, 42 - days.count)))
        return days
    }

    // MARK: - Tägliche Medikationsübersicht
    private var therapyDailyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(selectedDate))
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            ForEach(therapyMedications) { med in
                TherapyMedicationRow(medication: med)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 32)
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }

    // MARK: - Medikationsplan (Übersicht)
    private var medicationPlanOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deine Medikamente")
                .font(.headline)
                .padding(.horizontal, 20)
            ForEach(therapyMedications) { med in
                TherapyMedicationRow(medication: med)
            }
            .padding(.horizontal, 20)
            Spacer().frame(height: 32)
        }
    }
}

// MARK: - Therapie Medikationszeile (wie Dokumente in der Patientenakte)
private struct TherapyMedicationRow: View {
    let medication: TherapyMedication

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(medication.iconColor.opacity(0.15))
                Image(systemName: "pills.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(medication.iconColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(medication.dosage) um \(medication.time) (\(medication.status))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(medication.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "square")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - AI Chat (KI‑Chat) – MedGemma lokal, DSGVO-sicher
struct AIChatView: View {
    var documentsStore: DocumentsStore
    var onDismiss: (() -> Void)? = nil
    @State private var viewModel = ChatViewModel()
    @State private var message: String = ""
    @State private var selectedDocument: DocumentsStore.DocumentItem? = nil
    @State private var showDocumentPicker: Bool = false
    @State private var showChatHistorySheet: Bool = false
    @State private var recentChats: [ChatSession] = []
    @State private var chatHistorySearch: String = ""

    struct ChatSession: Identifiable {
        let id: UUID
        var title: String
        var messages: [ChatMessage]
    }

    private static let suggestedPrompts: [(title: String, subtitle: String)] = [
        ("Fragen", "zu deinen Befunden"),
        ("Erkläre", "meine Laborwerte"),
        ("Symptome", "beschreiben lassen")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header (wie Locally AI)
            chatHeader

            // MARK: Content
            if viewModel.messages.isEmpty {
                welcomeContent
            } else {
                chatMessages
            }

            // MARK: Input Bar
            chatInputBar
        }
        .background(ChatBackground())
        .sheet(isPresented: $showChatHistorySheet) {
            chatHistorySheet
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Links: Doppelstrich (Chat-Historie öffnen) – wie AktenView
            Button {
                showChatHistorySheet = true
            } label: {
                Image(systemName: "equal")
                    .font(.system(size: 18, weight: .medium))
            }
            .buttonStyle(.plain)
            .frame(height: 46)
            .padding(.horizontal, 16)
            .glassEffect()
            .clipShape(Capsule())

            Spacer()

            // Mitte: Modellname
            HStack(spacing: 4) {
                Text("myMed KI")
                    .font(.headline)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Rechts: Schließen (Overlay) oder Einstellungen | Chat Toggle
            HStack(spacing: 16) {
                if let dismiss = onDismiss {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .glassEffect()
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var chatHistorySheet: some View {
        let filteredChats = chatHistorySearch.isEmpty
            ? recentChats
            : recentChats.filter { $0.title.localizedCaseInsensitiveContains(chatHistorySearch) }

        return NavigationStack {
            VStack(spacing: 0) {
                // Suchleiste + Neuer-Chat-Button (wie Referenz)
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Suchen", text: $chatHistorySearch)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        startNewChat()
                        showChatHistorySheet = false
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6), in: .circle)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Liste der letzten Chats
                List {
                    ForEach(filteredChats) { chat in
                        Button {
                            loadChat(chat)
                            showChatHistorySheet = false
                        } label: {
                            Text(chat.title)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        showChatHistorySheet = false
                    }
                }
            }
        }
    }

    private func startNewChat() {
        if !viewModel.messages.isEmpty {
            let title = viewModel.messages.first?.text.prefix(50).description ?? "Chat"
            recentChats.insert(ChatSession(id: UUID(), title: String(title), messages: viewModel.messages), at: 0)
        }
        viewModel.messages = []
    }

    private func loadChat(_ chat: ChatSession) {
        viewModel.messages = chat.messages
    }

    private var welcomeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                VStack(spacing: 12) {
                    Text("Mein Begleiter")
                        .font(.title.bold())
                    Text("Stelle Fragen zu deinen Gesundheitsdaten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Vorgeschlagene Aktionen
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(Self.suggestedPrompts.enumerated()), id: \.offset) { _, prompt in
                            Button {
                                message = "\(prompt.title) \(prompt.subtitle)"
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(prompt.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: .capsule)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 140)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var chatMessages: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.messages) { msg in
                    chatBubble(for: msg)
                }
                if viewModel.isLoading {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            if viewModel.streamingText.isEmpty {
                                ProgressView()
                                Text("Antwort wird generiert…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(viewModel.streamingText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6), in: .rect(cornerRadius: 16, style: .continuous))
                        Spacer(minLength: 40)
                    }
                }
            }
            .padding()
        }
    }

    private func chatBubble(for msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }
            Text(msg.text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
                .background(
                    msg.role == .user
                        ? Color.brandAccent.opacity(0.15)
                        : Color(.systemGray6),
                    in: .rect(cornerRadius: 16, style: .continuous)
                )
            if msg.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            Button { showDocumentPicker = true } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 18, weight: .medium))
            }
            .accessibilityLabel(selectedDocument != nil ? "Dokument ändern" : "Dokument aus Akte anhängen")
            .buttonStyle(.plain)
            .frame(width: 40, height: 40)
            .background(selectedDocument != nil ? Color.brandAccent.opacity(0.2) : Color.clear, in: .circle)
            .overlay(
                Circle()
                    .strokeBorder(selectedDocument != nil ? Color.brandAccent : Color.clear, lineWidth: 2)
            )

            TextField("Frage stellen…", text: $message)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: .capsule)

            Button {
                guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let text = message
                message = ""
                viewModel.send(text)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 40, height: 40)
            .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : Color.brandAccent, in: .circle)
            .foregroundStyle(.white)
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerSheet(
                documents: documentsStore.documents,
                selectedDocument: $selectedDocument
            )
        }
    }
}

// MARK: - Dokument-Auswahl aus der Akte (skalierbar für viele Dokumente)
private struct DocumentPickerSheet: View {
    let documents: [DocumentsStore.DocumentItem]
    @Binding var selectedDocument: DocumentsStore.DocumentItem?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var selectedCategory: String? = nil
    @State private var sortOrder: SortOrder = .newestFirst

    enum SortOrder: String, CaseIterable {
        case newestFirst = "Neueste zuerst"
        case oldestFirst = "Älteste zuerst"
        case aToZ = "A–Z"
    }

    private static let filterCategories = ["Röntgen", "Labor", "Rechnung", "Befund", "Notiz", "Notfalldaten", "Sonstige"]

    private var filteredDocuments: [DocumentsStore.DocumentItem] {
        var result = documents
        if showFavoritesOnly { result = result.filter { $0.isFavorite } }
        if let cat = selectedCategory { result = result.filter { $0.category == cat } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
            }
        }
        switch sortOrder {
        case .newestFirst: result.sort { $0.date > $1.date }
        case .oldestFirst: result.sort { $0.date < $1.date }
        case .aToZ: result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
        return result
    }

    private var sectionedDocuments: [(title: String, items: [DocumentsStore.DocumentItem])] {
        let cal = Calendar.current
        let now = Date()
        func sectionTitle(for date: Date) -> String {
            if cal.isDateInToday(date) { return "Heute" }
            if cal.isDateInYesterday(date) { return "Gestern" }
            let days = cal.dateComponents([.day], from: date, to: now).day ?? 0
            if days <= 7 { return "Diese Woche" }
            if days <= 30 { return "Letzter Monat" }
            let df = DateFormatter()
            df.locale = .current
            df.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return df.string(from: date)
        }
        let grouped = Dictionary(grouping: filteredDocuments) { sectionTitle(for: $0.date) }
        let order = ["Heute", "Gestern", "Diese Woche", "Letzter Monat"]
        let sortedKeys = grouped.keys.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? 999
            let ib = order.firstIndex(of: b) ?? 999
            if ia != ib { return ia < ib }
            return a < b
        }
        return sortedKeys.map { (title: $0, items: grouped[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            List {
                searchSection

                if filteredDocuments.isEmpty && (!searchText.isEmpty || showFavoritesOnly || selectedCategory != nil) {
                    Section {
                        Text("Keine Dokumente gefunden")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                }

                ForEach(sectionedDocuments, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.items) { doc in
                            Button {
                                selectedDocument = doc
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: doc.typeIcon)
                                        .foregroundStyle(Color.palettePrimary)
                                        .frame(width: 32, alignment: .center)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(doc.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if doc.isFavorite {
                                        Image(systemName: "heart.fill")
                                            .font(.caption)
                                            .foregroundStyle(Color.brandAccent)
                                    }
                                    if selectedDocument?.id == doc.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.brandAccent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Dokument auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(showFavoritesOnly ? Color.brandAccent : .secondary)
                    }
                }
            }
        }
    }

    private var searchSection: some View {
        Section {
            LiquidGlassCard(contentPadding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Suche nach Dokumenten", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    Menu {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            Label("Alle", systemImage: selectedCategory == nil ? "checkmark" : "circle")
                        }
                        ForEach(Self.filterCategories, id: \.self) { cat in
                            Button {
                                withAnimation { selectedCategory = cat }
                            } label: {
                                Label(cat, systemImage: selectedCategory == cat ? "checkmark" : "circle")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(selectedCategory != nil ? Color.palettePrimary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.white)
    }
}

// MARK: - Chat-Hintergrund (wie Locally AI: vertikaler Gradient, unsere Farben)
private struct ChatBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.brandAccent.opacity(0.22),
                Color.paletteSecondary.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Components (iOS 26 Liquid Glass)
struct LiquidGlassCard<Content: View>: View {
    var contentPadding: EdgeInsets
    var content: () -> Content

    init(contentPadding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), @ViewBuilder content: @escaping () -> Content) {
        self.contentPadding = contentPadding
        self.content = content
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            content()
                .padding(contentPadding)
        }
    }
}

struct QuickActionButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .tint(Color.brandAccent)
    }
}

struct DeviceRow: View {
    var name: String
    var detail: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandAccent)
            VStack(alignment: .leading) {
                Text(name)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct AppointmentRow: View {
    var title: String
    var date: String

    var body: some View {
        HStack {
            Image(systemName: "stethoscope")
                .foregroundStyle(Color.brandAccent)
            VStack(alignment: .leading) {
                Text(title)
                Text(date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
    }
}

struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.brandAccent.opacity(0.15), location: 0),
                .init(color: Color.brandAccent.opacity(0.06), location: 0.4),
                .init(color: Color.brandAccent.opacity(0.02), location: 0.7),
                .init(color: Color(.systemBackground), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Einheitlicher Header wie „myMed“ – gleiche Höhe und Stil für alle Tabs
struct ThemedNavigationHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.largeTitle)
                .bold()
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

extension ThemedNavigationHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.title = title
        self.trailing = { EmptyView() }
    }
}

struct TabBarIconButton: View {
    var icon: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? Color.brandAccent : Color.primary.opacity(0.9))
                .padding(10)
                .background(
                    Circle()
                        .fill(.thinMaterial)
                        .opacity(isSelected ? 0.35 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }

    private var accessibilityTitle: Text {
        switch icon {
        case "house", "house.fill": return Text("Home")
        case "folder", "doc.text", "doc.text.fill": return Text("Akte")
        case "calendar": return Text("Termine")
        case "applewatch", "waveform.path.ecg": return Text("Health")
        case "message", "bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill": return Text("Frage stellen")
        default: return Text("Tab")
        }
    }
}

struct TabBarLabeledItem: View {
    var icon: String
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? Color.brandAccent : Color.primary.opacity(0.9))
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
                    .opacity(isSelected ? 0.3 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}


#Preview("Akte") {
    NavigationStack {
        DokumenteView(selectedTab: .constant(.records))
    }
}

#Preview("App") {
    ContentView()
}


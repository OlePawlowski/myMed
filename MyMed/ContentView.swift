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
    case home, records, appointments, devices, chat
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

// MARK: - ContentView

@available(iOS 26, *)
struct ContentView: View {

    @State private var selectedTab: AppTab = .home
    @State private var showChatOverlay: Bool = false
    

    var body: some View {
        ZStack {
            // MARK: - Custom TabView
            TabView(selection: $selectedTab) {

                Tab(value: AppTab.home) {
                    NavigationStack { HomeView(selectedTab: $selectedTab, onOpenChat: { showChatOverlay = true }) }
                } label: {
                    Label("Home", systemImage: "house")
                }

                Tab(value: AppTab.records) {
                    NavigationStack { DokumenteView(selectedTab: $selectedTab) }
                } label: {
                    Label("Akte", systemImage: "folder")
                }

                Tab(value: AppTab.appointments) {
                    NavigationStack { AppointmentsView() }
                } label: {
                    Label("Termine", systemImage: "calendar")
                }

                Tab(value: AppTab.devices) {
                    NavigationStack { DevicesView() }
                } label: {
                    Label("Geräte", systemImage: "applewatch")
                }

                // ✅ Chat als Action Button
                Tab(value: AppTab.chat, role: .search) {
                    EmptyView() // kein Content direkt
                } label: {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
            }
            .tint(Color.brandAccent)
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: selectedTab) { oldValue, newValue in
                // Overlay öffnen und Auswahl zurücksetzen
                if newValue == .chat {
                    showChatOverlay = true
                    selectedTab = oldValue
                }
            }

            // MARK: - Chat Overlay
            if showChatOverlay {
                AIChatView()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(8)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showChatOverlay = false
                        }
                    }
            }
        }
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




// MARK: - Home
struct HomeView: View {
    @Binding var selectedTab: AppTab
    var onOpenChat: () -> Void

    private static let chatPrompts = [
        "Wie geht es dir heute?",
        "Was kann ich für dich tun?",
        "Fragen zu deinen Befunden?",
        "Erzähl mir von deinen Symptomen."
    ]

    @State private var currentPromptIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header: Profilbild + Glocke oben rechts
                HStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: { /* Benachrichtigungen */ }) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)

                        Button(action: { /* Profil */ }) {
                            Image("profile-img")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)

                // Titel: myMed + Hinweis
                VStack(alignment: .leading, spacing: 4) {
                    Text("myMed")
                        .font(.largeTitle).bold()
                    Text("Deine Gesundheitsdaten an einem Ort.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Grid: links „Meine Akte“, rechts „Neue Datei“ + „My Health“
                HStack(alignment: .top, spacing: 14) {
                    // Links: Meine Akte (hervorgehoben)
                    Button(action: { selectedTab = .records }) {
                        HomeGridCard(
                            title: "Meine Akte",
                            subtitle: "Dokumente & Befunde",
                            icon: "folder.fill",
                            style: .primary
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Rechts: vertikal gestapelt, gleiche Höhe
                    VStack(spacing: 14) {
                        Button(action: { /* Foto scannen / Upload */ }) {
                            HomeGridCard(
                                title: "",
                                subtitle: "Scannen oder hochladen",
                                icon: "plus.circle.fill",
                                style: .secondary
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)

                        Button(action: { selectedTab = .appointments }) {
                            HomeCalendarWidget()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minHeight: 240)

                // Chat-Frame: interaktive Eingabe mit wechselnden Prompts
                VStack(spacing: 12) {
                    Button(action: onOpenChat) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.palettePrimary)
                            Text(HomeView.chatPrompts[currentPromptIndex])
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.palettePrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial, in: .capsule)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPromptIndex = (currentPromptIndex + 1) % HomeView.chatPrompts.count
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(BackgroundGradient())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Kalender-Widget im Apple-Kalender-Stil (Termine / Medikation)
private struct HomeCalendarWidget: View {
    private let calendar = Calendar.current
    private let weekdaySymbols = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    private var monthYear: String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "MMMM yyyy"
        return df.string(from: Date())
    }

    private var daysInMonth: [Int?] {
        guard let range = calendar.range(of: .day, in: .month, for: Date()),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday + 5) % 7
        var days: [Int?] = Array(repeating: nil, count: offset)
        days += range.map { $0 }
        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }
        return days
    }

    private func isToday(_ day: Int) -> Bool {
        calendar.component(.day, from: Date()) == day
    }

    var body: some View {
        LiquidGlassCard(contentPadding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(monthYear)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.palettePrimary)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                        if let d = day {
                            Text("\(d)")
                                .font(.system(size: 11, weight: isToday(d) ? .semibold : .regular))
                                .foregroundStyle(isToday(d) ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(isToday(d) ? Color.palettePrimary : Color.clear)
                                .clipShape(Circle())
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// Karte fürs Home-Grid (Liquid Glass, moderne Optik)
private struct HomeGridCard: View {
    enum Style { case primary, secondary }
    var title: String
    var subtitle: String
    var icon: String
    var style: Style
    var customImage: String? = nil

    private var isCompact: Bool { style == .secondary && title.isEmpty }
    var body: some View {
        LiquidGlassCard(contentPadding: isCompact ? EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16) : EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            Group {
                if style == .primary {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.palettePrimary.opacity(0.25))
                                    .frame(width: 52, height: 52)
                                Image(systemName: icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Color.palettePrimary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title).font(.title3.weight(.semibold))
                                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                        Group {
                            if let name = customImage {
                                Image(name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isCompact ? 36 : 42, height: isCompact ? 36 : 42)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.palettePrimary.opacity(0.15))
                                        .frame(width: isCompact ? 36 : 42, height: isCompact ? 36 : 42)
                                    Image(systemName: icon)
                                        .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                                        .foregroundStyle(Color.palettePrimary)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if !title.isEmpty {
                                Text(title).font(.subheadline.weight(.semibold))
                            }
                            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                        }
                        if !title.isEmpty {
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: title.isEmpty ? 60 : 100)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .overlay {
            if style == .primary {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.palettePrimary.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Records (Akte) – direkte Dokumenten-Übersicht, Back-Pfeil → Home
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
            .init(title: "MIO Telemedizinisches Monitoring", subtitle: "Musterfrau, Maria", date: daysAgo(3), type: .report, isFavorite: false),
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
        List {
            Section {
                Text("Patientenakte")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)

            // Header with Tiles (3 across)
            Section {
                LiquidGlassCard(contentPadding: EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        // Favoriten
                        Button {
                            withAnimation { showFavorites.toggle(); if showFavorites { showEmergency = false } }
                        } label: {
                            FeatureTile(title: "Favoriten", subtitle: favoritesSubtitle, systemImage: "star.fill", tint: Color.palettePrimary)
                        }
                        .buttonStyle(.plain)

                        // Notfalldaten
                        Button {
                            withAnimation { showEmergency.toggle(); if showEmergency { showFavorites = false } }
                        } label: {
                            FeatureTile(title: "Notfalldaten", subtitle: emergencySubtitle, systemImage: "cross.case.fill", tint: Color.paletteAccent)
                        }
                        .buttonStyle(.plain)

                        // Medikationsplan
                        Button { showMedicationSheet = true } label: {
                            FeatureTile(title: "Medikation", subtitle: "Bald verfügbar", systemImage: "pills", tint: Color.paletteQuaternary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowBackground(Color.white)
            }

            // Search bar below header tiles
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
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
            .listRowBackground(Color.white)

            // Horizontal categories chips above month sections
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Category.allCases) { cat in
                            CategoryChip(title: cat.rawValue, systemImage: cat.icon, tint: cat.tint, isSelected: selectedCategory == cat) {
                                withAnimation {
                                    if selectedCategory == cat { selectedCategory = nil } else { selectedCategory = cat }
                                }
                            }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 6, trailing: 12))
            .listRowBackground(Color.clear)

            ForEach(sectioned, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.items) { doc in
                        DocumentListRow(doc: doc)
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
                                Button { toggleFavorite(doc) } label: { Label("Favorit", systemImage: doc.isFavorite ? "star.slash" : "star") }
                                    .tint(Color.palettePrimary)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.custom(8))
        .contentMargins(.top, 8, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(BackgroundGradient())
        //.searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Suche nach Dokumenten"))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    selectedTab = .home
                } label: {
                    Label("Home", systemImage: "chevron.left")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { /* Scanner */ } label: { Label("Scannen", systemImage: "camera.viewfinder") }
                    Button { /* Upload */ } label: { Label("Hochladen", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.brandAccent)
                }
            }
        }
        .sheet(isPresented: $showMedicationSheet) {
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
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(doc.type.color.opacity(0.15))
                Image(systemName: doc.type.icon).foregroundStyle(doc.type.color)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title).font(.subheadline).fontWeight(.semibold)
                Text(doc.subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(dateShort(doc.date)).font(.caption2).foregroundStyle(.secondary)
                if doc.isFavorite {
                    Image(systemName: "star.fill").foregroundStyle(Color.palettePrimary)
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

// MARK: - Devices (Geräte)
struct DevicesView: View {
    var body: some View {
        List {
            Section("Verbundene Geräte") {
                DeviceRow(name: "Apple Watch", detail: "Series 9", systemImage: "applewatch")
                DeviceRow(name: "Blutdruckmesser", detail: "Withings", systemImage: "gauge.with.dots.needle.50percent")
            }
            Section("Weitere Geräte") {
                DeviceRow(name: "Waage", detail: "Noch nicht verbunden", systemImage: "scalemass")
                DeviceRow(name: "Thermometer", detail: "Noch nicht verbunden", systemImage: "thermometer")
            }
        }
        .listStyle(.insetGrouped)
        .tint(Color.brandAccent)
        .navigationTitle("Geräte")
    }
}

// MARK: - Appointments (Termine)
struct AppointmentsView: View {
    var body: some View {
        VStack(spacing: 0) {
            BackgroundGradient()
                .frame(height: 120)
                .ignoresSafeArea()
            List {
                Section("Bevorstehend") {
                    AppointmentRow(title: "Dr. Müller – Hausarzt", date: "Mo, 23. Feb · 10:30")
                }
                Section("Vorschläge") {
                    AppointmentRow(title: "Orthopädie", date: "In deiner Nähe")
                    AppointmentRow(title: "Dermatologie", date: "Freie Termine diese Woche")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Termine")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: {
                    Label("Buchen", systemImage: "calendar.badge.plus")
                }
            }
        }
    }
}

// MARK: - AI Chat (KI‑Chat)
struct AIChatView: View {
    @State private var message: String = ""
    @State private var messages: [String] = [
        "Willkommen beim myMed KI‑Chat! Stelle Fragen zu deinen Dokumenten oder Symptomen."
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages.indices, id: \.self) { idx in
                        LiquidGlassCard {
                            Text(messages[idx])
                        }
                    }
                }
                .padding()
            }
            HStack {
                TextField("Nachricht eingeben…", text: $message)
                    .textFieldStyle(.roundedBorder)
                Button {
                    guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    messages.append(message)
                    message = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .background(BackgroundGradient())
        .navigationTitle("KI‑Chat")
    }
}

// MARK: - Components
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
        LinearGradient(colors: [
            Color.brandAccent.opacity(0.18),
            Color(.systemBackground)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
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
        case "folder", "doc.text.fill": return Text("Akte")
        case "calendar": return Text("Termine")
        case "applewatch": return Text("Geräte")
        case "bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill": return Text("Chat")
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

#Preview {
    ContentView()
}


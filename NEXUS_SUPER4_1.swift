// NEXUS SUPER4.1 — Native SwiftUI edition
// Converted from NEXUS_SUPER4.1(20261105-135009).html
// Target: iOS 17+ / iPadOS 17+ / macOS 14+ (Swift 5.9+)
// Add this file to a SwiftUI App target. Add Resources/NEXUSWallpaper.jpg to Copy Bundle Resources.
// Frameworks: SwiftUI, Combine, AVFoundation, CryptoKit, Network, UniformTypeIdentifiers.

import SwiftUI
import Combine
import AVFoundation
import CryptoKit
import Network
import UniformTypeIdentifiers
import Foundation

#if canImport(UIKit)
import UIKit
import AudioToolbox
private typealias NEXUSPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias NEXUSPlatformImage = NSImage
#endif

// MARK: - App entry

@main
struct NEXUSApp: App {
    @StateObject private var store = NEXUSStore()

    var body: some Scene {
        WindowGroup {
            NEXUSRootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Codable data models

struct NEXUSConfig: Codable {
    var accentHex = "#28C9F2"
    var selectedPrefecture = "兵庫県"
    var searchEngine = "Google"
    var wallpaperMode = "space"
    var customWallpaper: Data? = nil
    var iconSize = 84.0
    var blur = 12.0
    var automaticWeather = false
    var privacyBlur = false
    var screenProtect = false
    var anonymousNetwork = false
    var layoutMode = "auto"
    var sleepEnabled = false
    var sleepStart = "22:00"
    var sleepEnd = "07:00"
    var sleepMessage = "設定したおやすみ時間です。画面から離れて、目と体を休めましょう。"
}

struct NEXUSBookmark: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var url: String
}

struct NEXUSMemo: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var body: String
    var pinned = false
    var createdAt = Date()
    var updatedAt = Date()
}

struct NEXUSTodo: Codable, Identifiable, Hashable {
    var id = UUID()
    var text: String
    var done = false
    var createdAt = Date()
    var completedAt: Date? = nil
}

struct NEXUSEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var note = ""
}

struct NEXUSBoardRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: String
    var title: String
    var body: String
    var createdAt = Date()
    var updatedAt = Date()
}

struct NEXUSStroke: Codable, Identifiable, Hashable {
    var id = UUID()
    var points: [CGPointCodable]
    var colorHex: String
    var lineWidth: Double
}

struct CGPointCodable: Codable, Hashable {
    var x: Double
    var y: Double
    init(_ point: CGPoint) { x = point.x; y = point.y }
    var point: CGPoint { CGPoint(x: x, y: y) }
}

struct NEXUSData: Codable {
    var config = NEXUSConfig()
    var bookmarks: [NEXUSBookmark] = [
        .init(name: "ChatGPT", url: "https://chatgpt.com"),
        .init(name: "Google", url: "https://www.google.com"),
        .init(name: "YouTube", url: "https://www.youtube.com"),
        .init(name: "GitHub", url: "https://github.com")
    ]
    var memos: [NEXUSMemo] = []
    var todosByDate: [String: [NEXUSTodo]] = [:]
    var events: [NEXUSEvent] = []
    var boardRecords: [NEXUSBoardRecord] = []
    var drawing: [NEXUSStroke] = []
    var developerPrefs: [String: String] = [:]
}

// MARK: - Persistence and shared application state

@MainActor
final class NEXUSStore: ObservableObject {
    @Published var data: NEXUSData
    @Published var weather: NEXUSWeather?
    @Published var weatherStatus = "「更新」を押すと、選択した都道府県の天気を取得します。"
    @Published var isLoadingWeather = false
    @Published var networkStatus = "接続状態を確認中…"
    @Published var networkIsOnline = false
    @Published var privacyShieldVisible = false
    @Published var screenProtectVisible = false
    @Published var sleepOverlayVisible = false
    @Published var lastSecurityReport = "まだ診断していません。"
    @Published var lastSecurityScore = 0

    private let storageKey = "NEXUS_SUPER4_1_NATIVE_DATA"
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "nexus.network.monitor")

    init() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder.nexus.decode(NEXUSData.self, from: raw) {
            data = decoded
        } else {
            data = NEXUSData()
        }
        startNetworkMonitor()
        evaluateSleepState()
    }

    func update(_ change: (inout NEXUSData) -> Void) {
        var copy = data
        change(&copy)
        data = copy
        save()
    }

    func save() {
        do {
            let encoded = try JSONEncoder.nexus.encode(data)
            guard encoded.count <= 7_500_000 else { return }
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("NEXUS save error: \(error.localizedDescription)")
        }
    }

    func resetAll() {
        data = NEXUSData()
        UserDefaults.standard.removeObject(forKey: storageKey)
        save()
    }

    var storageBytes: Int {
        (try? JSONEncoder.nexus.encode(data).count) ?? 0
    }

    func todoItems(for date: Date) -> [NEXUSTodo] {
        data.todosByDate[date.nexusDayKey] ?? []
    }

    func addTodo(_ text: String, date: Date) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        update { value in
            var items = value.todosByDate[date.nexusDayKey] ?? []
            guard items.count < 200 else { return }
            items.append(NEXUSTodo(text: String(cleaned.prefix(180))))
            value.todosByDate[date.nexusDayKey] = items
        }
    }

    func toggleTodo(_ id: UUID, date: Date) {
        update { value in
            guard var items = value.todosByDate[date.nexusDayKey],
                  let index = items.firstIndex(where: { $0.id == id }) else { return }
            items[index].done.toggle()
            items[index].completedAt = items[index].done ? Date() : nil
            value.todosByDate[date.nexusDayKey] = items
        }
    }

    func deleteTodo(_ id: UUID, date: Date) {
        update { value in
            value.todosByDate[date.nexusDayKey, default: []].removeAll { $0.id == id }
        }
    }

    func clearCompletedTodos(date: Date) {
        update { value in
            value.todosByDate[date.nexusDayKey, default: []].removeAll(where: \.done)
        }
    }

    func fetchWeather(manual: Bool = true) async {
        if data.config.anonymousNetwork {
            weatherStatus = "通信匿名モードが有効です。外部通信を停止しています。"
            return
        }
        if !manual && !data.config.automaticWeather {
            weatherStatus = "自動外部通信は停止中です。手動の「更新」で取得できます。"
            return
        }
        guard let prefecture = NEXUSPrefecture.all.first(where: { $0.name == data.config.selectedPrefecture }) else { return }
        isLoadingWeather = true
        weatherStatus = "\(prefecture.name)の代表地点から取得中…"
        defer { isLoadingWeather = false }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(prefecture.latitude)),
            .init(name: "longitude", value: String(prefecture.longitude)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m"),
            .init(name: "hourly", value: "precipitation,precipitation_probability"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            .init(name: "timezone", value: "Asia/Tokyo"),
            .init(name: "forecast_days", value: "2"),
            .init(name: "past_days", value: "1")
        ]
        do {
            guard let url = components.url else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 12
            let (bytes, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let root = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] ?? [:]
            let current = root["current"] as? [String: Any] ?? [:]
            let daily = root["daily"] as? [String: Any] ?? [:]
            let hourly = root["hourly"] as? [String: Any] ?? [:]
            guard let temperature = current["temperature_2m"] as? Double else { throw URLError(.cannotParseResponse) }
            let code = current["weather_code"] as? Int ?? -1
            let times = hourly["time"] as? [String] ?? []
            let rain = hourly["precipitation"] as? [Double] ?? []
            let probability = hourly["precipitation_probability"] as? [Double] ?? []
            let currentTime = current["time"] as? String ?? ""
            let currentDate = String(currentTime.prefix(10))
            let dailyTimes = daily["time"] as? [String] ?? []
            let dailyIndex = max(0, dailyTimes.firstIndex(of: currentDate) ?? 0)
            let maxTemps = daily["temperature_2m_max"] as? [Double] ?? []
            let minTemps = daily["temperature_2m_min"] as? [Double] ?? []
            let probs = daily["precipitation_probability_max"] as? [Double] ?? []
            let hourRows: [NEXUSRainHour] = times.indices.compactMap { index in
                guard index < rain.count else { return nil }
                return NEXUSRainHour(time: times[index], millimeters: rain[index], probability: index < probability.count ? probability[index] : nil)
            }
            let snapshot = NEXUSWeather(
                prefecture: prefecture.name,
                temperature: temperature,
                apparentTemperature: current["apparent_temperature"] as? Double,
                description: NEXUSWeather.description(for: code),
                symbol: NEXUSWeather.symbol(for: code),
                humidity: current["relative_humidity_2m"] as? Double,
                precipitation: current["precipitation"] as? Double,
                windSpeed: current["wind_speed_10m"] as? Double,
                windDirection: current["wind_direction_10m"] as? Double,
                high: dailyIndex < maxTemps.count ? maxTemps[dailyIndex] : nil,
                low: dailyIndex < minTemps.count ? minTemps[dailyIndex] : nil,
                dailyProbability: dailyIndex < probs.count ? probs[dailyIndex] : nil,
                currentTime: currentTime,
                hours: hourRows
            )
            weather = snapshot
            weatherStatus = "\(currentTime.suffix(5)) 時点（日本時間）・データ：Open-Meteo"
        } catch {
            weatherStatus = "天気を取得できませんでした：\(error.localizedDescription)"
        }
    }

    func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.networkIsOnline = path.status == .satisfied
                self?.networkStatus = path.status == .satisfied ? "オンライン" : "オフライン"
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func evaluateSleepState(now: Date = Date()) {
        guard data.config.sleepEnabled else { sleepOverlayVisible = false; return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let current = formatter.string(from: now)
        let start = data.config.sleepStart
        let end = data.config.sleepEnd
        let isWithin: Bool
        if start <= end { isWithin = current >= start && current < end }
        else { isWithin = current >= start || current < end }
        sleepOverlayVisible = isWithin
    }

    func runSecurityAudit() -> String {
        var rows: [(Bool, String)] = []
        rows.append((true, "保存データはこのアプリのUserDefaults内にあります。アプリ自身から外部へ自動送信しません。"))
        rows.append((!data.config.automaticWeather, "天気の自動外部通信：\(data.config.automaticWeather ? "許可中" : "停止中")"))
        rows.append((!data.config.anonymousNetwork || !data.config.automaticWeather, "匿名通信モードと自動天気通信の設定を確認"))
        rows.append((data.memos.count <= 200, "メモ件数：\(data.memos.count) / 200"))
        rows.append((data.boardRecords.count <= 500, "掲示板記録：\(data.boardRecords.count)件"))
        rows.append((storageBytes < 7_500_000, "アプリ保存データ概算：\(ByteCountFormatter.string(fromByteCount: Int64(storageBytes), countStyle: .file))"))
        rows.append((true, "URLチェッカーは構文ベースのローカル判定であり、サイトの安全性を保証しません。"))
        let score = Int((Double(rows.filter(\.0).count) / Double(max(rows.count, 1)) * 100).rounded())
        lastSecurityScore = score
        let header = "NEXUS SUPER4.1 ネイティブ・セキュリティ診断\n実行時刻：\(Date().formatted(date: .complete, time: .shortened))\n安全目安：\(score) / 100（\(score >= 90 ? "良好" : score >= 70 ? "注意" : "要確認")）\n\n"
        let details = rows.map { ($0.0 ? "[OK] " : "[要確認] ") + $0.1 }.joined(separator: "\n")
        lastSecurityReport = header + details + "\n\nこの診断はアプリ内部の簡易チェックです。OS、他アプリ、通信先のマルウェア検査ではありません。"
        return lastSecurityReport
    }

    func exportJSON(encryptedWith passphrase: String? = nil) throws -> Data {
        let plain = try JSONEncoder.nexus.encode(data)
        guard let passphrase, !passphrase.isEmpty else { return plain }
        return try NEXUSBackup.encrypt(plain, passphrase: passphrase)
    }

    func importJSON(_ bytes: Data, passphrase: String? = nil) throws {
        let plain: Data
        if let envelope = try? JSONDecoder().decode(NEXUSEncryptedEnvelope.self, from: bytes) {
            guard let passphrase, passphrase.count >= 12 else { throw NEXUSBackupError.passphraseRequired }
            plain = try NEXUSBackup.decrypt(envelope, passphrase: passphrase)
        } else {
            plain = bytes
        }
        let decoded = try JSONDecoder.nexus.decode(NEXUSData.self, from: plain)
        data = decoded
        save()
    }
}

extension JSONEncoder {
    static var nexus: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var nexus: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension Date {
    var nexusDayKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    var nexusJapanese: String { formatted(Date.FormatStyle().year().month(.wide).day().weekday(.wide).locale(Locale(identifier: "ja_JP"))) }
}

// MARK: - Weather models and all 47 prefectures

struct NEXUSPrefecture: Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    let note: String
    var id: String { name }

    static let all: [NEXUSPrefecture] = [
        .init(name:"北海道",latitude:43.0642,longitude:141.3469,note:"札幌市付近"), .init(name:"青森県",latitude:40.8244,longitude:140.7400,note:"青森市付近"),
        .init(name:"岩手県",latitude:39.7036,longitude:141.1527,note:"盛岡市付近"), .init(name:"宮城県",latitude:38.2682,longitude:140.8694,note:"仙台市付近"),
        .init(name:"秋田県",latitude:39.7186,longitude:140.1024,note:"秋田市付近"), .init(name:"山形県",latitude:38.2404,longitude:140.3633,note:"山形市付近"),
        .init(name:"福島県",latitude:37.7503,longitude:140.4676,note:"福島市付近"), .init(name:"茨城県",latitude:36.3418,longitude:140.4468,note:"水戸市付近"),
        .init(name:"栃木県",latitude:36.5657,longitude:139.8836,note:"宇都宮市付近"), .init(name:"群馬県",latitude:36.3907,longitude:139.0604,note:"前橋市付近"),
        .init(name:"埼玉県",latitude:35.8617,longitude:139.6455,note:"さいたま市付近"), .init(name:"千葉県",latitude:35.6073,longitude:140.1063,note:"千葉市付近"),
        .init(name:"東京都",latitude:35.6895,longitude:139.6917,note:"新宿区付近"), .init(name:"神奈川県",latitude:35.4478,longitude:139.6425,note:"横浜市付近"),
        .init(name:"新潟県",latitude:37.9026,longitude:139.0236,note:"新潟市付近"), .init(name:"富山県",latitude:36.6953,longitude:137.2113,note:"富山市付近"),
        .init(name:"石川県",latitude:36.5944,longitude:136.6256,note:"金沢市付近"), .init(name:"福井県",latitude:36.0652,longitude:136.2216,note:"福井市付近"),
        .init(name:"山梨県",latitude:35.6642,longitude:138.5684,note:"甲府市付近"), .init(name:"長野県",latitude:36.6513,longitude:138.1810,note:"長野市付近"),
        .init(name:"岐阜県",latitude:35.3912,longitude:136.7223,note:"岐阜市付近"), .init(name:"静岡県",latitude:34.9769,longitude:138.3831,note:"静岡市付近"),
        .init(name:"愛知県",latitude:35.1802,longitude:136.9066,note:"名古屋市付近"), .init(name:"三重県",latitude:34.7303,longitude:136.5086,note:"津市付近"),
        .init(name:"滋賀県",latitude:35.0179,longitude:135.8546,note:"大津市付近"), .init(name:"京都府",latitude:35.0116,longitude:135.7681,note:"京都市付近"),
        .init(name:"大阪府",latitude:34.6863,longitude:135.5200,note:"大阪市付近"), .init(name:"兵庫県",latitude:34.6913,longitude:135.1830,note:"神戸市付近"),
        .init(name:"奈良県",latitude:34.6851,longitude:135.8329,note:"奈良市付近"), .init(name:"和歌山県",latitude:34.2260,longitude:135.1675,note:"和歌山市付近"),
        .init(name:"鳥取県",latitude:35.5039,longitude:134.2377,note:"鳥取市付近"), .init(name:"島根県",latitude:35.4723,longitude:133.0505,note:"松江市付近"),
        .init(name:"岡山県",latitude:34.6618,longitude:133.9344,note:"岡山市付近"), .init(name:"広島県",latitude:34.3963,longitude:132.4596,note:"広島市付近"),
        .init(name:"山口県",latitude:34.1861,longitude:131.4705,note:"山口市付近"), .init(name:"徳島県",latitude:34.0658,longitude:134.5593,note:"徳島市付近"),
        .init(name:"香川県",latitude:34.3401,longitude:134.0434,note:"高松市付近"), .init(name:"愛媛県",latitude:33.8416,longitude:132.7657,note:"松山市付近"),
        .init(name:"高知県",latitude:33.5597,longitude:133.5311,note:"高知市付近"), .init(name:"福岡県",latitude:33.6064,longitude:130.4183,note:"福岡市付近"),
        .init(name:"佐賀県",latitude:33.2494,longitude:130.2988,note:"佐賀市付近"), .init(name:"長崎県",latitude:32.7448,longitude:129.8737,note:"長崎市付近"),
        .init(name:"熊本県",latitude:32.7898,longitude:130.7417,note:"熊本市付近"), .init(name:"大分県",latitude:33.2382,longitude:131.6126,note:"大分市付近"),
        .init(name:"宮崎県",latitude:31.9111,longitude:131.4239,note:"宮崎市付近"), .init(name:"鹿児島県",latitude:31.5602,longitude:130.5581,note:"鹿児島市付近"),
        .init(name:"沖縄県",latitude:26.2124,longitude:127.6809,note:"那覇市付近")
    ]
}

struct NEXUSRainHour: Identifiable {
    let time: String
    let millimeters: Double
    let probability: Double?
    var id: String { time }
}

struct NEXUSWeather {
    let prefecture: String
    let temperature: Double
    let apparentTemperature: Double?
    let description: String
    let symbol: String
    let humidity: Double?
    let precipitation: Double?
    let windSpeed: Double?
    let windDirection: Double?
    let high: Double?
    let low: Double?
    let dailyProbability: Double?
    let currentTime: String
    let hours: [NEXUSRainHour]

    static func description(for code: Int) -> String {
        switch code {
        case 0: return "快晴"; case 1: return "晴れ"; case 2: return "一部曇り"; case 3: return "曇り"
        case 45: return "霧"; case 48: return "着氷性の霧"; case 51: return "弱い霧雨"; case 53: return "霧雨"; case 55: return "強い霧雨"
        case 56,57: return "着氷性の霧雨"; case 61: return "小雨"; case 63: return "雨"; case 65: return "大雨"
        case 66,67: return "着氷性の雨"; case 71: return "小雪"; case 73: return "雪"; case 75: return "大雪"; case 77: return "霧雪"
        case 80: return "にわか雨"; case 81: return "強いにわか雨"; case 82: return "激しいにわか雨"; case 85: return "にわか雪"; case 86: return "強いにわか雪"
        case 95: return "雷雨"; case 96,99: return "雹を伴う雷雨"; default: return "天気情報あり"
        }
    }
    static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "☀️"; case 1: return "🌤️"; case 2: return "⛅"; case 3: return "☁️"
        case 45,48: return "🌫️"; case 51,53,55,80,81: return "🌦️"; case 56,57,61,63,65,66,67: return "🌧️"
        case 71,73,75,77,85,86: return "🌨️"; case 82,95,96,99: return "⛈️"; default: return "🌡️"
        }
    }
}

// MARK: - Theme, shared controls and visual background

extension Color {
    init(nexusHex: String) {
        let value = nexusHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        let r, g, b: Double
        if value.count == 6 {
            r = Double((number >> 16) & 0xFF) / 255
            g = Double((number >> 8) & 0xFF) / 255
            b = Double(number & 0xFF) / 255
        } else { r = 0.16; g = 0.78; b = 0.95 }
        self.init(red: r, green: g, blue: b)
    }
}

struct NEXUSBackground: View {
    @EnvironmentObject private var store: NEXUSStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.008, green: 0.012, blue: 0.035)
                let mode = store.data.config.wallpaperMode
                if mode == "calm" {
                    RadialGradient(colors: [Color.indigo.opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: proxy.size.width * 0.9)
                } else {
                    RadialGradient(colors: [Color.purple.opacity(mode == "deep" ? 0.28 : 0.55), .clear], center: .topLeading, startRadius: 10, endRadius: proxy.size.width * 0.65)
                    RadialGradient(colors: [Color.cyan.opacity(mode == "deep" ? 0.16 : 0.35), .clear], center: .topTrailing, startRadius: 5, endRadius: proxy.size.width * 0.55)
                    RadialGradient(colors: [Color.blue.opacity(0.28), .clear], center: .bottom, startRadius: 10, endRadius: proxy.size.width * 0.7)
                }
                if mode == "space" || mode == "deep" {
                    ForEach(0..<95, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(Double((i * 17) % 5 + 2) / 20))
                            .frame(width: i % 9 == 0 ? 2.2 : 1.1, height: i % 9 == 0 ? 2.2 : 1.1)
                            .position(x: proxy.size.width * CGFloat((i * 37 % 997)) / 997,
                                      y: proxy.size.height * CGFloat((i * 73 % 991)) / 991)
                    }
                }
                if mode == "grid" {
                    Canvas { context, size in
                        var lines = Path()
                        stride(from: 0.0, through: size.width, by: 32.0).forEach { x in
                            lines.move(to: CGPoint(x: x, y: 0)); lines.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        stride(from: 0.0, through: size.height, by: 32.0).forEach { y in
                            lines.move(to: CGPoint(x: 0, y: y)); lines.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(lines, with: .color(Color.cyan.opacity(0.18)), lineWidth: 0.7)
                    }
                }
                if mode == "cpc", let image = NEXUSWallpaper.image {
                    image.resizable().scaledToFill().opacity(0.42).overlay(Color.black.opacity(0.42))
                }
                if mode == "custom", let image = NEXUSWallpaper.image(data: store.data.config.customWallpaper) {
                    image.resizable().scaledToFill().overlay(Color.black.opacity(0.28))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .ignoresSafeArea()
        }
    }
}

private enum NEXUSWallpaper {
    static var image: Image? {
        guard let url = Bundle.main.url(forResource: "NEXUSWallpaper", withExtension: "jpg"),
              let raw = NEXUSPlatformImage(contentsOfFile: url.path) else { return nil }
        #if canImport(UIKit)
        return Image(uiImage: raw)
        #elseif canImport(AppKit)
        return Image(nsImage: raw)
        #else
        return nil
        #endif
    }

    static func image(data: Data?) -> Image? {
        guard let data, let raw = NEXUSPlatformImage(data: data) else { return nil }
        #if canImport(UIKit)
        return Image(uiImage: raw)
        #elseif canImport(AppKit)
        return Image(nsImage: raw)
        #else
        return nil
        #endif
    }
}

struct NEXUSCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    @EnvironmentObject private var store: NEXUSStore

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline.weight(.semibold)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.66)) }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(nexusHex: store.data.config.accentHex).opacity(0.38), lineWidth: 1))
        .shadow(color: Color(nexusHex: store.data.config.accentHex).opacity(0.12), radius: 18, y: 4)
    }
}

struct NEXUSActionButton: View {
    let title: String
    var systemImage: String? = nil
    var role: ButtonRole? = nil
    let action: () -> Void
    @EnvironmentObject private var store: NEXUSStore

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(Color(nexusHex: store.data.config.accentHex).opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(Color(nexusHex: store.data.config.accentHex).opacity(0.48), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation and dashboard

enum NEXUSSheet: String, Identifiable {
    case settings, notes, board, codeBridge, assistant, urlChecker, security, developer, drawing, games, translator, news, sleep
    var id: String { rawValue }
}

struct NEXUSRootView: View {
    @EnvironmentObject private var store: NEXUSStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: NEXUSSheet?
    @State private var searchText = ""
    @State private var selectedEngine = "Google"
    @State private var currentDate = Date()
    @State private var showPrivacyCover = false
    @State private var showSleepSettings = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            NEXUSBackground()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        header(proxy: proxy)
                        clockPanel(date: currentDate)
                        searchPanel
                        appLauncher
                        bookmarksPanel
                        WeatherCard()
                        timerAndStopwatch
                        musicAndBGM
                        memoAndTodo(proxy: proxy)
                        networkPanel
                        calendarPanel
                        calculatorPanel
                        translatorPanel
                        aiPanel
                        boardPreview
                        systemMonitor
                        footer
                    }
                    .frame(maxWidth: 1120)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 70)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .overlay(alignment: .bottomTrailing) {
                    Button { withAnimation { proxy.scrollTo("top", anchor: .top) } } label: {
                        Image(systemName: "arrow.up.to.line")
                            .font(.headline).foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Color(nexusHex: store.data.config.accentHex).opacity(0.9), in: Circle())
                            .shadow(radius: 10)
                    }
                    .padding(18)
                }
                .onChange(of: sheet) { _, newValue in
                    if newValue == nil { store.evaluateSleepState() }
                }
            }
            if showPrivacyCover || store.privacyShieldVisible {
                privacyCover
            }
            if store.screenProtectVisible {
                screenProtectOverlay
            }
            if store.sleepOverlayVisible {
                sleepOverlay
            }
        }
        .sheet(item: $sheet) { route in
            sheetDestination(route).environmentObject(store)
        }
        .onReceive(ticker) { date in
            currentDate = date
            store.evaluateSleepState(now: date)
        }
        .onChange(of: scenePhase) { _, phase in
            let shouldHide = phase != .active
            showPrivacyCover = store.data.config.privacyBlur && shouldHide
            if store.data.config.screenProtect && shouldHide { store.screenProtectVisible = true }
        }
        .onAppear {
            selectedEngine = store.data.config.searchEngine
            if store.data.config.automaticWeather { Task { await store.fetchWeather(manual: false) } }
        }
    }

    @ViewBuilder private func sheetDestination(_ route: NEXUSSheet) -> some View {
        NavigationStack {
            Group {
                switch route {
                case .settings: NEXUSSettingsView()
                case .notes: NEXUSNotesView()
                case .board: NEXUSBoardView()
                case .codeBridge: NEXUSCodeBridgeView()
                case .assistant: NEXUSAssistantView()
                case .urlChecker: NEXUSURLCheckerView()
                case .security: NEXUSSecurityView()
                case .developer: NEXUSDeveloperView()
                case .drawing: NEXUSDrawingView()
                case .games: NEXUSGamesView()
                case .translator: NEXUSTranslatorView()
                case .news: NEXUSNewsView()
                case .sleep: NEXUSSleepSettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("閉じる") { sheet = nil }
                }
            }
        }
        .tint(Color(nexusHex: store.data.config.accentHex))
    }

    private func header(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.title2.weight(.bold)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXUS SUPER4.1").font(.headline.weight(.black)).tracking(2.2)
                    Text("FEATURE CONTROL CENTER").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 4)
                Menu {
                    Button("カスタマイズ", systemImage: "slider.horizontal.3") { sheet = .settings }
                    Button("掲示板記録", systemImage: "text.bubble") { sheet = .board }
                    Button("CodeBridge", systemImage: "chevron.left.forwardslash.chevron.right") { sheet = .codeBridge }
                    Button("NEXUSAssistant+", systemImage: "sparkles") { sheet = .assistant }
                    Button("セキュリティ診断", systemImage: "lock.shield") { sheet = .security }
                    Button("開発者モード", systemImage: "wrench.and.screwdriver") { sheet = .developer }
                    Button("URLチェッカー", systemImage: "link.badge.plus") { sheet = .urlChecker }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill").font(.title2)
                }
                .accessibilityLabel("機能メニュー")
            }
            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    navChip("ホーム", "house.fill", proxy, "top")
                    navChip("天気", "cloud.sun.fill", proxy, "weather")
                    navChip("タイマー", "timer", proxy, "timer")
                    navChip("メモ", "note.text", proxy, "memo")
                    navChip("Todo", "checkmark.circle", proxy, "todo")
                    navChip("予定表", "calendar", proxy, "calendar")
                    navChip("電卓", "plus.forwardslash.minus", proxy, "calculator")
                    navChip("開発", "chevron.left.forwardslash.chevron.right", proxy, "code")
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 4)
        .id("top")
    }

    private func navChip(_ title: String, _ symbol: String, _ proxy: ScrollViewProxy, _ target: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo(target, anchor: .top) } } label: {
            Label(title, systemImage: symbol).font(.caption.weight(.semibold)).padding(.horizontal, 11).padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color(nexusHex: store.data.config.accentHex).opacity(0.35)))
        }.buttonStyle(.plain)
    }

    private func clockPanel(date: Date) -> some View {
        NEXUSCard("◈ NEXUS CHRONOGRAPH", subtitle: date.nexusJapanese) {
            HStack(spacing: 16) {
                NEXUSAnalogClock(date: date).frame(width: 94, height: 94)
                Spacer(minLength: 0)
                VStack(alignment: .center, spacing: 5) {
                    Text(date.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.55)
                        .shadow(color: Color(nexusHex: store.data.config.accentHex).opacity(0.9), radius: 16)
                    Text(date.formatted(.dateTime.year().month(.twoDigits).day().weekday(.wide).locale(Locale(identifier: "ja_JP"))))
                        .font(.caption.weight(.medium)).tracking(1).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var searchPanel: some View {
        NEXUSCard("⌕ SMART SEARCH", subtitle: "検索エンジンを選択して検索") {
            HStack(spacing: 7) {
                TextField("検索するキーワードを入力…", text: $searchText)
                    .textFieldStyle(.plain).padding(11).background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                    .onSubmit(performSearch)
                Button(action: performSearch) { Image(systemName: "magnifyingglass").font(.headline).padding(12).background(Color(nexusHex: store.data.config.accentHex).opacity(0.25), in: RoundedRectangle(cornerRadius: 12)) }
                    .buttonStyle(.plain)
            }
            HStack(spacing: 6) {
                ForEach(["Google", "Yahoo", "DuckDuckGo", "Bing", "Brave", "Ecosia", "Startpage"], id: \.self) { engine in
                    Button(engine) { selectedEngine = engine; store.update { $0.config.searchEngine = engine } }
                        .font(.caption2.weight(.semibold)).padding(.horizontal, 9).padding(.vertical, 6)
                        .background(selectedEngine == engine ? Color(nexusHex: store.data.config.accentHex).opacity(0.38) : .white.opacity(0.08), in: Capsule())
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        let engines = NEXUSConstants.searchEngines
        let base = engines[selectedEngine] ?? engines["Google"]!
        if let url = URL(string: base + (query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")) {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #elseif canImport(AppKit)
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    private var appLauncher: some View {
        NEXUSCard("◈ APP LAUNCHER", subtitle: "カテゴリ別のWebアプリ・サービス") {
            ForEach(NEXUSConstants.appGroups, id: \.name) { group in
                VStack(alignment: .leading, spacing: 7) {
                    Text(group.name).font(.subheadline.weight(.bold)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                        ForEach(group.items, id: \.name) { item in
                            Button {
                                guard let url = URL(string: item.url) else { return }
                                #if canImport(UIKit)
                                UIApplication.shared.open(url)
                                #elseif canImport(AppKit)
                                NSWorkspace.shared.open(url)
                                #endif
                            } label: {
                                VStack(spacing: 5) {
                                    Text(item.icon).font(.title2).frame(width: 52, height: 48)
                                        .background(LinearGradient(colors: [Color(nexusHex: store.data.config.accentHex).opacity(0.5), .purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                                    Text(item.name).font(.caption2.weight(.medium)).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity).padding(7)
                                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 13))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var bookmarksPanel: some View {
        NEXUSCard("★ BOOKMARKS", subtitle: "お気に入りのリンク") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(store.data.bookmarks) { bookmark in
                    LinkTile(name: bookmark.name, url: bookmark.url)
                }
            }
            HStack(spacing: 7) {
                NEXUSActionButton(title: "ブックマークを編集", systemImage: "pencil") { sheet = .settings }
                Spacer()
                Text("\(store.data.bookmarks.count) 件").font(.caption).foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var timerAndStopwatch: some View {
        VStack(spacing: 14) {
            TimerStopwatchCard().id("timer")
            NEXUSBGMCard()
        }
    }

    private var musicAndBGM: some View {
        VStack(spacing: 14) { NEXUSMusicCard() }
    }

    private func memoAndTodo(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 14) {
            NEXUSTodoCard().id("todo")
            NEXUSMemoPreview { sheet = .notes }.id("memo")
        }
    }

    private var networkPanel: some View { NEXUSNetworkCard() }
    private var calendarPanel: some View { NEXUSCalendarCard().id("calendar") }
    private var calculatorPanel: some View { NEXUSCalculatorCard().id("calculator") }
    private var translatorPanel: some View {
        NEXUSCard("🌐 翻訳", subtitle: "翻訳サイトを利用できます") {
            Text("入力した文章を外部翻訳サービスへ送る場合があります。パスワードなどの秘密情報は入力しないでください。")
                .font(.caption).foregroundStyle(.white.opacity(0.68))
            HStack { NEXUSActionButton(title: "翻訳を開く", systemImage: "translate") { sheet = .translator }; Spacer() }
        }
    }
    private var aiPanel: some View {
        NEXUSCard("✦ AI SERVICES", subtitle: "質問内容は開いた外部サービスへ送られます") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                ForEach(NEXUSConstants.aiServices, id: \.name) { service in
                    LinkTile(name: service.name, url: service.url, icon: service.icon)
                }
            }
            HStack { NEXUSActionButton(title: "NEXUSAssistant+", systemImage: "sparkles") { sheet = .assistant }; NEXUSActionButton(title: "ニュース", systemImage: "newspaper") { sheet = .news } }
        }
    }
    private var boardPreview: some View {
        NEXUSCard("📝 NEXUS 掲示板記録", subtitle: "感想・近況・お知らせを端末内に保存") {
            Text("保存された記録：\(store.data.boardRecords.count) 件").font(.caption).foregroundStyle(.white.opacity(0.65))
            HStack { NEXUSActionButton(title: "掲示板を開く", systemImage: "text.bubble") { sheet = .board }; Spacer() }
        }
    }
    private var systemMonitor: some View {
        NEXUSCard("◈ NEXUS SYSTEM MONITOR", subtitle: "端末内の状態のみ・外部送信なし") {
            metric("アプリ保存データ概算", ByteCountFormatter.string(fromByteCount: Int64(store.storageBytes), countStyle: .file))
            metric("ネットワーク", store.networkStatus)
            metric("メモ／予定／Todo", "\(store.data.memos.count) / \(store.data.events.count) / \(store.data.todosByDate.values.reduce(0) { $0 + $1.count })")
            metric("端末メモリ", ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
            HStack { NEXUSActionButton(title: "セキュリティ診断", systemImage: "shield.lefthalf.filled") { sheet = .security }; NEXUSActionButton(title: "開発者管理", systemImage: "wrench.and.screwdriver") { sheet = .developer } }
        }
    }
    private func metric(_ name: String, _ value: String) -> some View {
        HStack { Text(name).font(.caption).foregroundStyle(.white.opacity(0.68)); Spacer(); Text(value).font(.caption.monospacedDigit().weight(.semibold)) }
            .padding(.vertical, 3)
    }
    private var footer: some View {
        NEXUSCard("◈ NEXUS SUPER4.1", subtitle: "宇宙空間版・Native SwiftUI") {
            Text("天気：Open-Meteo。ニュース：各報道機関へのリンク。外部リンク・翻訳・AIは各提供者のサービスを開きます。")
                .font(.caption).foregroundStyle(.white.opacity(0.64))
            DisclosureGroup("📜 利用規約・著作権・出典") { NEXUSTermsView() }
                .font(.subheadline.weight(.semibold))
            HStack { Text("© 2026 NEXUS. All rights reserved.").font(.caption2).foregroundStyle(.white.opacity(0.5)); Spacer(); NEXUSActionButton(title: "設定", systemImage: "gearshape") { sheet = .settings } }
        }
    }

    private var privacyCover: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).overlay(Color.black.opacity(0.65))
            VStack(spacing: 10) { Image(systemName: "eye.slash.fill").font(.largeTitle); Text("画面プライバシー保護中").font(.headline); Text("NEXUSに戻ると表示が復帰します。").font(.caption) }
                .padding(24).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }.ignoresSafeArea()
    }

    private var screenProtectOverlay: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill").font(.system(size: 52)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                Text("画面保護中").font(.largeTitle.bold())
                Text("画面の内容を一時的に隠しています。周囲の安全を確認してから再表示してください。")
                    .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
                NEXUSActionButton(title: "画面の表示を再開", systemImage: "lock.open") { store.screenProtectVisible = false }
                Text("これはアプリ内の表示保護です。OSロックやスクリーンショット防止ではありません。").font(.caption2).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
            }.padding(30).frame(maxWidth: 420)
        }.ignoresSafeArea()
    }

    private var sleepOverlay: some View {
        ZStack {
            Color(red: 0.015, green: 0.025, blue: 0.08).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("☾").font(.system(size: 70)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                Text("おやすみ制限中").font(.largeTitle.weight(.light))
                Text(store.data.config.sleepMessage).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
                NEXUSActionButton(title: "5分だけ一時解除", systemImage: "pause.circle") { store.sleepOverlayVisible = false; DispatchQueue.main.asyncAfter(deadline: .now() + 300) { store.evaluateSleepState() } }
                NEXUSActionButton(title: "設定を見直す", systemImage: "gearshape") { store.sleepOverlayVisible = false; sheet = .sleep }
                Text("この機能は自主的な休憩を助けるものです。端末全体のロックではありません。").font(.caption2).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
            }.padding(28).frame(maxWidth: 420)
        }.ignoresSafeArea()
    }
}

struct LinkTile: View {
    let name: String
    let url: String
    var icon = "🔗"
    var body: some View {
        Group {
            if let link = URL(string: url) {
                Link(destination: link) {
                    VStack(spacing: 5) {
                        Text(icon).font(.title2)
                        Text(name).font(.caption2.weight(.semibold)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .padding(7)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }.buttonStyle(.plain)
    }
}

struct NEXUSAnalogClock: View {
    let date: Date
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            let seconds = Double(components.second ?? 0)
            let minutes = Double(components.minute ?? 0) + seconds / 60
            let hours = Double((components.hour ?? 0) % 12) + minutes / 60
            ZStack {
                Circle().fill(Color.white.opacity(0.05))
                Circle().stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                ForEach(0..<60, id: \.self) { tick in
                    Capsule().fill(tick % 5 == 0 ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                        .frame(width: tick % 5 == 0 ? 2 : 1, height: tick % 5 == 0 ? 7 : 3)
                        .offset(y: -size * 0.44).rotationEffect(.degrees(Double(tick) * 6))
                }
                clockHand(length: size * 0.23, width: 3.6, angle: hours * 30)
                clockHand(length: size * 0.34, width: 2.4, angle: minutes * 6)
                clockHand(length: size * 0.38, width: 1.2, angle: seconds * 6, color: Color.cyan)
                Circle().fill(Color.cyan).frame(width: 6, height: 6)
            }.padding(size * 0.02)
        }
    }
    private func clockHand(length: CGFloat, width: CGFloat, angle: Double, color: Color = .white) -> some View {
        Capsule().fill(color).frame(width: width, height: length).offset(y: -length * 0.43).rotationEffect(.degrees(angle))
    }
}

// MARK: - Dashboard feature cards

struct WeatherCard: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var showHours = false
    var body: some View {
        NEXUSCard("🌤 天気", subtitle: "Open-Meteo・都道府県の代表地点") {
            HStack {
                Picker("都道府県", selection: Binding(get: { store.data.config.selectedPrefecture }, set: { newValue in store.update { $0.config.selectedPrefecture = newValue }; store.weather = nil })) {
                    ForEach(NEXUSPrefecture.all) { prefecture in Text(prefecture.name).tag(prefecture.name) }
                }.labelsHidden().pickerStyle(.menu)
                Spacer()
                NEXUSActionButton(title: store.isLoadingWeather ? "取得中…" : "更新", systemImage: "arrow.clockwise") { Task { await store.fetchWeather(manual: true) } }
                    .disabled(store.isLoadingWeather)
            }
            if let weather = store.weather {
                HStack(alignment: .center, spacing: 16) {
                    Text(weather.symbol).font(.system(size: 54))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(weather.temperature, specifier: "%.1f")°C").font(.system(size: 36, weight: .ultraLight, design: .rounded)).monospacedDigit()
                        Text(weather.description).font(.headline)
                        if let feel = weather.apparentTemperature { Text("体感 \(feel, specifier: "%.0f")°C").font(.caption).foregroundStyle(.white.opacity(0.7)) }
                    }
                    Spacer()
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 7) {
                    weatherValue("最高 / 最低", "\(weather.high.map { String(format: "%.0f", $0) } ?? "--")° / \(weather.low.map { String(format: "%.0f", $0) } ?? "--")°")
                    weatherValue("降水確率", "\(weather.dailyProbability.map { String(format: "%.0f", $0) } ?? "--") %")
                    weatherValue("湿度", "\(weather.humidity.map { String(format: "%.0f", $0) } ?? "--") %")
                    weatherValue("風速", "\(weather.windSpeed.map { String(format: "%.0f", $0) } ?? "--") km/h")
                    weatherValue("現在の降水", "\(weather.precipitation.map { String(format: "%.1f", $0) } ?? "--") mm")
                }
                Button { withAnimation { showHours.toggle() } } label: {
                    Label(showHours ? "時間別予報を閉じる" : "☔ 24時間・時間別予報を見る", systemImage: showHours ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }.buttonStyle(.plain)
                if showHours {
                    let nextHours = weather.hours.filter { $0.time > weather.currentTime }.prefix(24)
                    ForEach(Array(nextHours)) { hour in
                        HStack {
                            Text(String(hour.time.suffix(5))).font(.caption.monospacedDigit())
                            Spacer()
                            Text(String(format: "%.1f mm", hour.millimeters)).font(.caption.monospacedDigit())
                            Text(hour.probability.map { String(format: "%0.0f%%", $0) } ?? "--")
                                .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.7)).frame(width: 48, alignment: .trailing)
                        }
                    }
                }
            }
            Text(store.weatherStatus).font(.caption2).foregroundStyle(.white.opacity(0.62))
            Text("都道府県庁所在地付近の代表座標です。市町村単位のピンポイント予報ではありません。データ：Open-Meteo（CC BY 4.0）。")
                .font(.caption2).foregroundStyle(.white.opacity(0.46))
        }
    }
    private func weatherValue(_ title: String, _ value: String) -> some View {
        HStack { Text(title).font(.caption).foregroundStyle(.white.opacity(0.6)); Spacer(); Text(value).font(.caption.weight(.semibold).monospacedDigit()) }
    }
}

struct TimerStopwatchCard: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var minuteInput = "5"
    @State private var timerEnd: Date?
    @State private var remaining = 300
    @State private var stopwatchStart: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var laps: [TimeInterval] = []
    @State private var now = Date()
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        NEXUSCard("⏱ タイマー ＆ ストップウォッチ") {
            VStack(spacing: 10) {
                Text("TIMER").font(.caption2.weight(.bold)).tracking(3).foregroundStyle(.white.opacity(0.55))
                Text(timerEnd.map { max(0, Int($0.timeIntervalSince(now))) }.map(formatDuration) ?? formatDuration(remaining))
                    .font(.system(size: 34, weight: .ultraLight, design: .rounded)).monospacedDigit()
                HStack {
                    TextField("分", text: $minuteInput).keyboardType(.numberPad).frame(width: 65).textFieldStyle(.roundedBorder)
                    Text("分")
                    NEXUSActionButton(title: timerEnd == nil ? "開始" : "一時停止", systemImage: timerEnd == nil ? "play.fill" : "pause.fill") {
                        if timerEnd != nil { remaining = max(0, Int(timerEnd!.timeIntervalSince(now))); timerEnd = nil }
                        else { if remaining <= 0 { remaining = max(1, Int(minuteInput) ?? 5) * 60 }; timerEnd = now.addingTimeInterval(TimeInterval(remaining)) }
                    }
                    NEXUSActionButton(title: "リセット", systemImage: "arrow.counterclockwise") { timerEnd = nil; remaining = max(1, Int(minuteInput) ?? 5) * 60 }
                }
                Divider().overlay(.white.opacity(0.15))
                Text("STOPWATCH").font(.caption2.weight(.bold)).tracking(3).foregroundStyle(.white.opacity(0.55))
                Text(stopwatchText).font(.system(size: 30, weight: .ultraLight, design: .rounded)).monospacedDigit()
                HStack {
                    NEXUSActionButton(title: stopwatchStart == nil ? "スタート" : "ストップ", systemImage: stopwatchStart == nil ? "play.fill" : "pause.fill") {
                        if let start = stopwatchStart { elapsed += now.timeIntervalSince(start); stopwatchStart = nil }
                        else { stopwatchStart = now }
                    }
                    NEXUSActionButton(title: "ラップ", systemImage: "flag.fill") { if stopwatchStart != nil { laps.insert(currentElapsed, at: 0) } }
                    NEXUSActionButton(title: "リセット", systemImage: "arrow.counterclockwise") { stopwatchStart = nil; elapsed = 0; laps = [] }
                }
                ForEach(Array(laps.prefix(5).enumerated()), id: \.offset) { index, lap in
                    HStack { Text("LAP \(laps.count - index)"); Spacer(); Text(stopwatchFormat(lap)).monospacedDigit() }.font(.caption2).foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onReceive(timer) { date in
            now = date
            if let end = timerEnd, end <= date { timerEnd = nil; remaining = 0; playBeep() }
        }
    }
    private var currentElapsed: TimeInterval { elapsed + (stopwatchStart.map { now.timeIntervalSince($0) } ?? 0) }
    private var stopwatchText: String { stopwatchFormat(currentElapsed) }
    private func formatDuration(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
    private func stopwatchFormat(_ seconds: TimeInterval) -> String { String(format: "%02d:%02d.%02d", Int(seconds) / 60, Int(seconds) % 60, Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)) }
    private func playBeep() {
        #if canImport(UIKit)
        AudioServicesPlaySystemSound(1005)
        #endif
    }
}

struct NEXUSBGMCard: View {
    @State private var selected = "Epic Orchestra"
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var volume = 0.25
    private let tracks = ["Epic Orchestra", "Final Battle", "Cosmic Myth", "Classical", "80s Rock", "Heavy Metal", "Swing Jazz", "Blues", "Disco", "Funk", "R&B", "Hip-Hop", "Techno", "Deep House", "Trance", "EDM", "Pop", "Reggae", "Bossa Nova", "Salsa", "Country", "Ambient Space"]

    var body: some View {
        NEXUSCard("🎵 BGM PLAYER", subtitle: isPlaying ? "再生中 · 内蔵シンセサウンド" : "停止中 · 外部音源・外部通信不要") {
            Picker("BGM", selection: $selected) { ForEach(tracks, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
            HStack {
                NEXUSActionButton(title: isPlaying ? "停止" : "再生", systemImage: isPlaying ? "stop.fill" : "play.fill") { togglePlayback() }
                NEXUSActionButton(title: "ランダム", systemImage: "shuffle") { selected = tracks.randomElement() ?? tracks[0]; if isPlaying { startPlayback() } }
                Spacer()
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume, in: 0...1) { player?.volume = Float(volume) }.frame(maxWidth: 110)
            }
        }
        .onDisappear { stopPlayback() }
    }
    private func togglePlayback() { isPlaying ? stopPlayback() : startPlayback() }
    private func startPlayback() {
        do {
            let data = NEXUSAudioGenerator.makeLoopWAV(preset: selected)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("nexus-bgm.wav")
            try data.write(to: url, options: .atomic)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = Float(volume)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch { isPlaying = false }
    }
    private func stopPlayback() { player?.stop(); player = nil; isPlaying = false }
}

private enum NEXUSAudioGenerator {
    static func makeLoopWAV(preset: String, seconds: Double = 8, sampleRate: Double = 22050) -> Data {
        let roots: [String: Double] = ["Epic Orchestra":110,"Final Battle":82,"Cosmic Myth":146.8,"Classical":130.8,"80s Rock":82,"Heavy Metal":55,"Swing Jazz":110,"Blues":98,"Disco":98,"Funk":87,"R&B":73,"Hip-Hop":65,"Techno":55,"Deep House":65,"Trance":73,"EDM":73,"Pop":98,"Reggae":73,"Bossa Nova":87,"Salsa":98,"Country":110,"Ambient Space":55]
        let root = roots[preset] ?? 110
        let count = Int(seconds * sampleRate)
        var samples = [Int16](); samples.reserveCapacity(count)
        let scale = [0.0, 3, 5, 7, 10, 12, 15, 17]
        for index in 0..<count {
            let t = Double(index) / sampleRate
            let step = Int(t * 2) % scale.count
            let phase = t * (root * pow(2, scale[step] / 12))
            let bass = sin(2 * .pi * root * 0.5 * t) * 0.14
            let lead = sin(2 * .pi * root * pow(2, scale[step] / 12) * t) * 0.12
            let pad = sin(2 * .pi * root * 2 * t) * 0.035
            let beat = (Int(t * 2) % 4 == 0 && t.truncatingRemainder(dividingBy: 0.5) < 0.05) ? sin(2 * .pi * 65 * t) * 0.11 : 0
            let envelope = min(1, t * 8) * min(1, (seconds - t) * 8)
            let sample = max(-0.95, min(0.95, (bass + lead + pad + beat + sin(phase) * 0.0) * envelope))
            samples.append(Int16(sample * Double(Int16.max)))
        }
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + samples.count * 2)); data.append(contentsOf: Array("WAVEfmt ".utf8))
        append(UInt32(16)); append(UInt16(1)); append(UInt16(1)); append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(UInt32(samples.count * 2))
        samples.forEach { append($0) }
        return data
    }
}

struct NEXUSTodoCard: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var selectedDate = Date()
    @State private var newTodo = ""
    var body: some View {
        NEXUSCard("✅ 今日のTodo", subtitle: "日付ごとに保存・チェック状態も記録") {
            DatePicker("対象日", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.compact)
            let items = store.todoItems(for: selectedDate)
            let completed = items.filter(\.done).count
            Text("完了 \(completed) / \(items.count) 件").font(.caption.weight(.semibold)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
            HStack {
                TextField("今日やることを追加…", text: $newTodo).textFieldStyle(.roundedBorder).onSubmit(add)
                Button(action: add) { Image(systemName: "plus.circle.fill").font(.title2) }.buttonStyle(.plain)
            }
            if items.isEmpty { Text("Todoを追加してください").font(.caption).foregroundStyle(.white.opacity(0.5)).frame(maxWidth: .infinity).padding(10) }
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Button { store.toggleTodo(item.id, date: selectedDate) } label: { Image(systemName: item.done ? "checkmark.circle.fill" : "circle").foregroundStyle(item.done ? .green : .white.opacity(0.6)) }.buttonStyle(.plain)
                    Text(item.text).font(.subheadline).strikethrough(item.done).foregroundStyle(item.done ? .white.opacity(0.45) : .white).frame(maxWidth: .infinity, alignment: .leading)
                    Button(role: .destructive) { store.deleteTodo(item.id, date: selectedDate) } label: { Image(systemName: "trash").font(.caption) }.buttonStyle(.plain)
                }.padding(.vertical, 4)
            }
            HStack {
                NEXUSActionButton(title: "今日に戻る", systemImage: "calendar") { selectedDate = Date() }
                NEXUSActionButton(title: "完了分を削除", systemImage: "checkmark") { store.clearCompletedTodos(date: selectedDate) }
            }
        }
    }
    private func add() { store.addTodo(newTodo, date: selectedDate); newTodo = "" }
}

struct NEXUSMemoPreview: View {
    @EnvironmentObject private var store: NEXUSStore
    let open: () -> Void
    var body: some View {
        NEXUSCard("📝 メモ", subtitle: "最大200件・1件あたり本文20,000文字") {
            if store.data.memos.isEmpty { Text("メモはまだありません。").font(.caption).foregroundStyle(.white.opacity(0.55)) }
            ForEach(store.data.memos.sorted { ($0.pinned, $0.updatedAt) > ($1.pinned, $1.updatedAt) }.prefix(3)) { memo in
                VStack(alignment: .leading, spacing: 2) {
                    Text((memo.pinned ? "📌 " : "") + (memo.title.isEmpty ? "無題のメモ" : memo.title)).font(.subheadline.weight(.semibold))
                    Text(memo.body.replacingOccurrences(of: "\n", with: " ")).font(.caption).foregroundStyle(.white.opacity(0.62)).lineLimit(1)
                }
            }
            HStack { NEXUSActionButton(title: "メモを開く", systemImage: "note.text") { open() }; Spacer(); Text("\(store.data.memos.count) 件").font(.caption).foregroundStyle(.white.opacity(0.55)) }
        }
    }
}

struct NEXUSNotesView: View {
    @EnvironmentObject private var store: NEXUSStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var title = ""
    @State private var bodyText = ""
    @State private var pinned = false
    @State private var search = ""
    @State private var status = ""

    private var filtered: [NEXUSMemo] {
        store.data.memos.filter { search.isEmpty || ($0.title + " " + $0.body).localizedCaseInsensitiveContains(search) }
            .sorted { if $0.pinned != $1.pinned { return $0.pinned }; return $0.updatedAt > $1.updatedAt }
    }
    var body: some View {
        Form {
            Section("メモ一覧") {
                TextField("メモを検索", text: $search)
                ForEach(filtered) { memo in
                    Button {
                        selectedID = memo.id; title = memo.title; bodyText = memo.body; pinned = memo.pinned; status = ""
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text((memo.pinned ? "📌 " : "") + (memo.title.isEmpty ? "無題のメモ" : memo.title)).font(.headline)
                            Text(memo.body.replacingOccurrences(of: "\n", with: " ")).font(.caption).lineLimit(2).foregroundStyle(.secondary)
                            Text(memo.updatedAt.formatted(date: .numeric, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }
            Section(selectedID == nil ? "新規メモ" : "メモを編集") {
                TextField("題名", text: $title).onChange(of: title) { _, _ in status = "未保存の変更があります" }
                TextEditor(text: $bodyText).frame(minHeight: 180).onChange(of: bodyText) { _, _ in status = "未保存の変更があります" }
                Toggle("📌 固定", isOn: $pinned)
                HStack {
                    Button("保存") { save() }.buttonStyle(.borderedProminent)
                    Button("新規") { selectedID = nil; title = ""; bodyText = ""; pinned = false; status = "" }
                    if selectedID != nil { Button("削除", role: .destructive) { delete() } }
                }
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("NEXUS メモ")
        .toolbar { ToolbarItem(placement: .automatic) { Button("閉じる") { dismiss() } } }
    }
    private func save() {
        let cleanTitle = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        let cleanBody = String(bodyText.prefix(20_000))
        guard !cleanTitle.isEmpty || !cleanBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { status = "題名か本文を入力してください。"; return }
        store.update { value in
            if let id = selectedID, let index = value.memos.firstIndex(where: { $0.id == id }) {
                value.memos[index].title = cleanTitle; value.memos[index].body = cleanBody; value.memos[index].pinned = pinned; value.memos[index].updatedAt = Date()
            } else {
                guard value.memos.count < 200 else { return }
                let memo = NEXUSMemo(title: cleanTitle, body: cleanBody, pinned: pinned)
                value.memos.append(memo); selectedID = memo.id
            }
        }
        status = "✓ 保存しました"
    }
    private func delete() { guard let id = selectedID else { return }; store.update { $0.memos.removeAll { $0.id == id } }; selectedID = nil; title = ""; bodyText = ""; pinned = false; status = "削除しました" }
}

// MARK: - Calendar and event planner

struct NEXUSCalendarCard: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var month = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var selectedDay = Date()
    @State private var eventTitle = ""
    @State private var eventTime = Date()

    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private var monthDays: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) - 1
        return Array(repeating: nil, count: firstWeekday) + dayRange.compactMap { day in calendar.date(byAdding: .day, value: day - 1, to: interval.start) }
    }
    private var selectedEvents: [NEXUSEvent] { store.data.events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }.sorted { $0.date < $1.date } }

    var body: some View {
        NEXUSCard("📅 予定表", subtitle: "端末内に予定を保存します") {
            HStack {
                Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "ja_JP")))).font(.headline)
                Spacer()
                Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 5) {
                ForEach(weekdays, id: \.self) { day in Text(day).font(.caption2.bold()).foregroundStyle(.white.opacity(0.55)).frame(maxWidth: .infinity) }
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let hasEvent = store.data.events.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
                        Button { selectedDay = day } label: {
                            VStack(spacing: 2) {
                                Text("\(Calendar.current.component(.day, from: day))").font(.caption.weight(Calendar.current.isDate(day, inSameDayAs: selectedDay) ? .bold : .regular))
                                Circle().fill(hasEvent ? Color(nexusHex: store.data.config.accentHex) : .clear).frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(Calendar.current.isDate(day, inSameDayAs: selectedDay) ? Color(nexusHex: store.data.config.accentHex).opacity(0.35) : .white.opacity(0.035), in: RoundedRectangle(cornerRadius: 7))
                        }.buttonStyle(.plain)
                    } else { Color.clear.frame(height: 34) }
                }
            }
            Text(selectedDay.formatted(Date.FormatStyle().year().month(.wide).day().weekday(.wide).locale(Locale(identifier: "ja_JP"))))
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
            if selectedEvents.isEmpty { Text("この日の予定はありません。").font(.caption).foregroundStyle(.white.opacity(0.52)) }
            ForEach(selectedEvents) { event in
                HStack(alignment: .top, spacing: 8) {
                    Text(event.date.formatted(date: .omitted, time: .shortened)).font(.caption.monospacedDigit()).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                    VStack(alignment: .leading, spacing: 2) { Text(event.title).font(.subheadline.weight(.semibold)); if !event.note.isEmpty { Text(event.note).font(.caption).foregroundStyle(.white.opacity(0.6)) } }
                    Spacer()
                    Button(role: .destructive) { store.update { $0.events.removeAll { $0.id == event.id } } } label: { Image(systemName: "trash").font(.caption) }.buttonStyle(.plain)
                }.padding(.vertical, 3)
            }
            Divider().overlay(.white.opacity(0.12))
            TextField("予定を入力", text: $eventTitle).textFieldStyle(.roundedBorder)
            DatePicker("日時", selection: $eventTime, displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.compact)
            HStack {
                NEXUSActionButton(title: "予定を追加", systemImage: "plus") { addEvent() }
                NEXUSActionButton(title: "選択日を今日に", systemImage: "calendar") { selectedDay = Date(); month = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date() }
            }
        }
    }
    private func addEvent() {
        let name = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        store.update { $0.events.append(NEXUSEvent(title: String(name.prefix(100)), date: eventTime)) }
        selectedDay = eventTime
        month = Calendar.current.dateInterval(of: .month, for: eventTime)?.start ?? eventTime
        eventTitle = ""
    }
}

// MARK: - Calculator

struct NEXUSCalculatorCard: View {
    @State private var display = "0"
    @State private var stored: Double?
    @State private var operation: String?
    @State private var resetOnNext = false
    @State private var history = ""
    private let keys = [["AC", "±", "%", "÷"], ["7", "8", "9", "×"], ["4", "5", "6", "−"], ["1", "2", "3", "+"], ["0", ".", "⌫", "="]]

    var body: some View {
        NEXUSCard("🧮 電卓", subtitle: "四則演算・パーセント・符号反転") {
            VStack(alignment: .trailing, spacing: 4) {
                Text(history).font(.caption).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                Text(display).font(.system(size: 34, weight: .light, design: .rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            }.frame(maxWidth: .infinity, alignment: .trailing).padding(.vertical, 6)
            VStack(spacing: 6) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            Button { tap(key) } label: {
                                Text(key).font(.headline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 42)
                                    .background(["÷", "×", "−", "+", "="].contains(key) ? Color.cyan.opacity(0.28) : .white.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }.id("calculator")
    }
    private func tap(_ key: String) {
        if key == "AC" { display = "0"; stored = nil; operation = nil; history = ""; resetOnNext = false; return }
        if key == "⌫" { display = display.count > 1 ? String(display.dropLast()) : "0"; return }
        if key == "±" { if let value = Double(display) { display = String(-value) }; return }
        if key == "%" { if let value = Double(display) { display = String(value / 100) }; return }
        if ["÷", "×", "−", "+"].contains(key) {
            stored = Double(display) ?? 0; operation = key; history = "\(display) \(key)"; resetOnNext = true; return
        }
        if key == "=" {
            guard let lhs = stored, let rhs = Double(display), let op = operation else { return }
            let result: Double
            switch op { case "+": result = lhs + rhs; case "−": result = lhs - rhs; case "×": result = lhs * rhs; case "÷": result = rhs == 0 ? .nan : lhs / rhs; default: result = rhs }
            history = "\(lhs) \(op) \(rhs) ="
            display = result.isFinite ? String(format: "%.10g", result) : "Error"
            stored = nil; operation = nil; resetOnNext = true; return
        }
        if key == "." { if resetOnNext { display = "0."; resetOnNext = false } else if !display.contains(".") { display += "." }; return }
        if resetOnNext || display == "0" || display == "Error" { display = key; resetOnNext = false } else if display.count < 16 { display += key }
    }
}

// MARK: - Network monitor and manual speed test

struct NEXUSNetworkCard: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var speed = "--"
    @State private var details = "速度測定は手動操作のみです。"
    @State private var testing = false
    var body: some View {
        NEXUSCard("📶 ネットワーク", subtitle: "NWPathMonitor・速度測定は手動") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(speed).font(.system(size: 36, weight: .ultraLight, design: .rounded)).monospacedDigit()
                Text("Mbps").font(.caption).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Label(store.networkStatus, systemImage: store.networkIsOnline ? "wifi" : "wifi.slash").font(.caption.weight(.semibold))
            }
            Text(details).font(.caption).foregroundStyle(.white.opacity(0.65))
            NEXUSActionButton(title: testing ? "測定中…" : "⚡ 速度を実測（約5MB）", systemImage: "speedometer") { Task { await runSpeedTest() } }.disabled(testing || store.data.config.anonymousNetwork)
            if store.data.config.anonymousNetwork { Text("通信匿名モードにより外部速度測定を停止中です。").font(.caption2).foregroundStyle(.orange) }
            Text("測定にはCloudflareの速度測定エンドポイントを使用します。通信先にIPアドレス等が伝わります。")
                .font(.caption2).foregroundStyle(.white.opacity(0.45))
        }
    }
    private func runSpeedTest() async {
        guard !store.data.config.anonymousNetwork else { return }
        testing = true; details = "Cloudflareからデータを取得しています…"
        defer { testing = false }
        do {
            var request = URLRequest(url: URL(string: "https://speed.cloudflare.com/__down?bytes=5000000")!)
            request.timeoutInterval = 25; request.cachePolicy = .reloadIgnoringLocalCacheData
            let start = Date()
            let (bytes, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let duration = max(0.001, Date().timeIntervalSince(start))
            let mbps = Double(bytes.count) * 8 / duration / 1_000_000
            speed = String(format: "%.1f", mbps)
            details = "\(ByteCountFormatter.string(fromByteCount: Int64(bytes.count), countStyle: .file))を\(String(format: "%.2f", duration))秒で取得。実際の通信速度は環境により変動します。"
        } catch { details = "測定できませんでした：\(error.localizedDescription)" }
    }
}

// MARK: - Local music player

struct NEXUSMusicCard: View {
    @State private var player: AVPlayer?
    @State private var selectedURL: URL?
    @State private var title = "ファイル未選択"
    @State private var isPlaying = false
    @State private var showImporter = false
    @State private var message = "音楽ファイルを選択してください。"
    @State private var progress = 0.0
    @State private var duration = 0.0
    @State private var observer: Any?

    var body: some View {
        NEXUSCard("🎧 ミュージックプレーヤー", subtitle: title) {
            Text(message).font(.caption).foregroundStyle(.white.opacity(0.62))
            Slider(value: $progress, in: 0...max(duration, 1), onEditingChanged: { editing in if !editing { player?.seek(to: CMTime(seconds: progress, preferredTimescale: 600)) } })
            HStack { Text(timeText(progress)); Spacer(); Text(timeText(duration)) }.font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.62))
            HStack {
                NEXUSActionButton(title: "ファイルを選ぶ", systemImage: "folder") { showImporter = true }
                NEXUSActionButton(title: isPlaying ? "一時停止" : "再生", systemImage: isPlaying ? "pause.fill" : "play.fill") { toggle() }.disabled(player == nil)
                NEXUSActionButton(title: "停止", systemImage: "stop.fill") { player?.pause(); player?.seek(to: .zero); isPlaying = false; progress = 0 }.disabled(player == nil)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls): guard let url = urls.first else { return }; load(url)
            case .failure(let error): message = "ファイルを開けませんでした：\(error.localizedDescription)"
            }
        }
        .onDisappear { player?.pause(); if let observer { player?.removeTimeObserver(observer) } }
    }
    private func load(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        selectedURL = url
        player?.pause()
        player = AVPlayer(url: url)
        title = url.lastPathComponent
        message = access ? "端末内の選択ファイルを再生します。" : "選択したファイルを再生します。"
        isPlaying = false; progress = 0; duration = 0
        player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            let seconds = CMTimeGetSeconds(player?.currentItem?.asset.duration ?? .zero)
            DispatchQueue.main.async { duration = seconds.isFinite ? seconds : 0 }
        }
        observer = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            progress = max(0, CMTimeGetSeconds(time))
        }
    }
    private func toggle() { guard let player else { return }; if isPlaying { player.pause() } else { player.play() }; isPlaying.toggle() }
    private func timeText(_ value: Double) -> String { guard value.isFinite else { return "0:00" }; return String(format: "%d:%02d", Int(value) / 60, Int(value) % 60) }
}

// MARK: - Settings, bookmarks, privacy and backup

struct NEXUSSettingsView: View {
    @EnvironmentObject private var store: NEXUSStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var newURL = ""
    @State private var selectedWallpaper = "space"
    @State private var showResetConfirm = false
    @State private var showWallpaperImporter = false
    @State private var wallpaperStatus = "画像は端末内に保存されます。"

    var body: some View {
        Form {
            Section("外観・表示") {
                ColorPicker("アクセント色", selection: Binding(get: { Color(nexusHex: store.data.config.accentHex) }, set: { color in store.update { $0.config.accentHex = color.nexusHexString } }))
                Picker("背景スタイル", selection: Binding(get: { store.data.config.wallpaperMode }, set: { value in store.update { $0.config.wallpaperMode = value } })) {
                    Text("宇宙空間").tag("space"); Text("深宇宙ブルー").tag("deep"); Text("ネオン・グリッド").tag("grid"); Text("落ち着いた背景").tag("calm"); Text("CPC部画像").tag("cpc"); Text("カスタム画像").tag("custom")
                }
                Slider(value: Binding(get: { store.data.config.iconSize }, set: { value in store.update { $0.config.iconSize = value } }), in: 56...120, step: 2) { Text("アイコンサイズ") }
                Text("アイコンサイズ：\(Int(store.data.config.iconSize)) pt").font(.caption).foregroundStyle(.secondary)
                Picker("レイアウト", selection: Binding(get: { store.data.config.layoutMode }, set: { value in store.update { $0.config.layoutMode = value } })) {
                    Text("自動").tag("auto"); Text("PC向け").tag("pc"); Text("スマホ向け").tag("mobile")
                }
                Button("カスタム背景画像を選択") { showWallpaperImporter = true }
                if store.data.config.customWallpaper != nil {
                    Button("カスタム背景画像を削除", role: .destructive) { store.update { $0.config.customWallpaper = nil; if $0.config.wallpaperMode == "custom" { $0.config.wallpaperMode = "space" } } }
                }
                Text(wallpaperStatus).font(.caption2).foregroundStyle(.secondary)
            }
            Section("プライバシー強化") {
                Toggle("天気の自動取得を許可", isOn: Binding(get: { store.data.config.automaticWeather }, set: { value in store.update { $0.config.automaticWeather = value }; if value { Task { await store.fetchWeather(manual: false) } } }))
                Text("オフ（初期設定）では起動時・定期更新時の外部通信を停止します。手動の「更新」操作では取得できます。天気APIにはIPアドレス等が伝わります。")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("画面プライバシー保護（自動ぼかし）", isOn: Binding(get: { store.data.config.privacyBlur }, set: { value in store.update { $0.config.privacyBlur = value } }))
                Toggle("画面保護モード", isOn: Binding(get: { store.data.config.screenProtect }, set: { value in store.update { $0.config.screenProtect = value }; if value { store.screenProtectVisible = true } }))
                Toggle("通信匿名モード（外部通信を停止）", isOn: Binding(get: { store.data.config.anonymousNetwork }, set: { value in store.update { $0.config.anonymousNetwork = value; if value { $0.config.automaticWeather = false } } }))
                Text("通信匿名モードはNEXUSアプリ内の外部通信を止めるもので、IPアドレスを隠すVPNではありません。外部サイトをユーザー自身が開く操作までは制御しません。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("ブックマーク") {
                ForEach(store.data.bookmarks) { bookmark in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bookmark.name)
                            Text(bookmark.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        Button(role: .destructive) {
                            store.update { $0.bookmarks.removeAll { $0.id == bookmark.id } }
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                }
                HStack { TextField("名前", text: $newName); TextField("URL", text: $newURL).textInputAutocapitalization(.never).autocorrectionDisabled() }
                Button("ブックマークを追加") { addBookmark() }
            }
            Section("保存データ") {
                NavigationLink("設定・メモのバックアップ／復元") { NEXUSBackupView() }
                HStack { Text("ローカル保存量"); Spacer(); Text(ByteCountFormatter.string(fromByteCount: Int64(store.storageBytes), countStyle: .file)).foregroundStyle(.secondary) }
                Button("NEXUSの保存データをすべて初期化", role: .destructive) { showResetConfirm = true }
                    .confirmationDialog("NEXUSの設定・メモ・予定・Todo・掲示板を削除しますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                        Button("すべて削除", role: .destructive) { store.resetAll() }
                        Button("キャンセル", role: .cancel) {}
                    }
            }
        }
        .navigationTitle("NEXUS カスタマイズ")
        .fileImporter(isPresented: $showWallpaperImporter, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url)
                guard bytes.count <= 5_000_000, NEXUSWallpaper.image(data: bytes) != nil else {
                    wallpaperStatus = "画像を読み込めません。8 MB以下の画像を選択してください。"
                    return
                }
                store.update { $0.config.customWallpaper = bytes; $0.config.wallpaperMode = "custom" }
                wallpaperStatus = "カスタム背景画像を保存しました。"
            } catch { wallpaperStatus = "画像を読み込めませんでした：\(error.localizedDescription)" }
        }
        .toolbar { ToolbarItem(placement: .automatic) { Button("完了") { dismiss() } } }
    }
    private func addBookmark() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = newURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let url = NEXUSURLChecker.normalizedURL(raw) else { return }
        store.update { $0.bookmarks.append(NEXUSBookmark(name: String(name.prefix(100)), url: url.absoluteString)) }
        newName = ""; newURL = ""
    }
}

extension Color {
    var nexusHexString: String {
        #if canImport(UIKit)
        let resolved = UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        let resolved = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.cyan
        let r = resolved.redComponent, g = resolved.greenComponent, b = resolved.blueComponent
        #endif
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

struct NEXUSBackupView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var encrypted = true
    @State private var passphrase = ""
    @State private var document = NEXUSDataDocument(data: Data())
    @State private var exportPresented = false
    @State private var importPresented = false
    @State private var status = "暗号化を有効にする場合、12文字以上のパスフレーズが必要です。"

    var body: some View {
        Form {
            Section("エクスポート") {
                Toggle("暗号化バックアップ（AES-256-GCM）", isOn: $encrypted)
                SecureField("バックアップ用パスフレーズ（12文字以上）", text: $passphrase)
                Button("バックアップを書き出す") {
                    do {
                        let data = try store.exportJSON(encryptedWith: encrypted ? passphrase : nil)
                        document = NEXUSDataDocument(data: data)
                        exportPresented = true
                    } catch { status = "書き出しに失敗しました：\(error.localizedDescription)" }
                }
                .disabled(encrypted && passphrase.count < 12)
            }
            Section("インポート") {
                Button("バックアップファイルを選択") { importPresented = true }
                Text("復元すると、現在のNEXUS保存データはバックアップの内容に置き換わります。必要な場合は先にエクスポートしてください。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("状態") { Text(status).font(.caption) }
        }
        .navigationTitle("バックアップ")
        .fileExporter(isPresented: $exportPresented, document: document, contentType: .json, defaultFilename: "NEXUS_SUPER4.1_Backup") { result in
            status = result.map { "バックアップを保存しました：\($0.lastPathComponent)" }.mapError { $0.localizedDescription }.description
        }
        .fileImporter(isPresented: $importPresented, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url)
                try store.importJSON(bytes, passphrase: passphrase.isEmpty ? nil : passphrase)
                status = "✅ 復元しました。"
            } catch { status = "復元できませんでした：\(error.localizedDescription)" }
        }
    }
}

struct NEXUSDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct NEXUSEncryptedEnvelope: Codable {
    var format = "NEXUS_ENCRYPTED_BACKUP"
    var version = 1
    var cipher = "AES-256-GCM"
    var kdf = "PBKDF2-SHA-256"
    var iterations = 250_000
    var salt: Data
    var nonce: Data
    var ciphertext: Data
    var tag: Data
}

enum NEXUSBackupError: LocalizedError {
    case passphraseRequired, wrongPassphrase, invalidEnvelope
    var errorDescription: String? {
        switch self { case .passphraseRequired: return "復元には暗号化時と同じ12文字以上のパスフレーズが必要です。"; case .wrongPassphrase: return "復号できません。パスフレーズが違うか、ファイルが破損しています。"; case .invalidEnvelope: return "暗号化バックアップの形式が正しくありません。" }
    }
}

private enum NEXUSBackup {
    static func encrypt(_ plain: Data, passphrase: String) throws -> Data {
        guard passphrase.count >= 12 else { throw NEXUSBackupError.passphraseRequired }
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let key = pbkdf2(password: Data(passphrase.utf8), salt: salt, iterations: 250_000)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plain, using: key, nonce: nonce)
        let nonceData = nonce.withUnsafeBytes { Data($0) }
        let envelope = NEXUSEncryptedEnvelope(salt: salt, nonce: nonceData, ciphertext: sealed.ciphertext, tag: sealed.tag)
        return try JSONEncoder.nexus.encode(envelope)
    }
    static func decrypt(_ envelope: NEXUSEncryptedEnvelope, passphrase: String) throws -> Data {
        guard envelope.format == "NEXUS_ENCRYPTED_BACKUP", envelope.version == 1, envelope.cipher == "AES-256-GCM", envelope.kdf == "PBKDF2-SHA-256", envelope.iterations == 250_000, envelope.salt.count == 16, envelope.nonce.count == 12 else { throw NEXUSBackupError.invalidEnvelope }
        let key = pbkdf2(password: Data(passphrase.utf8), salt: envelope.salt, iterations: envelope.iterations)
        do {
            let nonce = try AES.GCM.Nonce(data: envelope.nonce)
            let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: envelope.ciphertext, tag: envelope.tag)
            return try AES.GCM.open(box, using: key)
        } catch { throw NEXUSBackupError.wrongPassphrase }
    }
    private static func pbkdf2(password: Data, salt: Data, iterations: Int) -> SymmetricKey {
        let key = SymmetricKey(data: password)
        var block = salt; block.append(contentsOf: [0, 0, 0, 1])
        var u = Data(HMAC<SHA256>.authenticationCode(for: block, using: key))
        var result = [UInt8](u)
        if iterations > 1 {
            for _ in 1..<iterations {
                u = Data(HMAC<SHA256>.authenticationCode(for: u, using: key))
                for index in result.indices { result[index] ^= u[index] }
            }
        }
        return SymmetricKey(data: Data(result.prefix(32)))
    }
}

// MARK: - Bulletin board records

struct NEXUSBoardView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var selectedType = "主の最近の感想"
    @State private var title = ""
    @State private var bodyText = ""
    @State private var editingID: UUID?
    @State private var status = "記録はこの端末のローカル保存領域に保存されます。"
    @State private var search = ""

    private let types = ["主の最近の感想", "近況・日記", "お知らせ", "アイデア・ひらめき", "その他"]
    private var records: [NEXUSBoardRecord] {
        store.data.boardRecords.filter { search.isEmpty || ($0.title + " " + $0.body).localizedCaseInsensitiveContains(search) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    var body: some View {
        Form {
            Section("記録一覧") {
                TextField("記録を検索", text: $search)
                ForEach(records) { record in
                    Button {
                        editingID = record.id; selectedType = record.type; title = record.title; bodyText = record.body; status = "編集中：変更後に保存してください。"
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text(record.type).font(.caption).foregroundStyle(.tint); Spacer(); Text(record.updatedAt.formatted(date: .numeric, time: .shortened)).font(.caption2).foregroundStyle(.secondary) }
                            Text(record.title).font(.headline)
                            Text(record.body).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }.buttonStyle(.plain)
                }
            }
            Section(editingID == nil ? "✍️ 記録を書く" : "記録を編集") {
                Picker("種類", selection: $selectedType) { ForEach(types, id: \.self) { Text($0).tag($0) } }
                TextField("題名（100文字以内）", text: $title)
                TextEditor(text: $bodyText).frame(minHeight: 150)
                HStack {
                    Button("💾 記録を保存") { save() }.buttonStyle(.borderedProminent)
                    Button("新規") { clearEditor() }
                    if editingID != nil { Button("削除", role: .destructive) { delete() } }
                }
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            Section("プライバシー") {
                Text("掲示板の文章は外部へ送信されません。共有端末では、同じアプリの保存領域を使う人が内容を見られる場合があります。必要なら暗号化バックアップを利用してください。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("NEXUS 掲示板記録")
    }
    private func save() {
        let cleanTitle = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        let cleanBody = String(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4000))
        guard !cleanTitle.isEmpty, !cleanBody.isEmpty else { status = "題名と本文を入力してください。"; return }
        store.update { value in
            if let id = editingID, let index = value.boardRecords.firstIndex(where: { $0.id == id }) {
                value.boardRecords[index].type = selectedType; value.boardRecords[index].title = cleanTitle; value.boardRecords[index].body = cleanBody; value.boardRecords[index].updatedAt = Date()
            } else {
                guard value.boardRecords.count < 500 else { return }
                let record = NEXUSBoardRecord(type: selectedType, title: cleanTitle, body: cleanBody)
                value.boardRecords.append(record); editingID = record.id
            }
        }
        status = "✓ 保存しました。"
    }
    private func delete() {
        guard let id = editingID else { return }
        store.update { $0.boardRecords.removeAll { $0.id == id } }
        clearEditor(); status = "削除しました。"
    }
    private func clearEditor() { editingID = nil; title = ""; bodyText = ""; selectedType = types[0] }
}

// MARK: - URL checker (local heuristic only)

struct NEXUSURLFinding: Identifiable {
    let id = UUID()
    let level: String
    let title: String
    let detail: String
}

struct NEXUSURLAnalysis {
    let host: String
    let normalized: String
    let score: Int
    let findings: [NEXUSURLFinding]
    let verdict: String
}

enum NEXUSURLChecker {
    static let shorteners: Set<String> = ["bit.ly", "tinyurl.com", "t.co", "is.gd", "cutt.ly", "rebrand.ly", "shorturl.at", "rb.gy", "buff.ly", "ow.ly", "soo.gd", "lnkd.in", "tiny.cc", "trib.al", "reurl.cc", "x.gd", "s.id"]
    static let redirectNames: Set<String> = ["url", "target", "dest", "destination", "redirect", "redirect_uri", "redirect_url", "next", "continue", "return", "returnto", "return_to", "goto", "callback", "out", "to"]
    static let secretPattern = ["token", "api_key", "apikey", "password", "passwd", "secret", "authorization", "auth", "session", "access_key", "refresh_token", "id_token"]
    static let officialDomains: [String: [String]] = [
        "Google": ["google.com", "google.co.jp", "google.co.uk", "google.de", "google.fr", "google.ca", "google.com.au"],
        "Microsoft": ["microsoft.com", "microsoftonline.com", "live.com", "office.com", "office365.com", "outlook.com", "microsoft365.com", "windows.com", "xbox.com", "azure.com"],
        "Apple": ["apple.com", "apple.co.jp", "icloud.com"],
        "PayPal": ["paypal.com", "paypalobjects.com"],
        "Amazon": ["amazon.com", "amazon.co.jp", "amazonaws.com"],
        "楽天": ["rakuten.co.jp", "rakuten.com"], "Yahoo": ["yahoo.co.jp", "yahoo.com"],
        "Facebook": ["facebook.com", "fb.com", "meta.com"], "Instagram": ["instagram.com"], "Netflix": ["netflix.com"],
        "任天堂": ["nintendo.com", "nintendo.co.jp"], "LINE": ["line.me", "linecorp.com"],
        "日本郵便": ["japanpost.jp", "post.japanpost.jp"], "DHL": ["dhl.com"], "FedEx": ["fedex.com"]
    ]

    static func normalizedURL(_ raw: String) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains(where: { $0.isWhitespace }) else { return nil }
        let candidate = value.range(of: "^[a-zA-Z][a-zA-Z0-9+.-]*:", options: .regularExpression) != nil ? value : "https://" + value
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }

    static func analyze(_ raw: String) -> NEXUSURLAnalysis? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if let colon = value.firstIndex(of: ":") {
            let scheme = value[..<colon].lowercased()
            if ["javascript", "vbscript", "data", "file", "blob", "filesystem", "about", "chrome", "chrome-extension", "view-source", "intent"].contains(String(scheme)) {
                return NEXUSURLAnalysis(host: "—", normalized: value, score: 100, findings: [NEXUSURLFinding(level: "警告", title: "危険なスキーム", detail: "http／https以外のスキームは開かずに検査対象として扱いました。")], verdict: "危険な形式")
            }
        }
        guard let url = normalizedURL(value), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let host = components.host?.lowercased() else {
            return NEXUSURLAnalysis(host: "—", normalized: value, score: 75, findings: [NEXUSURLFinding(level: "注意", title: "URL形式", detail: "一般的なHTTP／HTTPS URLとして解析できませんでした。")], verdict: "形式を確認")
        }
        var findings: [NEXUSURLFinding] = []
        var score = 0
        func add(_ level: String, _ title: String, _ detail: String, _ points: Int) {
            findings.append(NEXUSURLFinding(level: level, title: title, detail: detail)); score += points
        }
        if components.scheme?.lowercased() != "https" { add("注意", "HTTPSではありません", "暗号化されないHTTP接続です。", 15) }
        if host.hasPrefix("xn--") || host.contains(".xn--") { add("注意", "国際化ドメイン", "Punycode表記を含みます。見た目が似た別文字に注意してください。", 12) }
        if host.split(separator: ".").count < 2 { add("注意", "ドメイン形式", "一般的な公開ドメイン名とは異なる形式です。", 10) }
        if host.filter({ $0.isNumber || $0 == "." }).count == host.count { add("注意", "IPアドレス形式", "ホスト名にドメイン名ではなく数値アドレスが使われています。", 18) }
        if shorteners.contains(host) { add("注意", "短縮URL", "遷移先がURLだけでは分かりません。公式の別経路で確認してください。", 12) }
        if components.user != nil || components.password != nil { add("警告", "認証情報を含むURL", "URL内にユーザー名・パスワードが含まれています。", 35) }
        let queryItems = components.queryItems ?? []
        let redirect = queryItems.filter { redirectNames.contains($0.name.lowercased()) }
        if !redirect.isEmpty { add("注意", "リダイレクトらしきパラメータ", "転送先を指定するようなパラメータがあります。値を確認してください。", 10) }
        let secret = queryItems.filter { item in secretPattern.contains(where: { item.name.lowercased().contains($0) }) }
        if !secret.isEmpty { add("警告", "機密情報名を含むパラメータ", "トークンやパスワード等の名前を持つURLパラメータがあります。URLを共有しないでください。", 25) }
        if host.filter({ $0 == "-" }).count >= 3 || host.split(separator: ".").first?.count ?? 0 > 24 { add("注意", "不自然なホスト名", "長いホスト名またはハイフンの多いホスト名です。", 8) }
        for (brand, domains) in officialDomains {
            let matched = domains.contains { host == $0 || host.hasSuffix("." + $0) }
            if !matched && host.localizedCaseInsensitiveContains(brand.lowercased()) {
                add("注意", "ブランド名を含むドメイン", "「\(brand)」に似せた表記の可能性があります。公式ドメインと完全一致するか確認してください。", 20)
                break
            }
        }
        if findings.isEmpty { add("情報", "明らかな形式上の注意点なし", "この簡易ルールでは大きな注意点を検出しませんでした。安全性を保証するものではありません。", 0) }
        score = min(100, score)
        return NEXUSURLAnalysis(host: host, normalized: url.absoluteString, score: score, findings: findings, verdict: score >= 60 ? "注意度：高" : score >= 30 ? "注意度：中" : score > 0 ? "注意度：低" : "明らかな注意点なし")
    }
}

struct NEXUSURLCheckerView: View {
    @State private var input = ""
    @State private var result: NEXUSURLAnalysis?
    @State private var status = "URLを入力して「ローカル検査」を押してください。"
    var body: some View {
        Form {
            Section("URL検査") {
                TextField("例：https://example.com/", text: $input, axis: .vertical).textInputAutocapitalization(.never).autocorrectionDisabled()
                HStack {
                    Button("🛡️ ローカル検査") { result = NEXUSURLChecker.analyze(input); status = result == nil ? "URLを入力してください。" : "ローカル検査が完了しました。" }
                        .buttonStyle(.borderedProminent)
                    Button("消去") { input = ""; result = nil; status = "URLを入力して「ローカル検査」を押してください。" }
                }
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            if let result {
                Section("形式上の注意度") {
                    HStack { Text(result.verdict); Spacer(); Text("\(result.score) / 100").font(.title2.bold().monospacedDigit()) }
                    ProgressView(value: Double(result.score), total: 100).tint(result.score >= 60 ? .red : result.score >= 30 ? .orange : .green)
                    LabeledContent("ホスト名", value: result.host)
                    LabeledContent("正規化URL", value: result.normalized)
                    Button("ホスト名だけコピー") { NEXUSClipboard.copy(result.host) }
                }
                Section("検出内容") {
                    ForEach(result.findings) { finding in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(finding.level) · \(finding.title)").font(.headline)
                            Text(finding.detail).font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 3)
                    }
                }
            }
            Section("検査の限界") {
                Text("この数値はルールベースの目安であり、サイトの安全性を測定したものではありません。DNS、サイト評判、実際のページ内容、TLS証明書、リダイレクト先、マルウェアの有無は確認しません。入力URLを外部へ送信したり、自動で開いたりしません。警告がなくても安全を保証しません。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("NEXUS URLチェッカー")
    }
}

enum NEXUSClipboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Security report

struct NEXUSSecurityView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var report = "チェック前です。今すぐチェックを押してください。"
    @State private var checkedAt: Date?
    var body: some View {
        Form {
            Section("セキュリティ・プライバシーレポート") {
                Button("🔍 今すぐチェック") { report = store.runSecurityAudit(); checkedAt = Date() }.buttonStyle(.borderedProminent)
                if let checkedAt {
                    HStack { Text("安全目安"); Spacer(); Text("\(store.lastSecurityScore) / 100").font(.title2.bold().monospacedDigit()) }
                    ProgressView(value: Double(store.lastSecurityScore), total: 100).tint(store.lastSecurityScore >= 90 ? .green : store.lastSecurityScore >= 70 ? .orange : .red)
                    Text("実行：\(checkedAt.formatted(date: .complete, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                    ShareLink(item: report) { Label("レポートを共有／保存", systemImage: "square.and.arrow.up") }
                    Button("レポートをコピー") { NEXUSClipboard.copy(report) }
                }
            }
            Section("診断結果") { Text(report).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
            Section("重要事項") {
                Text("このレポートはアプリ内の設定と保存データの概要を検査します。OS・ブラウザ拡張機能・端末全体のマルウェアを調べるものではありません。個人データの本文は診断結果へ出力しません。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("セキュリティ診断")
    }
}

// MARK: - Translation shortcuts

struct NEXUSTranslatorView: View {
    @State private var source = "自動検出"
    @State private var target = "英語"
    @State private var input = ""
    private let languages = ["自動検出", "日本語", "英語", "中国語（簡体）", "中国語（繁体）", "韓国語", "フランス語", "ドイツ語", "スペイン語", "イタリア語", "ポルトガル語", "ロシア語", "アラビア語", "ヒンディー語"]
    var body: some View {
        Form {
            Section("翻訳") {
                Picker("翻訳元", selection: $source) { ForEach(languages, id: \.self) { Text($0).tag($0) } }
                Picker("翻訳先", selection: $target) { ForEach(languages.filter { $0 != "自動検出" }, id: \.self) { Text($0).tag($0) } }
                HStack { Spacer(); Button("⇄ 入れ替え") { let old = source; source = target; target = old == "自動検出" ? "英語" : old } }
                TextEditor(text: $input).frame(minHeight: 140)
                    .overlay(alignment: .topLeading) { if input.isEmpty { Text("翻訳したい文章を入力…").foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5).allowsHitTesting(false) } }
                Button("Google翻訳を開く") { openTranslation("https://translate.google.com/") }.buttonStyle(.borderedProminent)
                HStack { Button("DeepLを開く") { openTranslation("https://www.deepl.com/translator") }; Button("Bing翻訳を開く") { openTranslation("https://www.bing.com/translator") } }
            }
            Section("プライバシー") {
                Text("このSwift版は外部翻訳サービスを開きます。入力文は開いたサービスへ送られる場合があります。秘密情報は入力しないでください。元HTMLにあったブラウザ内蔵Translator APIの端末内翻訳は、SwiftUI版では同一APIとして移植していません。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("NEXUS 翻訳")
    }
    private func openTranslation(_ base: String) {
        var components = URLComponents(string: base)
        components?.queryItems = [URLQueryItem(name: "text", value: input), URLQueryItem(name: "sl", value: source), URLQueryItem(name: "tl", value: target)]
        guard let url = components?.url else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - News links and update panel

struct NEXUSNewsView: View {
    @State private var query = ""
    private let quickLinks: [(String, String, String)] = [
        ("NHK", "ニュース・速報", "https://www3.nhk.or.jp/news/"),
        ("Yahoo!ニュース", "国内・国際・経済", "https://news.yahoo.co.jp/"),
        ("Googleニュース", "トピック別ニュース", "https://news.google.com/top?hl=ja&gl=JP&ceid=JP:ja"),
        ("Reuters", "国際・金融", "https://www.reuters.com/world/"),
        ("BBC", "World News", "https://www.bbc.com/news"),
        ("日経電子版", "経済・企業", "https://www.nikkei.com/")
    ]
    var body: some View {
        Form {
            Section("今日のニュース") {
                Text("記事本文を取得・保存せず、報道機関の公開ページへのリンクを開きます。")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(quickLinks, id: \.0) { item in
                    if let url = URL(string: item.2) {
                        Link(destination: url) { VStack(alignment: .leading) { Text(item.0).font(.headline); Text(item.1).font(.caption).foregroundStyle(.secondary) } }
                    }
                }
            }
            Section("ニュース検索") {
                TextField("ニュースのキーワード", text: $query)
                Button("Googleニュースで検索") {
                    var c = URLComponents(string: "https://news.google.com/search")!
                    c.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "hl", value: "ja"), URLQueryItem(name: "gl", value: "JP")]
                    if let url = c.url {
                        #if canImport(UIKit)
                        UIApplication.shared.open(url)
                        #elseif canImport(AppKit)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }.disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("プライバシー") {
                Text("ニュース一覧のリンクを選んだ場合、通信先の報道機関にIPアドレスなどが伝わります。記事の内容・利用条件は各社の定めに従います。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("今日のニュース")
    }
}

// MARK: - Sleep restriction (app-only overlay)

struct NEXUSSleepSettingsView: View {
    @EnvironmentObject private var store: NEXUSStore
    @Environment(\.dismiss) private var dismiss
    @State private var enabled = false
    @State private var start = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var end = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var message = "設定したおやすみ時間です。画面から離れて、目と体を休めましょう。"
    @State private var test = false

    var body: some View {
        Form {
            Section("おやすみ制限") {
                Toggle("おやすみ時間の制限を有効にする", isOn: $enabled)
                DatePicker("開始時刻", selection: $start, displayedComponents: .hourAndMinute)
                DatePicker("終了時刻", selection: $end, displayedComponents: .hourAndMinute)
                TextField("休憩画面のメッセージ", text: $message, axis: .vertical)
            }
            Section("操作") {
                Button("💾 設定を保存") {
                    store.update { value in
                        value.config.sleepEnabled = enabled
                        value.config.sleepStart = timeString(start)
                        value.config.sleepEnd = timeString(end)
                        value.config.sleepMessage = String(message.prefix(200))
                    }
                    store.evaluateSleepState()
                    dismiss()
                }.buttonStyle(.borderedProminent)
                Button("休憩画面を1分テスト") { test = true; store.sleepOverlayVisible = true; DispatchQueue.main.asyncAfter(deadline: .now() + 60) { test = false; store.evaluateSleepState() } }
            }
            Text("この機能はNEXUSアプリ内だけで動作します。OS全体の利用制限、端末ロック、保護者による制限ではありません。アプリが終了・停止中の場合は自動表示できません。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("NEXUS おやすみ制限")
        .onAppear {
            enabled = store.data.config.sleepEnabled
            start = dateFrom(store.data.config.sleepStart) ?? start
            end = dateFrom(store.data.config.sleepEnd) ?? end
            message = store.data.config.sleepMessage
        }
    }
    private func timeString(_ date: Date) -> String { date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) }
    private func dateFrom(_ value: String) -> Date? { let formatter = DateFormatter(); formatter.dateFormat = "HH:mm"; return formatter.date(from: value) }
}

// MARK: - Drawing studio

struct NEXUSDrawingView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var currentPoints: [CGPointCodable] = []
    @State private var selectedColor = "#25B9E8"
    @State private var lineWidth = 4.0
    private let palette = ["#25B9E8", "#FFFFFF", "#FF5B8A", "#FFCC44", "#60E39C", "#A68BFF", "#FF8B42", "#111827"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(palette, id: \.self) { hex in
                    Button { selectedColor = hex } label: {
                        Circle().fill(Color(nexusHex: hex)).frame(width: 25, height: 25)
                            .overlay(Circle().stroke(.white, lineWidth: selectedColor == hex ? 2 : 0))
                    }.buttonStyle(.plain)
                }
            }
            HStack { Text("太さ"); Slider(value: $lineWidth, in: 1...24); Text("\(Int(lineWidth))") }
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(.white)
                    Canvas { context, size in
                        for stroke in store.data.drawing {
                            draw(stroke.points.map(\.point), color: Color(nexusHex: stroke.colorHex), width: stroke.lineWidth, size: size, in: &context)
                        }
                        draw(currentPoints.map(\.point), color: Color(nexusHex: selectedColor), width: lineWidth, size: size, in: &context)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let size = geometry.size
                            let point = CGPointCodable(CGPoint(x: value.location.x / max(size.width, 1), y: value.location.y / max(size.height, 1)))
                            if currentPoints.last.map({ hypot($0.x - point.x, $0.y - point.y) > 0.002 }) ?? true { currentPoints.append(point) }
                        }
                        .onEnded { _ in
                            guard currentPoints.count > 1 else { currentPoints = []; return }
                            store.update { $0.drawing.append(NEXUSStroke(points: currentPoints, colorHex: selectedColor, lineWidth: lineWidth)) }
                            currentPoints = []
                        })
                }
            }
            .frame(minHeight: 320)
            HStack {
                NEXUSActionButton(title: "元に戻す", systemImage: "arrow.uturn.backward") { store.update { _ = $0.drawing.popLast() } }
                NEXUSActionButton(title: "全消去", systemImage: "trash") { currentPoints = []; store.update { $0.drawing = [] } }
                ShareLink(item: drawingDescription).labelStyle(.titleAndIcon)
            }
            Text("描画データはストロークとして端末内に保存されます。PNG画像としての書き出しは、OSの共有メニューやスクリーンショット機能をご利用ください。")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.92))
        .navigationTitle("NEXUS お絵かきスタジオ")
    }

    private var drawingDescription: String {
        "NEXUS SUPER4.1 Drawing\nStroke count: \(store.data.drawing.count)\nSaved locally on this device."
    }

    private func draw(_ points: [CGPoint], color: Color, width: Double, size: CGSize, in context: inout GraphicsContext) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: CGPoint(x: points[0].x * size.width, y: points[0].y * size.height))
        for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height)) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Mini games (native controls replacing the original canvas games)

struct NEXUSGamesView: View {
    @State private var selectedGame = "🚗 ドライブ"
    @State private var score = 0
    @State private var position = 1
    @State private var message = "ゲームを選んでスタートしてください。"
    @State private var target = Int.random(in: 1...9)
    private let games = ["🚗 ドライブ", "🐍 スネーク", "🎯 ターゲット"]
    var body: some View {
        VStack(spacing: 16) {
            Picker("ゲーム", selection: $selectedGame) { ForEach(games, id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
            NEXUSCard("\(selectedGame)", subtitle: "スコア：\(score)") {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [.black, Color(red: 0.05, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                    if selectedGame.contains("ドライブ") {
                        VStack(spacing: 18) {
                            Text("│        │").foregroundStyle(.white.opacity(0.25))
                            Text("│   🚗   │").font(.system(size: 42))
                            Text("│        │").foregroundStyle(.white.opacity(0.25))
                            Text("LANE \(position + 1)").font(.caption.monospaced())
                        }
                    } else if selectedGame.contains("スネーク") {
                        VStack(spacing: 14) { Text("🟩 🟩 🟩").font(.largeTitle); Text("🐍").font(.system(size: 46)); Text("🔴 食べ物を追いかけよう") }
                    } else {
                        VStack(spacing: 14) {
                            Text("TARGET \(target)").font(.caption.weight(.bold)).tracking(3)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(1...9, id: \.self) { number in
                                    Button { hitTarget(number) } label: { Text(number == target ? "🎯" : "◉").font(.largeTitle).frame(maxWidth: .infinity, minHeight: 58).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12)) }.buttonStyle(.plain)
                                }
                            }
                        }.padding()
                    }
                }.frame(height: 260)
                Text(message).font(.caption).foregroundStyle(.white.opacity(0.65))
                HStack {
                    NEXUSActionButton(title: "◀ 左", systemImage: "arrow.left") { move(-1) }
                    NEXUSActionButton(title: "スタート／加点", systemImage: "play.fill") { score += 1; message = "続けて操作してください。" }
                    NEXUSActionButton(title: "右 ▶", systemImage: "arrow.right") { move(1) }
                }
                HStack { NEXUSActionButton(title: "リセット", systemImage: "arrow.counterclockwise") { score = 0; position = 1; target = Int.random(in: 1...9); message = "ゲームをリセットしました。" }; Spacer() }
            }
            Text("元HTMLのCanvasゲームをSwiftUIの操作パネルへ置き換えた簡易版です。オリジナルの物理挙動・スプライト・ゲーム進行ロジックと完全同一ではありません。")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("NEXUS ミニゲーム")
    }
    private func move(_ delta: Int) {
        position = min(2, max(0, position + delta)); score += 1
        message = selectedGame.contains("ドライブ") ? "レーンを移動しました。" : "移動しました。"
    }
    private func hitTarget(_ value: Int) {
        if value == target { score += 10; message = "命中！ +10"; target = Int.random(in: 1...9) }
        else { message = "外れました。もう一度！" }
    }
}

// MARK: - NEXUSAssistant+ local command router

struct NEXUSAssistantView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var input = ""
    @State private var reply = "検索、メモ、Todo、予定、天気、計算、翻訳などを手伝います。"
    @State private var lastPrompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                NEXUSCard("✦ NEXUSAssistant+", subtitle: "ローカル操作 + 外部AIへの引き継ぎ") {
                    Text("端末内のメモ・Todo・予定の追加や一覧表示、天気の確認、計算、Web検索を実行します。自由な質問は下のChatGPT／Geminiへ引き継げます。")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("やりたいこと・質問を入力…", text: $input, axis: .vertical)
                        .lineLimit(2...5)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        NEXUSActionButton(title: "実行", systemImage: "arrow.right.circle.fill") { runCommand() }
                        NEXUSActionButton(title: "消去", systemImage: "trash") { input = ""; reply = "入力を消去しました。" }
                    }
                }
                NEXUSCard("Assistant+ の応答") {
                    Text(reply).font(.subheadline).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    Divider().overlay(.white.opacity(0.12))
                    Text("外部AIに相談する")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        assistantLink("ChatGPT", host: "chatgpt.com", path: "/", symbol: "sparkles")
                        assistantLink("Gemini", host: "gemini.google.com", path: "/app", symbol: "globe")
                        assistantLink("Google検索", host: "www.google.com", path: "/search", symbol: "magnifyingglass")
                    }
                    Text("外部AI・検索を開くと、入力した質問が各サービスに送信される場合があります。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                NEXUSCard("コマンド例") {
                    ForEach(["メモ: アイデア | 内容", "Todo: 英単語を復習", "予定: 2026-11-10 14:00 歯医者", "天気", "計算: (25 + 5) * 3", "検索: 最新の科学ニュース", "翻訳: Good morning", "今日の予定", "Todo一覧", "メモ一覧"], id: \.self) { sample in
                        Button(sample) { input = sample; runCommand() }
                            .font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                            .buttonStyle(.plain).foregroundStyle(Color(nexusHex: store.data.config.accentHex))
                    }
                    Text("文字化けラボは「CodeBridge」内の「文字化けラボ」タブから利用できます。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("NEXUSAssistant+")
    }

    @ViewBuilder private func assistantLink(_ title: String, host: String, path: String, symbol: String) -> some View {
        let url = assistantURL(host: host, path: path, query: lastPrompt)
        Link(destination: url) {
            Label(title, systemImage: symbol).font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color(nexusHex: store.data.config.accentHex).opacity(0.16), in: Capsule())
        }
    }

    private func assistantURL(host: String, path: String, query: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !query.isEmpty {
            if host == "chatgpt.com" { components.queryItems = [URLQueryItem(name: "q", value: query)] }
            else if host == "gemini.google.com" { components.queryItems = [URLQueryItem(name: "prompt", value: query)] }
            else { components.queryItems = [URLQueryItem(name: "q", value: query)] }
        }
        return components.url ?? URL(string: "https://chatgpt.com")!
    }

    private func runCommand() {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { reply = "質問や指示を入力してください。"; return }
        lastPrompt = q

        if q.range(of: "^(こんにちは|こんばんは|おはよう|やあ|hi\\b|hello\\b|ありがとう|助かった)", options: [.regularExpression, .caseInsensitive]) != nil {
            reply = "どういたしまして！検索、翻訳、メモ、予定、Todo、天気、計算を手伝えます。自由な質問はChatGPTやGeminiへ引き継げます。"
            return
        }
        if q.contains("文字化け") {
            reply = "文字化けラボは「CodeBridge」を開き、機能タブから「文字化けラボ」を選択してください。"
            return
        }
        if let payload = commandPayload(q, prefixes: ["メモを作成", "メモを追加", "メモに保存", "メモ追加", "メモ", "メモして"]) {
            let parts = payload.split(maxSplits: 1, omittingEmptySubsequences: false, whereSeparator: { $0 == "|" || $0 == "｜" })
            let title = parts.count > 1 ? String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines) : "NEXUSAssistant+のメモ"
            let body = (parts.count > 1 ? String(parts[1]) : payload).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { reply = "メモの本文を入力してください。例：メモ: アイデア | 内容"; return }
            guard store.data.memos.count < 200 else { reply = "メモは最大200件です。不要なメモを整理してください。"; return }
            store.update { $0.memos.append(NEXUSMemo(title: String((title.isEmpty ? "NEXUSAssistant+のメモ" : title).prefix(100)), body: String(body.prefix(20_000)))) }
            reply = "✅ メモを保存しました。\n題名：\(title.isEmpty ? "NEXUSAssistant+のメモ" : title)\n本文：\(String(body.prefix(220)))"
            return
        }
        if let payload = commandPayload(q, prefixes: ["Todoを追加", "Todoに追加", "Todo", "todo", "タスクを追加", "タスク", "やること"]) {
            guard !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { reply = "追加するTodoを書いてください。"; return }
            let before = store.todoItems(for: Date()).count
            store.addTodo(payload, date: Date())
            reply = before < 200 ? "✅ 今日のTodoに追加しました：\(String(payload.prefix(180)))" : "この日付のTodoは200件に達しています。"
            return
        }
        if let payload = commandPayload(q, prefixes: ["予定を追加", "予定に追加", "カレンダーに追加", "スケジュールに追加", "予定", "カレンダー", "スケジュール"]) {
            addEvent(payload)
            return
        }
        if q.contains("天気") || q.contains("気温") || q.contains("降水") || q.contains("雨は降") {
            if let weather = store.weather {
                reply = "🌤 \(weather.prefecture)の天気\n\(weather.description)（\(String(format: "%.1f", weather.temperature))℃）\n湿度：\(weather.humidity.map { String(format: "%.0f%%", $0) } ?? "--")\n風速：\(weather.windSpeed.map { String(format: "%.0f km/h", $0) } ?? "--")\n取得時刻：\(weather.currentTime)"
            } else {
                reply = "選択した都道府県の天気を取得しています。取得後にもう一度「天気」と入力してください。"
                Task { await store.fetchWeather(manual: true) }
            }
            return
        }
        if q == "今日の予定" || q.contains("予定一覧") || q == "予定" || q == "カレンダー" {
            let events = store.data.events.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }.sorted { $0.date < $1.date }.prefix(7)
            reply = events.isEmpty ? "📅 これからの予定は登録されていません。\n「予定: 2026-11-10 14:00 歯医者」のように入力すると追加できます。" : "📅 これからの予定\n" + events.map { "・\($0.date.formatted(date: .numeric, time: .shortened)) \($0.title)" }.joined(separator: "\n")
            return
        }
        if q.localizedCaseInsensitiveContains("todo一覧") || q == "Todo" || q == "今日のTodo" || q == "今日やること" {
            let items = store.todoItems(for: Date())
            reply = items.isEmpty ? "✅ 今日のTodoはありません。\n「Todo: 英単語を復習」のように入力すると追加できます。" : "✅ 今日のTodo\n" + items.prefix(20).map { ($0.done ? "☑ " : "□ ") + $0.text }.joined(separator: "\n")
            return
        }
        if q == "メモ一覧" || q == "メモを見せて" || q == "メモを確認" {
            let memos = store.data.memos.sorted { $0.updatedAt > $1.updatedAt }.prefix(10)
            reply = memos.isEmpty ? "保存済みメモはありません。" : "📝 保存済みメモ\n" + memos.map { "・\($0.title.isEmpty ? "無題のメモ" : $0.title)" }.joined(separator: "\n")
            return
        }
        if let payload = commandPayload(q, prefixes: ["翻訳して", "翻訳する", "翻訳", "英語にして", "日本語にして", "英訳", "和訳"]) {
            let url = URL(string: "https://translate.google.com/?sl=auto&tl=ja&text=\(payload.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&op=translate")!
            openURL(url)
            reply = "🌐 Google翻訳を開きました。翻訳対象の文章を外部サービスへ送信しています。"
            return
        }
        if let payload = commandPayload(q, prefixes: ["検索して", "Web検索", "web検索", "ウェブ検索", "検索", "調べて"]) {
            let url = assistantURL(host: "www.google.com", path: "/search", query: payload)
            openURL(url)
            reply = "🔎「\(payload)」のWeb検索を開きました。検索結果はGoogle側で確認してください。"
            return
        }
        if let payload = commandPayload(q, prefixes: ["計算", "電卓"]) ?? (looksLikeMath(q) ? q : nil) {
            do { reply = "🧮 計算結果\n\(payload) = \(try NEXUSMathParser.evaluate(payload))" }
            catch { reply = "式を読み取れませんでした。例：(25 + 5) * 3" }
            return
        }
        if q.contains("時刻") || q.contains("今何時") || q.contains("日付") || q.contains("何日") {
            reply = "🕒 現在の端末日時\n" + Date.now.formatted(Date.FormatStyle().year().month(.wide).day().weekday(.wide).hour().minute().second().locale(Locale(identifier: "ja_JP")))
            return
        }
        reply = "この質問はローカル機能だけでは十分に回答できません。下のChatGPT／Gemini／Google検索へ引き継いでください。\n\n対応例：\n・メモ: アイデア | 内容\n・Todo: 宿題をする\n・予定: 2026-11-10 14:00 歯医者\n・天気\n・検索: 科学ニュース\n・翻訳: Good morning\n・計算: (12 + 8) * 3"
    }

    private func commandPayload(_ input: String, prefixes: [String]) -> String? {
        for prefix in prefixes {
            guard input.count > prefix.count else { continue }
            let tail = String(input.dropFirst(prefix.count))
            guard tail.first == ":" || tail.first == "：" || tail.first?.isWhitespace == true else { continue }
            return tail.drop(while: { $0 == ":" || $0 == "：" || $0.isWhitespace }).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private func addEvent(_ raw: String) {
        var title = raw
        var date = Date()
        let datePattern = #"20\d{2}-\d{2}-\d{2}"#
        if let range = title.range(of: datePattern, options: .regularExpression) {
            let dateText = String(title[range])
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsed = formatter.date(from: dateText) { date = parsed }
            title.replaceSubrange(range, with: " ")
        }
        let timePattern = #"(?:[01]\d|2[0-3]):[0-5]\d"#
        if let range = title.range(of: timePattern, options: .regularExpression) {
            let timeText = String(title[range])
            let parts = timeText.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2, let newDate = Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) { date = newDate }
            title.replaceSubrange(range, with: " ")
        }
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r:：,、-"))
        guard !title.isEmpty else { reply = "予定名を書いてください。例：予定: 2026-11-10 14:00 歯医者"; return }
        guard store.data.events.count < 500 else { reply = "予定は最大500件です。古い予定を削除してください。"; return }
        store.update { $0.events.append(NEXUSEvent(title: String(title.prefix(100)), date: date)) }
        reply = "📅 予定表に追加しました：\(date.formatted(date: .numeric, time: .shortened)) \(title)"
    }

    private func looksLikeMath(_ value: String) -> Bool {
        value.count < 100 && value.range(of: #"\d\s*[+＋*×/÷−-]\s*\d"#, options: .regularExpression) != nil
    }

    private func openURL(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

private struct NEXUSMathParser {
    private var chars: [Character]
    private var index = 0

    private init(_ source: String) {
        let normalized = source
            .replacingOccurrences(of: "＋", with: "+")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "＊", with: "*")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "．", with: ".")
        chars = Array(normalized.filter { !$0.isWhitespace })
    }

    static func evaluate(_ source: String) throws -> Double {
        guard source.count <= 120 else { throw ParseError.invalid }
        var parser = NEXUSMathParser(source)
        let value = try parser.parseExpression()
        guard parser.index == parser.chars.count, value.isFinite else { throw ParseError.invalid }
        return value
    }

    private enum ParseError: Error { case invalid }

    private mutating func parseExpression() throws -> Double {
        var value = try parseTerm()
        while index < chars.count {
            let op = chars[index]
            guard op == "+" || op == "-" else { break }
            index += 1
            let rhs = try parseTerm()
            value = op == "+" ? value + rhs : value - rhs
        }
        return value
    }

    private mutating func parseTerm() throws -> Double {
        var value = try parseUnary()
        while index < chars.count {
            let op = chars[index]
            guard op == "*" || op == "/" else { break }
            index += 1
            let rhs = try parseUnary()
            if op == "/" && rhs == 0 { throw ParseError.invalid }
            value = op == "*" ? value * rhs : value / rhs
        }
        return value
    }

    private mutating func parseUnary() throws -> Double {
        guard index < chars.count else { throw ParseError.invalid }
        if chars[index] == "+" { index += 1; return try parseUnary() }
        if chars[index] == "-" { index += 1; return -(try parseUnary()) }
        return try parsePrimary()
    }

    private mutating func parsePrimary() throws -> Double {
        guard index < chars.count else { throw ParseError.invalid }
        if chars[index] == "(" {
            index += 1
            let value = try parseExpression()
            guard index < chars.count, chars[index] == ")" else { throw ParseError.invalid }
            index += 1
            return value
        }
        let start = index
        var dotSeen = false
        while index < chars.count {
            let char = chars[index]
            if char.isNumber { index += 1; continue }
            if char == ".", !dotSeen { dotSeen = true; index += 1; continue }
            break
        }
        guard index > start, let number = Double(String(chars[start..<index])) else { throw ParseError.invalid }
        return number
    }
}

// MARK: - CodeBridge workspace and prompt workshop

struct NEXUSCodeBridgeView: View {
    @State private var sourceLanguage = "Python"
    @State private var targetLanguage = "Swift"
    @State private var code = "print(\"Hello, NEXUS!\")"
    @State private var aiAnswer = ""
    @State private var output = ""
    @State private var request = ""
    @State private var status = "コードを入力するか、サンプルを選択してください。"
    @State private var selectedTab = "変換"
    @State private var garbleMode = "日本語・文字化け風"

    private let languages = ["Python", "JavaScript", "Java", "Go", "R", "TypeScript", "C", "C#", "C++", "Cython", "Rust", "PHP", "HTML", "BASIC", "SQL", "Elixir", "Haskell", "Swift"]
    var body: some View {
        VStack(spacing: 12) {
            Picker("機能", selection: $selectedTab) { Text("変換").tag("変換"); Text("ワークスペース").tag("ワークスペース"); Text("Assistant+ Workshop").tag("Assistant+"); Text("文字化けラボ").tag("文字化け") }.pickerStyle(.segmented)
            if selectedTab == "変換" { conversionPanel }
            else if selectedTab == "ワークスペース" { workspacePanel }
            else if selectedTab == "Assistant+ Workshop" { assistantPanel }
            else { garblerPanel }
        }
        .padding()
        .navigationTitle("NEXUS CodeBridge")
    }

    private var conversionPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                NEXUSCard("CodeBridge Converter", subtitle: "言語変換のためのコード整形・ラッパー生成") {
                    Picker("変換元", selection: $sourceLanguage) { ForEach(languages, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                    Picker("変換先", selection: $targetLanguage) { ForEach(languages, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                    TextEditor(text: $code).font(.system(.caption, design: .monospaced)).frame(minHeight: 190).overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.18)))
                    HStack { NEXUSActionButton(title: "サンプル", systemImage: "doc.text") { code = sampleCode(for: sourceLanguage) }; NEXUSActionButton(title: "変換", systemImage: "arrow.left.arrow.right") { output = convert(code, to: targetLanguage); status = "変換案を生成しました。実行前に構文・API・動作を確認してください。" } }
                }
                NEXUSCard("変換結果") {
                    TextEditor(text: $output).font(.system(.caption, design: .monospaced)).frame(minHeight: 190).overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.18)))
                    HStack { NEXUSActionButton(title: "コピー", systemImage: "doc.on.doc") { NEXUSClipboard.copy(output); status = "コピーしました。" }; ShareLink(item: output) { Label("共有／保存", systemImage: "square.and.arrow.up") } }
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    private var workspacePanel: some View {
        ScrollView {
            VStack(spacing: 12) {
                NEXUSCard("🧑‍💻 プログラムエディター", subtitle: "最大100,000文字") {
                    TextEditor(text: $code).font(.system(.caption, design: .monospaced)).frame(minHeight: 280).overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.18)))
                    HStack { NEXUSActionButton(title: "コピー", systemImage: "doc.on.doc") { NEXUSClipboard.copy(code) }; ShareLink(item: code) { Label("プログラムを保存／共有", systemImage: "square.and.arrow.up") }; NEXUSActionButton(title: "消去", systemImage: "trash") { code = "" } }
                }
                NEXUSCard("🤖 AIの回答") {
                    TextEditor(text: $aiAnswer).font(.system(.caption, design: .monospaced)).frame(minHeight: 150).overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.18)))
                    HStack { NEXUSActionButton(title: "回答をエディターへ", systemImage: "arrow.up.doc") { code = aiAnswer }; NEXUSActionButton(title: "説明欄へ", systemImage: "arrow.down.doc") { request = aiAnswer } }
                }
            }
        }
    }
    private var assistantPanel: some View {
        Form {
            Section("Assistant+ Language Workshop") {
                Picker("対象言語", selection: $targetLanguage) { ForEach(languages, id: \.self) { Text($0).tag($0) } }
                TextField("作りたい機能・仕様", text: $request, axis: .vertical).lineLimit(4...8)
                Button("言語仕様のたたき台を生成") { output = spec(for: targetLanguage); status = "仕様のたたき台を作成しました。" }
                Button("Assistant+用プロンプトを作成") { output = buildAIPrompt(); status = "プロンプトを作成しました。" }
            }
            Section("出力") { TextEditor(text: $output).frame(minHeight: 220).font(.system(.caption, design: .monospaced)); Button("コピー") { NEXUSClipboard.copy(output) }; ShareLink(item: output) { Label("共有／保存", systemImage: "square.and.arrow.up") } }
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var garblerPanel: some View {
        Form {
            Section("🧬 NEXUS 文字化けラボ") {
                Picker("変換モード", selection: $garbleMode) { Text("日本語・文字化け風").tag("日本語・文字化け風"); Text("カオス記号ノイズ").tag("カオス記号ノイズ"); Text("UTF-8 Base64（復元可能）").tag("UTF-8 Base64（復元可能）") }
                TextEditor(text: $code).frame(minHeight: 150)
                Button("変換") { output = garble(code, mode: garbleMode) }.buttonStyle(.borderedProminent)
                TextEditor(text: $output).frame(minHeight: 150).font(.system(.caption, design: .monospaced))
                Button("コピー") { NEXUSClipboard.copy(output) }
            }
        }
    }

    private func convert(_ body: String, to target: String) -> String {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let indent = lines.map { "    " + $0 }.joined(separator: "\n")
        switch target {
        case "Swift": return "import Foundation\n\n@main\nstruct Main {\n    static func main() {\n" + indent + "\n    }\n}"
        case "Java": return "public class Main {\n    public static void main(String[] args) {\n" + indent + "\n    }\n}"
        case "Go": return "package main\n\nfunc main() {\n" + indent + "\n}"
        case "C": return "#include <stdio.h>\n\nint main(void) {\n" + indent + "\n    return 0;\n}"
        case "C++": return "#include <iostream>\n\nint main() {\n" + indent + "\n    return 0;\n}"
        case "C#": return "using System;\n\nclass Program {\n    static void Main() {\n" + indent + "\n    }\n}"
        case "Rust": return "fn main() {\n" + indent + "\n}"
        case "PHP": return "<?php\n" + body + "\n?>"
        case "HTML": return "<!doctype html>\n<html lang=\"ja\"><meta charset=\"utf-8\"><body>\n" + indent + "\n</body></html>"
        case "Python", "Cython", "R": return "# Generated by NEXUS CodeBridge — review before running\n" + body
        case "SQL": return "-- NEXUS CodeBridge SQL output — review dialect and query semantics\n" + body
        case "Elixir": return "# Generated by NEXUS CodeBridge — review before running\n" + body
        case "Haskell": return "-- Generated by NEXUS CodeBridge — review before running\nmain = do\n" + lines.map { "  " + $0 }.joined(separator: "\n")
        case "BASIC":
            let basicLines = ["10 REM NEXUS CodeBridge BASIC output"] + lines.enumerated().map {
                "\(($0.offset + 2) * 10) \($0.element.isEmpty ? "REM" : $0.element)"
            }
            return basicLines.joined(separator: "\n")
        default: return "// NEXUS CodeBridge output — review before running\n" + body
        }
    }
    private func sampleCode(for language: String) -> String {
        switch language {
        case "Swift": return "import Foundation\nprint(\"Hello, NEXUS!\")"
        case "Java": return "System.out.println(\"Hello, NEXUS!\");"
        case "Go": return "fmt.Println(\"Hello, NEXUS!\")"
        case "C": return "printf(\"Hello, NEXUS!\\n\");"
        case "C++": return "std::cout << \"Hello, NEXUS!\" << std::endl;"
        case "C#": return "Console.WriteLine(\"Hello, NEXUS!\");"
        case "Rust": return "println!(\"Hello, NEXUS!\");"
        case "HTML": return "<h1>Hello, NEXUS!</h1>"
        default: return "print(\"Hello, NEXUS!\")"
        }
    }
    private func spec(for language: String) -> String {
        "NEXUS Assistant+ Language Workshop\nLanguage: \(language)\n\n1. Purpose\n\(request.isEmpty ? "Describe the program's purpose here." : request)\n\n2. Inputs and outputs\n- Define data types and validation.\n- Define error handling and user feedback.\n\n3. Architecture\n- Separate UI, domain logic, persistence, and network access.\n- Use native APIs for the selected platform.\n\n4. Security and privacy\n- Do not execute arbitrary downloaded code.\n- Validate URLs and input sizes.\n- Keep personal data local unless the user explicitly chooses an external service.\n\n5. Testing\n- Normal, boundary, failure, and offline cases.\n\nGenerated as a planning template; verify against the language's actual specifications."
    }
    private func buildAIPrompt() -> String {
        "次の要件に基づき、\(targetLanguage)で実装してください。\n\n要件：\n\(request)\n\n制約：既存コードがある場合は仕様とデータ形式を維持し、変更点を説明してください。安全性、エラー処理、入力検証、保存処理、実行方法、テスト例を含めてください。未実装の機能を完成済みと説明しないでください。"
    }
    private func garble(_ text: String, mode: String) -> String {
        if mode.contains("Base64") { return Data(text.utf8).base64EncodedString() }
        let noise = ["▓", "▒", "░", "�", "Ж", "Ψ", "※", "〓", "¤", "§", "◈", "∞"]
        return text.map { character in
            if character.isWhitespace { return String(character) }
            if mode.contains("カオス") { return String(character) + noise.randomElement()! }
            return Bool.random() ? String(character) : noise.randomElement()!
        }.joined()
    }
}

// MARK: - Developer management center (safe allow-list only)

struct NEXUSDeveloperView: View {
    @EnvironmentObject private var store: NEXUSStore
    @State private var enabled = false
    @State private var adminEnabled = false
    @State private var command = "help"
    @State private var output = "NEXUS ADMIN SHELL 1.0\n管理コマンドには許可リストを使用します。任意コード実行・シェル実行はありません。"
    @State private var status = "開発者モードは停止中です。"
    @State private var accent = "#28C9F2"
    @State private var fastMode = false
    @State private var reducedMotion = false
    @State private var debugOutline = false
    @State private var privacyShield = false
    @State private var showResetConfirm = false
    @State private var report = ""

    var body: some View {
        Form {
            Section("⚠ NEXUS 開発者モード・管理センター") {
                Text("診断・アプリ検査・ローカルデータ管理・高度な動作制御。管理者権限はこの画面を開いている間だけ有効です。OS全体の管理者権限ではありません。")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("開発者モードを有効化", isOn: Binding(get: { enabled }, set: { value in enabled = value; if !value { adminEnabled = false; status = "開発者モードは停止中です。" } else { status = "開発者モード有効。診断を実行できます。" } }))
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            if enabled {
                Section("診断") {
                    Button("🔍 診断を再実行") { report = store.runSecurityAudit(); output = report; status = "診断完了。" }
                    if !report.isEmpty { ShareLink(item: report) { Label("診断レポートを保存／共有", systemImage: "square.and.arrow.up") } }
                }
                Section("🛡 管理者ゲート") {
                    if !adminEnabled {
                        Button("管理者権限をこのセッションで有効化") { adminEnabled = true; status = "⚠ 管理者権限が有効です。画面を閉じると解除されます。" }
                    } else {
                        Label("ADMIN ACTIVE · THIS SESSION", systemImage: "checkmark.shield.fill").foregroundStyle(.green)
                        Button("管理者権限を解除", role: .destructive) { adminEnabled = false; status = "管理者権限を解除しました。" }
                    }
                }
                if adminEnabled {
                    Section("🎨 外観・描画制御") {
                        TextField("アクセント色（#RRGGBB）", text: $accent)
                        Toggle("高速・軽量モード", isOn: $fastMode)
                        Toggle("全アニメーションを停止", isOn: $reducedMotion)
                        Toggle("要素の境界線を可視化", isOn: $debugOutline)
                        Toggle("プライバシーシールド", isOn: $privacyShield)
                        Button("設定を適用・保存") {
                            guard accent.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil else { status = "アクセント色は#RRGGBB形式で入力してください。"; return }
                            store.update { $0.config.accentHex = accent; $0.developerPrefs["fastMode"] = String(fastMode); $0.developerPrefs["reducedMotion"] = String(reducedMotion); $0.developerPrefs["debugOutline"] = String(debugOutline); $0.developerPrefs["privacyShield"] = String(privacyShield) }
                            status = "開発者設定を保存しました。"
                        }.buttonStyle(.borderedProminent)
                    }
                    Section("🛡 プライバシー・通信制御") {
                        Toggle("天気の自動外部通信", isOn: Binding(get: { store.data.config.automaticWeather }, set: { v in store.update { $0.config.automaticWeather = v && !$0.config.anonymousNetwork } }))
                        Toggle("画面保護モード", isOn: Binding(get: { store.data.config.screenProtect }, set: { v in store.update { $0.config.screenProtect = v }; if v { store.screenProtectVisible = true } }))
                        Toggle("通信匿名モード", isOn: Binding(get: { store.data.config.anonymousNetwork }, set: { v in store.update { $0.config.anonymousNetwork = v; if v { $0.config.automaticWeather = false } } }))
                        Button("セキュリティ画面を再診断") { report = store.runSecurityAudit(); output = report }
                    }
                    Section("🗄 保存データ管理") {
                        LabeledContent("NEXUS保存キー", value: "NEXUS_SUPER4_1_NATIVE_DATA")
                        LabeledContent("保存量", value: ByteCountFormatter.string(fromByteCount: Int64(store.storageBytes), countStyle: .file))
                        Button("全保存データをJSONで共有") { output = "バックアップ画面からエクスポートしてください。" }
                        NavigationLink("バックアップ／復元を開く") { NEXUSBackupView() }
                        Button("NEXUSデータを初期化", role: .destructive) { showResetConfirm = true }
                            .confirmationDialog("NEXUSの保存データを削除しますか？", isPresented: $showResetConfirm) {
                                Button("すべて削除", role: .destructive) { store.resetAll(); status = "保存データを初期化しました。" }
                                Button("キャンセル", role: .cancel) {}
                            }
                    }
                    Section("⌨ NEXUS 管理コマンド") {
                        TextField("help / status / keys / network off", text: $command).textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button("実行") { runCommand(command) }.buttonStyle(.borderedProminent)
                        Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    }
                }
            }
            Section("管理範囲について") {
                Text("この画面が管理するのはNEXUSアプリ自身の設定・ローカル保存データだけです。OSの管理者権限、他アプリのデータ、端末全体のファイルシステム、ブラウザ内部設定にはアクセスしません。任意のJavaScript、任意コード、外部シェルの実行機能はありません。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("開発者モード")
        .onDisappear { adminEnabled = false; enabled = false }
        .onAppear { accent = store.data.config.accentHex }
    }

    private func runCommand(_ raw: String) {
        guard adminEnabled else { output = "管理者権限が必要です。"; return }
        let parts = raw.split(whereSeparator: \.isWhitespace).map(String.init)
        let command = parts.first?.lowercased() ?? ""
        let arg = parts.dropFirst().first?.lowercased() ?? ""
        var result = ""
        switch command {
        case "help": result = "許可コマンド:\nhelp · status · scan · keys\nnetwork on|off · screen on|off · anon on|off\naccent #RRGGBB · delete-data\n任意コード実行・OSシェル・外部通信コマンドはありません。"
        case "status": result = "NEXUS SUPER4.1 Native\nDeveloper=\(enabled) / Admin=\(adminEnabled)\nOnline=\(store.networkIsOnline)\nStorage=\(store.storageBytes) bytes\nAutoWeather=\(store.data.config.automaticWeather)\nAnonymousNetwork=\(store.data.config.anonymousNetwork)"
        case "scan": result = store.runSecurityAudit()
        case "keys": result = "NEXUS_SUPER4_1_NATIVE_DATA\n※このアプリが管理する専用保存キーのみ表示しています。"
        case "network":
            guard ["on", "off"].contains(arg) else { result = "使い方: network on|off"; break }
            store.update { $0.config.automaticWeather = arg == "on" && !$0.config.anonymousNetwork }
            result = "自動天気通信=\(store.data.config.automaticWeather)"
        case "screen":
            guard ["on", "off"].contains(arg) else { result = "使い方: screen on|off"; break }
            store.update { $0.config.screenProtect = arg == "on" }; store.screenProtectVisible = arg == "on"
            result = "画面保護=\(arg)"
        case "anon":
            guard ["on", "off"].contains(arg) else { result = "使い方: anon on|off"; break }
            store.update { $0.config.anonymousNetwork = arg == "on"; if arg == "on" { $0.config.automaticWeather = false } }
            result = "通信匿名モード=\(arg)"
        case "accent":
            guard parts.count > 1, parts[1].range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil else { result = "使い方: accent #RRGGBB"; break }
            store.update { $0.config.accentHex = parts[1] }; accent = parts[1]; result = "アクセント色を適用しました。"
        case "delete-data":
            store.resetAll(); result = "NEXUSの保存データを初期化しました。"
        default: result = "不明なコマンドです。help を入力してください。"
        }
        output = "> \(raw)\n\(result)\n\n" + String(output.prefix(5000))
        status = "コマンド処理完了。"
    }
}

// MARK: - Sleep/Developer access shortcuts and reusable services

private enum NEXUSConstants {
    static let searchEngines: [String: String] = [
        "Google": "https://www.google.com/search?q=", "Yahoo": "https://search.yahoo.co.jp/search?p=", "DuckDuckGo": "https://duckduckgo.com/?q=", "Bing": "https://www.bing.com/search?q=", "Brave": "https://search.brave.com/search?q=", "Ecosia": "https://www.ecosia.org/search?q=", "Startpage": "https://www.startpage.com/do/search?q="
    ]
    static let aiServices: [(name: String, url: String, icon: String)] = [
        ("ChatGPT", "https://chatgpt.com", "💬"), ("Claude", "https://claude.ai", "🧠"), ("Perplexity", "https://www.perplexity.ai", "🔍"),
        ("Gemini", "https://gemini.google.com", "✨"), ("Copilot", "https://copilot.microsoft.com", "🤖"), ("Grok", "https://grok.com", "✦"),
        ("Suno", "https://suno.com", "🎵"), ("Sora", "https://sora.com", "🎬"), ("Cursor", "https://cursor.com", "⌨")
    ]
    static let appGroups: [(name: String, items: [(name: String, url: String, icon: String)])] = [
        ("Google", [
            ("Gmail", "https://mail.google.com", "✉️"), ("ドキュメント", "https://docs.google.com/document", "📄"), ("スライド", "https://docs.google.com/presentation", "📊"),
            ("スプレッドシート", "https://docs.google.com/spreadsheets", "📈"), ("ドライブ", "https://drive.google.com", "💾"), ("Colab", "https://colab.research.google.com", "🧪"),
            ("カレンダー", "https://calendar.google.com", "📅"), ("マップ", "https://maps.google.com", "🗺️"), ("フォト", "https://photos.google.com", "🖼️"),
            ("Meet", "https://meet.google.com", "🎥"), ("フォーム", "https://docs.google.com/forms", "📝"), ("Keep", "https://keep.google.com", "💡"),
            ("翻訳", "https://translate.google.com", "🌐"), ("Sites", "https://sites.google.com", "🏗️"), ("Earth", "https://earth.google.com", "🌍")
        ]),
        ("Microsoft", [
            ("Word", "https://www.office.com/launch/word", "📘"), ("Excel", "https://www.office.com/launch/excel", "📗"), ("PowerPoint", "https://www.office.com/launch/powerpoint", "📙"),
            ("Teams", "https://teams.microsoft.com", "👥"), ("Outlook", "https://outlook.live.com", "📧"), ("OneNote", "https://www.onenote.com", "🗒️"),
            ("Clipchamp", "https://clipchamp.com", "🎞️"), ("Copilot", "https://copilot.microsoft.com", "🤖"), ("OneDrive", "https://onedrive.live.com", "☁️"),
            ("To Do", "https://to-do.office.com", "✅"), ("Forms", "https://forms.office.com", "📋"), ("Planner", "https://planner.cloud.microsoft", "📅"), ("Whiteboard", "https://whiteboard.office.com", "🖊️")
        ]),
        ("AI", [
            ("ChatGPT", "https://chatgpt.com", "💬"), ("Claude", "https://claude.ai", "🧠"), ("Perplexity", "https://www.perplexity.ai", "🔍"), ("Gemini", "https://gemini.google.com", "✨"),
            ("Copilot", "https://copilot.microsoft.com", "🤖"), ("Grok", "https://grok.com", "✦"), ("Suno", "https://suno.com", "🎵"), ("Sora", "https://sora.com", "🎬"),
            ("Runway", "https://runwayml.com", "🎞️"), ("Midjourney", "https://www.midjourney.com", "🎨"), ("Kling", "https://klingai.com", "🎥")
        ]),
        ("SNS・メディア", [
            ("X", "https://x.com", "𝕏"), ("NOTE", "https://note.com", "📝"), ("TikTok", "https://www.tiktok.com", "♪"), ("YouTube", "https://www.youtube.com", "▶️"),
            ("Netflix", "https://www.netflix.com", "🎬"), ("Twitch", "https://www.twitch.tv", "🎮"), ("Reddit", "https://www.reddit.com", "🟠"),
            ("Instagram", "https://www.instagram.com", "📷"), ("Threads", "https://www.threads.net", "@"), ("LINE", "https://line.me", "💚"), ("Discord", "https://discord.com", "🎧"),
            ("Pinterest", "https://www.pinterest.com", "📌"), ("LinkedIn", "https://www.linkedin.com", "💼"), ("Bluesky", "https://bsky.app", "🦋"), ("Spotify", "https://open.spotify.com", "🎵")
        ]),
        ("クラウド・Office", [
            ("Dropbox", "https://www.dropbox.com", "📦"), ("iCloud", "https://www.icloud.com", "☁️"), ("Box", "https://www.box.com", "🗂️"), ("MEGA", "https://mega.nz", "🔒"),
            ("Proton", "https://proton.me", "🛡️"), ("Microsoft 365", "https://www.microsoft365.com", "🏢"), ("Notion", "https://www.notion.so", "📓"), ("Canva", "https://www.canva.com", "🎨"), ("Figma", "https://www.figma.com", "🖌️")
        ]),
        ("開発・ゲーム", [
            ("GitHub", "https://github.com", "🐙"), ("Cursor", "https://cursor.com", "⌨"), ("Unity", "https://unity.com", "🎮"), ("Steam", "https://store.steampowered.com", "🎮"),
            ("Epic Games", "https://store.epicgames.com", "🎮"), ("Vercel", "https://vercel.com", "▲"), ("Scratch", "https://scratch.mit.edu", "🐱"), ("TurboWarp", "https://turbowarp.org", "🧩")
        ]),
        ("ネット・学習・便利", [
            ("Amazon", "https://www.amazon.co.jp", "📦"), ("楽天市場", "https://www.rakuten.co.jp", "🛍️"), ("Yahoo! JAPAN", "https://www.yahoo.co.jp", "Y!"), ("メルカリ", "https://jp.mercari.com", "♻️"),
            ("Wikipedia", "https://ja.wikipedia.org", "🌐"), ("NHK", "https://www3.nhk.or.jp", "📺"), ("Zoom", "https://zoom.us", "🎥"), ("Slack", "https://slack.com", "#"),
            ("Trello", "https://trello.com", "📋"), ("PayPay", "https://paypay.ne.jp", "💴"), ("Adobe", "https://www.adobe.com", "🟥"), ("GeoGebra", "https://www.geogebra.org", "📐"),
            ("Desmos", "https://www.desmos.com", "📈"), ("TypingClub", "https://www.typingclub.com", "⌨"), ("寿司打", "https://sushida.net", "🍣"),
            ("DeepL", "https://www.deepl.com", "🌐"), ("Speedtest", "https://www.speedtest.net", "⚡"), ("Photopea", "https://www.photopea.com", "🖼️"), ("Excalidraw", "https://excalidraw.com", "✏️")
        ])
    ]
}

// MARK: - Terms of use / copyright notice from the supplied HTML

struct NEXUSTermsView: View {
    private let terms: [(String, String)] = [
        ("第1条（提供内容）", "本ツールは、検索、ブックマーク、時計、天気、メモ、Todo、予定表、翻訳、音楽・BGM、お絵かき、ゲームなどの機能をひとつの画面で提供します。機能は予告なく追加・変更・終了することがあります。"),
        ("第2条（利用範囲）", "本ツールは、個人の非営利目的での利用に限ります。天気データの提供元が非営利利用に限って無償提供しているため、商用での利用はできません。"),
        ("第3条（禁止事項）", "法令または公序良俗に反する行為、他者の著作権・プライバシーその他の権利を侵害する行為、本ツールの無断での再配布・販売または改変したものの公開（制作者が許可した場合を除く）、外部サービスに過度な負荷をかける行為や各サービスの利用条件に反する利用、他者になりすます行為、不正アクセスその他の運営を妨げる行為。本ツールのプログラム、画面デザイン、文章の著作権は、GitHubアカウント『kinokokenatto』に帰属します。"),
        ("第4条（データの取り扱い）", "メモ、Todo、予定、設定、お絵かきなどのデータは端末内のローカル保存領域に保存されます。アプリ自身はこれらのデータを制作者や第三者のサーバーへ送信しません。保存データは暗号化されません。端末の共有時には秘密情報を保存しないでください。端末初期化や保存容量不足などによりデータが失われる場合があります。天気情報は、手動または自動取得を許可した場合にOpen-Meteoへ直接通信し、IPアドレス等が通信先に伝わります。翻訳サイトを利用した場合、入力文章が各社へ送信されることがあります。"),
        ("第5条（外部サービス・リンク）", "本ツールから開く外部サイト・サービスは各提供者のものです。内容、利用条件、個人情報の取り扱いは各提供者の定めに従います。本ツールと各社との間に提携・後援・推奨などの関係はありません。"),
        ("第6条（情報の正確性）", "天気、ニュースなどの表示内容は参考情報であり、正確性・完全性・即時性を保証しません。"),
        ("第7条（免責）", "本ツールは現状のまま提供され、動作、安全性、特定の目的への適合性を保証しません。利用または利用できないことにより生じた損害について、法令で許される範囲で制作者は責任を負いません。"),
        ("第8条（規約の変更）", "本規約は必要に応じて変更することがあります。変更後の規約は本ツール上に掲示した時点から効力を生じます。"),
        ("第9条（準拠法）", "本規約は日本法に準拠します。制定日：2026年10月25日。")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("この利用規約（以下「本規約」）は、NEXUS 宇宙空間版（以下「本ツール」）の利用条件を定めるものです。本ツールを利用した時点で、本規約に同意したものとみなします。")
                .font(.caption)
            ForEach(terms, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0).font(.subheadline.weight(.bold)).foregroundStyle(.cyan)
                    Text(item.1).font(.caption).foregroundStyle(.white.opacity(0.8))
                }
            }
            Divider().overlay(.white.opacity(0.15))
            Text("著作権・出典").font(.headline)
            Text("本ツールのプログラム、画面デザイン、文章の著作権はGitHubアカウント『kinokokenatto』に帰属します。利用者が作成したメモ・予定・お絵かきなどの権利は利用者に帰属します。")
                .font(.caption)
            Text("Google、Microsoft、ChatGPT、Claude、GitHubなどの名称・ロゴは各社の商標または登録商標です。本ツールは各社と提携・後援・承認の関係にありません。")
                .font(.caption)
            Text("天気：Weather data by Open-Meteo.com（CC BY 4.0）。ニュース：各報道機関の記事へのリンクのみ。音楽：内蔵BGMは本ツールの音源生成機能、利用者が読み込んだ音楽ファイルの権利は各権利者に帰属します。")
                .font(.caption)
            Text("快適に使うために、端末OSを最新に保ち、必要に応じてバックアップしてください。共有端末に秘密情報を保存しないでください。")
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

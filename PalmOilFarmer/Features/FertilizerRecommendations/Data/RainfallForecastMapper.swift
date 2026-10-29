import Foundation

enum RainfallForecastMapper {
    static func loadBundled(from bundle: Bundle = .main) -> RainfallForecast? {
        guard let url = bundle.url(forResource: "rain_view", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        return map(payload)
    }

    static func decode(_ data: Data) throws -> RainfallForecast {
        map(try JSONDecoder().decode(Payload.self, from: data))
    }

    private static func map(_ payload: Payload) -> RainfallForecast {
        let heavyThreshold = payload.thresholds.heavyMillimetersOver
        let days = payload.days.map { day in
            RainfallDay(
                id: day.date,
                weekday: weekday(for: day.date, format: "EEE"),
                symbol: symbol(for: day.icon),
                precipitationMillimeters: day.millimeters,
                isHeavy: day.millimeters > heavyThreshold,
                spreadStatus: spreadDescription(for: day.spread)
            )
        }
        let heavyWeekdays = payload.headline.heavyDays.map { weekday(for: $0, format: "EEEE") }
        let safeWeekdays = payload.advice.safeDays.map { weekday(for: $0, format: "EEEE") }
        let avoidWeekdays = payload.advice.avoidDays.map { weekday(for: $0, format: "EEEE") }
        let heavyAdviceDays = payload.advice.heavyDays.map { weekday(for: $0, format: "EEEE") }
        let safeDates = payload.advice.safeDays.map(dateWithWeekday)
        let avoidDates = payload.advice.avoidDays.map(dateWithWeekday)
        let heavyAdviceDates = payload.advice.heavyDays.map(dateWithWeekday)
        let headline = heavyWeekdays.isEmpty
            ? "Tidak ada hujan lebat dalam prakiraan"
            : "Hujan lebat pada \(indonesianList(heavyWeekdays))"
        let summary: String
        if !safeWeekdays.isEmpty && !heavyAdviceDays.isEmpty {
            summary = "Taburkan pupuk pada **\(indonesianList(safeDates, conjunction: "atau", separator: "; "))**. Hindari **\(indonesianList(avoidDates, conjunction: "dan", separator: "; "))**; hujan lebat pada **\(indonesianList(heavyAdviceDates))** dapat menghanyutkan pupuk."
        } else if !safeWeekdays.isEmpty {
            summary = "Hari yang disarankan untuk pemupukan: **\(indonesianList(safeWeekdays))**."
        } else {
            summary = "Periksa kembali prakiraan sebelum menentukan waktu pemupukan."
        }

        return RainfallForecast(
            dateRange: "\(dateLabel(payload.chart.start))–\(dateLabel(payload.chart.end))",
            headline: headline,
            days: days,
            summary: summary,
            heavyThresholdMillimeters: heavyThreshold
        )
    }

    private static func dateLabel(_ value: String) -> String {
        format(value, pattern: "d MMMM")
    }

    private static func dateWithWeekday(_ value: String) -> String {
        "\(weekday(for: value, format: "EEEE")), \(dateLabel(value))"
    }

    private static func weekday(for value: String, format: String) -> String {
        Self.format(value, pattern: format)
    }

    private static func format(_ value: String, pattern: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "id_ID")
        output.calendar = Calendar(identifier: .gregorian)
        output.timeZone = TimeZone(secondsFromGMT: 0)
        output.dateFormat = pattern
        return output.string(from: date)
    }

    private static func indonesianList(
        _ values: [String],
        conjunction: String = "dan",
        separator: String = ", "
    ) -> String {
        switch values.count {
        case 0: return ""
        case 1: return values[0]
        case 2: return "\(values[0]) \(conjunction) \(values[1])"
        default: return values.dropLast().joined(separator: separator) + "\(separator)\(conjunction) " + values[values.count - 1]
        }
    }

    private static func symbol(for icon: String) -> String {
        switch icon {
        case "partly_cloudy": return "cloud.sun.fill"
        case "light_rain": return "cloud.sun.rain.fill"
        case "heavy_rain": return "cloud.heavyrain.fill"
        default: return "cloud.fill"
        }
    }

    private static func spreadDescription(for spread: String) -> String {
        switch spread {
        case "safe": return "Disarankan untuk pemupukan"
        case "day_before_heavy": return "Hindari sebelum hujan lebat"
        case "heavy": return "Hujan lebat"
        default: return "Periksa kondisi cuaca"
        }
    }

    private struct Payload: Decodable {
        let thresholds: ThresholdsDTO
        let chart: ChartDTO
        let days: [DayDTO]
        let headline: HeadlineDTO
        let advice: AdviceDTO
    }

    private struct ThresholdsDTO: Decodable {
        let heavyMillimetersOver: Double
        enum CodingKeys: String, CodingKey {
            case heavyMillimetersOver = "heavy_mm_over"
        }
    }

    private struct ChartDTO: Decodable {
        let start: String
        let end: String
    }

    private struct DayDTO: Decodable {
        let date: String
        let millimeters: Double
        let icon: String
        let spread: String
        enum CodingKeys: String, CodingKey {
            case date, icon, spread
            case millimeters = "mm"
        }
    }

    private struct HeadlineDTO: Decodable {
        let heavyDays: [String]
        enum CodingKeys: String, CodingKey {
            case heavyDays = "heavy_days"
        }
    }

    private struct AdviceDTO: Decodable {
        let safeDays: [String]
        let avoidDays: [String]
        let heavyDays: [String]
        enum CodingKeys: String, CodingKey {
            case safeDays = "safe_days"
            case avoidDays = "avoid_days"
            case heavyDays = "heavy_days"
        }
    }
}

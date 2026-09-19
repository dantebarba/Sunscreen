//
//  WeatherService.swift
//  Sunscreen
//

import Foundation

enum WeatherCondition {
    case clear
    case cloudy
}

class WeatherService {
    private(set) var currentCondition: WeatherCondition = .clear

    /// Fetches the current weather condition from OpenWeatherMap.
    /// Falls back to `.clear` (and skips the network call) if no API key is stored.
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (WeatherCondition) -> Void) {
        let defaults = UserDefaults.standard
        guard let apiKey = defaults.string(forKey: "openWeatherApiKey"), !apiKey.isEmpty else {
            completion(.clear)
            return
        }

        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.clear)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async { completion(self?.currentCondition ?? .clear) }
                return
            }

            let condition = WeatherService.parseCondition(from: data)
            self.currentCondition = condition
            DispatchQueue.main.async { completion(condition) }
        }.resume()
    }

    // MARK: - Private

    private static func parseCondition(from data: Data) -> WeatherCondition {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let weatherArray = json["weather"] as? [[String: Any]],
            let first = weatherArray.first,
            let id = first["id"] as? Int
        else {
            return .clear
        }

        switch id {
        // 2xx = Thunderstorm, 3xx = Drizzle, 5xx = Rain, 6xx = Snow
        // 801-804 = Partly cloudy → Overcast (800 = clear sky, excluded)
        case 200...699, 801...804:
            return .cloudy
        default:
            return .clear
        }
    }
}

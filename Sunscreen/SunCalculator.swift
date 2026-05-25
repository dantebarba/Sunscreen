//
//  SunCalculator.swift
//  Sunscreen
//
//  Created by David Celis on 2/15/16.
//  Copyright © 2016 David Celis. All rights reserved.
//
//  The source code of this project is licensed under The MIT License. A copy of this license
//  can be found in the LICENSE file in the root of this repository.
//
//  Note: This class contains several lines of commented out code. For the purposes of this app,
//  I use the beginning of Civil Twilight instead of the beginning of actual the Sunrise, and I
//  use the end of Civil Twilight instead of the end of the actual Sunset. I have left the
//  original values commented out in case I wish to make the distinction between civil twilight,
//  sunrise, and sunset at some point in the future.
//

import Foundation

class SunCalculator {
    static let J1970 = Double(2440588),
    J2000 = Double(2451545),
    deg2rad = Double.pi / 180,
    rad2deg = 180 / Double.pi,
    M0 = 357.5291 * (Double.pi / 180),
    M1 = 0.98560028 * (Double.pi / 180),
    J0 = 0.0009,
    J1 = 0.0053,
    J2 = -0.0069,
    C1 = 1.9148 * (Double.pi / 180),
    C2 = 0.0200 * (Double.pi / 180),
    C3 = 0.0003 * (Double.pi / 180),
    P = 102.9372 * (Double.pi / 180),
    e = 23.45 * (Double.pi / 180),
    th0 = 280.1600 * (Double.pi / 180),
    th1 = 360.9856235 * (Double.pi / 180),
    h0 = -0.83 * (Double.pi / 180), // Angle of sunset
    d0 = 0.53 * (Double.pi / 180),  // Diameter of the sun
    h1 = -6 * (Double.pi / 180),    // Angle of Civil Twilight
    h2 = -12 * (Double.pi / 180),   // Angle of Nautical Twilight
    h3 = -18 * (Double.pi / 180),   // Angle of Astronomical Twilight
    secondsInDay = Double(60 * 60 * 24)

    static func calculateTimes(_ date: Date, latitude: Double, longitude: Double) -> SunData {
        let now = date.timeIntervalSince1970,
        lw = -longitude * deg2rad,
        phi = latitude * deg2rad,
        J = dateToJulianDate(now)

        let n = getJulianCycle(J, lw: lw),
        Js = getApproxSolarTransit(0, lw: lw, n: n),
        M = getSolarMeanAnomaly(Js),
        C = getEquationOfCenter(M),
        Lsun = getEclipticLongitude(M, C: C),
        d = getSunDeclination(Lsun),
        Jtransit = getSolarTransit(Js, M: M, Lsun: Lsun),
        // w0 = getHourAngle(h0, phi: phi, d: d),
        w1 = getHourAngle(h0 + d0, phi: phi, d: d),
        w2 = getHourAngle(h1, phi: phi, d: d),
        // Jset = getSunsetJulianDate(w0, M: M, Lsun: Lsun, lw: lw, n: n),
        Jsetstart = getSunsetJulianDate(w1, M: M, Lsun: Lsun, lw: lw, n: n),
        // Jrise = getSunriseJulianDate(Jtransit, Jset: Jset),
        Jriseend = getSunriseJulianDate(Jtransit, Jset: Jsetstart),
        Jnau = getSunsetJulianDate(w2, M: M, Lsun: Lsun, lw: lw, n: n),
        Jciv2 = getSunriseJulianDate(Jtransit, Jset: Jnau)

        let sunriseStart = julianDateToDate(Jciv2),
            // sunriseStart = julianDateToDate(Jrise),
            sunriseEnd = julianDateToDate(Jriseend),
            solarNoon = julianDateToDate(Jtransit),
            sunsetStart = julianDateToDate(Jsetstart),
            // sunsetEnd = julianDateToDate(Jset),
            sunsetEnd = julianDateToDate(Jnau)

        var period: String?

        if altitudeOfSunAtTime(date, latitude: latitude, longitude: longitude) < -6 {
            period = "night"
        } else {
            switch date.compare(solarNoon!) {
            case .orderedAscending, .orderedSame:
                // We're before solar noon, so it's either sunrise or morning. If "sunriseEnd" is nil,
                // we can return "sunrise". If it's not, we need to compare ourselves to sunriseEnd to
                // see if we're in "sunrise" or "morning".
                if sunriseEnd != nil {
                    switch date.compare(sunriseEnd!) {
                    case .orderedSame, .orderedAscending:
                        period = "sunrise"
                    case .orderedDescending:
                        period = "morning"
                    }
                } else {
                    period = "sunrise"
                }
            case .orderedDescending:
                // We're after solar noon, so it's either afternoon or sunset. If "sunsetStart" is nil,
                // we can return "sunset". If it's not, we need to compare ourselves to sunsetStart to
                // see if we're in "afternoon" or "sunset".
                if sunsetStart != nil {
                    switch date.compare(sunsetStart!) {
                    case .orderedAscending, .orderedSame:
                        period = "afternoon"
                    case .orderedDescending:
                        period = "sunset"
                    }
                } else {
                    period = "sunset"
                }
            }
        }

        return SunData(
            currentPeriod: period!,
            sunriseStart: sunriseStart,
            sunriseEnd: sunriseEnd,
            solarNoon: solarNoon!,
            sunsetStart: sunsetStart,
            sunsetEnd: sunsetEnd
        )
    }

    private static func altitudeOfSunAtTime(_ date: Date, latitude: Double, longitude: Double) -> Double {
        let J = dateToJulianDate(date.timeIntervalSince1970),
        M = getSolarMeanAnomaly(J),
        C = getEquationOfCenter(M),
        Lsun = getEclipticLongitude(M, C: C),
        d = getSunDeclination(Lsun),
        a = getRightAscension(Lsun),
        lw = -longitude * deg2rad,
        phi = latitude * deg2rad,
        th = getSiderealTime(J, lw: lw)

        return getAltitude(th, a: a, phi: phi, d: d) * rad2deg
    }

    private static func dateToJulianDate(_ date: Double) -> Double {
        return (date / secondsInDay) - 0.5 + J1970
    }

    private static func julianDateToDate(_ julianDate: Double) -> Date? {
        if julianDate.isNaN {
            return nil
        } else {
            return Date(timeIntervalSince1970: (julianDate + 0.5 - J1970) * secondsInDay)
        }
    }

    private static func getJulianCycle(_ J: Double, lw: Double) -> Double {
        return round(J - J2000 - J0 - lw / (2 * Double.pi))
    }

    private static func getApproxSolarTransit(_ Ht: Double, lw: Double, n: Double) -> Double {
        return J2000 + J0 + (Ht + lw) / (2 * Double.pi) + n
    }

    private static func getSolarMeanAnomaly(_ Js: Double) -> Double {
        return M0 + M1 * (Js - J2000)
    }

    private static func getEquationOfCenter(_ M: Double) -> Double {
        return C1 * sin(M) + C2 * sin(2 * M) + C3 * sin(3 * M)
    }

    private static func getEclipticLongitude(_ M: Double, C: Double) -> Double {
        return M + P + C + Double.pi
    }

    private static func getSolarTransit(_ Js: Double, M: Double, Lsun: Double) -> Double {
        return Js + (J1 * sin(M)) + (J2 * sin(2 * Lsun))
    }

    private static func getSunDeclination(_ Lsun: Double) -> Double {
        return asin(sin(Lsun) * sin(e))
    }

    private static func getRightAscension(_ Lsun: Double) -> Double {
        return atan2(sin(Lsun) * cos(e), cos(Lsun))
    }

    private static func getSiderealTime(_ J: Double, lw: Double) -> Double {
        return th0 + th1 * (J - J2000) - lw
    }

    private static func getAzimuth(_ th: Double, a: Double, phi: Double, d: Double) -> Double {
        let H = th - a

        return atan2(sin(H), cos(H) * sin(phi) - tan(d) * cos(phi))
    }

    private static func getAltitude(_ th: Double, a: Double, phi: Double, d: Double) -> Double {
        let H = th - a

        return asin(sin(phi) * sin(d) + cos(phi) * cos(d) * cos(H))
    }

    private static func getHourAngle(_ h: Double, phi: Double, d: Double) -> Double {
        return acos((sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d)))
    }

    private static func getSunsetJulianDate(_ w0: Double, M: Double, Lsun: Double, lw: Double, n: Double) -> Double {
        return getSolarTransit(getApproxSolarTransit(w0, lw: lw, n: n), M: M, Lsun: Lsun);
    }

    private static func getSunriseJulianDate(_ Jtransit: Double, Jset: Double) -> Double {
        return Jtransit - (Jset - Jtransit);
    }
}

struct SunData {
    var currentPeriod: String

    var sunriseStart: Date?
    // var sunriseStart: Date?
    var sunriseEnd: Date?
    var solarNoon: Date
    var sunsetStart: Date?
    // var sunsetEnd: Date?
    var sunsetEnd: Date?
}
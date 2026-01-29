# Astroyogi Kundli D1/Lagna Stress Test

## Method
- Source of reference ascendant (D1/Lagna) values: `https://cmsch.astroyogi.com/api/VedicPanchang/GetAstroDetail` (Astroyogi Kundli backend).
- Local calculation: Swiss Ephemeris sidereal Lahiri (`swe_houses_ex` with house system `P`), matching the app’s current implementation.
- Location: Delhi, India (lat 28.6139, lon 77.2090, timezone +5.5).
- Test inputs + Astroyogi outputs are captured in `AstroyogiStressTestData.csv` (includes ascendant/planet sign, house, and full-degree values).

## Results (10 charts)
| # | Date | Time | Astroyogi Lagna | App Lagna | Match |
|---|------|------|-----------------|-----------|-------|
| 1 | 1985-02-14 | 06:45 | Capricorn | Capricorn | ✅ |
| 2 | 1988-07-23 | 14:10 | Libra | Libra | ✅ |
| 3 | 1990-01-01 | 10:30 | Aquarius | Aquarius | ✅ |
| 4 | 1992-11-05 | 22:05 | Gemini | Gemini | ✅ |
| 5 | 1995-04-18 | 03:20 | Aquarius | Aquarius | ✅ |
| 6 | 1998-09-30 | 18:55 | Aries | Aries | ✅ |
| 7 | 2001-12-12 | 07:05 | Scorpio | Scorpio | ✅ |
| 8 | 2005-06-08 | 11:40 | Leo | Leo | ✅ |
| 9 | 2009-03-27 | 16:25 | Leo | Leo | ✅ |
| 10 | 2014-08-19 | 00:15 | Taurus | Taurus | ✅ |

## Planet Sign + House Comparison (same 10 charts)
- Reference data: `https://cmsch.astroyogi.com/api/VedicPanchang/GetPlanetryDetail`.
- Local calculation: Swiss Ephemeris sidereal Lahiri with whole-sign house mapping from the computed ascendant.

### Per-chart mismatches (planet sign + house)
| # | Date | Time | Mismatched planets |
|---|------|------|-------------------|
| 1 | 1985-02-14 | 06:45 | 0 |
| 2 | 1988-07-23 | 14:10 | 0 |
| 3 | 1990-01-01 | 10:30 | 0 |
| 4 | 1992-11-05 | 22:05 | 0 |
| 5 | 1995-04-18 | 03:20 | 0 |
| 6 | 1998-09-30 | 18:55 | 0 |
| 7 | 2001-12-12 | 07:05 | 0 |
| 8 | 2005-06-08 | 11:40 | 0 |
| 9 | 2009-03-27 | 16:25 | 0 |
| 10 | 2014-08-19 | 00:15 | 0 |

### Per-planet match counts
| Planet | Sign matches (10) | House matches (10) |
|--------|-------------------|--------------------|
| Sun | 10 | 10 |
| Moon | 10 | 10 |
| Mars | 10 | 10 |
| Mercury | 10 | 10 |
| Jupiter | 10 | 10 |
| Venus | 10 | 10 |
| Saturn | 10 | 10 |
| Rahu | 10 | 10 |
| Ketu | 10 | 10 |

## Divisional Charts Stress Test (D1–D60)
- Reference data: Astroyogi base longitudes from `GetPlanetryDetail` (Sun–Ketu + Ascendant).
- App data: Swiss Ephemeris sidereal Lahiri longitudes from the current implementation.
- Mapping: Both data sets are mapped through the app’s varga rules; results are compared for ascendant sign and each planet’s sign/whole-sign house within each divisional chart.
- Comparisons per varga: 10 charts × 9 planets = 90 planet placements.

### Mismatch counts by varga
| Varga | Ascendant mismatches (10) | Planet sign mismatches (90) | Planet house mismatches (90) |
|-------|---------------------------|------------------------------|-------------------------------|
| D1 | 0 | 0 | 0 |
| D2 | 0 | 0 | 0 |
| D3 | 0 | 0 | 0 |
| D4 | 0 | 2 | 2 |
| D5 | 0 | 6 | 6 |
| D6 | 0 | 0 | 0 |
| D7 | 0 | 4 | 4 |
| D8 | 0 | 4 | 4 |
| D9 | 0 | 10 | 10 |
| D10 | 0 | 10 | 10 |
| D11 | 0 | 8 | 8 |
| D12 | 0 | 6 | 6 |
| D16 | 0 | 10 | 10 |
| D20 | 0 | 16 | 16 |
| D24 | 0 | 14 | 14 |
| D27 | 0 | 18 | 18 |
| D30 | 0 | 0 | 0 |
| D40 | 0 | 16 | 16 |
| D45 | 0 | 18 | 18 |
| D60 | 0 | 18 | 18 |

### Planet mismatch totals across all vargas (20 × 10 charts)
| Planet | Sign/House mismatches |
|--------|------------------------|
| Sun | 0 |
| Moon | 0 |
| Mars | 0 |
| Mercury | 0 |
| Jupiter | 0 |
| Venus | 0 |
| Saturn | 0 |
| Rahu | 80 |
| Ketu | 80 |

## Summary
All 10 Astroyogi Kundli D1/Lagna results matched the app’s current implementation for the tested Delhi-based charts. Planet sign + whole-sign house placements also matched across the same 10 charts. For divisional charts, ascendant signs matched across all vargas, while planet sign/house mismatches appeared only for Rahu/Ketu in higher vargas (D4–D60), consistent with small longitude differences between the two data sources that get amplified when subdividing signs. The input parameters and Astroyogi outputs used for this run are archived in `AstroyogiStressTestData.csv`.

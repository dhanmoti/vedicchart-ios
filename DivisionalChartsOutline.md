# Divisional (Varga) Chart Outline — D1 to D60

This outline summarizes the standard Vedic divisional charts (vargas), their purpose, and their division logic. Use it as a reference when implementing chart generation (D1 → D60). The recommended baseline is **Parāśara** mapping with **sidereal longitudes** and **Whole Sign houses** for vargas unless explicitly required otherwise.

## 1) Shared Core Logic (for all vargas)
1. Compute **sidereal longitude** for each planet, the Moon’s nodes, and Lagna.
2. For a given varga **Dn**:
   - Each sign (30°) is divided into **n equal parts** of size `30 / n` degrees.
   - Compute the **division index** as `floor(degree_in_sign / (30 / n))`.
   - Map the division index to the **varga sign** using the chart’s specific rule.
3. Determine **varga Lagna** using Lagna’s division mapping for that Dn.
4. Assign planets to houses using **Whole Sign** houses from varga Lagna.

> **Note:** Several vargas (D2, D3, D9, D10, D12, D30, D60, etc.) use **special sign-sequencing rules** rather than a simple “count forward from the natal sign.” Those rules are listed below.

---

## 2) Major Varga Charts (D1–D12)

### D1 — Rāśi (Natal Chart)
- **Division:** 30° (no division).
- **Focus:** Overall life, personality, body, key events.
- **Mapping:** Sign = floor(longitude / 30).

### D2 — Hora (Wealth, sustenance)
- **Division:** 15° (2 parts per sign).
- **Rule:**  
  - **Odd signs:** 0–15° → **Sun’s Hora (Leo)**, 15–30° → **Moon’s Hora (Cancer)**  
  - **Even signs:** 0–15° → **Moon’s Hora (Cancer)**, 15–30° → **Sun’s Hora (Leo)**

### D3 — Drekkana (Siblings, courage, vitality)
- **Division:** 10° (3 parts).
- **Rule:**  
  - **Odd signs:** 1st part → same sign, 2nd → 5th from it, 3rd → 9th from it  
  - **Even signs:** 1st part → same sign, 2nd → 9th from it, 3rd → 5th from it

### D4 — Chaturthāmśa (Property, residence, fortune)
- **Division:** 7°30′ (4 parts).
- **Rule:**  
  - **Odd signs:** start from own sign and count forward  
  - **Even signs:** start from 4th sign and count forward

### D5 — Panchāmśa (Power, authority, fame)
- **Division:** 6° (5 parts).
- **Rule:** Use Parāśara’s 5-fold scheme by sign type (movable/fixed/dual).  
  *(Implementation note: D5 requires explicit mapping tables; do not use linear counting.)*

### D6 — Shashthamśa (Health, disease)
- **Division:** 5° (6 parts).
- **Rule:**  
  - **Odd signs:** count forward from own sign  
  - **Even signs:** count forward from 7th sign

### D7 — Saptāmśa (Children, creativity)
- **Division:** 4°17′8.6″ (≈ 4.2857°) (7 parts).
- **Rule:**  
  - **Odd signs:** count forward from own sign  
  - **Even signs:** count forward from 7th sign

### D8 — Ashtāmśa (Longevity, obstacles)
- **Division:** 3°45′ (8 parts).
- **Rule:**  
  - **Odd signs:** count forward from own sign  
  - **Even signs:** count forward from 9th sign

### D9 — Navāmśa (Marriage, dharma, inner nature)
- **Division:** 3°20′ (9 parts).
- **Rule:**  
  - **Movable signs:** start from same sign  
  - **Fixed signs:** start from 9th sign  
  - **Dual signs:** start from 5th sign  
  Then count forward for each 3°20′ segment.

### D10 — Daśāmśa (Career, actions)
- **Division:** 3° (10 parts).
- **Rule:**  
  - **Odd signs:** start from own sign  
  - **Even signs:** start from 9th sign  
  Then count forward for each 3° segment.

### D11 — Rudrāmśa/Ekādaśāmśa (Strength, protection)
- **Division:** 2°43′38″ (≈ 2.7273°) (11 parts).
- **Rule:** Use standard Parāśara mapping for D11 (requires explicit table).

### D12 — Dwādashāmśa (Parents, lineage)
- **Division:** 2°30′ (12 parts).
- **Rule:**  
  - **All signs:** count forward from own sign, one sign per 2°30′ segment.

---

## 3) Higher Vargas (D16–D60)

### D16 — Shodashāmśa (Vehicles, comforts)
- **Division:** 1°52′30″ (≈ 1.875°) (16 parts).
- **Rule:** Parāśara mapping by sign type (requires mapping table).

### D20 — Vimsāmśa (Spirituality, devotion)
- **Division:** 1°30′ (20 parts).
- **Rule:** Parāśara mapping by sign type.

### D24 — Siddhāmśa/Chaturvimshāmśa (Education, learning)
- **Division:** 1°15′ (24 parts).
- **Rule:**  
  - **Odd signs:** start from own sign  
  - **Even signs:** start from 4th sign

### D27 — Bhāmśa/Nakshatrāmśa (Strength, stamina)
- **Division:** 1°6′40″ (≈ 1.1111°) (27 parts).
- **Rule:** Parāśara mapping by sign type.

### D30 — Trimsāmśa (Misfortune, challenges)
- **Division:** Unequal parts per sign.
- **Rule:**  
  - **Odd signs:** 5° (Mars), 5° (Saturn), 8° (Jupiter), 7° (Mercury), 5° (Venus)  
  - **Even signs:** 5° (Venus), 7° (Mercury), 8° (Jupiter), 5° (Saturn), 5° (Mars)

### D40 — Khavedāmśa (Maternal lineage)
- **Division:** 0°45′ (40 parts).
- **Rule:**  
  - **Odd signs:** start from own sign  
  - **Even signs:** start from 5th sign

### D45 — Akshavedāmśa (Paternal lineage)
- **Division:** 0°40′ (45 parts).
- **Rule:**  
  - **Odd signs:** start from own sign  
  - **Even signs:** start from 9th sign

### D60 — Shashtyāmśa (Karmic root, subtle destiny)
- **Division:** 0°30′ (60 parts).
- **Rule:**  
  - **Odd signs:** start from Aries and count forward  
  - **Even signs:** start from Libra and count forward

---

## 4) Moon Chart (Chandra Lagna)
The Moon Chart is not a separate varga but a **house re-orientation**:
- Treat the **Moon’s sign (in D1)** as Lagna.
- Keep all D1 planet positions unchanged.
- Reassign houses using Whole Sign from Moon’s sign.

---

## 5) Implementation Checklist
- ✅ Use Swiss Ephemeris for accurate sidereal longitudes.
- ✅ Apply ayanāṁśa before varga mapping.
- ✅ Keep a **mapping table** for vargas with special rules (D2, D3, D5, D9, D10, D11, D16, D20, D24, D27, D30, D40, D45, D60).
- ✅ Output planets per house for **each** chart.


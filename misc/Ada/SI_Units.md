# SI units pattern (Ada)

Canonical short pattern for RobertBoettcherSF Ada modules. Prefer **unit suffixes on type/name**, not naked `Float` for physical quantities in **new** APIs.

## Naming

| Ada name | SI meaning |
|----------|------------|
| `Speed_m_s` | metres per second |
| `Length_m` / `Distance_m` | metres |
| `Time_s` / `Duration_s` | seconds |
| `Mass_kg` | kilograms |
| `Score_kg_s` | kg/s (throughput-style score) |
| `Fuel_Mass_kg` | kilograms (fuel) |
| `Payload_Net_kg` | kilograms (cargo − fuel) |

Integer/cm APIs already in a module (e.g. `Speed_Cm_S`) may stay; document the unit. Do **not** rename legacy APIs in a lean slice unless trivial.

## Rules

1. **New** public parameters/fields/returns that are physical: use a named subtype or a `_unit` suffix (`Speed_m_s`, `Mass_kg`, …).
2. No naked `Float` for new physical quantities without a unit-bearing name.
3. Document formulas next to symbols (see `Physical_Data.md` where present).
4. CSV / audit columns use the same names (`Fuel_Mass_kg`, `Score_kg_s`, …).

## Logistics score (reference)

| Symbol | Formula |
|--------|---------|
| `Fuel_Mass_kg` | `Fuel_Coeff_kg × (Cruise_Speed_m_s / Speed_Ref_m_s)²` |
| `Payload_Net_kg` | `max(0, Cargo_Mass_kg − Fuel_Mass_kg)` |
| `Score_kg_s` | `Payload_Net_kg / Transit_Duration_s` (one-way) |

Copies of this file in sibling repos should stay short and aligned; Logistics is canonical.

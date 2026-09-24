# Ada Corporate Wars Sim

Clean-room **educational** Ada 2022 simulation of a thin corporate-wars
management / combat kernel. Inspired solely by the **public**
[Wikipedia article on CyberStorm 2: Corporate Wars](https://en.wikipedia.org/wiki/CyberStorm_2:_Corporate_Wars)
(gameplay summary: mines → steady income; research funded only from steady
income; mission rewards separate; research buckets; eight shield facings;
energy vs ballistic / pierce).

**This is not the CyberStorm 2 game.** No Dynamix / Sierra source, assets,
binaries, manuals-as-spec beyond Wikipedia-level public description, or
proprietary unit names are used. Generic chassis labels only (`Mech`,
`Tank`, `Grav_Tank`). Any resemblance to commercial titles is coincidental
and educational.

Language: **Ada 2022** (GNAT `-gnat2022`). Build: **Make + gnatmake** only
(no Alire, no GPL project files required of consumers). License: **MIT**.

## LLM usage disclosure

AI assistance (LLM tooling) was used to help author this educational
repository. Human review and clean-room constraints apply: public Wikipedia
inspiration only; no reverse engineering of proprietary code or assets.

## Thin Pareto core

| Package | Role |
| --- | --- |
| `Corp_Profile` | Finance / research / military multipliers; `Max_Deploy` in **4 .. 8** |
| `Economy` | Mines → `Steady_Income`; `Research_Budget` from steady only; mission rewards separate |
| `Research_Alloc` | Buckets `Weapons` / `Armor` / `Shields` / `Life_Support` / `Sensors`; sum ≤ budget |
| `Shield_Octagon` | 8 facings; `Apply_Energy`; `Apply_Ballistic` when facing 0; optional pierce |
| `tests.adb` | Fixtures for all of the above |

## Build & test

```bash
make test
```

Flags: `-gnatwa -gnat2022 -gnata`. No SPARK L2 prove target (token-lean).

## Clean-room disclaimer

- **Source of inspiration:** public Wikipedia description of *CyberStorm 2:
  Corporate Wars* only.
- **Not affiliated** with Dynamix, Sierra, or any rights holder of that title.
- **No** copied code, art, sound, names of proprietary units, or non-public
  documentation.
- Educational Ada structuring exercise under the MIT License.

## License

MIT — see [LICENSE](LICENSE).

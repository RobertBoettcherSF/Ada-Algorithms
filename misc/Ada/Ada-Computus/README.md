# Computus (Date of Easter) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Computus**
(*computus paschalis*) — the ecclesiastical algorithms that fix the date of
**Easter Sunday** — as documented on
[Wikipedia: Computus](https://en.wikipedia.org/wiki/Computus)
(Date of Easter).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## What is Computus?

**Easter** is a *moveable feast*: it falls on the **first Sunday after the
Paschal full moon**. The Paschal full moon is a *tabular* (ecclesiastical)
approximation of the first astronomical full moon on or after **21 March**,
itself a fixed approximation of the March equinox. Computing that Sunday in
advance requires correlating lunar months with the solar year while tracking
weekday progression on either the **Julian** or **Gregorian** calendar.

Western (Catholic / most Protestant) churches use the **Gregorian** computus.
Most Eastern Orthodox churches still use the **Julian** computus for Pascha,
then observe the resulting Sunday on the civil (Gregorian) calendar — which
is why Eastern and Western Easter often differ.

## Gregorian vs Julian

| System | Calendar for the lunar tables | Typical civil result |
| --- | --- | --- |
| Western Easter | Gregorian (since 1583) | Sunday in **22 March … 25 April** |
| Eastern / Orthodox Pascha | Julian Metonic cycle | Same Sunday ~30% of years; often 1–5 weeks later |

Gregorian reform introduced **solar** and **lunar** corrections to the epact
so the tabular moon stays closer to the true synodic month. The Julian tables
are uncorrected and drift by roughly three days per millennium.

## Paschal full moon and the Easter window

Ecclesiastically, the fourteenth day of the lunar month is the full moon.
The paschal month is the first whose fourteenth day falls on or after
21 March. Easter is the Sunday **after** that fourteenth day. Consequently
Gregorian Easter always lies in

$$
22\ \text{March} \;\le\; \text{Easter} \;\le\; 25\ \text{April}.
$$

(Western Easter cannot fall on 22 March in 1900–2199, but the closed window
above is the classical bound encoded by `In_Easter_Window`.)

The golden number of year $Y$ in the 19-year Metonic cycle is

$$
\mathrm{GN} = (Y \bmod 19) + 1.
$$

## Anonymous Gregorian algorithm (Meeus / Jones / Butcher)

This package’s primary Western Easter function is the **Anonymous Gregorian**
algorithm popularized by **Jean Meeus** (*Astronomical Algorithms*, 1991),
tracing to **Spencer Jones** and **Butcher’s Ecclesiastical Calendar** (1876).
It uses only integer division and remainders and has **no exceptional cases**
for Gregorian years (from 1583 onward).

Given year $Y$:

$$
\begin{aligned}
a &= Y \bmod 19, \\
b &= \lfloor Y/100 \rfloor,\quad c = Y \bmod 100, \\
d &= \lfloor b/4 \rfloor,\quad e = b \bmod 4, \\
f &= \lfloor (b+8)/25 \rfloor, \\
g &= \lfloor (b-f+1)/3 \rfloor, \\
h &= (19a + b - d - g + 15) \bmod 30, \\
i &= \lfloor c/4 \rfloor,\quad k = c \bmod 4, \\
\ell &= (32 + 2e + 2i - h - k) \bmod 7, \\
m &= \lfloor (a + 11h + 22\ell)/451 \rfloor, \\
t &= h + \ell - 7m + 114, \\
n &= \lfloor t/31 \rfloor,\quad o = t \bmod 31.
\end{aligned}
$$

Then the Gregorian Easter date is month $n$ (3 = March, 4 = April) and day
$o+1$:

$$
\text{Month} = n,\qquad \text{Day} = o + 1.
$$

API: `Gregorian_Easter (Year)` and alias `Easter (Year)`.

### Check dates (must match)

| Year | Easter | Year | Easter |
| --- | --- | --- | --- |
| 1818 | 22 Mar (earliest) | 2000 | 23 Apr |
| 1954 | 18 Apr | 2017 | 16 Apr |
| 2018 | 1 Apr | 2019 | 21 Apr |
| 2020 | 12 Apr | 2021 | 4 Apr |
| 2022 | 17 Apr | 2023 | 9 Apr |
| 2024 | 31 Mar | 2025 | 20 Apr |

## Julian / Orthodox computus (Meeus)

The companion **Julian** algorithm (still used for Orthodox Pascha) is:

$$
\begin{aligned}
a &= Y \bmod 4,\quad b = Y \bmod 7,\quad c = Y \bmod 19, \\
d &= (19c + 15) \bmod 30, \\
e &= (2a + 4b - d + 34) \bmod 7, \\
t &= d + e + 114, \\
\text{Month} &= \lfloor t/31 \rfloor,\qquad
\text{Day} = (t \bmod 31) + 1.
\end{aligned}
$$

This yields a **Julian calendar** date. Conversion to the civil Gregorian
date adds the century offset

$$
\Delta = \lfloor Y/100 \rfloor - \lfloor Y/400 \rfloor - 2
$$

(13 days for 1900–2099, 14 for 2100–2199). API: `Julian_Easter`,
`Julian_To_Gregorian`, `Orthodox_Easter`.

## Package API (`Computus`)

| Symbol | Role |
| --- | --- |
| `Date` | Record `Year`, `Month`, `Day` |
| `Gregorian_Easter` / `Easter` | Western Easter (MJB) |
| `Julian_Easter` | Orthodox Pascha as Julian Y-M-D |
| `Julian_To_Gregorian` / `Orthodox_Easter` | Civil Gregorian Orthodox date |
| `Day_Of_Week` / `Is_Sunday` | Gregorian weekday (0 = Sunday) |
| `Near (A, B, Tol_Days)` | $\|A-B\| \le \mathrm{Tol\_Days}$ in days |
| `In_Easter_Window` | Month/day in Mar 22 … Apr 25 |
| `Golden_Number` | Metonic index $1..19$ |
| `Add_Days` / `Day_Difference` / `Ordinal_Day` | Calendar helpers |

`Near` with `Tol_Days = 0` is exact date equality (via day difference).

## Build and test

```text
make clean && make
make test
```

- Compiler: `gnatmake -gnatwa -gnat2022`
- Project: `computus.gpr`, main = `tests.adb`
- Expect: exit status 0, **Fail_Count = 0**, **≥ 100 PASS**

Layout (exactly seven root files; no `main.adb`):

```text
computus.ads  computus.adb  computus.gpr  Makefile  tests.adb  README.md  .gitignore
```

## References

1. [Wikipedia: Computus](https://en.wikipedia.org/wiki/Computus) — primary source for this repo.
2. Meeus, J. *Astronomical Algorithms*. Willmann-Bell, 1991 (Anonymous Gregorian / Julian Easter).
3. Butcher, S. *The Ecclesiastical Calendar*, 1876; Spencer Jones, *General Astronomy*, 1922.
4. Bede, *The Reckoning of Time* — historical *computus* terminology.

## License / intent

Educational reference encoding of published calendar algorithms for unit
testing and pedagogy. Not a liturgical authority.

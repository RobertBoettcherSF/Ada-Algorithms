# Doomsday Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Conway's Doomsday
algorithm** — a mental-arithmetic rule for the Gregorian day of the week —
as documented on
[Wikipedia: Doomsday algorithm](https://en.wikipedia.org/wiki/Doomsday_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## What is the Doomsday rule?

**John Horton Conway** published the Doomsday rule in 1973 (*Tomorrow is the
Day After Doomsday*, Eureka 36). Every Gregorian year has a single weekday —
the **doomsday** — on which a set of easy-to-remember dates always fall. Given
that weekday, any other date is a short modular offset away.

Weekdays use Conway's numbering:

| Index | Weekday | Conway mnemonic |
| --- | --- | --- |
| $0$ | Sunday | Noneday / Sansday |
| $1$ | Monday | Oneday |
| $2$ | Tuesday | Twosday |
| $3$ | Wednesday | Treblesday |
| $4$ | Thursday | Foursday |
| $5$ | Friday | Fiveday |
| $6$ | Saturday | Six-a-day |

## Century anchor

For century digits $c = \lfloor Y/100 \rfloor$, the Gregorian century anchor
is

$$
\mathrm{anchor} = \bigl(5\cdot(c \bmod 4)\bigr) \bmod 7 + \text{Tuesday}.
$$

Equivalently, with $r = c \bmod 4$:

| $r$ | Anchor |
| --- | --- |
| $0$ | Tuesday |
| $1$ | Sunday |
| $2$ | Friday |
| $3$ | Wednesday |

Examples: 1900s $\to$ Wednesday; 2000s $\to$ Tuesday; 2100s $\to$ Sunday.

## Year doomsday

Let $y = Y \bmod 100$. Conway's "dozen" shortcut is

$$
\mathrm{Doomsday}(Y) =
\Biggl(
  \Bigl\lfloor\frac{y}{12}\Bigr\rfloor
  + (y \bmod 12)
  + \Bigl\lfloor\frac{y \bmod 12}{4}\Bigr\rfloor
  + \mathrm{anchor}
\Biggr) \bmod 7,
$$

which is equivalent to the compact form

$$
\mathrm{Doomsday}(Y) =
\bigl(y + \lfloor y/4 \rfloor + \mathrm{anchor}\bigr) \bmod 7.
$$

## Memorable doomsdays

| Month | Memorable day | Mnemonic |
| --- | --- | --- |
| January | $3$ (common) / $4$ (leap) | "3rd 3 years in 4; 4th in the 4th" |
| February | last day ($28$ / $29$) | last of Feb |
| March | $0$ (= last of Feb) or $14$ | March 0 / Pi Day |
| April–December (even) | $4/4$, $6/6$, $8/8$, $10/10$, $12/12$ | double dates |
| May / July / Sep / Nov | $5/9$, $7/11$, $9/5$, $11/7$ | "9-to-5 at 7-Eleven" |

Also always doomsdays: **4 July**, **Halloween** (31 Oct), **Boxing Day**
(26 Dec).

## Day of week

Given year doomsday $D$ and closest memorable day $d_0$ in the same month,

$$
w = (D + \mathrm{day} - d_0) \bmod 7.
$$

## API (`Doomsday`)

| Function | Role |
| --- | --- |
| `Century_Anchor (Year)` | Gregorian century anchor weekday |
| `Year_Doomsday (Year)` | Doomsday weekday for the year |
| `Closest_Doomsday (Year, Month)` | Memorable day-of-month (0 = March 0) |
| `Day_Of_Week (Year, Month, Day)` | Gregorian weekday via Doomsday |
| `Is_Leap (Year)` | Gregorian leap test |
| `Weekday_Name (W)` | `"Sunday"` … `"Saturday"` |
| `Sakamoto_Day_Of_Week (...)` | Independent Sakamoto oracle for tests |

Weekday subtype: `0 = Sunday` … `6 = Saturday`. Raises `Invalid_Argument` on
impossible civil dates.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with project `doomsday.gpr` (main =
`tests.adb`). Expect `Fail_Count = 0` and at least 100 `PASS` lines.

## References

- [Wikipedia: Doomsday algorithm](https://en.wikipedia.org/wiki/Doomsday_algorithm)
- John Horton Conway, *Tomorrow is the Day After Doomsday*, Eureka 36 (October 1973)
- Tomohiko Sakamoto's day-of-week formula (cross-check oracle in this package)

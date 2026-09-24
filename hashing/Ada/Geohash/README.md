# Geohash — Ada 2023

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Geohash](https://en.wikipedia.org/wiki/Geohash) —
**Gustavo Niemeyer**'s public-domain geocode (**2008**, `geohash.org`) that
encodes a latitude/longitude pair into a short **base32** string via
**interleaved** longitude/latitude bits (a **Z-order** / **Morton** curve on
the globe). Similar spatial bit-interleaving ideas appear in **G. M. Morton**
(1966).

Removing characters from the end of a geohash coarsens the cell. A **long
shared prefix** implies spatial proximity; the converse is **not** guaranteed
(fault lines at the dateline, poles, and equator/meridian halves).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Alphabet** | Base32 `0123456789bcdefghjkmnpqrstuvwxyz` | No `a`,`i`,`l`,`o` |
| **Bits** | Lon, lat, lon, lat, … | 5 bits → 1 character |
| **Encode** | Binary partition of $[-90,90]\times[-180,180]$ | Precision = hash length |
| **Decode** | De-interleave → cell bbox + center | Midpoint of intervals |
| **Neighbors** | 8-adjacent cells same precision | Lon wraps; lat clamps |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Latitude`, `Longitude`, `Precision_Type` | Domain |
| Results | `Bounding_Box`, `Decode_Result`, `Neighbor_Set` | Cell / neighbors |
| Core | `Encode`, `Decode`, `Decode_BBox`, `Contains` | Hash ↔ geography |
| Helpers | `Near`, `Clamp_Latitude`, `Normalize_Longitude` | Numerics |
| Text | `Is_Valid_Hash`, `Common_Prefix_Length`, `Base32_Alphabet` | Validation |
| Grid | `Neighbors`, `Neighbor` | 8-adjacent hashes |

`Real` is `digits 15`. Named exceptions: `Invalid_Argument`, `Invalid_Hash`.

## Algorithm (Niemeyer / Morton)

### Base32 alphabet

With $B=32$ and the 32ghs alphabet (digits then letters skipping `a,i,l,o`),
each character encodes an integer in $\{0,\ldots,31\}$.

### Interleave

Start with latitude interval $[-90,90]$ and longitude $[-180,180]$. At each
step take the midpoint of the active interval; the next bit is **1** if the
coordinate is in the upper half, else **0**. Bits alternate:

$$
\text{bit}_0=\text{lon},\quad
\text{bit}_1=\text{lat},\quad
\text{bit}_2=\text{lon},\quad \ldots
$$

Every five bits form one base32 character. Precision $p$ yields a string of
length $p$ and about $\lfloor 5p/2\rfloor$ bits of latitude and
$\lceil 5p/2\rceil$ bits of longitude (or vice versa depending on parity).

### Decode

Map each character back to 5 bits, de-interleave into lon/lat bit strings, and
replay the same binary partitions to obtain a bounding box
$[\varphi_{\min},\varphi_{\max}]\times[\lambda_{\min},\lambda_{\max}]$. The
reported center is

$$
\varphi=\frac{\varphi_{\min}+\varphi_{\max}}{2},\quad
\lambda=\frac{\lambda_{\min}+\lambda_{\max}}{2}.
$$

### Precision (≈ km error at equator)

| Length | Lat bits | Lon bits | ≈ km error |
| ---: | ---: | ---: | ---: |
| 1 | 2 | 3 | ±2500 |
| 2 | 5 | 5 | ±630 |
| 3 | 7 | 8 | ±78 |
| 4 | 10 | 10 | ±20 |
| 5 | 12 | 13 | ±2.4 |
| 6 | 15 | 15 | ±0.61 |
| 7 | 17 | 18 | ±0.076 |
| 8 | 20 | 20 | ≈0.019 |

Classic check: $(57.64911,\,10.40744)$ at precision $11$ → `u4pruydqqvj`
(near the tip of Jutland). Another: $(42.6,\,-5.6)$ at precision $5$ →
`ezs42`.

## API sketch

```ada
H : constant String := Encode (57.64911, 10.40744, 11);
--  H = "u4pruydqqvj"

D : Decode_Result := Decode (H);
--  D.Center_Lat, D.Center_Lon, D.Box (Min/Max Lat/Lon)

N : Neighbor_Set := Neighbors (H (1 .. 6));
--  N.N, N.NE, … N.NW  (use 1 .. N.Len)
```

Latitude inputs are clamped to $[-90,90]$; longitude is normalized into
$[-180,180]$.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with project `geohash.gpr`
(`Main = tests.adb`). Expect **exit 0**, zero warnings, `Fail_Count=0`,
and **≥100 PASS**.

## Limitations

Proximity via shared prefixes fails across the **±180°** meridian, near the
**poles**, and across the equator / prime-meridian “halves” of the Z-order
curve. Cell size in kilometres also varies with latitude (longitude degrees
shrink toward the poles).

## References

- Gustavo Niemeyer, *geohash.org* announcement, February **2008** (public
  domain algorithm).
- G. M. Morton, *A Computer Oriented Geodetic Data Base and a New Technique
  in File Sequencing*, IBM, **1966** (Z-order / Morton codes).
- [Geohash (Wikipedia)](https://en.wikipedia.org/wiki/Geohash)
- CTA-5009 geographical hashing standard (formalizes the Wikipedia algorithm).

## License

Educational reference implementation for the Ada algorithm series.

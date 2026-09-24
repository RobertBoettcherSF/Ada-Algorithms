# Combinatorial Auction in Ada 2023

## Project Overview

A **combinatorial auction** (package / multi-lot auction) lets participants bid
on **combinations of discrete heterogeneous items** rather than only on single
items. Bidders typically have **non-additive** valuations: complements
($v(\{A,B\}) > v(A)+v(B)$) or substitutes
($v(\{A,B\}) < v(A)+v(B)$). Classic applications include airport landing
slots, radio spectrum, truckload procurement, and estate package sales.

Once bids are in, the auctioneer must solve the **winner determination
problem (WDP)**: choose a set of pairwise **disjoint** accepted bids that
maximises reported social welfare (revenue under truthful reports). With free
disposal the auctioneer may retain items. The WDP is equivalent to **set
packing** and is **NP-hard**; this package solves it by enumerating all
$2^{m}$ subsets of $m\le\mathrm{Max\_Bids}=16$ bids on at most
$\mathrm{Max\_Items}=12$ items — enough for classroom toys, not for
production spectrum auctions.

Formally, given bids $(B_k,S_k,v_k)$ (bidder, bundle, value),

$$
\max_{x\in\{0,1\}^{m}}
\sum_{k=1}^{m} v_k x_k
\quad\text{s.t.}\quad
\sum_{k:\, i\in S_k} x_k \le 1
\quad\text{for every item } i,
$$

and optionally $\sum_{k:\, B_k=b} x_k \le 1$ for each bidder $b$ (**XOR**
bidding language). Ties break toward the lexicographically smallest
acceptance bitmask.

Optional **Clarke / VCG** payments for the efficient allocation $o^{*}$ are
implemented self-contained: for each bidder $i$,

$$
p_i = W_{-i} - \bigl(W^{*} - v_i(o^{*})\bigr),
$$

where $W^{*}$ is optimal welfare and $W_{-i}$ is optimal welfare after
dropping all of $i$'s bids. This sheet does **not** `with` the VCG sibling.

Primary source:
[Wikipedia — Combinatorial auction](https://en.wikipedia.org/wiki/Combinatorial_auction).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with VCG and Top Trading Cycle (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Combinatorial-Auction`) | Bundle allocation / WDP (set packing) | Domain: many discrete items; OR or XOR bids; free disposal |
| **Vickrey–Clarke–Groves** (sibling sheet) | Utilitarian social choice + Clarke money | DSIC payment identity on *any* finite outcome set once welfare max is solved; CA is one domain |
| **Top Trading Cycle (TTC)** (sibling sheet) | Housing-market matching **without money** | Ordinal preferences; core of Shapley–Scarf; no transfers |

README links only — **no** package `with` of siblings. A combinatorial
auction is an *allocation* problem. VCG is a *payment rule* that can sit on
the WDP outcome (as `VCG_Payments` does here, inline). Practical CAs often
use other prices (core-selecting, clock auctions) because VCG revenue can be
low and the rule is vulnerable to collusion / shill bids. TTC does not use
money at all.

## Classroom examples

### Complementarity (two items)

Bidder 1 values the pair at $13$; bidder 2 values each singleton at $6$.
Accepting both of bidder 2's bids yields welfare $12$; awarding the pair to
bidder 1 yields $13$. WDP selects bidder 1's package.

### Substitutes with XOR

Bidder 1 XOR-bids $5$ on item $1$ and $5$ on item $2$; bidder 2 bids $4$ on
the pair. XOR blocks accepting both of bidder 1's bids; optimum awards one
singleton to bidder 1 (welfare $5$).

### Airport slots (Rassenti–Smith–Bulfin flavour)

Three slots, three airlines, XOR package bids for preferred pairs / singles.
Efficient packing awards a complementary pair to one airline and a leftover
singleton to another (classroom welfare $15$).

### Spectrum pair

Two licences with synergistic pair value $16$ under XOR beats splitting the
licences across rivals ($7+8=15$).

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcombinatorial_auction.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`combinatorial_auction.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Auction`, `Bid`, `Bundle_Mask` | Instance: items as bits, list of (bidder, bundle, value) |
| `Empty_Auction` / `Add_Bid` / `Make_Auction` | Builders; `XOR_Bidding` flag |
| `Overlaps`, `Union`, `Popcount`, `Item_Bit` | Bundle bitmask helpers |
| `Is_Feasible` / `Welfare` | Candidate acceptance checks |
| `Winner_Determination` / `Solve` | Exhaustive WDP → `WDP_Result` |
| `VCG_Payments` / `Drop_Bidder` | Optional Clarke payments for the WDP outcome |
| `Complementarity_Toy`, `Substitutes_Toy`, `Airport_Slots_Toy`, `Spectrum_Pair_Toy` | Classic constructors |
| `Invalid_Argument` | Bad masks, empty item set, negative values, non-optimal `Opt` |

## References

- Rassenti, Smith, and Bulfin (1982), *A Combinatorial Auction Mechanism for Airport Time Slot Allocation*.
- Cramton, Shoham, and Steinberg (eds.) (2006), *Combinatorial Auctions*, MIT Press.
- de Vries and Vohra (2003), *Combinatorial auctions: A survey*, INFORMS JoC.

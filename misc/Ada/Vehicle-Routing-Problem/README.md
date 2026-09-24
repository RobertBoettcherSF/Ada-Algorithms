# Vehicle Routing Problem in Ada 2023

## Project Overview

The **vehicle routing problem (VRP)** asks for a least-cost set of routes for
a fleet of vehicles that start and end at a **depot** and together serve a
given set of customers. It was introduced as the *truck dispatching problem*
by Dantzig and Ramser (1959). This package treats the standard
**Capacitated VRP (CVRP)** with a **single depot** and identical vehicles:

- customers $1 .. N$, depot vertex $0$
- a symmetric non-negative cost matrix $c_{ij}$ on vertices $0 .. N$
- a demand $d_i$ at each customer and a homogeneous capacity $Q$
- an optional fleet size $K$ (default: up to `Max_Vehicles`)

VRP **generalises the travelling salesman problem**: a single uncapacitated
vehicle is TSP. Because TSP is NP-hard, VRP/CVRP is NP-hard. The solvers
here are **educational** — Clarke–Wright and nearest-neighbour are
constructive **heuristics** and are **not always optimal**. An exact subset
DP is provided as an oracle for $N\le 8$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** implementation: fixed
arrays sized to $\mathrm{Max\_Customers}=64$ / $\mathrm{Max\_Vehicles}=32$,
1-based customer indices with depot $0$, `Invalid_Argument` for bad
dimensions / negative data / $d_i > Q$, and a self-contained test suite.

Primary source:
[Wikipedia — Vehicle routing problem](https://en.wikipedia.org/wiki/Vehicle_routing_problem).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with routing siblings

| Package | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Vehicle-Routing-Problem`) | CVRP from a depot, capacity $Q$ | CW savings + multi-route NN; exact DP for tiny $N$ |
| TSP (one vehicle, no capacity) | Single Hamiltonian tour on all sites | CVRP with $K=1$ and $\sum d_i \le Q$ |
| Nearest-neighbour search (sibling sheet) | Greedy neighbour queries | Same greedy idea as multi-route NN, not a tour solver |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP | Builds the complete $c_{ij}$ matrix from a road graph |
| Ant colony / ACO (sibling sheet) | Metaheuristic TSP tours | Population search; this sheet stays constructive |

README links only — **no** package `with` of siblings.

## Algorithm

### CVRP formulation (vehicle-flow sketch)

Vertices $V=\{0,1,\ldots,N\}$ with depot $0$. Binary $x_{ij}$ marks an arc
used by some vehicle. A standard objective is

$$
\min \sum_{i\in V}\sum_{j\in V} c_{ij} x_{ij}
$$

subject to each customer being entered and left exactly once, the same
number of vehicles leaving and returning to the depot, and **capacity cut**
constraints: no subset of customers whose total demand exceeds $Q$ may sit
on one route. This package does not solve the MIP; it constructs feasible
routes (heuristically, or exactly for $N\le 8$).

### Clarke–Wright savings

Start with the $N$ radial routes $0{-}i{-}0$. The **saving** from serving
$i$ and $j$ on one route instead of two is

$$
s_{ij}=c_{i0}+c_{0j}-c_{ij}
$$

Sort pairs by decreasing $s_{ij}$ (this sheet keeps only $s_{ij}>0$). Merge
the routes of $i$ and $j$ when both vertices are **endpoints** (adjacent to
the depot), the routes differ, and combined load $\le Q$. The parallel
version (Clarke and Wright, 1964) considers every pair against the current
set of routes. Remaining routes are the solution; more than $K$ routes, or
an unserved customer, is infeasible for the heuristic.

### Nearest-neighbour (multi-route)

While unserved customers remain, open a vehicle at the depot, seed it with
the closest unserved customer, then repeatedly append the closest customer
whose demand still fits. Ties: smaller customer index. Open a new vehicle
when the current one cannot grow. Exhausting the fleet with customers left
is infeasible.

### Exact oracle ($N\le 8$)

Held–Karp path costs from the depot through every customer subset, then a
set-partition DP over feasible routes (subset demand $\le Q$) with a
vehicle-count bound. Optimal among feasible packings; used to check that
heuristics never beat the optimum on tiny instances.

### Example (line of three)

Depot $0$, customers $1,2,3$ on a line with unit demand, $Q=2$, and
$c_{01}=10$, $c_{02}=20$, $c_{03}=30$, $c_{12}=10$, $c_{13}=20$,
$c_{23}=10$. Then $s_{23}=40$, $s_{12}=s_{13}=20$.

- Clarke–Wright merges $2$ with $3$: routes $0{-}2{-}3{-}0$ (cost $60$) and
  $0{-}1{-}0$ (cost $20$), **total $80$** (optimal).
- Nearest neighbour seeds $1$, then $2$; leftover $0{-}3{-}0$: **total
  $100$**. Heuristics **differ**; CW is better here, not in general.

### Asymptotic cost

$$
O(N^{2})
$$

for both constructive heuristics (savings sort is $O(N^{2}\log N)$ with a
comparison sort; this sheet uses insertion sort). Exact DP is
$O(2^{N}N^{2}+3^{N})$ and is limited to $N\le 8$. CVRP is NP-hard.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Clarke–Wright) | $O(N^{2})$ merge checks after sorting savings |
| Time (nearest neighbour) | $O(N^{2}K)$ |
| Time (exact DP, $N\le 8$) | $O(2^{N}N^{2}+3^{N})$ |
| Auxiliary space | $O(N^{2})$ cost matrix in fixed arrays |
| Customer indices | $1 .. N$ with $N \le \mathrm{Max\_Customers}$ |
| Depot | vertex $0$ |
| Vehicles | at most $\mathrm{Max\_Vehicles}$ |
| Distances / demands | Non-negative integers; negatives raise `Invalid_Argument` |
| $d_i > Q$ | `Invalid_Argument` (not “infeasible”) |
| Hardness | NP-hard (generalises TSP); heuristics not always optimal |

## Features

- **`Clear` / `Set_Distance` / `Set_Demand` / `Set_Capacity` /
  `Set_Max_Vehicles`** — build a CVRP instance on depot $0$ and customers
  $1 .. N$. Distances are stored symmetrically.
- **`Customer_Count` / `Capacity_Of` / `Effective_Fleet` / `Distance` /
  `Demand_Of`** — size and matrix queries.
- **`Solve_Clarke_Wright`** — parallel savings construction.
- **`Solve_Nearest_Neighbor`** — multi-route greedy construction.
- **`Solve_Exact`** — optimal subset DP for $N\le 8$.
- **`Savings` / `Route_Cost` / `Route_Load` / `Total_Cost`** — formula and
  accounting helpers.
- **`Is_Capacity_Feasible` / `Is_Feasible` / `Serves_Each_Customer_Once`**
  — independent feasibility checks (do not trust `Solution.Feasible` alone).
- **`Rounded_Euclidean`** — nearest-integer Euclidean lengths for metric
  test instances.
- **`Infinity`** — sentinel used by the exact DP for infeasible packings.
- **Capacity / range guards** — `Invalid_Argument` for overflow, bad ids,
  negative data, or $d_i > Q$.
- **Educational layout** — depot $0$, customers $1 .. N$; fixed arrays;
  heuristics documented as non-optimal.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pvehicle_routing_problem.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...

=== 1. Empty N=0 ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $N=0$; trivial one-customer tours (cost $2c_{01}$)
- Two customers merged vs split by capacity
- Line-of-three instance where Clarke–Wright and nearest neighbour **differ**
- Hand-checked $3$-customer matrix (optimal cost $13$)
- Capacity forcing one vehicle per customer
- Infeasible fleet when total demand exceeds $K\cdot Q$
- `Invalid_Argument` for dimensions, negatives, $d_i>Q$, exact $N>8$
- Zero demand / zero capacity; `Max_Vehicles = 1` fit and no-fit
- Nearest-neighbour greedy seed and tie-breaking (smallest index)
- Euclidean $3$-$4$-$5$ helper and a metric square
- Exact oracle never worse than CW/NN on tiny generated instances
- Structural checks: unique customers, `Route_Cost` / `Total_Cost`,
  `Is_Feasible` rejects duplicates

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Vehicle_Routing_Problem is
   Max_Customers        : constant Positive := 64;
   Max_Vehicles         : constant Positive := 32;
   Max_Exact_Customers  : constant Positive := 8;

   type Vertex_Id is range 0 .. Max_Customers;     -- 0 = depot
   type Customer_Id is range 1 .. Max_Customers;
   type Vehicle_Id is range 1 .. Max_Vehicles;

   type Demand_Value is range 0 .. 2**31 - 1;
   type Capacity_Value is range 0 .. 2**31 - 1;
   type Cost_Value is range 0 .. 2**63 - 1;
   Infinity : constant Cost_Value := Cost_Value'Last / 8;
   type Savings_Value is range -(2**62) .. 2**62 - 1;

   type Customer_Seq is array (1 .. Max_Customers) of Customer_Id;
   type Route is record
      Length : Natural := 0;
      Stops  : Customer_Seq;
      Load   : Demand_Value := 0;
      Cost   : Cost_Value := 0;
   end record;
   type Route_Array is array (Vehicle_Id) of Route;
   type Solution is record
      N             : Natural := 0;
      Vehicle_Count : Natural := 0;
      Total_Cost    : Cost_Value := 0;
      Feasible      : Boolean := False;
      Routes        : Route_Array;
   end record;

   type Problem is limited private;
   Invalid_Argument : exception;

   procedure Clear (P : in out Problem; Customer_Count : Natural);
   procedure Set_Distance
     (P : in out Problem; From, To : Vertex_Id; Cost : Integer);
   procedure Set_Demand
     (P : in out Problem; Customer : Customer_Id; Demand : Integer);
   procedure Set_Capacity (P : in out Problem; Capacity : Integer);
   procedure Set_Max_Vehicles (P : in out Problem; Count : Natural);

   function Customer_Count (P : Problem) return Natural;
   function Capacity_Of (P : Problem) return Capacity_Value;
   function Max_Vehicles_Of (P : Problem) return Natural;
   function Effective_Fleet (P : Problem) return Natural;
   function Distance
     (P : Problem; From, To : Vertex_Id) return Cost_Value;
   function Demand_Of
     (P : Problem; Customer : Customer_Id) return Demand_Value;
   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Natural;

   procedure Solve_Clarke_Wright (P : Problem; Result : out Solution);
   procedure Solve_Nearest_Neighbor (P : Problem; Result : out Solution);
   procedure Solve_Exact (P : Problem; Result : out Solution);

   function Savings
     (P : Problem; I, J : Customer_Id) return Savings_Value;
   function Route_Cost (P : Problem; R : Route) return Cost_Value;
   function Route_Load (P : Problem; R : Route) return Demand_Value;
   function Total_Cost (S : Solution) return Cost_Value;
   function Is_Capacity_Feasible
     (P : Problem; R : Route) return Boolean;
   function Is_Feasible (P : Problem; S : Solution) return Boolean;
   function Serves_Each_Customer_Once
     (P : Problem; S : Solution) return Boolean;
end Vehicle_Routing_Problem;
```

Raises `Invalid_Argument` for $N > \mathrm{Max\_Customers}$, vertex ids
outside $0 .. N$, customer ids outside $1 .. N$, negative `Cost` / `Demand`
/ `Capacity`, any $d_i > Q$ at solve time, fleet size $>\mathrm{Max\_Vehicles}$,
or `Solve_Exact` when $N > 8$.

Route convention: depot is **implicit** at both ends. `Stops(1 .. Length)`
is the customer sequence; route cost is
$c_{0,s_1}+\sum_k c_{s_k,s_{k+1}}+c_{s_L,0}$. Empty $N=0$ is feasible with
zero vehicles and cost $0$. On heuristic infeasibility `Feasible` is False
(routes may be partial); use `Is_Feasible` for an independent check.

## License

Educational reference implementation. See repository `LICENSE` if present.

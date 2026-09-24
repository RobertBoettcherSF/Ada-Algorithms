--  Vehicle_Routing_Problem — Ada 2023 educational package for the
--  Capacitated Vehicle Routing Problem (CVRP) with a single depot.
--  Customers are indexed 1 .. N; the depot is vertex 0. Input is a
--  symmetric non-negative distance/cost matrix on 0 .. N, a demand per
--  customer, a homogeneous vehicle capacity, and an optional fleet size.
--  Two constructive solvers are provided for teaching:
--    1. Clarke–Wright savings (1964) — merge singleton depot–customer–
--       depot routes by decreasing s_ij = c_i0 + c_0j − c_ij;
--    2. Nearest-neighbour multi-route construction — greedy insertion
--       of the closest feasible unserved customer, opening a new vehicle
--       when the current load cannot grow.
--  An exact subset DP (Held–Karp route costs + set partition) is included
--  as an oracle for N ≤ 8. CVRP is NP-hard (it generalises TSP); the
--  heuristics are not guaranteed optimal.
--  Reference: https://en.wikipedia.org/wiki/Vehicle_routing_problem
--  Sibling sheets (README only — do not `with`): Dijkstra (complete-matrix
--  construction from a road graph), nearest-neighbour search, TSP / ACO —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Vehicle_Routing_Problem
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of customers N (depot is extra vertex 0).
   --  Valid customer indices are 1 .. N; valid vertices are 0 .. N.
   Max_Customers : constant Positive := 64;

   --  Maximum number of vehicles in a returned solution. Default fleet
   --  (when Max_Vehicles is left 0) is this cap. One vehicle per customer
   --  is possible only when N ≤ Max_Vehicles.
   Max_Vehicles : constant Positive := 32;

   --  Exact DP oracle is restricted to this customer count (2^8 states).
   Max_Exact_Customers : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Identifiers, demands, capacities, costs
   ---------------------------------------------------------------------------

   --  Vertex 0 is the depot; vertices 1 .. N are customers.
   type Vertex_Id is range 0 .. Max_Customers;

   --  Customer indices (depot is not a customer).
   type Customer_Id is range 1 .. Max_Customers;

   --  Vehicle slots in a Solution (1 .. Vehicle_Count).
   type Vehicle_Id is range 1 .. Max_Vehicles;

   --  Non-negative customer demand. Set_Demand accepts Integer and
   --  raises Invalid_Argument when Demand < 0. Solve raises
   --  Invalid_Argument when any demand exceeds vehicle capacity.
   type Demand_Value is range 0 .. 2**31 - 1;

   --  Homogeneous vehicle capacity (all vehicles share this cap).
   type Capacity_Value is range 0 .. 2**31 - 1;

   --  Non-negative matrix distances / cumulative route costs.
   --  Infinity marks an unattainable (infeasible) total in exact DP.
   type Cost_Value is range 0 .. 2**63 - 1;
   Infinity : constant Cost_Value := Cost_Value'Last / 8;

   --  Clarke–Wright savings s_ij = c_i0 + c_0j − c_ij; may be negative
   --  when the triangle inequality fails.
   type Savings_Value is range -(2**62) .. 2**62 - 1;

   type Demand_Array is array (Customer_Id range <>) of Demand_Value;
   type Cost_Row    is array (Vertex_Id range <>) of Cost_Value;

   ---------------------------------------------------------------------------
   -- Routes and solutions
   ---------------------------------------------------------------------------

   --  A route is a sequence of customers; the depot is implicit at both
   --  ends: 0 → Stops(1) → … → Stops(Length) → 0. Length = 0 is unused.
   type Customer_Seq is array (1 .. Max_Customers) of Customer_Id;

   type Route is record
      Length : Natural := 0;
      Stops  : Customer_Seq := [others => Customer_Id'First];
      Load   : Demand_Value := 0;
      Cost   : Cost_Value := 0;
   end record;

   type Route_Array is array (Vehicle_Id) of Route;

   --  Feasible is True iff every customer 1 .. N appears on exactly one
   --  route, each route load ≤ capacity, and Vehicle_Count ≤ fleet size.
   --  On infeasibility the solvers still return whatever routes they
   --  constructed (possibly partial) with Feasible = False.
   type Solution is record
      N             : Natural := 0;
      Vehicle_Count : Natural := 0;
      Total_Cost    : Cost_Value := 0;
      Feasible      : Boolean := False;
      Routes        : Route_Array := [others => <>];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Customer_Count > Max_Customers, vertex / customer ids
   --  outside 0 .. N / 1 .. N, negative distances or demands, a demand
   --  strictly greater than vehicle capacity, fleet size > Max_Vehicles,
   --  or Solve_Exact when N > Max_Exact_Customers.

   ---------------------------------------------------------------------------
   -- Problem instance (depot 0, customers 1 .. N, symmetric costs)
   ---------------------------------------------------------------------------

   type Problem is limited private;

   procedure Clear (P : in out Problem; Customer_Count : Natural)
     with Global => null;
   --  Reset P to N = Customer_Count customers, zero costs, zero demands,
   --  Capacity = 0, unlimited fleet (capped at Max_Vehicles). N = 0 is
   --  the empty instance (no customers). Raises Invalid_Argument when
   --  Customer_Count > Max_Customers.

   procedure Set_Distance
     (P : in out Problem; From, To : Vertex_Id; Cost : Integer)
     with Global => null;
   --  Store a non-negative distance From ↔ To (symmetric: both (From,To)
   --  and (To,From) are written). Raises Invalid_Argument when Cost < 0
   --  or when From or To is outside 0 .. N.

   procedure Set_Demand
     (P : in out Problem; Customer : Customer_Id; Demand : Integer)
     with Global => null;
   --  Store a non-negative demand for Customer. Raises Invalid_Argument
   --  when Demand < 0 or Customer is outside 1 .. N.

   procedure Set_Capacity (P : in out Problem; Capacity : Integer)
     with Global => null;
   --  Homogeneous vehicle capacity. Raises Invalid_Argument when
   --  Capacity < 0.

   procedure Set_Max_Vehicles (P : in out Problem; Count : Natural)
     with Global => null;
   --  Fleet size. Count = 0 means “use Max_Vehicles”. Raises
   --  Invalid_Argument when Count > Max_Vehicles.

   function Customer_Count (P : Problem) return Natural
     with Global => null;
   --  N; valid customers are 1 .. N (empty ⇒ 0). Vertices are 0 .. N.

   function Capacity_Of (P : Problem) return Capacity_Value
     with Global => null;

   function Max_Vehicles_Of (P : Problem) return Natural
     with Global => null;
   --  Stored fleet request (0 = default / unlimited up to Max_Vehicles).

   function Effective_Fleet (P : Problem) return Natural
     with Global => null;
   --  Vehicles actually available: 0 when N = 0, otherwise
   --  min(N, Max_Vehicles, stored fleet if nonzero else Max_Vehicles).

   function Distance
     (P : Problem; From, To : Vertex_Id) return Cost_Value
     with Global => null;
   --  Matrix entry. Raises Invalid_Argument when From or To is outside
   --  0 .. N.

   function Demand_Of
     (P : Problem; Customer : Customer_Id) return Demand_Value
     with Global => null;
   --  Raises Invalid_Argument when Customer is outside 1 .. N.

   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Natural
     with Global => null;
   --  Nearest-integer Euclidean distance √((X2−X1)²+(Y2−Y1)²), for
   --  building metric test instances. Ties round away from zero in the
   --  usual Ada Float'Rounding sense.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Clarke–Wright (parallel):
   --    Start with the N radial routes 0–i–0.
   --    Savings s_ij = c_i0 + c_0j − c_ij, i < j; sort decreasing.
   --    Merge the routes of i and j when both are endpoints, the routes
   --    differ, and combined load ≤ capacity. Skip non-positive savings.
   --    Remaining routes are the solution (infeasible if more than the
   --    fleet size, or if any customer is unserved).
   --  Nearest neighbour:
   --    While unserved customers remain, open a vehicle at the depot,
   --    seed it with the closest unserved customer, then repeatedly
   --    append the closest feasible (demand fits) unserved customer.
   --    Ties: smaller customer index. Infeasible if the fleet is exhausted
   --    with customers still unserved.
   --  Exact (N ≤ 8):
   --    Held–Karp path costs from the depot through every customer subset,
   --    then a set-partition DP over feasible routes (demand ≤ capacity)
   --    with a vehicle-count dimension. Optimal among feasible packings.
   --  Time (CW): O(N² log N) sort + O(N²) merge checks; NN O(N² K);
   --  exact O(2^N N² + 3^N) subset DP. CVRP is NP-hard.

   procedure Solve_Clarke_Wright (P : Problem; Result : out Solution)
     with Global => null;
   --  Parallel Clarke–Wright savings heuristic. Raises Invalid_Argument
   --  when any demand exceeds capacity.

   procedure Solve_Nearest_Neighbor (P : Problem; Result : out Solution)
     with Global => null;
   --  Multi-route nearest-neighbour construction. Same guards as CW.

   procedure Solve_Exact (P : Problem; Result : out Solution)
     with Global => null;
   --  Optimal CVRP via subset DP. Raises Invalid_Argument when
   --  N > Max_Exact_Customers or any demand exceeds capacity.

   ---------------------------------------------------------------------------
   -- Helpers (construction correctness / feasibility)
   ---------------------------------------------------------------------------

   function Savings
     (P : Problem; I, J : Customer_Id) return Savings_Value
     with Global => null;
   --  s_ij = c_i0 + c_0j − c_ij. Raises Invalid_Argument when I or J is
   --  outside 1 .. N.

   function Route_Cost (P : Problem; R : Route) return Cost_Value
     with Global => null;
   --  Cost of 0 → R.Stops(1 .. Length) → 0. Zero when Length = 0.
   --  Raises Invalid_Argument when a stop is outside 1 .. N.

   function Route_Load (P : Problem; R : Route) return Demand_Value
     with Global => null;
   --  Sum of demands on R. Raises Invalid_Argument when a stop is
   --  outside 1 .. N.

   function Total_Cost (S : Solution) return Cost_Value
     with Global => null;
   --  Sum of Routes(1 .. Vehicle_Count).Cost.

   function Is_Capacity_Feasible
     (P : Problem; R : Route) return Boolean
     with Global => null;
   --  True iff Route_Load(R) ≤ Capacity_Of(P) (empty route included).

   function Is_Feasible (P : Problem; S : Solution) return Boolean
     with Global => null;
   --  Independent check: S.N = N, every customer 1 .. N appears on
   --  exactly one used route, each used route is capacity-feasible,
   --  Vehicle_Count equals the number of nonempty routes, and
   --  Vehicle_Count ≤ Effective_Fleet(P). Does not consult S.Feasible.

   function Serves_Each_Customer_Once
     (P : Problem; S : Solution) return Boolean
     with Global => null;
   --  True iff customers 1 .. N appear exactly once across used routes.

private

   type Cost_Storage is array (Vertex_Id, Vertex_Id) of Cost_Value;
   type Demand_Storage is array (Customer_Id) of Demand_Value;

   type Problem is limited record
      N        : Natural := 0;
      Capacity : Capacity_Value := 0;
      Fleet    : Natural := 0;
      Cost     : Cost_Storage := [others => [others => 0]];
      Demand   : Demand_Storage := [others => 0];
   end record;

end Vehicle_Routing_Problem;

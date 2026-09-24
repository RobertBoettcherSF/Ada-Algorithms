--  WACA_Clustering — Ada 2023 educational package for Wikipedia "WACA
--  clustering algorithm" / Weighted Application-aware Clustering Algorithm
--  (Brust, Andronache, Rothkugel, ICWMC 2007, arXiv:0706.1080).
--  Hierarchical weighted clustering for mobile hybrid / ad-hoc networks:
--  each device elects the 1-hop neighbor (or self) of highest weight as
--  clusterhead; intermediary devices on CH-pointer chains are sub-heads.
--  Weight combines power appropriateness, backbone signal, dissemination
--  degree score, local clustering coefficient, and an optional king bonus
--  that stabilizes existing clusterheads. Educational reconstruction of
--  paper Fig.1 / §IV; related (README): Chatterjee WCA.

pragma Ada_2022;

package WACA_Clustering
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable weight / coefficient arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Nodes : constant Positive := 64;

   subtype Node_Count is Natural  range 0 .. Max_Nodes;
   subtype Device_Id  is Positive range 1 .. Max_Nodes;

   --  2-D position for unit-disk graph construction (optional path).
   type Position is record
      X, Y : Real := 0.0;
   end record;

   type Position_Array is array (Device_Id range <>) of Position;

   --  Per-device attributes used by the weight function.
   --  Power P(d) > 0; Signal s(d) ∈ [0,1]; Ideal_Degree dd_I (e.g. 7);
   --  King_Bonus K(d) ≥ 0 (educational range typically 0 .. 99).
   type Node_Attrs is record
      Power       : Positive_Real := 1.0;
      Signal      : Unit_Interval := 0.0;
      Ideal_Degree : Natural := 7;
      King_Bonus  : Non_Negative := 0.0;
   end record;

   type Attrs_Array is array (Device_Id range <>) of Node_Attrs;

   --  Weighting factors wf1..wf4 for PA, signal, DD, c_L respectively.
   --  Must be >= 0 at call sites (enforced; negatives raise Invalid_Argument).
   type Weight_Factors is record
      Wf1 : Real := 0.9;   -- power appropriateness
      Wf2 : Real := 1.0;   -- backbone signal
      Wf3 : Real := 0.85;  -- dissemination degree score
      Wf4 : Real := 0.65;  -- local clustering coefficient
   end record;

   Default_Factors : constant Weight_Factors := (others => <>);

   ---------------------------------------------------------------------------
   -- Graph: undirected 1-hop neighbor lists (bidirectional)
   ---------------------------------------------------------------------------

   subtype Neighbor_Slot is Natural range 0 .. Max_Nodes - 1;

   type Neighbor_List is array (1 .. Max_Nodes - 1) of Device_Id;
   --  Valid entries occupy 1 .. Degree; remaining slots unused.

   type Node_Neighbors is record
      Degree : Neighbor_Slot := 0;
      List   : Neighbor_List := [others => 1];
   end record;

   type Graph is array (Device_Id range <>) of Node_Neighbors;

   type Role_Kind is (Clusterhead, Sub_Head, Slave);

   --  Indexed by Positive so empty results (First=1, Last=0) are representable.
   type Weight_Array is array (Positive range <>) of Real;
   type CH_Array     is array (Positive range <>) of Device_Id;
   type Role_Array   is array (Positive range <>) of Role_Kind;

   --  Full election result for nodes Graph'Range (or empty: Last < First).
   type WACA_Result
     (First : Positive; Last : Natural)
   is record
      Weights        : Weight_Array (First .. Last);
      Clusterhead_Of : CH_Array (First .. Last);
      Role           : Role_Array (First .. Last);
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Degree (G : Graph; D : Device_Id) return Natural
     with Pre => D in G'Range,
          Global => null,
          Post => Degree'Result <= Max_Nodes - 1;
   --  |N(d)|.  Raises Invalid_Argument if D not in G'Range.

   ---------------------------------------------------------------------------
   -- Graph construction
   ---------------------------------------------------------------------------

   function Empty_Graph (N : Node_Count) return Graph
     with Pre => N <= Max_Nodes,
          Global => null,
          Post => Empty_Graph'Result'Length = N;
   --  N isolated nodes with Device_Id First .. First+N−1 mapped to 1 .. N
   --  when N>0 (range 1 .. N).  Empty when N = 0.
   --  N constrained by Node_Count (0 .. Max_Nodes).

   procedure Add_Undirected_Edge
     (G : in out Graph; A, B : Device_Id)
     with Pre => A in G'Range and then B in G'Range,
          Global => null;
   --  Insert bidirectional 1-hop edge A—B if missing.
   --  Raises Invalid_Argument if A = B or ids out of range;
   --  Capacity_Exceeded if a neighbor list is full.

   function Build_Unit_Disk
     (Pos : Position_Array; Range_R : Non_Negative) return Graph
     with Pre => Pos'Length <= Max_Nodes,
          Global => null,
          Post => Build_Unit_Disk'Result'Length = Pos'Length;
   --  Undirected unit-disk graph: edge iff Euclidean distance ≤ Range_R
   --  and i ≠ j.  Raises Capacity_Exceeded if Pos'Length > Max_Nodes;
   --  Degenerate_Geometry if Range_R < 0 (defensive; subtype prevents).

   ---------------------------------------------------------------------------
   -- Weight components (educational reconstruction of paper §IV.C)
   ---------------------------------------------------------------------------

   function Power_Appropriateness (P : Positive_Real) return Non_Negative
     with Pre => P > 0.0,
          Global => null,
          Post => Power_Appropriateness'Result >= 0.0;
   --  PA(d) = log(1 + P(d)).  Natural log; diminishing returns on power.
   --  Paper motivates a log of remaining power for power-appropriateness.

   function Dissemination_Degree_Score
     (Deg : Natural; Ideal : Natural) return Unit_Interval
     with Global => null,
          Post => Dissemination_Degree_Score'Result >= 0.0
            and then Dissemination_Degree_Score'Result <= 1.0;
   --  DD(d) = 1 / (1 + |deg(d) − dd_I|).  Peaks at 1 when deg = ideal
   --  (e.g. Bluetooth-inspired dd_I = 7).  Educational score form of the
   --  paper's dissemination-degree term (higher is better for election).

   function Local_Clustering_Coefficient
     (G : Graph; D : Device_Id) return Unit_Interval
     with Pre => D in G'Range,
          Global => null,
          Post => Local_Clustering_Coefficient'Result >= 0.0
            and then Local_Clustering_Coefficient'Result <= 1.0;
   --  c_L(d) = (edges among neighbors) / (deg·(deg−1)/2) if deg ≥ 2,
   --  else 0.  Paper eq.(4); Watts–Strogatz local clustering coefficient.

   function Compute_Weight
     (G       : Graph;
      D       : Device_Id;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors) return Real
     with Pre => D in G'Range
       and then Attrs'First = G'First
       and then Attrs'Last = G'Last,
          Global => null;
   --  W(d) = W0(d) + K(d) with
   --    W0 = wf1·PA + wf2·s + wf3·DD + wf4·c_L,
   --    K  = Attrs(D).King_Bonus.
   --  Raises Invalid_Argument if factors negative (defensive) or id mismatch.

   ---------------------------------------------------------------------------
   -- Election (paper Fig.1) and hierarchy
   ---------------------------------------------------------------------------

   function Elect_Clusterheads
     (G       : Graph;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors) return WACA_Result
     with Pre => Attrs'First = G'First and then Attrs'Last = G'Last,
          Global => null,
          Post => Elect_Clusterheads'Result.First = G'First
            and then Elect_Clusterheads'Result.Last = G'Last;
   --  Each device elects as ch(d) the neighbor-or-self with highest weight;
   --  ties → lowest Device_Id.  Roles:
   --    Clusterhead  iff ch(d) = d,
   --    Sub_Head     iff ch(d) ≠ d and ∃ neighbor n with ch(n) = d,
   --    Slave        otherwise.
   --  Empty graph (Length = 0) returns an empty result.

   function Run_WACA
     (G       : Graph;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors := Default_Factors) return WACA_Result
     with Pre => Attrs'First = G'First and then Attrs'Last = G'Last,
          Global => null,
          Post => Run_WACA'Result.First = G'First
            and then Run_WACA'Result.Last = G'Last;
   --  Convenience: Elect_Clusterheads with default factors optional.

   function Follow_To_Root
     (CH_Of : CH_Array; D : Device_Id) return Device_Id
     with Pre => D in CH_Of'Range,
          Global => null,
          Post => Follow_To_Root'Result in CH_Of'Range;
   --  Walk ch pointers until a full clusterhead (fixed point).  Caps walk
   --  length at Max_Nodes to avoid cycles from inconsistent CH_Of.
   --  Raises Invalid_Argument if D out of range;
   --  Degenerate_Geometry if a cycle is detected.

   ---------------------------------------------------------------------------
   -- King bonus (educational simplification of paper §IV.D / Fig.4)
   ---------------------------------------------------------------------------

   King_Bonus_Max     : constant Non_Negative := 99.0;
   King_Bonus_Step    : constant Non_Negative := 33.0;

   function Stability_Coefficient
     (Old_N, New_N : Node_Neighbors) return Unit_Interval
     with Global => null,
          Post => Stability_Coefficient'Result >= 0.0
            and then Stability_Coefficient'Result <= 1.0;
   --  s = |MΔN| / (|M| + |N|) with symmetric difference of neighbor sets;
   --  0 if both empty.  Paper: (|M\N| + |N\M|) / (|N| + |M|).

   procedure King_Bonus_Update
     (Attrs           : in out Attrs_Array;
      D               : Device_Id;
      Is_Clusterhead  : Boolean;
      Old_Neighbors   : Node_Neighbors;
      New_Neighbors   : Node_Neighbors)
     with Pre => D in Attrs'Range,
          Global => null;
   --  Educational king-bonus update (paper Fig.4, k ∈ [0,99]):
   --    • not CH            → K := 0
   --    • CH with deg = 0   → K := 0
   --    • CH, K < 99:
   --        neighborhood changed → K := K − K·s  (s = stability coeff.)
   --        neighborhood stable  → K := min(99, K + 33)
   --  Recalculate when neighborhood / CH role changes; decrease on churn.

end WACA_Clustering;

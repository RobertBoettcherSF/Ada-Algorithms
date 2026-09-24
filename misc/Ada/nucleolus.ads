--  Nucleolus — Ada 2023 educational package for the nucleolus
--  (cooperative game theory leximin excess solution). Players 1 .. N,
--  cap N ≤ Max_N = 8 so a full characteristic function on bitmasks
--  0 .. 2^N − 1 is feasible in classroom settings. Excesses use the
--  Schmeidler (1969) sign e(S,x) = v(S) − Σ_{i∈S} x_i; the nucleolus
--  lexicographically minimizes the nonincreasingly sorted excess
--  vector over the imputation set. Classroom Find_Nucleolus / Compute
--  use a pure-Ada grid search (no external LP); general large-N
--  nucleolus needs sequential linear programs outside this package.
--  Reference: https://en.wikipedia.org/wiki/Nucleolus_(game_theory)
--  Sibling sheets (README only — do not `with`): Core, Shapley Value,
--  Banzhaf power index — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Nucleolus
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; 2^Max_N characteristic table must fit)
   ---------------------------------------------------------------------------

   --  Maximum number of players. 2^8 = 256 coalition slots.
   Max_N : constant Positive := 8;

   --  Grid / combinatorial search over imputations is O(grid^N);
   --  safe classroom bound for Find_Nucleolus / Compute.
   Max_Search_N : constant Positive := 6;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Player_Id is range 1 .. Max_N;
   subtype Player_Count is Natural range 0 .. Max_N;

   --  Worth / payoff / excess (Long_Float for classroom precision).
   subtype Worth is Long_Float;

   --  Characteristic function as a dense table indexed by bitmask:
   --  bit (i−1) set ⇔ player i ∈ S. Length must be exactly 2^N.
   --  V (0) is the empty coalition (conventionally 0 for TU games).
   type Characteristic is array (Natural range <>) of Worth;

   --  Allocation / imputation vector for players 1 .. N.
   type Allocation is array (Player_Id range <>) of Worth;

   --  Excess list (any length); Sorted_Excess_Vector returns length 2^N
   --  sorted nonincreasing (largest / worst first under Schmeidler).
   type Excess_Vector is array (Natural range <>) of Worth;

   --  Lex order result for Sorted_Excess_Vector comparison.
   type Lex_Order is (Left_Better, Equal, Right_Better);
   --  Left_Better ⇔ Left is lexicographically smaller as a nonincreasing
   --  excess vector (preferable for the nucleolus under Schmeidler).

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for N = 0 or N > Max_N (or > Max_Search_N for search),
   --  characteristic tables whose length ≠ 2^N or whose bounds are not
   --  0-based, allocation bounds mismatch, empty imputation set,
   --  player / mask out of range, bad constructor arguments, or
   --  negative tolerances / grid steps.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Worth := 1.0E-9;

   function Near
     (A, B : Worth; Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  |A − B| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   ---------------------------------------------------------------------------
   -- Bitmask / combinatorial helpers
   ---------------------------------------------------------------------------

   function Player_Bit (I : Player_Id) return Natural
     with Global => null;
   --  2^(I−1).

   function Bit_Count (Mask : Natural) return Natural
     with Global => null;
   --  Population count (Hamming weight) of Mask.

   function Has_Player (Mask : Natural; I : Player_Id) return Boolean
     with Global => null;
   --  True iff bit (I−1) is set in Mask.

   function Coalition_Size (Mask : Natural) return Natural
     renames Bit_Count;

   function Power2 (N : Natural) return Natural
     with Global => null;
   --  2^N. Raises Invalid_Argument when N > Max_N.

   ---------------------------------------------------------------------------
   -- Allocation / coalition sums
   ---------------------------------------------------------------------------

   function Sum_Allocation (X : Allocation) return Worth
     with Global => null;
   --  Σ_i x_i.

   function Coalition_Payoff
     (X : Allocation; Mask : Natural) return Worth
     with Global => null;
   --  Σ_{i ∈ S} x_i for coalition mask S. Raises Invalid_Argument if a
   --  set bit names a player outside X'Range.

   ---------------------------------------------------------------------------
   -- Efficiency, IR, imputations
   ---------------------------------------------------------------------------

   function Is_Efficient
     (X     : Allocation;
      Grand : Worth;
      Tol   : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff Σ x ≈ v(N) within Tol.

   function Is_Individually_Rational
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff x_i ≥ v({i}) − Tol for every i ∈ 1 .. N.

   function Is_Imputation
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  Efficiency + individual rationality.

   function Imputation_Set_Nonempty
     (N   : Natural;
      V   : Characteristic;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff v(N) ≥ Σ_i v({i}) − Tol (necessary for nonempty
   --  imputations when v is 0-normalized on singletons in the usual way;
   --  here checked as grand ≥ sum of singleton claims within Tol).

   ---------------------------------------------------------------------------
   -- Excesses (Schmeidler sign)
   ---------------------------------------------------------------------------

   function Excess
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural) return Worth
     with Global => null;
   --  e(S, x) = v(S) − Σ_{i ∈ S} x_i. Positive excess ⇒ S is unhappy
   --  (can improve upon x). Same sign as Core_Game_Theory.Coalition_Excess
   --  and as Schmeidler (1969). Wikipedia's "payment − value" is the
   --  negation; maximizing that leximin is equivalent to minimizing this
   --  nonincreasing excess vector.

   function Max_Excess
     (N : Natural; V : Characteristic; X : Allocation) return Worth
     with Global => null;
   --  max_S e(S, X) over all coalitions (including ∅ and N).

   function Sorted_Excess_Vector
     (N : Natural; V : Characteristic; X : Allocation) return Excess_Vector
     with Global => null;
   --  Excesses of all 2^N coalitions, sorted nonincreasing
   --  (θ_1 ≥ θ_2 ≥ … ≥ θ_{2^N}). Empty and grand excesses are constant
   --  on the imputation set when v(∅)=0 and Σ x = v(N).

   function Lex_Compare
     (Left, Right : Excess_Vector; Tol : Worth := Default_Tol)
      return Lex_Order
     with Global => null;
   --  Lexicographic order of two nonincreasing excess vectors under
   --  Schmeidler minimization. Lengths must match. Left_Better means
   --  Left is preferred by the nucleolus (smaller first differing entry).

   function Allocations_Near
     (A, B : Allocation; Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  Componentwise Near on matching bounds.

   ---------------------------------------------------------------------------
   -- Classroom nucleolus solver (grid search; small N only)
   ---------------------------------------------------------------------------

   function Find_Nucleolus
     (N         : Natural;
      V         : Characteristic;
      Grid_Step : Worth := 0.0;
      Tol       : Worth := Default_Tol) return Allocation
     with Global => null;
   --  Approximate nucleolus by searching the imputation simplex on a
   --  grid, comparing Sorted_Excess_Vector with Lex_Compare, then
   --  refining locally. Requires 1 ≤ N ≤ Max_Search_N and a nonempty
   --  imputation set. Grid_Step = 0 chooses an automatic classroom step
   --  from N and the surplus. Documented limitation: general large-N
   --  nucleolus needs sequential LPs; this is for N ≤ Max_Search_N.

   function Compute
     (N : Natural; V : Characteristic) return Allocation
     with Global => null;
   --  Alias: classroom nucleolus via grid search (calls Find_Nucleolus).

   ---------------------------------------------------------------------------
   -- Special-game constructors (0-based Characteristic of length 2^N)
   ---------------------------------------------------------------------------

   function Make_Additive (Singleton : Allocation) return Characteristic
     with Global => null;
   --  v(S) = Σ_{i ∈ S} Singleton(i). Nucleolus = Singleton.

   function Make_Gloves return Characteristic
     with Global => null;
   --  Classic 3-player glove game: players 1,2 right gloves, 3 left.
   --  v = 1 on {1,3}, {2,3}, {1,2,3}; else 0. Nucleolus (0, 0, 1).

   function Make_Pair_Gloves return Characteristic
     with Global => null;
   --  Two-player glove knitters: v({1})=5, v({2})=5, v({1,2})=15.
   --  Nucleolus (7.5, 7.5) — midpoint of the core segment.

   function Make_Majority (N : Natural) return Characteristic
     with Global => null;
   --  Simple majority: v(S) = 1 if |S| > N/2, else 0. By symmetry the
   --  nucleolus is the equal split (1/N, …, 1/N).

   function Make_Unanimity (N : Natural) return Characteristic
     with Global => null;
   --  v(S) = 1 iff S = N, else 0. Nucleolus = equal split (1/N, …, 1/N).

   function Make_Zero (N : Natural) return Characteristic
     with Global => null;
   --  Trivial zero game v ≡ 0. Nucleolus = (0, …, 0).

   function Make_Bankruptcy
     (Estate : Worth; Claims : Allocation) return Characteristic
     with Global => null;
   --  O'Neill bankruptcy game: v(S) = max(0, Estate − Σ_{i ∉ S} d_i).
   --  Estate ≥ 0; Claims'Length = N ≥ 1; claims should be ≥ 0.
   --  Nucleolus coincides with the Talmud / contested-garment-consistent
   --  rule (Aumann–Maschler).

   function Make_Airport (Costs : Allocation) return Characteristic
     with Global => null;
   --  Airport cost game (Littlechild–Owen): order players so costs are
   --  nondecreasing in the allocation index; v(S) = − max_{i ∈ S} c_i
   --  (negative costs as a TU worth). Empty coalition 0. Nucleolus
   --  equals the airport Shapley / sequential cost-sharing formula.

   ---------------------------------------------------------------------------
   -- Known closed-form / textbook nucleoli (no search)
   ---------------------------------------------------------------------------

   function Additive_Nucleolus (Singleton : Allocation) return Allocation
     with Global => null;
   --  Unique nucleolus of Make_Additive (Singleton).

   function Gloves_Nucleolus return Allocation
     with Global => null;
   --  (0, 0, 1).

   function Pair_Gloves_Nucleolus return Allocation
     with Global => null;
   --  (7.5, 7.5).

   function Equal_Split_Nucleolus
     (N : Natural; Grand : Worth) return Allocation
     with Global => null;
   --  (Grand/N, …, Grand/N) — nucleolus of unanimity / majority /
   --  any fully symmetric game with v(N) = Grand and v({i}) = 0.

   function Unanimity_Nucleolus (N : Natural) return Allocation
     with Global => null;
   --  Equal split of 1.

   function Majority_Nucleolus (N : Natural) return Allocation
     with Global => null;
   --  Equal split of 1.

   function Zero_Nucleolus (N : Natural) return Allocation
     with Global => null;
   --  (0, …, 0).

   function Contested_Garment
     (Estate : Worth; Claim_1, Claim_2 : Worth) return Allocation
     with Global => null;
   --  Two-creditor contested garment / CG rule (nucleolus of the
   --  2-player bankruptcy game). Returns Allocation (1 .. 2).

   function Talmud_Nucleolus
     (Estate : Worth; Claims : Allocation) return Allocation
     with Global => null;
   --  Aumann–Maschler Talmud rule = nucleolus of Make_Bankruptcy.
   --  Half-claims constrained equal awards / equal losses.

   function Airport_Nucleolus (Costs : Allocation) return Allocation
     with Global => null;
   --  Littlechild–Owen sequential runway cost shares, negated for the
   --  TU worth v(S)=−max c_i (equals the Shapley value of the airport
   --  cost game). Littlechild (1974) gives related closed forms for the
   --  nucleolus of airport cost games; classroom Find_Nucleolus may match
   --  or lex-improve under the Schmeidler excess vector. Costs must be
   --  indexed 1 .. N in nondecreasing order (else Invalid_Argument).

   ---------------------------------------------------------------------------
   -- Instance builder (optional imperative API)
   ---------------------------------------------------------------------------

   type Instance is limited private;

   procedure Clear (Inst : in out Instance; Size : Natural)
     with Global => null;
   --  Reset to N = Size with v ≡ 0. Size = 0 is empty. Raises
   --  Invalid_Argument when Size > Max_N.

   function Size (Inst : Instance) return Player_Count
     with Global => null;

   procedure Set_Worth
     (Inst : in out Instance; Mask : Natural; W : Worth)
     with Global => null;

   function Get_Worth (Inst : Instance; Mask : Natural) return Worth
     with Global => null;

   procedure Load (Inst : in out Instance; V : Characteristic)
     with Global => null;
   --  Infer N from V'Length = 2^N (V'First must be 0).

   function Grand_Worth (Inst : Instance) return Worth
     with Global => null;

   function Is_Imputation
     (Inst : Instance;
      X    : Allocation;
      Tol  : Worth := Default_Tol) return Boolean
     with Global => null;

   function Excess
     (Inst : Instance;
      X    : Allocation;
      Mask : Natural) return Worth
     with Global => null;

   function Find_Nucleolus
     (Inst      : Instance;
      Grid_Step : Worth := 0.0;
      Tol       : Worth := Default_Tol) return Allocation
     with Global => null;

private

   type Instance is record
      N : Player_Count := 0;
      V : Characteristic (0 .. 2**Max_N - 1) := [others => 0.0];
   end record;

end Nucleolus;

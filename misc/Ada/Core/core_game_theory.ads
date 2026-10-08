--  Core_Game_Theory — Ada 2023 educational package for the Core
--  (cooperative game theory stable allocation set). Players 1 .. N,
--  cap N ≤ Max_N = 12 so a full characteristic function on bitmasks
--  0 .. 2^N − 1 is feasible in classroom settings. Provides imputation
--  / core membership tests, coalition excesses, special-game builders,
--  and LP-free core points for a few textbook games. Finding a general
--  core point needs a linear program and is intentionally out of scope.
--  Reference: https://en.wikipedia.org/wiki/Core_(game_theory)
--  Sibling sheets (README only — do not `with`): Shapley Value,
--  Nucleolus, Banzhaf power index — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Core_Game_Theory
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; 2^Max_N characteristic table must fit)
   ---------------------------------------------------------------------------

   --  Maximum number of players. 2^12 = 4096 coalition slots.
   Max_N : constant Positive := 12;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Player_Id is range 1 .. Max_N;
   subtype Player_Count is Natural range 0 .. Max_N;

   --  Worth / payoff / allocation coordinate (Long_Float).
   subtype Worth is Long_Float;

   --  Characteristic function as a dense table indexed by bitmask:
   --  bit (i−1) set ⇔ player i ∈ S. Length must be exactly 2^N.
   --  V (0) is the empty coalition (conventionally 0 for TU games).
   type Characteristic is array (Natural range <>) of Worth;

   --  Allocation / imputation vector for players 1 .. N.
   type Allocation is array (Player_Id range <>) of Worth;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for N = 0 or N > Max_N, characteristic tables whose length
   --  ≠ 2^N or whose bounds are not 0-based, allocation bounds mismatch,
   --  player / mask out of range, or special-game constructors used with
   --  unsupported sizes (e.g. empty-core miners asking for a core point).

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
   --  Σ_{i ∈ S} x_i for coalition mask S. Bits outside X'Range ignored
   --  only if clear; any set bit with player > X'Last raises
   --  Invalid_Argument.

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
   --  Efficiency + individual rationality (an imputation).

   ---------------------------------------------------------------------------
   -- Excesses, blocking, core membership
   ---------------------------------------------------------------------------

   function Coalition_Excess
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural) return Worth
     with Global => null;
   --  e(S, x) = v(S) − Σ_{i ∈ S} x_i. Positive excess ⇒ S can improve
   --  upon x (blocks when > Tol).

   function Blocks
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural;
      Tol  : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff Coalition_Excess (S, x) > Tol (strict improvement).
   --  Empty and grand coalitions never block under the usual convention
   --  (grand excess is ≈ 0 for imputations; empty excess is −0).

   function Is_In_Core
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff X is an imputation and e(S, X) ≤ Tol for every S ⊆ N.
   --  Equivalent: Σ_{i ∈ S} x_i ≥ v(S) − Tol for all coalitions S.

   function Max_Excess
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation) return Worth
     with Global => null;
   --  max_S e(S, X) over all coalitions (including ∅ and N).

   function Worst_Coalition
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation) return Natural
     with Global => null;
   --  A mask attaining Max_Excess (smallest mask on ties).

   function Count_Blocking
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Natural
     with Global => null;
   --  Number of coalitions with excess > Tol (typically excluding the
   --  empty set when v(∅)=0; still counted if excess is positive).

   ---------------------------------------------------------------------------
   -- Special-game constructors (return 0-based Characteristic of length 2^N)
   ---------------------------------------------------------------------------

   function Make_Additive (Singleton : Allocation) return Characteristic
     with Global => null;
   --  v(S) = Σ_{i ∈ S} Singleton(i). Unique core point = Singleton when
   --  treated as the imputation (efficiency automatic).

   function Make_Gloves return Characteristic
     with Global => null;
   --  Classic 3-player left/right glove game: players 1,2 hold right
   --  gloves, player 3 a left glove. v = 1 on {1,3}, {2,3}, {1,2,3};
   --  else 0. Unique core point (0, 0, 1).

   function Make_Pair_Gloves return Characteristic
     with Global => null;
   --  Two-player Wikipedia glove knitters: v({1})=5, v({2})=5,
   --  v({1,2})=15. Core = {(x,y) | x+y=15, x≥5, y≥5}.

   function Make_Miners (N : Natural) return Characteristic
     with Global => null;
   --  v(S) = ⌊|S|/2⌋. Even N: unique core (1/2,…,1/2). Odd N: empty
   --  core. Raises Invalid_Argument when N = 0 or N > Max_N.

   function Make_Majority (N : Natural) return Characteristic
     with Global => null;
   --  Simple majority: v(S) = 1 if |S| > N/2, else 0. For odd N ≥ 3 the
   --  core is empty. Raises Invalid_Argument when N < 1 or N > Max_N.

   function Make_Unanimity (N : Natural) return Characteristic
     with Global => null;
   --  v(S) = 1 iff S = N, else 0. Core = all imputations (simplex
   --  x_i ≥ 0, Σ x_i = 1).

   function Make_Zero (N : Natural) return Characteristic
     with Global => null;
   --  Trivial zero game v ≡ 0. Core = {0}.

   ---------------------------------------------------------------------------
   -- LP-free core points for special games
   ---------------------------------------------------------------------------

   function Additive_Core_Point (Singleton : Allocation) return Allocation
     with Global => null;
   --  The unique core allocation of Make_Additive (Singleton).

   function Gloves_Core_Point return Allocation
     with Global => null;
   --  Unique core of Make_Gloves: (0, 0, 1).

   function Pair_Gloves_Core_Point
     (Share_1 : Worth := 7.5) return Allocation
     with Global => null;
   --  One core point of Make_Pair_Gloves: (Share_1, 15 − Share_1).
   --  Requires 5 ≤ Share_1 ≤ 10 (else Invalid_Argument).

   function Miners_Core_Point (N : Natural) return Allocation
     with Global => null;
   --  For even N: (1/2,…,1/2). Raises Invalid_Argument when N is odd
   --  (empty core) or N = 0 / N > Max_N.

   function Unanimity_Equal_Point (N : Natural) return Allocation
     with Global => null;
   --  Equal split (1/N,…,1/N) — always in the unanimity core.

   function Equal_Surplus_Allocation
     (N : Natural; V : Characteristic) return Allocation
     with Global => null;
   --  x_i = v({i}) + (v(N) − Σ_j v({j})) / N. Always an imputation of
   --  the 0-normalized surplus; may or may not lie in the core. Useful
   --  classroom probe — call Is_In_Core to check. Raises Invalid_Argument
   --  for bad N / V.

   --  General core membership is the primary API. Computing some / all
   --  core points for an arbitrary game requires a linear-programming
   --  solver (Bondareva–Shapley balancedness is README-level only).

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

   function Is_In_Core
     (Inst : Instance;
      X    : Allocation;
      Tol  : Worth := Default_Tol) return Boolean
     with Global => null;

   function Coalition_Excess
     (Inst : Instance;
      X    : Allocation;
      Mask : Natural) return Worth
     with Global => null;

private

   type Instance is record
      N : Player_Count := 0;
      V : Characteristic (0 .. 2**Max_N - 1) := [others => 0.0];
   end record;

end Core_Game_Theory;

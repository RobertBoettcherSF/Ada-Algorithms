--  Banzhaf_Power_Index — Ada 2023 educational package for the Banzhaf
--  power index (Penrose–Banzhaf / Banzhaf–Coleman) on weighted voting
--  games and general simple games. Players 1 .. N, cap N ≤ Max_N = 16
--  so a full 0/1 characteristic on bitmasks 0 .. 2^N − 1 and a
--  2^{N−1} swing enumeration stay classroom-feasible.
--  Reference: https://en.wikipedia.org/wiki/Banzhaf_power_index
--  Sibling sheets (README only — do not `with`): Shapley value,
--  Shapley–Shubik, Core, Nucleolus — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Banzhaf_Power_Index
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; 2^Max_N table / 2^{N−1} swings must fit)
   ---------------------------------------------------------------------------

   --  Maximum number of players. 2^16 = 65_536 coalition slots.
   --  Weighted enumeration of 2^{N−1} remains practical near N = 20;
   --  this cap keeps a dense 0/1 table in classroom memory.
   Max_N : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Player_Id is range 1 .. Max_N;
   subtype Player_Count is Natural range 0 .. Max_N;

   --  Absolute / normalized index (Long_Float for classroom precision).
   subtype Worth is Long_Float;

   --  Weighted voting game: quota q and weights w_i (player i).
   type Weight_Vector is array (Player_Id range <>) of Natural;

   --  Simple-game characteristic as a dense 0/1 table indexed by bitmask:
   --  bit (i−1) set ⇔ player i ∈ S. Length must be exactly 2^N.
   --  V(0) is the empty coalition and must be 0 (losing).
   type Characteristic is array (Natural range <>) of Natural;

   --  Raw swing counts η_i (player i is critical in that many coalitions).
   type Count_Vector is array (Player_Id range <>) of Natural;

   --  β' (absolute / Penrose–Banzhaf) or β (normalized Banzhaf).
   type Index_Vector is array (Player_Id range <>) of Worth;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for N = 0 or N > Max_N, quota = 0, weight vectors whose
   --  bounds are not 1-based or whose length is not in 1 .. Max_N,
   --  characteristic tables whose length ≠ 2^N or whose bounds are not
   --  0-based, entries outside {0,1}, a winning empty coalition,
   --  a non-monotonic simple game, null callback, player ids outside
   --  1 .. N, masks outside 0 .. 2^N − 1, Tol < 0, or a normalized /
   --  Coleman index when the relevant denominator is 0.

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

   function Factorial (K : Natural) return Worth
     with Global => null;
   --  K! as Worth. Raises Invalid_Argument when K > 20.

   function Binomial (N, K : Natural) return Natural
     with Global => null;
   --  C(N, K). K > N → 0. Raises Invalid_Argument when N > 20.

   function Coalition_Weight
     (Weights : Weight_Vector; Mask : Natural) return Long_Long_Integer
     with Global => null;
   --  Σ_{i ∈ S} w_i for the coalition encoded by Mask (bits outside
   --  Weights'Range are ignored). Requires Weights'First = 1.

   ---------------------------------------------------------------------------
   -- Game instance
   ---------------------------------------------------------------------------

   type Instance is private;

   function Weighted
     (Quota : Natural; Weights : Weight_Vector) return Instance
     with Global => null;
   --  Weighted voting game [q; w_1, …, w_n]. Requires 1 ≤ n ≤ Max_N,
   --  Weights'First = 1, Quota ≥ 1. A coalition S wins iff
   --  Σ_{i∈S} w_i ≥ q.

   function From_Characteristic
     (N : Natural; Winning : Characteristic) return Instance
     with Global => null;
   --  General simple game from a 0/1 table. Requires N in 1 .. Max_N,
   --  Winning'First = 0, Winning'Length = 2^N, every entry in {0,1},
   --  Winning(0) = 0, and monotonicity (S winning and S ⊂ T ⇒ T winning).

   function Majority (N : Natural) return Instance
     with Global => null;
   --  Equal weights 1, quota ⌊N/2⌋ + 1 (simple majority).

   function Equal_Weights
     (N : Natural; Each : Natural; Quota : Natural) return Instance
     with Global => null;
   --  n players, every weight = Each, given quota. Each may be 0
   --  (all dummies) but Quota must be ≥ 1 and N in 1 .. Max_N.

   function UN_Security_Council return Instance
     with Global => null;
   --  Classroom UNSC toy: 5 permanent members (weight 7) and 10
   --  non-permanent (weight 1), quota 39. Equivalent to “9 yes votes
   --  including all 5 veto powers.”

   function Corporate_Shareholders return Instance
     with Global => null;
   --  Classroom four-shareholder game [51; 40, 30, 20, 10]
   --  (equivalent, after scaling, to Straffin’s [6; 4, 3, 2, 1]).

   function Size (G : Instance) return Player_Count
     with Global => null;

   function Is_Weighted_Game (G : Instance) return Boolean
     with Global => null;

   function Quota_Of (G : Instance) return Natural
     with Global => null;
   --  Quota q. For a simple (table) game this is 0.

   function Weight_Of (G : Instance; I : Player_Id) return Natural
     with Global => null;
   --  w_i. For a simple (table) game this is 0. I must be in 1 .. N.

   function Weights_Of (G : Instance) return Weight_Vector
     with Global => null;
   --  Slice 1 .. N of the stored weights (zeros for a table game).

   function Characteristic_Of (G : Instance) return Characteristic
     with Global => null;
   --  Materialized 0/1 table of length 2^N (0-based).

   ---------------------------------------------------------------------------
   -- Winning / critical
   ---------------------------------------------------------------------------

   function Is_Winning (G : Instance; Mask : Natural) return Boolean
     with Global => null;
   --  True iff the coalition encoded by Mask is winning.
   --  Raises Invalid_Argument when G is empty or Mask ≥ 2^N.

   function Is_Winning
     (Quota : Natural; Weights : Weight_Vector; Mask : Natural)
      return Boolean
     with Global => null;

   function Is_Winning
     (N : Natural; Winning : Characteristic; Mask : Natural)
      return Boolean
     with Global => null;

   function Is_Critical
     (G : Instance; Mask : Natural; I : Player_Id) return Boolean
     with Global => null;
   --  True iff i ∈ S, S is winning, and S \ {i} is losing
   --  (i is a swing / critical voter in S). Raises Invalid_Argument
   --  when I is outside 1 .. N or Mask ≥ 2^N.

   function Is_Critical
     (Quota : Natural; Weights : Weight_Vector;
      Mask  : Natural; I : Player_Id) return Boolean
     with Global => null;

   function Is_Critical
     (N       : Natural;
      Winning : Characteristic;
      Mask    : Natural;
      I       : Player_Id) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Swing counts and Banzhaf indices
   ---------------------------------------------------------------------------

   function Swing_Counts (G : Instance) return Count_Vector
     with Global => null;
   --  η_i = # { S ⊆ N \ {i} : v(S) = 0 and v(S ∪ {i}) = 1 }.
   --  Returns Count_Vector (1 .. N).

   function Swing_Counts
     (Quota : Natural; Weights : Weight_Vector) return Count_Vector
     with Global => null;

   function Swing_Counts
     (N : Natural; Winning : Characteristic) return Count_Vector
     with Global => null;

   function Swing_Counts
     (N    : Natural;
      Wins : access function (Mask : Natural) return Boolean)
      return Count_Vector
     with Global => null;
   --  Callback form. Nested test functions may be passed via 'Access.

   function Total_Swings (Eta : Count_Vector) return Natural
     with Global => null;
   --  Σ_j η_j.

   function Total_Swings (G : Instance) return Natural
     with Global => null;

   function Absolute_Banzhaf (G : Instance) return Index_Vector
     with Global => null;
   --  β'_i = η_i / 2^{n−1}  (Penrose–Banzhaf). Returns 1 .. N.

   function Absolute_Banzhaf
     (Quota : Natural; Weights : Weight_Vector) return Index_Vector
     with Global => null;

   function Absolute_Banzhaf
     (N : Natural; Winning : Characteristic) return Index_Vector
     with Global => null;

   function Penrose_Banzhaf (G : Instance) return Index_Vector
     renames Absolute_Banzhaf;

   function Normalized_Banzhaf (G : Instance) return Index_Vector
     with Global => null;
   --  β_i = η_i / Σ_j η_j. Raises Invalid_Argument when Σ η = 0.

   function Normalized_Banzhaf
     (Quota : Natural; Weights : Weight_Vector) return Index_Vector
     with Global => null;

   function Normalized_Banzhaf
     (N : Natural; Winning : Characteristic) return Index_Vector
     with Global => null;

   ---------------------------------------------------------------------------
   -- Coleman / dummy / dictator / veto / symmetry
   ---------------------------------------------------------------------------

   function Winning_Count (G : Instance) return Natural
     with Global => null;
   --  Number of winning coalitions (masks in 0 .. 2^N − 1).

   function Losing_Count (G : Instance) return Natural
     with Global => null;
   --  2^N − Winning_Count.

   function Coleman_Prevent (G : Instance) return Index_Vector
     with Global => null;
   --  Coleman power to prevent action: η_i / # winning coalitions.
   --  Raises Invalid_Argument when no coalition wins.

   function Coleman_Initiate (G : Instance) return Index_Vector
     with Global => null;
   --  Coleman power to initiate action: η_i / # losing coalitions.
   --  Raises Invalid_Argument when no coalition loses.

   function Is_Dummy (G : Instance; I : Player_Id) return Boolean
     with Global => null;
   --  True iff η_i = 0 (never critical).

   function Is_Dictator (G : Instance; I : Player_Id) return Boolean
     with Global => null;
   --  True iff {i} wins (equivalently η_i = 2^{n−1} and others 0).

   function Is_Vetoer (G : Instance; I : Player_Id) return Boolean
     with Global => null;
   --  True iff N \ {i} is losing (i belongs to every winning coalition).

   function Are_Symmetric
     (G : Instance; I, J : Player_Id) return Boolean
     with Global => null;
   --  True iff I and J are interchangeable: for every S avoiding both,
   --  S ∪ {i} wins ⇔ S ∪ {j} wins.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Sum_Indices (Beta : Index_Vector) return Worth
     with Global => null;

   function Is_Normalized
     (Beta : Index_Vector; Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff Σ β ≈ 1 within Tol.

private

   type Form_Kind is (Weighted_Form, Simple_Form);

   type Weight_Store is array (Player_Id) of Natural;
   type Win_Store is array (Natural range 0 .. 2 ** Max_N - 1) of Boolean;

   type Instance is record
      N     : Player_Count := 0;
      Form  : Form_Kind    := Weighted_Form;
      Quota : Natural      := 0;
      W     : Weight_Store := [others => 0];
      Win   : Win_Store    := [others => False];
   end record;

end Banzhaf_Power_Index;

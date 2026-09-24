--  Shapley_Value — Ada 2023 educational package for the Shapley value
--  (cooperative game theory fair allocation). Players 1 .. N, cap
--  N ≤ Max_N = 12 so a full characteristic function on bitmasks
--  0 .. 2^N − 1 is feasible in classroom settings. Computes φ by the
--  classic weighted marginal-contribution sum over coalitions, with an
--  optional full permutation enumeration for small N (cross-check).
--  Reference: https://en.wikipedia.org/wiki/Shapley_value
--  Sibling sheets (README only — do not `with`): Core, Nucleolus,
--  Banzhaf power index — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Shapley_Value
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; 2^Max_N characteristic table must fit)
   ---------------------------------------------------------------------------

   --  Maximum number of players. 2^12 = 4096 coalition slots.
   Max_N : constant Positive := 12;

   --  Permutation enumeration is O(N!); safe classroom bound.
   Max_Perm_N : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Player_Id is range 1 .. Max_N;
   subtype Player_Count is Natural range 0 .. Max_N;

   --  Worth / payoff / Shapley share (Long_Float for classroom precision).
   subtype Worth is Long_Float;

   --  Characteristic function as a dense table indexed by bitmask:
   --  bit (i−1) set ⇔ player i ∈ S. Length must be exactly 2^N.
   --  V (0) is the empty coalition (conventionally 0 for TU games).
   type Characteristic is array (Natural range <>) of Worth;

   --  φ vector for players 1 .. N (caller uses slice 1 .. N).
   type Value_Vector is array (Player_Id range <>) of Worth;

   --  Callback form of v uses anonymous access parameters on Compute /
   --  Marginal / Compute_By_Permutations so nested test functions may
   --  be passed via 'Access (named access types forbid that).

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for N = 0 or N > Max_N (or > Max_Perm_N for permutation
   --  path), characteristic tables whose length ≠ 2^N or whose bounds
   --  are not 0-based, null callback, player ids outside 1 .. N,
   --  or masks that already contain the player in Marginal.

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

   function Factorial (K : Natural) return Worth
     with Global => null;
   --  K! as Worth. Raises Invalid_Argument when K! overflows Worth
   --  useful range for this package (K > 20).

   function Binomial (N, K : Natural) return Worth
     with Global => null;
   --  C(N, K) = N! / (K! (N−K)!). K > N → 0.0.

   function Shapley_Weight
     (Coalition_Size : Natural; N : Natural) return Worth
     with Global => null;
   --  |S|! (n − |S| − 1)! / n!  for a coalition S not containing i.
   --  Raises Invalid_Argument when N = 0 or Coalition_Size ≥ N.

   function Power2 (N : Natural) return Natural
     with Global => null;
   --  2^N. Raises Invalid_Argument when N > Max_N.

   ---------------------------------------------------------------------------
   -- Marginal contribution
   ---------------------------------------------------------------------------

   function Marginal
     (V      : Characteristic;
      S_Mask : Natural;
      I      : Player_Id) return Worth
     with Global => null;
   --  v(S ∪ {i}) − v(S). Requires V'First = 0, I's bit clear in S_Mask,
   --  and both masks in V'Range. Raises Invalid_Argument otherwise.

   function Marginal
     (V      : access function (Mask : Natural) return Worth;
      S_Mask : Natural;
      I      : Player_Id) return Worth
     with Global => null;
   --  Same via callback. Raises Invalid_Argument when V is null or
   --  I already belongs to S_Mask.

   ---------------------------------------------------------------------------
   -- Core solvers
   ---------------------------------------------------------------------------

   function Compute
     (N : Natural; V : Characteristic) return Value_Vector
     with Global => null;
   --  φ_i via the classic sum over S ⊆ N \ {i}. Requires V'First = 0
   --  and V'Length = 2^N. Returns Value_Vector (1 .. N). Raises
   --  Invalid_Argument for bad N or incomplete / mis-indexed V.

   function Compute
     (N : Natural;
      V : access function (Mask : Natural) return Worth) return Value_Vector
     with Global => null;
   --  Same with a callback characteristic function.

   function Values
     (N : Natural; V : Characteristic) return Value_Vector
     renames Compute;
   --  Alias for Compute (array form).

   function Compute_By_Permutations
     (N : Natural; V : Characteristic) return Value_Vector
     with Global => null;
   --  φ_i = (1/n!) Σ_π [v(P_i^π ∪ {i}) − v(P_i^π)]. O(N · N!).
   --  Requires 1 ≤ N ≤ Max_Perm_N and a valid characteristic table.
   --  Intended as a cross-check of Compute for small classroom N.

   function Compute_By_Permutations
     (N : Natural;
      V : access function (Mask : Natural) return Worth) return Value_Vector
     with Global => null;
   --  Permutation path with callback v.

   ---------------------------------------------------------------------------
   -- Efficiency / axiom helpers
   ---------------------------------------------------------------------------

   function Sum_Values (Phi : Value_Vector) return Worth
     with Global => null;
   --  Σ_i φ_i.

   function Is_Efficient
     (Phi   : Value_Vector;
      Grand : Worth;
      Tol   : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff Σ φ ≈ v(N) within Tol (efficiency axiom).

   function Is_Dummy
     (N : Natural;
      V : Characteristic;
      I : Player_Id;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff every marginal of I is ≈ 0 (null / dummy player).

   function Are_Symmetric
     (N : Natural;
      V : Characteristic;
      I, J : Player_Id;
      Tol : Worth := Default_Tol) return Boolean
     with Global => null;
   --  True iff I and J are interchangeable: for every S avoiding both,
   --  v(S∪{i}) = v(S∪{j}) within Tol.

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
   --  Set v(Mask). Raises Invalid_Argument when Mask ≥ 2^N.

   function Get_Worth (Inst : Instance; Mask : Natural) return Worth
     with Global => null;

   procedure Load (Inst : in out Instance; V : Characteristic)
     with Global => null;
   --  Infer N from V'Length = 2^N (V'First must be 0). Raises
   --  Invalid_Argument when length is not a power of two in 2^1 .. 2^Max_N
   --  (N = 0 empty table length 1 is accepted as the empty game).

   function Compute (Inst : Instance) return Value_Vector
     with Global => null;
   --  Compute φ from the stored characteristic table.

   function Compute_By_Permutations (Inst : Instance) return Value_Vector
     with Global => null;

   function Grand_Worth (Inst : Instance) return Worth
     with Global => null;
   --  v(N) = V(2^N − 1).

private

   type Instance is record
      N : Player_Count := 0;
      V : Characteristic (0 .. 2**Max_N - 1) := [others => 0.0];
   end record;

end Shapley_Value;

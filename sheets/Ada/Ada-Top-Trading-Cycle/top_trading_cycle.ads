--  Top_Trading_Cycle — Ada 2023 educational package for the Gale /
--  Shapley–Scarf Top Trading Cycle (TTC) algorithm on housing markets.
--  Agents 1 .. N each own one house (identity endowment by default, or
--  a general endowment permutation). Strict preference lists are
--  complete permutations of houses. Each round every remaining agent
--  points to the owner of their favourite remaining house; every cycle
--  in that functional graph is cleared (agents receive the pointed
--  house) until none remain. Yields the unique core allocation and is
--  strategy-proof under strict preferences. Cap N ≤ Max_N = 32.
--  Reference: https://en.wikipedia.org/wiki/Top_trading_cycle
--  Sibling sheets (README only — do not `with`): Gale–Shapley (stable
--  bipartite matching), VCG (money / quasilinear mechanisms) —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Top_Trading_Cycle
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum market size (agents and houses 1 .. N).
   Max_N : constant Positive := 32;

   --  Exhaustive core spot-check bound (2^N · N! work grows fast).
   Max_Core_Check_N : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Identifiers, preference / endowment / assignment arrays
   ---------------------------------------------------------------------------

   type Agent_Id is range 1 .. Max_N;
   subtype House_Id is Agent_Id;

   --  Prefs (Agent, Rank) = house at that rank (1 = most preferred,
   --  N = least preferred). Each row must be a permutation of 1 .. N.
   type Pref_Matrix is array (Positive range <>, Positive range <>)
     of Natural;

   --  Endowment (Agent) = house owned by Agent; must be a permutation
   --  of 1 .. N. Identity endowment means Agent I owns house I.
   type Id_Array is array (Positive range <>) of Natural;

   --  Pointing map: Point (Agent) = agent currently holding Agent's
   --  top remaining house (0 = not in the residual market).
   subtype Pointing_Array is Id_Array;

   --  Cycle buffer: Cycle (1 .. Length) lists agents on one directed
   --  cycle of a pointing map (Cycle (Length) points to Cycle (1)).
   subtype Cycle_Array is Id_Array;

   ---------------------------------------------------------------------------
   -- Solution
   ---------------------------------------------------------------------------

   --  House_Of (A) = house assigned to agent A.
   --  Agent_Of (H) = agent assigned house H (inverse of House_Of).
   --  The two arrays are mutual inverses on 1 .. N.
   type Allocation is record
      N        : Natural := 0;
      House_Of : Id_Array (1 .. Max_N) := [others => 0];
      Agent_Of : Id_Array (1 .. Max_N) := [others => 0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Size > Max_N, non-1-based / non-square Load, preference
   --  rows that are not permutations of 1 .. N, endowment arrays that
   --  are not permutations, agent / house / rank ids outside 1 .. N,
   --  core checks with N > Max_Core_Check_N, or empty pointing / cycle
   --  queries on malformed maps.

   ---------------------------------------------------------------------------
   -- Problem instance (N agents, preference lists, endowment)
   ---------------------------------------------------------------------------

   type Instance is limited private;

   procedure Clear (Inst : in out Instance; Size : Natural)
     with Global => null;
   --  Reset Inst to order n = Size with identity endowment (agent i
   --  owns house i) and identity preferences (agent i ranks house k
   --  at rank k). Size = 0 is the empty instance. Raises
   --  Invalid_Argument when Size > Max_N.

   procedure Set_Preference
     (Inst  : in out Instance;
      Agent : Agent_Id;
      Rank  : Agent_Id;
      House : House_Id)
     with Global => null;
   --  Agent's Rank-th choice becomes House (1 = most preferred).
   --  Raises Invalid_Argument when any id is outside 1 .. Size(Inst).

   procedure Set_Endowment
     (Inst  : in out Instance;
      Agent : Agent_Id;
      House : House_Id)
     with Global => null;
   --  Agent's endowed house becomes House. Full endowment must be a
   --  permutation before Solve; this setter only writes one entry.
   --  Raises Invalid_Argument when any id is outside 1 .. Size(Inst).

   procedure Load_Preferences
     (Inst : in out Instance; Prefs : Pref_Matrix)
     with Global => null;
   --  Copy Prefs as preference lists. Requires Prefs'First(1) =
   --  Prefs'First(2) = 1, square of order Size(Inst), each row a
   --  permutation of 1 .. N. Raises Invalid_Argument otherwise.
   --  Inst must already have a Size via Clear or Load.

   procedure Load_Endowment
     (Inst : in out Instance; Endow : Id_Array)
     with Global => null;
   --  Copy Endow (1 .. N) as the endowment. Requires Endow'First = 1,
   --  Endow'Length ≥ N, and Endow(1 .. N) a permutation of 1 .. N.
   --  Raises Invalid_Argument otherwise.

   procedure Load
     (Inst  : in out Instance;
      Prefs : Pref_Matrix;
      Endow : Id_Array)
     with Global => null;
   --  Clear Inst to the order of Prefs and copy preferences plus
   --  endowment. Raises Invalid_Argument when Prefs is not 1-based
   --  square ≤ Max_N, Endow is not a matching permutation, or a
   --  preference row is not a permutation.

   procedure Load_Identity_Endowment
     (Inst : in out Instance; Prefs : Pref_Matrix)
     with Global => null;
   --  Clear + Load_Preferences with identity endowment (agent i owns
   --  house i). Same Prefs shape / permutation rules as Load.

   function Size (Inst : Instance) return Natural
     with Global => null;
   --  Current order n (0 .. Max_N).

   function Preference
     (Inst : Instance; Agent, Rank : Agent_Id) return House_Id
     with Global => null;
   --  House at the given rank on Agent's list.
   --  Raises Invalid_Argument when ids are outside 1 .. N or the
   --  stored entry is not a valid house id.

   function Endowment
     (Inst : Instance; Agent : Agent_Id) return House_Id
     with Global => null;
   --  House owned by Agent under the instance endowment.
   --  Raises Invalid_Argument when Agent is outside 1 .. N or the
   --  stored entry is not a valid house id.

   function Owner_Of_House
     (Inst : Instance; House : House_Id) return Agent_Id
     with Global => null;
   --  Agent who owns House under the endowment (inverse of Endowment).
   --  Raises Invalid_Argument when House is outside 1 .. N or does not
   --  appear exactly once in the endowment.

   function Rank_Of
     (Inst : Instance; Agent : Agent_Id; House : House_Id) return Agent_Id
     with Global => null;
   --  Rank of House on Agent's list (1 = most preferred).
   --  Raises Invalid_Argument when ids are outside 1 .. N or House
   --  does not appear on the list.

   function Prefers
     (Inst                    : Instance;
      Agent                   : Agent_Id;
      Candidate, Incumbent    : House_Id) return Boolean
     with Global => null;
   --  True iff Agent strictly prefers Candidate to Incumbent.
   --  Raises Invalid_Argument when any id is outside 1 .. N or a named
   --  house is missing from Agent's list.

   function Is_Complete_Permutation
     (Prefs : Pref_Matrix; N : Natural) return Boolean
     with Global => null;
   --  True iff N = 0, or Prefs is 1-based with at least N rows and
   --  columns and each of rows 1 .. N is a permutation of 1 .. N.
   --  Does not raise.

   function Is_Permutation
     (A : Id_Array; N : Natural) return Boolean
     with Global => null;
   --  True iff A(1 .. N) is a permutation of 1 .. N (N = 0 ⇒ True).
   --  Requires A'First = 1 and A'Length ≥ N; otherwise False.

   ---------------------------------------------------------------------------
   -- Pointing graph / cycle helpers (residual market)
   ---------------------------------------------------------------------------

   procedure Compute_Pointing
     (Inst      : Instance;
      Remaining : Id_Array;
      Point     : out Pointing_Array)
     with Global => null;
   --  For each agent i with Remaining(i) ≠ 0, set Point(i) to the
   --  current owner (among remaining agents) of i's favourite house
   --  still held by a remaining agent. Remaining must be length ≥ N
   --  with Remaining'First = 1; nonzero marks agents still in the
   --  market. Point entries for non-remaining agents are 0. Uses the
   --  instance endowment as the current holding (callers that mutate
   --  holdings should use Compute_Pointing_With_Holdings). Raises
   --  Invalid_Argument when Inst prefs / endowment are invalid or
   --  Remaining shape is wrong.

   procedure Compute_Pointing_With_Holdings
     (Inst      : Instance;
      Remaining : Id_Array;
      Holding   : Id_Array;
      Point     : out Pointing_Array)
     with Global => null;
   --  Same as Compute_Pointing but Holding(Agent) is the house
   --  currently held by Agent (must be a permutation on the remaining
   --  agents' slots). Used inside Solve as cycles are cleared.

   procedure Find_Cycle
     (Point  : Pointing_Array;
      N      : Natural;
      Start  : Agent_Id;
      Cycle  : out Cycle_Array;
      Length : out Natural)
     with Global => null;
   --  Follow Point from Start until a directed cycle is closed.
   --  Writes the cycle agents into Cycle(1 .. Length) in walk order
   --  (each points to the next; Cycle(Length) points to Cycle(1)).
   --  Length = 0 if Start is outside 1 .. N, Point(Start) = 0, or no
   --  cycle is reachable from Start among nodes with nonzero Point.
   --  Requires Point'First = 1 and Point'Length ≥ N. Does not raise
   --  on missing cycles; raises Invalid_Argument when N > Max_N or
   --  Point shape is wrong.

   function Has_Cycle
     (Point : Pointing_Array; N : Natural) return Boolean
     with Global => null;
   --  True iff the functional graph Point(1 .. N) (ignoring zeros)
   --  contains at least one directed cycle. N = 0 ⇒ False.
   --  Raises Invalid_Argument when N > Max_N or Point shape is wrong.

   function Count_Cycles
     (Point : Pointing_Array; N : Natural) return Natural
     with Global => null;
   --  Number of distinct directed cycles in Point(1 .. N).
   --  Raises Invalid_Argument when N > Max_N or Point shape is wrong.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Top Trading Cycle)
   ---------------------------------------------------------------------------
   --  Residual market R ← {1 .. n}; each agent holds their endowment.
   --  While R ≠ ∅:
   --    every i ∈ R points to the owner (in R) of i's favourite house
   --    still held by someone in R;
   --    the pointing map is a functional graph, so ≥ 1 cycle exists;
   --    clear every cycle: each agent on a cycle receives the house
   --    held by the agent they point to, then leave R.
   --  Terminates in ≤ n rounds; output is the unique strict-core
   --  allocation and is strategy-proof (Roth). Contrast (README only):
   --  Gale–Shapley finds a stable bipartite matching (two-sided
   --  preferences, no endowments); VCG is a money-based efficient /
   --  strategy-proof mechanism for quasilinear preferences.

   procedure Solve (Inst : Instance; Result : out Allocation)
     with Global => null;
   --  Run TTC. Empty n = 0 yields an empty allocation. Raises
   --  Invalid_Argument when preference rows or the endowment are not
   --  permutations of 1 .. N.

   function Allocate (Inst : Instance) return Allocation
     with Global => null;
   --  Functional form of Solve.

   ---------------------------------------------------------------------------
   -- Core / structural checks
   ---------------------------------------------------------------------------

   function Is_Bijection (Result : Allocation) return Boolean
     with Global => null;
   --  True iff House_Of(1 .. N) is a permutation of 1 .. N and
   --  Agent_Of is its inverse. N = 0 ⇒ True. False (does not raise)
   --  when N > Max_N.

   function Is_Individually_Rational
     (Inst : Instance; Result : Allocation) return Boolean
     with Global => null;
   --  True iff Result.N = Size(Inst), Result is a bijection, and every
   --  agent weakly prefers their assigned house to their endowment
   --  (rank of assigned ≤ rank of endowment). Empty n = 0 is IR.
   --  Raises Invalid_Argument when Inst prefs / endowment are invalid.
   --  Returns False when Result.N disagrees or is not a bijection.

   function Is_In_Core
     (Inst : Instance; Result : Allocation) return Boolean
     with Global => null;
   --  Spot-check: True iff Result is individually rational and no
   --  nonempty coalition S can reallocate the houses endowed to S
   --  among its members so that every member of S strictly prefers
   --  the new house to Result (weak-core blocking). Requires
   --  Size(Inst) ≤ Max_Core_Check_N; raises Invalid_Argument when
   --  larger, or when Inst prefs / endowment are invalid. Empty n = 0
   --  is in the core. Returns False when Result disagrees in size or
   --  is not a bijection. With strict preferences the TTC allocation
   --  is the unique core allocation, so this check is a classroom
   --  oracle for small n.

   function House_Of
     (Result : Allocation; Agent : Agent_Id) return House_Id
     with Global => null;
   function Agent_Of
     (Result : Allocation; House : House_Id) return Agent_Id
     with Global => null;
   --  Inspect an assignment. Raises Invalid_Argument when the id is
   --  outside 1 .. Result.N or the stored mate is not a valid id.

private

   type Pref_Store is array (Agent_Id, Agent_Id) of Natural;
   type Own_Store is array (Agent_Id) of Natural;

   type Instance is limited record
      N     : Natural := 0;
      Prefs : Pref_Store := [others => [others => 0]];
      Endow : Own_Store := [others => 0];
   end record;

end Top_Trading_Cycle;

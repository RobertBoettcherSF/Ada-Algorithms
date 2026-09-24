--  Gale_Shapley_Algorithm — Ada 2023 educational package for the
--  Gale–Shapley deferred-acceptance algorithm (stable marriage /
--  stable matching). Equal-sized bipartite sets of proposers and
--  receivers, indices 1 .. N. Each participant supplies a complete
--  preference permutation of the other side. Deferred acceptance
--  yields a stable matching that is proposer-optimal (and
--  receiver-pessimal). Receiver-proposing is the dual: pass
--  Who_Proposes => Receivers, or swap the two preference matrices.
--  Cap N ≤ Max_N. Fixed arrays; no dynamic heap.
--  Reference: https://en.wikipedia.org/wiki/Gale–Shapley_algorithm
--  Sibling sheets (README only — do not `with`): Hopcroft–Karp
--  (cardinality bipartite matching), Hungarian (weighted assignment),
--  Blossom / Edmonds (general matching) — RobertBoettcherSF Ada
--  algorithm series.

pragma Ada_2022;

package Gale_Shapley_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum order n (proposers 1 .. N and receivers 1 .. N).
   Max_N : constant Positive := 128;

   ---------------------------------------------------------------------------
   -- Identifiers, preference matrices, matching arrays
   ---------------------------------------------------------------------------

   type Person_Id is range 1 .. Max_N;

   --  Prefs (Person, Rank) = partner at that rank (1 = most preferred,
   --  N = least preferred). Each row must be a permutation of 1 .. N.
   type Pref_Matrix is array (Positive range <>, Positive range <>)
     of Natural;

   --  Mate (I) = partner of person I; unused / unmatched slots hold 0.
   type Mate_Array is array (Positive range <>) of Natural;

   --  Which side makes proposals. Proposers (default) yields the
   --  proposer-optimal / receiver-pessimal stable matching; Receivers
   --  is the dual (receiver-optimal / proposer-pessimal).
   type Side is (Proposers, Receivers);

   ---------------------------------------------------------------------------
   -- Solution
   ---------------------------------------------------------------------------

   --  Proposer_Mate (P) = receiver matched to proposer P.
   --  Receiver_Mate (R) = proposer matched to receiver R.
   --  The two arrays are mutual inverses on 1 .. N.
   type Matching is record
      N             : Natural := 0;
      Proposer_Mate : Mate_Array (1 .. Max_N) := [others => 0];
      Receiver_Mate : Mate_Array (1 .. Max_N) := [others => 0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Size > Max_N, non-square / non-1-based Load, preference
   --  rows that are not permutations of 1 .. N (duplicates, zeros,
   --  incomplete, out of range), person / rank ids outside 1 .. N, or
   --  rank lookup of a partner that is not on the person's list.

   ---------------------------------------------------------------------------
   -- Problem instance (two N×N complete preference lists)
   ---------------------------------------------------------------------------

   type Instance is limited private;

   procedure Clear (Inst : in out Instance; Size : Natural)
     with Global => null;
   --  Reset Inst to order n = Size with identity preferences on both
   --  sides (person I ranks partner K at rank K). Size = 0 is the empty
   --  instance. Raises Invalid_Argument when Size > Max_N.

   procedure Set_Proposer_Choice
     (Inst     : in out Instance;
      Proposer : Person_Id;
      Rank     : Person_Id;
      Receiver : Person_Id)
     with Global => null;
   --  Proposer's Rank-th choice becomes Receiver (1 = most preferred).
   --  Raises Invalid_Argument when any id is outside 1 .. Size(Inst).

   procedure Set_Receiver_Choice
     (Inst     : in out Instance;
      Receiver : Person_Id;
      Rank     : Person_Id;
      Proposer : Person_Id)
     with Global => null;
   --  Receiver's Rank-th choice becomes Proposer (1 = most preferred).
   --  Raises Invalid_Argument when any id is outside 1 .. Size(Inst).

   procedure Load_Proposer_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix)
     with Global => null;
   --  Copy Prefs as proposer lists. Requires Prefs'First(1) =
   --  Prefs'First(2) = 1, square of order Size(Inst), each row a
   --  permutation of 1 .. N. Raises Invalid_Argument otherwise.
   --  Inst must already have been given a Size via Clear or Load.

   procedure Load_Receiver_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix)
     with Global => null;
   --  Copy Prefs as receiver lists. Same shape / permutation rules as
   --  Load_Proposer_Prefs.

   procedure Load
     (Inst                      : in out Instance;
      Proposer_Prefs            : Pref_Matrix;
      Receiver_Prefs            : Pref_Matrix)
     with Global => null;
   --  Clear Inst to the common order of the two 1-based square
   --  matrices and copy both sides. Raises Invalid_Argument when the
   --  matrices disagree in shape, exceed Max_N, are not 1-based, or
   --  contain a non-permutation row.

   function Size (Inst : Instance) return Natural
     with Global => null;
   --  Current order n (0 .. Max_N).

   function Proposer_Choice
     (Inst : Instance; Proposer, Rank : Person_Id) return Person_Id
     with Global => null;
   --  Receiver at the given rank on the proposer's list.
   --  Raises Invalid_Argument when the ids are outside 1 .. N or the
   --  stored entry is not a valid person id.

   function Receiver_Choice
     (Inst : Instance; Receiver, Rank : Person_Id) return Person_Id
     with Global => null;
   --  Proposer at the given rank on the receiver's list.
   --  Raises Invalid_Argument when the ids are outside 1 .. N or the
   --  stored entry is not a valid person id.

   ---------------------------------------------------------------------------
   -- Rank lookup and preference tests
   ---------------------------------------------------------------------------

   function Proposer_Rank
     (Inst : Instance; Proposer, Receiver : Person_Id) return Person_Id
     with Global => null;
   --  Rank of Receiver on Proposer's list (1 = most preferred).
   --  Raises Invalid_Argument when ids are outside 1 .. N or Receiver
   --  does not appear on the list.

   function Receiver_Rank
     (Inst : Instance; Receiver, Proposer : Person_Id) return Person_Id
     with Global => null;
   --  Rank of Proposer on Receiver's list (1 = most preferred).
   --  Raises Invalid_Argument when ids are outside 1 .. N or Proposer
   --  does not appear on the list.

   function Prefers
     (Inst                          : Instance;
      Who                           : Side;
      Person, Candidate, Incumbent  : Person_Id) return Boolean
     with Global => null;
   --  True iff Person (on side Who) strictly prefers Candidate to
   --  Incumbent. Raises Invalid_Argument when any id is outside 1 .. N
   --  or a named partner is missing from Person's list.

   function Is_Complete_Permutation
     (Prefs : Pref_Matrix; N : Natural) return Boolean
     with Global => null;
   --  True iff N = 0, or Prefs is 1-based with at least N rows and
   --  columns and each of rows 1 .. N is a permutation of 1 .. N.
   --  Does not raise.

   function Is_Permutation
     (A : Mate_Array; N : Natural) return Boolean
     with Global => null;
   --  True iff A(1 .. N) is a permutation of 1 .. N (N = 0 ⇒ True).
   --  Requires A'First = 1 and A'Length ≥ N; otherwise False.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Gale–Shapley deferred acceptance)
   ---------------------------------------------------------------------------
   --  All proposers start free. While a free proposer P remains, P
   --  proposes to the next receiver R on P's list. If R is free, R
   --  tentatively accepts. If R is engaged to Q and prefers P to Q,
   --  R switches (Q becomes free). Otherwise R rejects P. Each
   --  proposer walks their list at most once, so at most n² proposals
   --  occur. The algorithm terminates with a perfect matching that is
   --  stable, proposer-optimal, and receiver-pessimal among all
   --  stable matchings. The matching is independent of the order in
   --  which free proposers are selected. Contrast (README only):
   --  Hopcroft–Karp maximises cardinality (unweighted); Hungarian
   --  optimises edge weights under a perfect matching; Blossom /
   --  Edmonds handles general (non-bipartite) graphs.

   procedure Solve (Inst : Instance; Result : out Matching)
     with Global => null;
   --  Proposer-optimal deferred acceptance (Who_Proposes = Proposers).
   --  Empty n = 0 yields an empty matching. Raises Invalid_Argument
   --  when either side's lists are not complete permutations of 1 .. N.

   procedure Solve
     (Inst : Instance; Result : out Matching; Who_Proposes : Side)
     with Global => null;
   --  Deferred acceptance with the named side proposing. Receivers
   --  yields the receiver-optimal (proposer-pessimal) stable matching.

   function Match
     (Inst : Instance; Who_Proposes : Side := Proposers) return Matching
     with Global => null;
   --  Functional form of Solve.

   ---------------------------------------------------------------------------
   -- Stability and structural checks
   ---------------------------------------------------------------------------

   function Is_Bijection (Result : Matching) return Boolean
     with Global => null;
   --  True iff Proposer_Mate(1 .. N) is a permutation of 1 .. N and
   --  Receiver_Mate is its inverse. N = 0 ⇒ True. False (does not
   --  raise) when N > Max_N.

   function Is_Stable
     (Inst : Instance; Result : Matching) return Boolean
     with Global => null;
   --  True iff Result.N = Size(Inst), Result is a bijection, and no
   --  blocking pair exists: there is no proposer P and receiver R who
   --  both strictly prefer each other to their assigned partners.
   --  Empty n = 0 is stable. Raises Invalid_Argument when Inst's
   --  preference lists are not complete permutations. Returns False
   --  (does not raise) when Result.N disagrees with Size(Inst) or the
   --  matching is not a bijection.

   function Receiver_Of
     (Result : Matching; Proposer : Person_Id) return Person_Id
     with Global => null;
   function Proposer_Of
     (Result : Matching; Receiver : Person_Id) return Person_Id
     with Global => null;
   --  Inspect a mate. Raises Invalid_Argument when the id is outside
   --  1 .. Result.N or the stored mate is not a valid person id.

private

   type Pref_Store is array (Person_Id, Person_Id) of Natural;

   type Instance is limited record
      N     : Natural := 0;
      P_List : Pref_Store := [others => [others => 0]];
      R_List : Pref_Store := [others => [others => 0]];
   end record;

end Gale_Shapley_Algorithm;

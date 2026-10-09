pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Lemke-Howson: one Nash equilibrium of a two-player game with integer
--  payoffs, by complementary pivoting on the two best-response polytopes
--  P = {x >= 0 : B'^T x <= 1} and Q = {y >= 0 : A' y <= 1}, where A', B'
--  are the payoffs shifted to be at least 1 (a shift does not change best
--  responses).  Labels: 1 .. M are player 1's strategies, M + 1 .. M + N
--  player 2's.  Initial_Drop is the label dropped first; different labels
--  can lead to different equilibria.
--
--  Arithmetic is exact: the tableaux hold Big_Integer entries and are
--  pivoted by integer (fraction-free) pivoting, where each new entry is
--  (pivot * entry - column * row) / previous pivot and the division is
--  exact.  Nothing can overflow, whatever the Integer payoffs.
--  Degenerate games (several best responses, ties in the ratio test) are
--  handled by the lexicographic ratio test, which never revisits a basis.
--
--  The result is certified: Found is the exact check Is_Nash below (both
--  mixed strategies are probability vectors, and every strategy played
--  with positive probability is a best response to the other player's
--  strategy), and the postcondition proves that.  That Found is always
--  True (the path ends at an equilibrium within Max_Steps) is the theorem
--  of Lemke and Howson with lexicographic pivoting; it is tested, not
--  proved (tools/vv/handover.csv).
package Lemke_Howson with SPARK_Mode => On is

   Max_Strategies : constant := 5;
   subtype Strategy_Count is Positive range 1 .. Max_Strategies;
   subtype Label_Type is Positive range 1 .. 2 * Max_Strategies;

   type Payoff_Matrix is array (Strategy_Count range <>, Strategy_Count range <>) of Integer;
   type Big_Vector is array (Strategy_Count range <>) of Big_Integer;

   --  Mixed strategies as exact fractions: x (I) = X (I) / Dx and
   --  y (J) = Y (J) / Dy.
   type Exact_Equilibrium (M, N : Strategy_Count) is record
      Found : Boolean;
      X     : Big_Vector (1 .. M);
      Dx    : Big_Integer;
      Y     : Big_Vector (1 .. N);
      Dy    : Big_Integer;
   end record;

   --  V (V'First) + .. + V (K).
   function Sum_To (V : Big_Vector; K : Natural) return Big_Integer is
     (if K < V'First then To_Big_Integer (0) else Sum_To (V, K - 1) + V (K))
   with Pre => K <= V'Last, Subprogram_Variant => (Decreases => K);

   function Is_Mixed (V : Big_Vector; D : Big_Integer) return Boolean is
     (D > 0 and then (for all I in V'Range => V (I) >= 0) and then Sum_To (V, V'Last) = D);

   --  Player 1's payoff for row I against Y (times Dy):
   --  A (I, 1) * Y (1) + .. + A (I, K) * Y (K).
   function Row_Payoff (A : Payoff_Matrix; Y : Big_Vector; I : Strategy_Count; K : Natural) return Big_Integer is
     (if K < 1 then To_Big_Integer (0)
      else Row_Payoff (A, Y, I, K - 1) + To_Big_Integer (A (I, K)) * Y (K))
   with Pre => I in A'Range (1) and then K <= A'Last (2) and then A'First (2) = 1
               and then Y'First = 1 and then Y'Last = A'Last (2),
        Subprogram_Variant => (Decreases => K);

   --  Player 2's payoff for column J against X (times Dx).
   function Col_Payoff (B : Payoff_Matrix; X : Big_Vector; J : Strategy_Count; K : Natural) return Big_Integer is
     (if K < 1 then To_Big_Integer (0)
      else Col_Payoff (B, X, J, K - 1) + To_Big_Integer (B (K, J)) * X (K))
   with Pre => J in B'Range (2) and then K <= B'Last (1) and then B'First (1) = 1
               and then X'First = 1 and then X'Last = B'Last (1),
        Subprogram_Variant => (Decreases => K);

   --  Strategies are numbered from 1 because the labels 1 .. M + N are
   --  built from the strategy numbers.
   function Same_Shape (A, B : Payoff_Matrix) return Boolean is
     (A'First (1) = 1 and then A'First (2) = 1 and then B'First (1) = 1 and then B'First (2) = 1
      and then B'Last (1) = A'Last (1) and then B'Last (2) = A'Last (2));

   --  (X / Dx, Y / Dy) is a Nash equilibrium of (A, B): both are mixed
   --  strategies and every strategy in a support is a best response.
   function Is_Nash (A, B : Payoff_Matrix; X : Big_Vector; Dx : Big_Integer; Y : Big_Vector; Dy : Big_Integer)
     return Boolean is
     (Is_Mixed (X, Dx) and then Is_Mixed (Y, Dy)
      and then (for all I in 1 .. A'Last (1) =>
                  (if X (I) > 0 then
                     (for all K in 1 .. A'Last (1) =>
                        Row_Payoff (A, Y, I, A'Last (2)) >= Row_Payoff (A, Y, K, A'Last (2)))))
      and then (for all J in 1 .. A'Last (2) =>
                  (if Y (J) > 0 then
                     (for all K in 1 .. A'Last (2) =>
                        Col_Payoff (B, X, J, A'Last (1)) >= Col_Payoff (B, X, K, A'Last (1))))))
   with Pre => Same_Shape (A, B) and then X'First = 1 and then X'Last = A'Last (1)
               and then Y'First = 1 and then Y'Last = A'Last (2);

   function Find_Equilibrium
     (A, B         : Payoff_Matrix;
      Initial_Drop : Label_Type := 1) return Exact_Equilibrium
   with
     Global => null,
     Pre    => Same_Shape (A, B) and then Initial_Drop <= A'Last (1) + A'Last (2),
     Post   => Find_Equilibrium'Result.M = A'Last (1) and then Find_Equilibrium'Result.N = A'Last (2)
               and then Find_Equilibrium'Result.Found
                        = Is_Nash (A, B, Find_Equilibrium'Result.X, Find_Equilibrium'Result.Dx,
                                   Find_Equilibrium'Result.Y, Find_Equilibrium'Result.Dy);

end Lemke_Howson;

--  Fibonacci_Search body — SPARK Level 4 Lourakis / Wikipedia Fibonacci
--  search. Uses a precomputed F_0 .. F_11 table (F_11 = 89 ≥ Max_N) and
--  shrinks a table index rather than recomputing the triple with subtraction,
--  so Level-4 SMT can discharge bounds without Fibonacci lemmas. Bounded
--  for-loops make termination immediate for the prover.

package body Fibonacci_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Precomputed Fibonacci numbers F_0 .. F_11 (F_11 = 89 ≥ Max_N = 64)
   ---------------------------------------------------------------------------

   subtype Fib_Ix is Natural range 0 .. 11;
   type Fib_Table is array (Fib_Ix) of Fib_Nat;

   Fib_Top : constant := 89;  --  F (11)

   Fibs : constant Fib_Table :=
     [0 => 0, 1 => 1, 2 => 1, 3 => 2, 4 => 3, 5 => 5,
      6 => 8, 7 => 13, 8 => 21, 9 => 34, 10 => 55, 11 => Fib_Top];

   --  Fibs (11) must reach Max_N so the M search below always stops. Both
   --  sides are static, so this is checked when the unit is compiled
   --  rather than by a run-time assertion that can never fail.
   pragma Compile_Time_Error
     (Fib_Top < Max_N, "Fibs (11) must be >= Max_N: extend Fibs");

   ---------------------------------------------------------------------------
   -- Safe min for 1-based probe index
   ---------------------------------------------------------------------------

   function Min_Index (X, Y : Ext_Index) return Ext_Index
     with
       Global => null,
       Post   =>
         Min_Index'Result <= X
         and then Min_Index'Result <= Y
         and then (Min_Index'Result = X or else Min_Index'Result = Y)
   is
   begin
      if X <= Y then
         return X;
      else
         return Y;
      end if;
   end Min_Index;

   ---------------------------------------------------------------------------
   -- Public Find
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
      N      : constant Index := A'Length;
      M      : Fib_Ix;
      Offset : Ext_Index;
      Probe  : Ext_Index;
      Cand   : Ext_Index;
      Step   : Fib_Nat;
   begin
      if N = 0 then
         return 0;
      end if;

      --  Smallest M in 2 .. 11 with Fibs(M) ≥ N.
      --  Lourakis starts at (F_2, F_1, F_0) = (1, 1, 0) so M ≥ 2.
      M := 2;
      for I in Fib_Ix range 2 .. 11 loop
         pragma Loop_Invariant (M in 2 .. I);
         pragma Loop_Invariant (M >= 2);
         pragma Loop_Invariant
           (for all J in Fib_Ix range 2 .. M - 1 => Fibs (J) < N);
         M := I;
         exit when Fibs (I) >= N;
      end loop;

      pragma Assert (M >= 2);
      pragma Assert (Fibs (M) >= N);

      --  Eliminated-front offset in 1-based logical positions (0 = nothing
      --  eliminated). Logical position P lives at A (A'First + (P - 1)),
      --  so A may start at any origin.
      Offset := 0;

      --  Main search while Fibs(M) > 1, i.e. M > 2. At most 11 shrinks.
      for Guard in 1 .. 11 loop
         pragma Loop_Invariant (M >= 1);
         pragma Loop_Invariant (Offset <= N);
         pragma Loop_Invariant (N >= 1);
         pragma Loop_Invariant (N = A'Length);
         exit when M <= 2;

         --  M ≥ 3 ⇒ M - 2 ≥ 1 and Fibs(M - 2) ≥ 1.
         pragma Assert (M >= 3);
         Step := Fibs (M - 2);
         pragma Assert (Step >= 1);

         --  i = min(offset + F_{M-2}, n) in 1-based indexing.
         if Natural (Offset) <= Max_N + 1 - Natural (Step) then
            Cand := Offset + Ext_Index (Step);
         else
            Cand := Max_N + 1;
         end if;
         Probe := Min_Index (Cand, Ext_Index (N));
         pragma Assert (Probe >= 1);
         pragma Assert (Probe <= N);
         pragma Assert (A'First + (Probe - 1) in A'Range);

         if A (A'First + (Probe - 1)) < Key then
            --  Discard logical positions 1 .. Probe; reduce Fibonacci index by one.
            M      := M - 1;
            Offset := Probe;
         elsif A (A'First + (Probe - 1)) > Key then
            --  Discard logical positions Probe .. N; reduce Fibonacci index by two.
            M := M - 2;
         else
            return Index (A'First + (Probe - 1));
         end if;
      end loop;

      --  One candidate may remain when F_{M-1} ≠ 0 (M = 2 ⇒ F_1 = 1).
      --  After a two-step shrink from M = 3, M = 1 and F_0 = 0 ⇒ skip.
      if M >= 1
        and then Fibs (M - 1) /= 0
        and then Offset < N
      then
         Cand := Offset + 1;
         pragma Assert (Cand >= 1);
         pragma Assert (Cand <= N);
         pragma Assert (A'First + (Cand - 1) in A'Range);
         if A (A'First + (Cand - 1)) = Key then
            return Index (A'First + (Cand - 1));
         end if;
      end if;

      return 0;
   end Find;

end Fibonacci_Search;

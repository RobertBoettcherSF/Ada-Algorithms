--  Jump_Search body — SPARK Level 4 jump / block search with optional Step,
--  overflow-safe jump arithmetic, and bounded for-loops for termination.

package body Jump_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Integer floor square root for N ≤ Max_N (result ≤ 8)
   ---------------------------------------------------------------------------

   function Floor_Sqrt (N : Natural) return Natural
     with
       Global => null,
       Pre    => N <= Max_N,
       Post   =>
         Floor_Sqrt'Result <= 8
         and then Floor_Sqrt'Result * Floor_Sqrt'Result <= N
         and then (if Floor_Sqrt'Result < 8 then
                     (Floor_Sqrt'Result + 1) * (Floor_Sqrt'Result + 1) > N)
         and then (if N = 0 then Floor_Sqrt'Result = 0)
         and then (if N >= 1 then Floor_Sqrt'Result >= 1)
   is
      --  8² = 64 = Max_N; search descending so the first hit is ⌊√N⌋.
   begin
      for R in reverse Natural range 0 .. 8 loop
         if R * R <= N then
            return R;
         end if;
      end loop;
      return 0;
   end Floor_Sqrt;

   ---------------------------------------------------------------------------
   -- Overflow-safe advance: min(Curr + Step, Max_N + 1)
   ---------------------------------------------------------------------------

   function Advance (Curr : Ext_Index; Step : Positive) return Ext_Index
     with
       Global => null,
       Post   =>
         Advance'Result >= Curr
         and then Advance'Result <= Max_N + 1
         and then (if Natural (Step) >= (Max_N + 1) - Natural (Curr) then
                     Advance'Result = Max_N + 1
                   else
                     Advance'Result = Curr + Step)
   is
      Room : constant Natural := (Max_N + 1) - Natural (Curr);
   begin
      if Natural (Step) >= Room then
         return Max_N + 1;
      else
         return Curr + Step;
      end if;
   end Advance;

   ---------------------------------------------------------------------------
   -- Core search with an explicit positive step size
   ---------------------------------------------------------------------------

   function Find_With_Step
     (A    : Element_Array;
      Key  : Integer;
      Step : Positive) return Index
     with
       Global => null,
       Pre    => In_Bounds (A) and then Is_Sorted (A),
       Post   =>
         (if Find_With_Step'Result > 0 then
            Find_With_Step'Result in A'Range
            and then A (Find_With_Step'Result) = Key)
   is
      N     : constant Index := A'Length;
      Prev  : Ext_Index;
      Curr  : Ext_Index;
      Probe : Index;
      Idx   : Ext_Index;
      Bound : Index;
   begin
      if N = 0 then
         return 0;
      end if;

      --  Cursors walk logical positions: 0-based block cursors, 1-based
      --  probe position min(Curr, N). Logical position P lives at
      --  A (A'First + (P - 1)), so A may start at any origin.
      Prev := 0;
      Curr := Ext_Index (if Natural (Step) >= Max_N + 1 then Max_N + 1
                         else Natural (Step));

      --  Jump phase: at most Max_N + 1 advances.
      for Guard in 1 .. Max_N + 1 loop
         --  Prev, Curr <= Max_N + 1 is the range of Ext_Index itself, so
         --  it is not restated here (GNAT 12 -gnatwc: always True).
         pragma Loop_Invariant (Curr >= 1);
         pragma Loop_Invariant (Prev <= Curr);
         pragma Loop_Invariant (N >= 1);
         pragma Loop_Invariant (N = A'Length);

         --  1-based probe at min(Curr, N); Curr ≥ 1 so probe ∈ 1 .. N.
         if Curr < N then
            Probe := Index (Curr);
         else
            Probe := N;
         end if;
         pragma Assert (Probe in 1 .. N);
         pragma Assert (A'First + (Probe - 1) in A'Range);

         exit when not (A (A'First + (Probe - 1)) < Key);

         Prev := Curr;
         Curr := Advance (Curr, Step);

         if Prev >= N then
            return 0;
         end if;
      end loop;

      --  Linear scan of [Prev + 1, min(Curr, N)].
      if Curr <= N then
         Bound := Index (Curr);
      else
         Bound := N;
      end if;

      if Prev >= Bound then
         return 0;
      end if;

      Idx := Prev + 1;
      pragma Assert (Idx >= 1);
      pragma Assert (Idx <= Bound);

      for Guard in 1 .. Max_N loop
         pragma Loop_Invariant (Idx >= 1);
         pragma Loop_Invariant (Idx <= Bound + 1);
         pragma Loop_Invariant (Bound <= N);
         pragma Loop_Invariant (Bound >= 1);
         pragma Loop_Invariant (N = A'Length);
         exit when Idx > Bound;

         pragma Assert (A'First + (Idx - 1) in A'Range);

         if A (A'First + (Idx - 1)) = Key then
            return Index (A'First + (Idx - 1));
         elsif A (A'First + (Idx - 1)) > Key then
            return 0;
         end if;

         Idx := Idx + 1;
      end loop;

      return 0;
   end Find_With_Step;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
      N    : constant Index := A'Length;
      Step : Natural;
   begin
      if N = 0 then
         return 0;
      end if;

      Step := Floor_Sqrt (N);
      --  N ≥ 1 ⇒ Floor_Sqrt (N) ≥ 1.
      pragma Assert (Step >= 1);
      return Find_With_Step (A, Key, Positive (Step));
   end Find;

   function Find
     (A    : Element_Array;
      Key  : Integer;
      Step : Positive) return Index
   is
   begin
      return Find_With_Step (A, Key, Step);
   end Find;

end Jump_Search;

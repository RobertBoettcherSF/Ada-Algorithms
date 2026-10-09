--  Ternary_Search body — SPARK Level 4 discrete unimodal peak finding and
--  optional ternary key search on a sorted ascending array. Overflow-safe
--  thirds-points; bounded for-loops so termination is immediate for the
--  prover.

package body Ternary_Search
  with SPARK_Mode => On
is

   --  When Hi - Lo <= Threshold, finish with a linear scan (avoids
   --  degenerate m1/m2 collisions on tiny windows).
   Threshold : constant Natural := 2;

   ---------------------------------------------------------------------------
   -- Primary: Find_Maximum_Index
   ---------------------------------------------------------------------------

   function Find_Maximum_Counted (A : Element_Array) return Max_Result is
      Lo, Hi   : Ext_Index;
      M1, M2   : Ext_Index;
      V1, V2   : Integer;
      Rise     : Integer;   --  A (M1 + 1), read only when V1 = V2
      Fall     : Integer;   --  A (M2 - 1), read only when V1 = V2
      Best     : Index;
      Best_Val : Integer;
      Span     : Natural;
      Probes   : Natural := 0;
   begin
      if A'Length = 1 then
         return (Index_Of_Max => A'First, Probes => 0);
      end if;

      Lo := A'First;
      Hi := A'Last;

      --  At most Max_N iterations; each step shrinks the window.
      for Guard in 1 .. Max_N loop
         pragma Loop_Invariant (Lo >= A'First);
         pragma Loop_Invariant (Hi <= A'Last);
         pragma Loop_Invariant (Lo <= Hi);
         pragma Loop_Invariant (Hi - Lo <= A'Last - A'First);
         pragma Loop_Invariant (Probes <= 4 * (Guard - 1));
         exit when Hi - Lo <= Threshold;

         Span := Hi - Lo;
         M1 := Lo + Span / 3;
         M2 := Hi - Span / 3;
         pragma Assert (M1 in Lo .. Hi);
         pragma Assert (M2 in Lo .. Hi);
         pragma Assert (M1 <= M2);

         V1 := A (M1);
         V2 := A (M2);
         Probes := Probes + 2;
         if V1 < V2 then
            --  Peak cannot lie at or left of M1 on a unimodal array.
            Lo := M1 + 1;
         elsif V1 > V2 then
            --  Peak cannot lie at or right of M2.
            Hi := M2 - 1;
         else
            --  Equal. Look one step inside [M1, M2]: if A still rises after
            --  M1, a maximum lies right of M1; if A still falls before M2,
            --  a maximum lies left of M2 (both follow from unimodality).
            --  On a strictly unimodal array both hold, so the window
            --  shrinks to (M1, M2) and the search stays O(log n). Only a
            --  true plateau (neither holds: 0 0 0 0 0 0 0 1 vs 1 0 0 0 0 0
            --  0 0) leaves no comparison that can narrow the window; then
            --  the scan of [Lo, Hi] below runs, O(n) on such inputs.
            --  Span >= 3 gives M1 + 1 <= Hi and M2 - 1 >= Lo; when
            --  M2 = M1 + 1, Rise is A (M2) = V1, so both cannot fire and
            --  Lo <= Hi is kept.
            Rise := A (M1 + 1);
            Fall := A (M2 - 1);
            Probes := Probes + 2;
            if Rise <= V1 and then Fall <= V2 then
               exit;
            end if;
            if Rise > V1 then
               Lo := M1 + 1;
            end if;
            if Fall > V2 then
               Hi := M2 - 1;
            end if;
         end if;
      end loop;

      Best := Lo;
      Best_Val := A (Lo);
      Probes := Probes + 1;
      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Best in Lo .. I - 1);
         pragma Loop_Invariant (Best in A'Range);
         pragma Loop_Invariant (Best_Val = A (Best));
         pragma Loop_Invariant (Probes <= 4 * Max_N + 1 + (I - Lo - 1));
         Probes := Probes + 1;
         if A (I) > Best_Val then
            Best := I;
            Best_Val := A (I);
         end if;
      end loop;
      return (Index_Of_Max => Best, Probes => Probes);
   end Find_Maximum_Counted;

   ---------------------------------------------------------------------------
   -- Secondary: Find (sorted key search)
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
      Lo, Hi : Ext_Index;
      M1, M2 : Ext_Index;
      Span   : Natural;
   begin
      if A'Length = 0 then
         return 0;
      end if;

      Lo := A'First;
      Hi := A'Last;

      --  At most Max_N+1 iterations; ternary search needs ≤ log_{3/2}(N)+O(1).
      for Guard in 1 .. Max_N + 1 loop
         pragma Loop_Invariant (Lo >= A'First);
         pragma Loop_Invariant (Hi <= A'Last);
         pragma Loop_Invariant (Lo <= Hi + 1);
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) < Key);
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) > Key);
         exit when Lo > Hi;

         Span := Hi - Lo;
         M1 := Lo + Span / 3;
         M2 := Hi - Span / 3;
         pragma Assert (M1 in Lo .. Hi);
         pragma Assert (M2 in Lo .. Hi);
         pragma Assert (M1 <= M2);

         if A (M1) = Key then
            return M1;
         end if;
         if M2 /= M1 and then A (M2) = Key then
            return M2;
         end if;

         if Key < A (M1) then
            Hi := M1 - 1;
         elsif Key > A (M2) then
            Lo := M2 + 1;
         else
            --  Key is strictly between A(M1) and A(M2).
            Lo := M1 + 1;
            Hi := M2 - 1;
         end if;
      end loop;

      return 0;
   end Find;

end Ternary_Search;

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

   function Find_Maximum_Index (A : Element_Array) return Index is
      Lo, Hi : Ext_Index;
      M1, M2 : Ext_Index;
      Best   : Index;
      Span   : Natural;
   begin
      if A'Length = 1 then
         return A'First;
      end if;

      Lo := A'First;
      Hi := A'Last;

      --  At most Max_N iterations; each step shrinks the window.
      for Guard in 1 .. Max_N loop
         pragma Loop_Invariant (Lo >= A'First);
         pragma Loop_Invariant (Hi <= A'Last);
         pragma Loop_Invariant (Lo <= Hi);
         pragma Loop_Invariant (Hi - Lo <= A'Last - A'First);
         exit when Hi - Lo <= Threshold;

         Span := Hi - Lo;
         M1 := Lo + Span / 3;
         M2 := Hi - Span / 3;
         pragma Assert (M1 in Lo .. Hi);
         pragma Assert (M2 in Lo .. Hi);
         pragma Assert (M1 <= M2);

         if A (M1) < A (M2) then
            --  Peak cannot lie at or left of M1 on a unimodal array.
            Lo := M1 + 1;
         elsif A (M1) > A (M2) then
            --  Peak cannot lie at or right of M2.
            Hi := M2 - 1;
         else
            --  Equal: for (non-)strict unimodal, a maximum lies in [M1, M2].
            Lo := M1;
            Hi := M2;
         end if;
      end loop;

      Best := Lo;
      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (Best in Lo .. I - 1);
         pragma Loop_Invariant (Best in A'Range);
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Find_Maximum_Index;

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
         pragma Loop_Invariant (Lo >= 1);
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

--  Binary_Search body — SPARK Level 4 classic iterative binary search with
--  overflow-safe midpoint, plus leftmost / rightmost duplicate-key variants.
--  Loops are bounded `for` loops so termination is immediate for the prover.

package body Binary_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Classic iterative Find (Wikipedia "Procedure")
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
      Lo  : Ext_Index;
      Hi  : Ext_Index;
      Mid : Ext_Index;
   begin
      if A'Length = 0 then
         return 0;
      end if;

      Lo := A'First;
      Hi := A'Last;

      --  At most Max_N+1 iterations; binary search needs ≤ log2(N)+1.
      for Guard in 1 .. Max_N + 1 loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= A'Last);
         pragma Loop_Invariant (Lo <= Hi + 1);
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) < Key);
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) > Key);
         exit when Lo > Hi;

         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid in Lo .. Hi);
         pragma Assert (Mid in A'Range);

         if A (Mid) < Key then
            Lo := Mid + 1;
         elsif A (Mid) > Key then
            Hi := Mid - 1;
         else
            return Mid;
         end if;
      end loop;

      return 0;
   end Find;

   ---------------------------------------------------------------------------
   -- Leftmost (Find_First) — Wikipedia lower-bound style on [L, R)
   ---------------------------------------------------------------------------

   function Find_First (A : Element_Array; Key : Integer) return Index is
      Lo  : Ext_Index;
      Hi  : Ext_Index;
      Mid : Ext_Index;
   begin
      if A'Length = 0 then
         return 0;
      end if;

      --  Half-open interval: [A'First, A'Last + 1).
      Lo := A'First;
      Hi := A'Last + 1;

      for Guard in 1 .. Max_N + 1 loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= A'Last + 1);
         pragma Loop_Invariant (Lo <= Hi);
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) < Key);
         pragma Loop_Invariant
           (for all K in Hi .. A'Last => A (K) >= Key);
         exit when Lo >= Hi;

         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid in Lo .. Hi - 1);
         pragma Assert (Mid in A'Range);

         if A (Mid) < Key then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;

      if Lo <= A'Last and then A (Lo) = Key then
         return Lo;
      else
         return 0;
      end if;
   end Find_First;

   ---------------------------------------------------------------------------
   -- Rightmost (Find_Last) — Wikipedia upper-bound − 1
   ---------------------------------------------------------------------------

   function Find_Last (A : Element_Array; Key : Integer) return Index is
      Lo   : Ext_Index;
      Hi   : Ext_Index;
      Mid  : Ext_Index;
      Cand : Ext_Index;
   begin
      if A'Length = 0 then
         return 0;
      end if;

      Lo := A'First;
      Hi := A'Last + 1;

      for Guard in 1 .. Max_N + 1 loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= A'Last + 1);
         pragma Loop_Invariant (Lo <= Hi);
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) <= Key);
         pragma Loop_Invariant
           (for all K in Hi .. A'Last => A (K) > Key);
         exit when Lo >= Hi;

         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid in Lo .. Hi - 1);
         pragma Assert (Mid in A'Range);

         if A (Mid) > Key then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;

      Cand := Hi - 1;
      if Cand >= A'First and then A (Cand) = Key then
         return Cand;
      else
         return 0;
      end if;
   end Find_Last;

end Binary_Search;

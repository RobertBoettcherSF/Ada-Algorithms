--  Interpolation_Search body — SPARK Level 4 interpolation / predictive
--  search with overflow-safe Long_Long_Integer probe arithmetic and a
--  bounded for-loop so termination is immediate for the prover (worst
--  case is O(n)).

package body Interpolation_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Overflow-safe interpolated probe in [Lo, Hi]
   ---------------------------------------------------------------------------

   function Probe
     (Lo, Hi       : Index;
      A_Lo, A_Hi   : Integer;
      Key          : Integer) return Index
     with
       Global => null,
       Pre    =>
         Lo >= 1
         and then Hi <= Max_N
         and then Lo < Hi
         and then A_Hi > A_Lo
         and then Key >= A_Lo
         and then Key <= A_Hi,
       Post   => Probe'Result in Lo .. Hi
   is
      Diff_Key : constant Long_Long_Integer :=
        Long_Long_Integer (Key) - Long_Long_Integer (A_Lo);
      Span     : constant Long_Long_Integer :=
        Long_Long_Integer (Hi - Lo);
      Diff_Val : constant Long_Long_Integer :=
        Long_Long_Integer (A_Hi) - Long_Long_Integer (A_Lo);
      Offset   : Long_Long_Integer;
      Pos      : Integer;
   begin
      --  Diff_Key ∈ [0, Diff_Val], Span ∈ [1, Max_N−1], Diff_Val ≥ 1.
      --  Product fits comfortably in Long_Long_Integer (classroom Max_N).
      pragma Assert (Diff_Key >= 0);
      pragma Assert (Diff_Val > 0);
      pragma Assert (Span >= 1);
      Offset := (Diff_Key * Span) / Diff_Val;
      pragma Assert (Offset >= 0);
      pragma Assert (Offset <= Span);
      Pos := Lo + Integer (Offset);
      if Pos < Integer (Lo) then
         return Lo;
      elsif Pos > Integer (Hi) then
         return Hi;
      else
         return Index (Pos);
      end if;
   end Probe;

   ---------------------------------------------------------------------------
   -- Public Find
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
      Lo  : Ext_Index;
      Hi  : Ext_Index;
      Pos : Index;
   begin
      if A'Length = 0 then
         return 0;
      end if;

      Lo := A'First;
      Hi := A'Last;

      --  At most Max_N iterations; each step returns or shrinks [Lo,Hi]
      --  by at least one index (worst-case interpolation is O(n)).
      for Guard in 1 .. Max_N loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= A'Last);
         pragma Loop_Invariant (Lo <= Hi + 1);
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) < Key);
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) > Key);
         exit when Lo > Hi;
         pragma Assert (Lo in A'Range);
         pragma Assert (Hi in A'Range);

         --  Key outside the remaining value range ⇒ miss.
         exit when Key < A (Lo) or else Key > A (Hi);

         --  Equal-value run: whole remaining window shares one value.
         if A (Hi) = A (Lo) then
            if A (Lo) = Key then
               return Index (Lo);
            else
               return 0;
            end if;
         end if;

         Pos := Probe (Index (Lo), Index (Hi), A (Lo), A (Hi), Key);
         pragma Assert (Pos in Lo .. Hi);
         pragma Assert (Pos in A'Range);

         if A (Pos) = Key then
            return Pos;
         elsif A (Pos) < Key then
            Lo := Ext_Index (Pos) + 1;
         else
            Hi := Ext_Index (Pos) - 1;
         end if;
      end loop;

      return 0;
   end Find;

end Interpolation_Search;

pragma Ada_2022;

package body Search_2D_Matrix with SPARK_Mode => On is

   --  In row-major order A <= B gives Cell (A) <= Cell (B).
   procedure Lemma_Chain (M : Sorted_Matrix; A, B : Cell_Index)
   with
     Ghost,
     Pre  => A <= B,
     Post => Cell (M, A) <= Cell (M, B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Cell (M, K) <= Cell (M, K + 1));
         pragma Loop_Invariant (Cell (M, A) <= Cell (M, K + 1));
      end loop;
   end Lemma_Chain;

   --  Below L every cell is < Target and from L on > Target: no cell
   --  equals it.
   subtype Insert_Point is Positive range 1 .. Cells + 1;

   procedure Lemma_Absent (M : Sorted_Matrix; Target : Value; L : Insert_Point)
   with
     Ghost,
     Pre  => (L = 1 or else Cell (M, L - 1) < Target)
             and then (L = Cells + 1 or else Cell (M, L) > Target),
     Post => (for all K in Cell_Index => Cell (M, K) /= Target)
   is
   begin
      for K in Cell_Index loop
         if K < L then
            Lemma_Chain (M, K, L - 1);
         else
            Lemma_Chain (M, L, K);
         end if;
         pragma Loop_Invariant (for all J in 1 .. K => Cell (M, J) /= Target);
      end loop;
   end Lemma_Absent;

   --  Largest H - L after K comparisons: 64 halved K times.
   function Width (K : Natural) return Natural is
     (case K is
        when 0 => 64, when 1 => 32, when 2 => 16, when 3 => 8,
        when 4 => 4, when 5 => 2, when 6 => 1, when others => 0)
   with Ghost;

   function Contains (Input : Sorted_Matrix; Target : Value) return Search_Result is
      L      : Insert_Point := 1;           --  the first cell >= Target is
      H      : Insert_Point := Cells + 1;   --  in L .. H (Cells + 1: none)
      Mid    : Cell_Index;
      Halves : Natural range 0 .. 7 := 0;
   begin
      while L < H loop
         pragma Loop_Invariant (L <= H);
         pragma Loop_Invariant (L = 1 or else Cell (Input, L - 1) < Target);
         pragma Loop_Invariant (H = Cells + 1 or else Cell (Input, H) >= Target);
         pragma Loop_Invariant (H - L <= Width (Halves));
         pragma Loop_Variant (Decreases => H - L);
         Mid := L + (H - L) / 2;
         Halves := Halves + 1;
         if Cell (Input, Mid) < Target then
            L := Mid + 1;
         else
            H := Mid;
         end if;
      end loop;
      if L <= Cells and then Cell (Input, L) = Target then
         return (Found => True, Probes => Halves + 1);
      end if;
      Lemma_Absent (Input, Target, L);
      return (Found => False, Probes => Halves + (if L <= Cells then 1 else 0));
   end Contains;
end Search_2D_Matrix;

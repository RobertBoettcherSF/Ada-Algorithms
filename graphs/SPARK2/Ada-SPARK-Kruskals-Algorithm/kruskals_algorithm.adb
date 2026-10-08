pragma Ada_2022;
package body Kruskals_Algorithm with SPARK_Mode => On is
   function Root (P : Parent_Array; N : Node) return Node is
      R : Node := N;
   begin
      for Step in Node loop
         if P (R) /= R then R := P (R); end if;
      end loop;
      return R;
   end Root;
   procedure Compute (Edges : in Edge_Array; Chosen : out Edge_Array; Count : out Edge_Count; Total : out Natural) is
      Sorted : Edge_Array := Edges;
      Parent : Parent_Array;
      T : Edge;
      RA, RB : Node;
   begin
      for N in Node loop Parent (N) := N; end loop;
      for I in Edge_Index loop
         for J in Edge_Index range I .. Edge_Index'Last loop
            if Sorted (J).Weight < Sorted (I).Weight then
               T := Sorted (I); Sorted (I) := Sorted (J); Sorted (J) := T;
            end if;
         end loop;
      end loop;
      Chosen := (others => (U => 1, V => 1, Weight => 0)); Count := 0; Total := 0;
      for I in Edge_Index loop
         RA := Root (Parent, Sorted (I).U); RB := Root (Parent, Sorted (I).V);
         if RA /= RB and then Count < Edge_Count'Last then
            Count := Count + 1; Chosen (Count) := Sorted (I); Parent (RB) := RA;
            if Total <= Natural'Last - Sorted (I).Weight then
               Total := Total + Sorted (I).Weight;
            end if;
         end if;
      end loop;
   end Compute;
end Kruskals_Algorithm;

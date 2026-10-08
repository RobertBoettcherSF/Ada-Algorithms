pragma Ada_2022;
package body Exponential_Search with SPARK_Mode => On is
   function Search (A : Data; Target : Element) return Search_Result is
      Bound : Integer := 1;
      Low : Integer;
      High : Integer;
      Middle : Integer;
   begin
      if A (Index'First) = Target then
         return Search_Result (Index'First);
      end if;
      if A (Index'First) > Target then
         return 0;
      end if;

      while Bound < Capacity and then A (Index (Bound)) < Target loop
         pragma Loop_Invariant (Bound >= 1 and Bound <= Capacity);
         pragma Loop_Variant (Decreases => Capacity - Bound);
         if Bound > Capacity / 2 then
            Bound := Capacity;
         else
            Bound := Bound * 2;
         end if;
      end loop;
      Low := Bound / 2 + 1;
      High := Integer'Min (Bound, Capacity);

      while Low <= High loop
         pragma Loop_Invariant (Low >= 1 and Low <= Capacity + 1);
         pragma Loop_Invariant (High >= 0 and High <= Capacity);
         pragma Loop_Variant (Decreases => High - Low + 1);
         Middle := (Low + High) / 2;
         if A (Index (Middle)) = Target then
            return Search_Result (Middle);
         elsif A (Index (Middle)) < Target then
            Low := Middle + 1;
         else
            High := Middle - 1;
         end if;
      end loop;
      return 0;
   end Search;
end Exponential_Search;

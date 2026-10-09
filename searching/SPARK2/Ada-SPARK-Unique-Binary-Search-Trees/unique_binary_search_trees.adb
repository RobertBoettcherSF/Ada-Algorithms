pragma Ada_2022;

package body Unique_Binary_Search_Trees with SPARK_Mode => On is

   --  A! * B! <= (A + B)!, stated with a division so that it cannot overflow
   procedure Fact_Mul (A, B : Node_Count)
     with Ghost,
          Pre  => A + B <= Max_Nodes,
          Post => Fact (A) <= Fact (A + B) / Fact (B),
          Subprogram_Variant => (Decreases => B)
   is
   begin
      if B > 0 then
         Fact_Mul (A, B - 1);
         pragma Assert (Fact (B) = Long_Long_Integer (B) * Fact (B - 1));
         pragma Assert (Fact (A + B) = Long_Long_Integer (A + B) * Fact (A + B - 1));
      end if;
   end Fact_Mul;

   --  Root K splits 1 .. M into K - 1 smaller and M - K larger keys, so
   --  T (M) = sum over K in 1 .. M of T (K - 1) * T (M - K), T (0) = 1.
   function Number_Of_Trees (N : Node_Count) return Tree_Count is
      T : array (Node_Count) of Count := [others => 1];
   begin
      for M in 1 .. N loop
         pragma Loop_Invariant (for all I in 0 .. M - 1 => T (I) <= Fact (I));
         declare
            Sum : Long_Long_Integer := 0;
         begin
            for K in 1 .. M loop
               pragma Loop_Invariant (Sum in 0 .. Long_Long_Integer (K - 1) * Fact (M - 1));
               Fact_Mul (K - 1, M - K);
               pragma Assert (T (K - 1) * T (M - K) <= Fact (M - 1));
               Sum := Sum + T (K - 1) * T (M - K);
            end loop;
            pragma Assert (Sum >= 1);
            pragma Assert (Fact (M) = Long_Long_Integer (M) * Fact (M - 1));
            T (M) := Sum;
         end;
      end loop;
      return T (N);
   end Number_Of_Trees;
end Unique_Binary_Search_Trees;

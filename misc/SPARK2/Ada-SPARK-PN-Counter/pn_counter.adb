pragma Ada_2022;

package body Pn_Counter
  with SPARK_Mode => On
is
   function Empty return Counter is
   begin
      return (P => [others => 0], N => [others => 0]);
   end Empty;

   function Value (C : Counter) return Integer is
      Acc : Integer := 0;
   begin
      for A in Actor_Id loop
         pragma Loop_Invariant
           (Acc in
              -((A - 1) * Max_Ticks) .. ((A - 1) * Max_Ticks));
         Acc := Acc + Integer (C.P (A)) - Integer (C.N (A));
      end loop;
      return Acc;
   end Value;

   procedure Increment (C : in out Counter; Who : Actor_Id) is
   begin
      C.P (Who) := C.P (Who) + 1;
   end Increment;

   procedure Decrement (C : in out Counter; Who : Actor_Id) is
   begin
      C.N (Who) := C.N (Who) + 1;
   end Decrement;

   procedure Merge (Into : in out Counter; Other : Counter) is
   begin
      for A in Actor_Id loop
         pragma Loop_Invariant
           (for all K in Actor_Id =>
              (if K < A then
                 Into.P (K) = Tick'Max (Into'Loop_Entry.P (K), Other.P (K))
                 and then Into.N (K) =
                   Tick'Max (Into'Loop_Entry.N (K), Other.N (K))
               else
                 Into.P (K) = Into'Loop_Entry.P (K)
                 and then Into.N (K) = Into'Loop_Entry.N (K)));
         Into.P (A) := Tick'Max (Into.P (A), Other.P (A));
         Into.N (A) := Tick'Max (Into.N (A), Other.N (A));
      end loop;
   end Merge;
end Pn_Counter;

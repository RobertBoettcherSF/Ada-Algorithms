pragma Ada_2022;
package body Sort_Array_By_Parity_II with SPARK_Mode => On is
   procedure Sort_By_Parity (Input : in Parity_Balanced; Output : out Int_Array) is
      Even_Position : Positive := 2;   --  next free even position
      Odd_Position  : Positive := 1;   --  next free odd position
   begin
      Output := [others => 0];
      for I in Index loop
         if Input (I) mod 2 = 0 then
            Output (Even_Position) := Input (I);
            Even_Position := Even_Position + 2;
         else
            Output (Odd_Position) := Input (I);
            Odd_Position := Odd_Position + 2;
         end if;
         pragma Loop_Invariant (Even_Position = 2 + 2 * Evens_Up_To (Input, I));
         pragma Loop_Invariant (Odd_Position = 1 + 2 * (I - Evens_Up_To (Input, I)));
         pragma Loop_Invariant (for all K in Index =>
                                  (if K mod 2 = 0 and then K < Even_Position then Output (K) mod 2 = 0));
         pragma Loop_Invariant (for all K in Index =>
                                  (if K mod 2 = 1 and then K < Odd_Position then Output (K) mod 2 = 1));
      end loop;
   end Sort_By_Parity;
end Sort_Array_By_Parity_II;

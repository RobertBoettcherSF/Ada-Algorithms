pragma Ada_2022;
package body Sort_Array_By_Parity_II with SPARK_Mode => On is
   procedure Sort_By_Parity (Input : in Int_Array; Output : out Int_Array) is
      Even_Position : Integer range 1 .. 10 := 2;
      Odd_Position : Integer range 1 .. 10 := 1;
   begin
      Output := (others => 0);
      for I in Input'Range loop
         if Input (I) mod 2 = 0 then
            if Even_Position <= Output'Last then
               Output (Even_Position) := Input (I);
               Even_Position := Even_Position + 2;
            end if;
         else
            if Odd_Position <= Output'Last then
               Output (Odd_Position) := Input (I);
               Odd_Position := Odd_Position + 2;
            end if;
         end if;
      end loop;
   end Sort_By_Parity;
end Sort_Array_By_Parity_II;

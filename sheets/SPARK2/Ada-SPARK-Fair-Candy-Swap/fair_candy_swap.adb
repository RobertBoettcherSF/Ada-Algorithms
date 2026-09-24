pragma Ada_2022;
package body Fair_Candy_Swap with SPARK_Mode => On is
   procedure Find_Swap (Alice : in Candy_Array; Bob : in Candy_Array;
                         Swap_A : out Candy; Swap_B : out Candy; Found : out Boolean) is
      Sum_A : Integer := 0;
      Sum_B : Integer := 0;
   begin
      for I in Index loop
         Sum_A := Sum_A + Alice (I);
         Sum_B := Sum_B + Bob (I);
      end loop;
      Swap_A := Alice (Index'First);
      Swap_B := Bob (Index'First);
      Found := False;
      for I in Index loop
         for J in Index loop
            if Sum_A - Alice (I) + Bob (J) = Sum_B - Bob (J) + Alice (I) then
               Swap_A := Alice (I);
               Swap_B := Bob (J);
               Found := True;
            end if;
         end loop;
      end loop;
   end Find_Swap;
end Fair_Candy_Swap;

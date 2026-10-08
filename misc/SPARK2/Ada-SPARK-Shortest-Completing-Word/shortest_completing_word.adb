pragma Ada_2022;
package body Shortest_Completing_Word with SPARK_Mode => On is
   function Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val (Character'Pos (C) + 32);
      else
         return C;
      end if;
   end Lower;

   procedure Is_Completing (Plate, Word : Text; Plate_Length, Word_Length : Length_Type;
                            Result : out Boolean) is
      Need : Natural range 0 .. 32;
      Have : Natural range 0 .. 32;
   begin
      Result := True;
      for I in Index loop
         exit when I > Plate_Length;
         if Lower (Plate (I)) in 'a' .. 'z' then
            Need := 0;
            Have := 0;
            for J in Index loop
               exit when J > Word_Length;
               if Lower (Word (J)) = Lower (Plate (I)) then
                  Have := Have + 1;
               end if;
               pragma Loop_Invariant (Have <= J);
            end loop;
            for K in Index loop
               exit when K > Plate_Length;
               if Lower (Plate (K)) = Lower (Plate (I)) then
                  Need := Need + 1;
               end if;
               pragma Loop_Invariant (Need <= K);
            end loop;
            if Have < Need then
               Result := False;
            end if;
         end if;
      end loop;
   end Is_Completing;
end Shortest_Completing_Word;

pragma Ada_2022;

package body Hand_Of_Straights_Stub with SPARK_Mode => On is
   function Can_Hand (Hand : Hand_Array; Size : Group_Size) return Boolean is
      Sorted : Hand_Array := Hand;
      Minimum : Index;
      Temporary : Card;
   begin
      for I in Index loop
         Minimum := I;
         for J in Index range I .. Index'Last loop
            if Sorted (J) < Sorted (Minimum) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Sorted (I);
         Sorted (I) := Sorted (Minimum);
         Sorted (Minimum) := Temporary;
      end loop;

      case Size is
         when 1 =>
            return True;
         when 2 =>
            return Sorted (2) - Sorted (1) = 1
              and then Sorted (4) - Sorted (3) = 1
              and then Sorted (6) - Sorted (5) = 1
              and then Sorted (8) - Sorted (7) = 1;
         when 3 =>
            return False;
         when 4 =>
            return Sorted (2) - Sorted (1) = 1
              and then Sorted (3) - Sorted (2) = 1
              and then Sorted (4) - Sorted (3) = 1
              and then Sorted (6) - Sorted (5) = 1
              and then Sorted (7) - Sorted (6) = 1
              and then Sorted (8) - Sorted (7) = 1;
      end case;
   end Can_Hand;
end Hand_Of_Straights_Stub;

pragma SPARK_Mode (On);

--  Scaffold for the failing test: the old ternary count table by length,
--  and only the last letter decoded.
package body Letter_Combinations_Of_A_Phone_Number is
   function Count (Number : Digit_String) return Positive is
   begin
      case Number'Length is
         when 0 => return 1;
         when 1 => return 3;
         when 2 => return 9;
         when 3 => return 27;
         when 4 => return 81;
         when 5 => return 243;
         when 6 => return 729;
         when 7 => return 2_187;
         when 8 => return 6_561;
         when 9 => return 19_683;
         when 10 => return 59_049;
         when 11 => return 177_147;
         when 12 => return 531_441;
         when others => return 1;
      end case;
   end Count;

   function Combination (Number : Digit_String; K : Natural) return String is
      R : String (1 .. Number'Last) := [others => 'a'];
   begin
      if Number'Length > 0 then
         R (Number'Last) := Letter (Number (Number'Last), K mod Letters (Number (Number'Last)));
      end if;
      return R;
   end Combination;
end Letter_Combinations_Of_A_Phone_Number;

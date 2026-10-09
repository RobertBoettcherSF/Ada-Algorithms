pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Minimum_Number_Of_Days_To_Make_M_Bouquets;
use Minimum_Number_Of_Days_To_Make_M_Bouquets;
with Own_Checks;

procedure Tests is
   --  Flowers 1 .. 8 bloom on days 5 4 3 2 1 7 6 8.
   Bloom_Days : constant Bloom_Array := [5, 4, 3, 2, 1, 7, 6, 8];

   procedure Expect (Bouquets : Bouquet_Count; Size : Bouquet_Size; First_Day : Day) is
      R : constant Day_Result := Minimum_Day (Bloom_Days, Bouquets, Size);
   begin
      pragma Assert (R.Possible and then R.First_Day = First_Day);
   end Expect;
   R : Day_Result;
begin
   Expect (1, 1, 1);   --  flower 5 on day 1
   Expect (1, 2, 2);   --  flowers 4, 5 on day 2
   Expect (1, 4, 4);   --  flowers 2 .. 5 on day 4
   Expect (2, 2, 4);   --  flowers 2 .. 5 on day 4 make two pairs; day 3 has only 3 .. 5
   Expect (2, 3, 7);   --  day 6: runs 1 .. 5 and 7 give one triple; day 7: 1 .. 7 give two
   Expect (4, 2, 8);   --  all eight flowers
   Expect (8, 1, 8);
   R := Minimum_Day (Bloom_Days, 3, 3);   --  9 flowers needed, only 8
   pragma Assert (not R.Possible and then R.First_Day = Day'Last);
   Put_Line ("Minimum_Number_Of_Days_To_Make_M_Bouquets: PASS");
   Own_Checks;
end Tests;

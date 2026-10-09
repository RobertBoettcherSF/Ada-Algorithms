pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Integer_Break; use Integer_Break;

--  Expected values worked out by hand (see tests/SOURCES.txt).
procedure Tests is
   Old : constant array (2 .. 10) of Positive := [1, 2, 4, 6, 9, 12, 18, 27, 36];

   procedure Expect_Split (N : Number; Want : Part_List) is
      Got : constant Part_List := Best_Split (N);
   begin
      if Got'First /= 1 or else Got'Length /= Want'Length or else Got /= Want then
         raise Program_Error with "Best_Split" & N'Image;
      end if;
   end Expect_Split;

   procedure Check_Split (N : Number) is
      Got  : constant Part_List := Best_Split (N);
      Sum  : Natural := 0;
      Prod : Long_Long_Integer := 1;
   begin
      for P of Got loop
         Sum := Sum + P;
         Prod := Prod * Long_Long_Integer (P);
      end loop;
      if Got'Length < 2 or else Sum /= N or else Prod /= Long_Long_Integer (Maximum (N)) then
         raise Program_Error with "Best_Split properties" & N'Image;
      end if;
   end Check_Split;
begin
   for N in Old'Range loop
      if Maximum (N) /= Old (N) then
         raise Program_Error with "Maximum" & N'Image;
      end if;
   end loop;
   --  11 = 3 + 3 + 3 + 2: 54; 12 = 3 + 3 + 3 + 3: 81; 57 = 19 threes:
   --  3 ** 19 = 1_162_261_467; 58 = 18 threes and a 4 (or two 2s):
   --  4 * 3 ** 18 = 1_549_681_956, the limit (59 would give
   --  2 * 3 ** 19 = 2_324_522_934 > Natural'Last).
   if Maximum (11) /= 54 or else Maximum (12) /= 81
     or else Maximum (57) /= 1_162_261_467 or else Maximum (58) /= 1_549_681_956
   then
      raise Program_Error with "Maximum 11 / 12 / 57 / 58";
   end if;
   --  The split takes the smallest best first part, then keeps the rest
   --  whole if that is at least as good as splitting it:
   --  2: 1 + 1; 3: 1 * 2 = 2 * 1, so 1 + 2; 4: 2 + 2;
   --  10: 2 * 18 = 36 first (1 * 27 is less), 8: 2 * 9 first, 6: 3 * 3
   --  first (1 * 6 and 2 * 4 are less), 3 kept whole: 2 + 2 + 3 + 3.
   Expect_Split (2, [1, 1]);
   Expect_Split (3, [1, 2]);
   Expect_Split (4, [2, 2]);
   Expect_Split (10, [2, 2, 3, 3]);
   for N in Number loop
      Check_Split (N);
   end loop;
   Put_Line ("PASS Integer_Break");
end Tests;

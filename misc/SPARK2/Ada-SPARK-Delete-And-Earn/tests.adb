pragma Ada_2022;
with Ada.Text_IO;
with Delete_And_Earn; use Delete_And_Earn;

procedure Tests with SPARK_Mode => Off is
   --  Delete and Earn: pick a number X, earn X, and every X - 1 and X + 1
   --  is deleted too; repeat. Taking one copy of X makes taking all copies
   --  free, so the answer is the best sum of Points (X) = X * (copies of X)
   --  over a set of values with no two adjacent.
   procedure Check (Nums : Num_Array; Want : Score; Label : String) is
      Got : constant Score := Max_Earn (Nums);
   begin
      if Got /= Want then
         raise Program_Error with Label & ": got" & Got'Image & ", expected" & Want'Image;
      end if;
   end Check;

   procedure Check (N : Number; Want : Score) is
   begin
      if Maximum (N) /= Want then
         raise Program_Error with "Maximum (" & N'Image & ") =" & Maximum (N)'Image
           & ", expected" & Want'Image;
      end if;
   end Check;

   No_Numbers : constant Num_Array (1 .. 0) := [others => 1];
begin
   --  Each value 1 .. N once (the old table's question).
   Check (1, 1);
   Check (6, 12);
   Check (16, 72);
   --  Beyond the old table (N <= 16): all values of N's parity,
   --  1 + 3 + .. + 17 = 81, 2 + 4 + .. + 20 = 110, 2 + .. + 100 = 2_550.
   Check (17, 81);
   Check (20, 110);
   Check (100, 2_550);
   --  Arrays, worked by hand:
   --  3 4 2: take 4 and 2 (3 is deleted by either) -> 6.
   --  2 2 3 3 3 4: points 2 -> 4, 3 -> 9, 4 -> 4; 3s alone beat 2 + 4 -> 9.
   --  1 1 1 2 4 5 5 5 6: points 1 -> 3, 2 -> 2, 4 -> 4, 5 -> 15, 6 -> 6;
   --    best {1, 5} -> 18 (next {2, 5} -> 17, {1, 4, 6} -> 13).
   --  100 100: 200. 99 100: adjacent, take 100. 50 52: not adjacent, 102.
   --  Empty array: 0.
   Check ([3, 4, 2], 6, "3 4 2");
   Check ([2, 2, 3, 3, 3, 4], 9, "2 2 3 3 3 4");
   Check ([1, 1, 1, 2, 4, 5, 5, 5, 6], 18, "1 1 1 2 4 5 5 5 6");
   Check ([100, 100], 200, "100 100");
   Check ([99, 100], 100, "99 100");
   Check ([52, 50], 102, "52 50");
   Check ([7], 7, "7");
   Check (No_Numbers, 0, "empty");
   Ada.Text_IO.Put_Line ("PASS Delete_And_Earn");
end Tests;

pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Insertion_Sort; use Binary_Insertion_Sort;
with Own_Checks;
procedure Tests is
   --  Inserting element I + 1 into the sorted first I elements by binary
   --  search takes at most floor (log2 I) + 1 comparisons, so a sort of
   --  N elements takes at most the sum of that over I = 1 .. N - 1
   --  (17 for N = 8).
   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   function Insertion_Bound return Natural is
      Sum : Natural := 0;
   begin
      for I in 1 .. Index'Last - 1 loop
         Sum := Sum + Floor_Log2 (I) + 1;
      end loop;
      return Sum;
   end Insertion_Bound;

   Bound : constant Natural := Insertion_Bound;

   procedure Expect (Input, Want : Input_Array; Label : String) is
      R : constant Sort_Result := Sort (Input);
   begin
      if R.Sorted /= Want then
         raise Program_Error with Label & ": wrong order";
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " comparisons, more than the binary-insertion bound" & Bound'Image;
      end if;
   end Expect;
begin
   Expect ([23, 4, 17, 9, 1, 31, 12, 6], [1, 4, 6, 9, 12, 17, 23, 31], "original example");
   Expect ([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8], "ascending");
   Expect ([8, 7, 6, 5, 4, 3, 2, 1], [1, 2, 3, 4, 5, 6, 7, 8], "descending");
   Expect ([3, 1, 3, 1, 3, 1, 3, 1], [1, 1, 1, 1, 3, 3, 3, 3], "repeats");
   Expect ([others => 0], [others => 0], "all equal");
   Put_Line ("PASS Binary_Insertion_Sort");
   Own_Checks;
end Tests;

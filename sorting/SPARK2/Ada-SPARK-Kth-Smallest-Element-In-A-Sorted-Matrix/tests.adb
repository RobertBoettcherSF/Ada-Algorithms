pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Kth_Smallest_Matrix; use Kth_Smallest_Matrix;
procedure Tests is
   --  The original 4 x 4 example (rows and columns rise).
   Small : constant Matrix :=
     [1 => [1, 5, 9, 10, 0, 0, 0, 0], 2 => [2, 6, 10, 11, 0, 0, 0, 0],
      3 => [3, 7, 11, 12, 0, 0, 0, 0], 4 => [4, 8, 12, 13, 0, 0, 0, 0],
      others => [others => 0]];
   --  10 (I + J): equal values along anti-diagonals.
   Diag  : constant Matrix := [for I in Dimension => [for J in Dimension => 10 * (I + J)]];
   --  3 I + 5 J: rows overlap (row 1 ends above where row 2 starts).
   Mixed : constant Matrix := [for I in Dimension => [for J in Dimension => 3 * I + 5 * J]];

   --  A binary search on the value needs at most floor (log2 1001) + 1 =
   --  10 counts over Value 0 .. 1000, and a staircase count of the
   --  entries <= X compares at most 2 * N entries.
   function Floor_Log2 (X : Positive) return Natural is
      K : Natural := 0;
      R : Positive := X;
   begin
      while R > 1 loop
         R := R / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   type Flat is array (Rank range <>) of Integer;

   --  Reference: the N x N block sorted by insertion.
   function Sorted_Block (M : Matrix; N : Dimension) return Flat is
      F    : Flat (1 .. N * N) := [others => 0];
      Last : Natural := 0;
      J    : Natural;
   begin
      for R in 1 .. N loop
         for C in 1 .. N loop
            J := Last;
            while J >= 1 and then F (J) > M (R, C) loop
               F (J + 1) := F (J);
               J := J - 1;
            end loop;
            F (J + 1) := M (R, C);
            Last := Last + 1;
         end loop;
      end loop;
      return F;
   end Sorted_Block;

   procedure Check (M : Matrix; N : Dimension; Label : String) is
      S     : constant Flat := Sorted_Block (M, N);
      Bound : constant Natural := (Floor_Log2 (Value'Last - Value'First + 1) + 1) * 2 * N;
   begin
      for K in 1 .. N * N loop
         declare
            R : constant Kth_Result := Kth (M, N, K);
         begin
            if R.Kth /= S (K) then
               raise Program_Error with Label & " K" & K'Image & ":" & R.Kth'Image & ", expected" & S (K)'Image;
            end if;
            if R.Probes > Bound then
               raise Program_Error with Label & " K" & K'Image & ":" & R.Probes'Image
                 & " comparisons, more than (floor (log2 1001) + 1) * 2 * N =" & Bound'Image;
            end if;
         end;
      end loop;
   end Check;
begin
   Check (Small, 4, "4 x 4 example");
   Check (Diag, 8, "10 (I + J)");
   Check (Mixed, 8, "3 I + 5 J");
   for N in Dimension loop
      Check (Mixed, N, "3 I + 5 J, N =" & N'Image);
   end loop;
   Put_Line ("PASS Kth Smallest Matrix");
end Tests;

pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Median_Of_Two_Sorted_Arrays_Lite; use Median_Of_Two_Sorted_Arrays_Lite;
with Own_Checks;

procedure Tests is
   --  The original example (1 3 8 10 / 2 4 9 12, median 6) padded on
   --  both sides with equal numbers of small and large values, so the
   --  two middle values stay 4 and 8.
   A : constant Input_Array := [0, 0, 0, 0, 0, 0, 1, 3, 8, 10, 50, 50, 50, 50, 50, 50];
   B : constant Input_Array := [0, 0, 0, 0, 0, 0, 2, 4, 9, 12, 60, 60, 60, 60, 60, 60];
   --  All of Left below all of Right, and the reverse.
   Low  : constant Input_Array := [for I in Index => I];
   High : constant Input_Array := [for I in Index => 50 + I];
   --  Interleaved: odd and even numbers.
   Odd  : constant Input_Array := [for I in Index => 2 * I - 1];
   Even : constant Input_Array := [for I in Index => 2 * I];

   --  A binary search for the cut needs at most floor (log2 (2 * N)) + 2
   --  comparisons; the old selection sort of all 2 * N values needs
   --  2 * N * (2 * N - 1) / 2.
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

   Bound : constant Natural := Floor_Log2 (2 * Length) + 2;

   procedure Expect (L, R : Input_Array; Want : Value; Label : String) is
      M : constant Median_Result := Median (L, R);
   begin
      if M.Median /= Want then
         raise Program_Error with Label & ": median" & M.Median'Image & ", expected" & Want'Image;
      end if;
      if M.Probes > Bound then
         raise Program_Error with Label & ":" & M.Probes'Image
           & " comparisons, more than floor (log2 (2 * N)) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (A, B, 6, "original example, padded");
   Expect (Low, High, (16 + 51) / 2, "Left below Right");
   Expect (High, Low, (16 + 51) / 2, "Right below Left");
   Expect (Odd, Even, (16 + 17) / 2, "odd / even");
   Expect (Even, Odd, (16 + 17) / 2, "even / odd");
   Expect ([others => 7], [others => 7], 7, "all equal");
   Put_Line ("PASS Median_Of_Two_Sorted_Arrays_Lite");
   Own_Checks;
end Tests;

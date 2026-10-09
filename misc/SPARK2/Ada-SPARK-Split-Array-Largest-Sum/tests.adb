pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Split_Array_Largest_Sum; use Split_Array_Largest_Sum;

procedure Tests is
   A    : constant Input_Array := [7, 2, 5, 10, 8, 1, 3, 4];   --  sum 40
   Full : constant Input_Array := [others => 100];

   --  Limits 1 .. 800: a halving search tries at most ceil (log2 800) = 10;
   --  the bound asserted here is floor (log2 800) + 2 = 11.
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

   Bound : constant Natural := Floor_Log2 (Limit'Last) + 2;

   procedure Expect (X : Input_Array; Parts : Part_Count; Want : Limit; Label : String) is
      R : constant Sum_Result := Largest_Sum (X, Parts);
   begin
      if R.Largest /= Want then
         raise Program_Error with Label & ": largest sum" & R.Largest'Image & ", expected" & Want'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " limits tried, more than floor (log2 800) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (A, 2, 24, "two parts");          --  7 2 5 10 | 8 1 3 4
   Expect (A, 8, 10, "eight parts");        --  the largest element
   Expect (A, 1, 40, "one part");           --  the whole sum
   Expect (A, 3, 16, "three parts");        --  7 2 5 | 10 | 8 1 3 4
   Expect (A, 4, 14, "four parts");         --  7 2 5 | 10 | 8 1 3 | 4
   Expect (A, 5, 10, "five parts");
   Expect (Full, 1, 800, "eight 100s, one part");
   Expect (Full, 3, 300, "eight 100s, three parts");
   Expect (Full, 5, 200, "eight 100s, five parts");
   Expect (Full, 8, 100, "eight 100s, eight parts");
   Put_Line ("Split_Array_Largest_Sum: PASS");
end Tests;

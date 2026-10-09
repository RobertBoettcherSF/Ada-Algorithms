pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Search_Upper_Bound; use Binary_Search_Upper_Bound;

procedure Tests is
   --  The original six values, then 100s.
   Input : constant Input_Array := [-8, -2, 0, 4, 9, 12, others => 100];
   --  -50, -47, .., 43: Up (I) = 3 * I - 53.
   Up    : constant Input_Array := [for I in Index => 3 * I - 53];

   --  N = 32 sorted values, 33 candidate positions: a halving search
   --  needs at most floor (log2 33) + 1 = 6 reads; asserted here is
   --  floor (log2 N) + 2 = 7.
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

   Bound : constant Natural := Floor_Log2 (Length) + 2;

   procedure Expect (D : Input_Array; Target : Target_Value; Where : Result_Index; Label : String) is
      R : constant Search_Result := Find (D, Target);
   begin
      if R.Position /= Where then
         raise Program_Error with Label & ": position" & R.Position'Image & ", expected" & Where'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image & " reads, more than floor (log2 N) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Input, -9, 1, "target -9");
   Expect (Input, 0, 4, "target 0");
   Expect (Input, 9, 6, "target 9");
   Expect (Input, 12, 7, "target 12");
   Expect (Input, 20, 7, "target 20");
   Expect (Input, 99, 7, "target 99");
   Expect (Input, 100, 33, "target 100");
   Expect (Up, -100, 1, "Up target -100");
   Expect (Up, -1, 18, "Up target -1");
   Expect (Up, 45, 33, "Up target 45");
   Expect (Up, 42, 32, "Up target 42");
   Put_Line ("Binary_Search_Upper_Bound: PASS");
end Tests;

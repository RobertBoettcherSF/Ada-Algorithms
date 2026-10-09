pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Sqrtx; use Sqrtx;
with Own_Checks;

procedure Tests is
   --  Roots 0 .. 100: a halving search squares at most ceil (log2 101) = 7
   --  candidates; the bound asserted here is floor (log2 101) + 2 = 8.
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

   Bound : constant Natural := Floor_Log2 (Root'Last + 1) + 2;

   procedure Expect (V : Input; Want : Root) is
      R : constant Root_Result := Integer_Square_Root (V);
   begin
      if R.Value /= Want then
         raise Program_Error with "sqrt" & V'Image & ":" & R.Value'Image & ", expected" & Want'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with "sqrt" & V'Image & ":" & R.Probes'Image
           & " candidates squared, more than floor (log2 101) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (0, 0);
   Expect (1, 1);
   Expect (8, 2);
   Expect (10_000, 100);
   Expect (9_999, 99);
   Expect (3, 1);
   Expect (4, 2);
   Expect (2_500, 50);
   Expect (2_499, 49);
   Put_Line ("Sqrtx: PASS");
   Own_Checks;
end Tests;

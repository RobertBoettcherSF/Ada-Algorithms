pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Babylonian_Sqrt; use Babylonian_Sqrt;
with Own_Checks;

procedure Tests is
   --  Roots 0 .. 100. The Babylonian (Newton) iteration from 100 takes at
   --  most 8 steps on 0 .. 10,000 (halving while far, then quadratic); the
   --  bound asserted here is floor (log2 101) + 2 = 8, the same as a
   --  halving search over the 101 roots would need plus one.
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

   Bound : constant Natural := Floor_Log2 (101) + 2;

   procedure Expect (N : Input; Want : Natural) is
      R : constant Sqrt_Result := Sqrt (N);
   begin
      if R.Root /= Want then
         raise Program_Error with "sqrt" & N'Image & ":" & R.Root'Image & ", expected" & Want'Image;
      end if;
      if R.Steps > Bound then
         raise Program_Error with "sqrt" & N'Image & ":" & R.Steps'Image
           & " steps, more than floor (log2 101) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (0, 0);
   Expect (144, 12);
   Expect (10_000, 100);
   Expect (143, 11);
   Expect (145, 12);
   Expect (1, 1);
   Expect (2, 1);
   Expect (3, 1);
   Expect (9_999, 99);
   Put_Line ("Babylonian_Sqrt: PASS");
   Own_Checks;
end Tests;

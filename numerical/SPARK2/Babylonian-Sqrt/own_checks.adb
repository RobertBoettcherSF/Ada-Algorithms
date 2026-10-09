--  Own tests for Babylonian_Sqrt (written for this repository; see
--  tests/SOURCES.txt). Assumption: Sqrt returns a wrong
--  root for some N in 0 .. 10,000, or takes more than
--  floor (log2 101) + 2 refinement steps.
--  Reference: the root by counting odd numbers (1 + 3 + ... + (2K - 1)
--  = K * K), with no multiplication: the root is how many odd numbers
--  can be subtracted from N. Every N 0 .. 10,000 is checked.
pragma Ada_2022;
with Ada.Text_IO;
with Babylonian_Sqrt; use Babylonian_Sqrt;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Steps  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

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

   function Odd_Count_Root (V : Natural) return Natural is
      Left : Integer := V;
      Odd  : Positive := 1;
      K    : Natural := 0;
   begin
      while Left >= Odd loop
         Left := Left - Odd;
         Odd := Odd + 2;
         K := K + 1;
      end loop;
      return K;
   end Odd_Count_Root;
begin
   for V in Input loop
      declare
         R    : constant Sqrt_Result := Sqrt (V);
         Want : constant Natural := Odd_Count_Root (V);
      begin
         Report (R.Root = Want, "N" & V'Image & " got" & R.Root'Image & " want" & Want'Image);
         Report (R.Steps <= Bound, "N" & V'Image & R.Steps'Image & " steps");
         Max_Steps := Natural'Max (Max_Steps, R.Steps);
      end;
   end loop;
   --  Measured worst case: 8 steps (N = 3, from X = 100: 50 25 12 6 3 2 1, stop).
   Report (Max_Steps = 8, "worst case steps" & Max_Steps'Image & ", expected 8");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (every N 0 .. 10,000 vs an odd-number count; steps <= floor (log2 101) + 2, worst case 8)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;

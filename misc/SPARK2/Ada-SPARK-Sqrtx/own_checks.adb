--  Own tests for Sqrtx (written for this repository; see
--  tests/SOURCES.txt). Assumption: Integer_Square_Root returns a wrong
--  root for some Value in 0 .. 10,000, or squares more than
--  floor (log2 101) + 2 candidates.
--  Reference: the root by counting odd numbers (1 + 3 + ... + (2K - 1)
--  = K * K), with no multiplication: the root is how many odd numbers
--  can be subtracted from Value. Every Value 0 .. 10,000 is checked.
pragma Ada_2022;
with Ada.Text_IO;
with Sqrtx; use Sqrtx;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;

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

   Bound : constant Natural := Floor_Log2 (Root'Last + 1) + 2;

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
         R    : constant Root_Result := Integer_Square_Root (V);
         Want : constant Natural := Odd_Count_Root (V);
      begin
         Report (R.Value = Want, "Value" & V'Image & " got" & R.Value'Image & " want" & Want'Image);
         Report (R.Probes <= Bound, "Value" & V'Image & R.Probes'Image & " probes");
         Max_Probes := Natural'Max (Max_Probes, R.Probes);
      end;
   end loop;
   --  101 candidates need 7 probes in the worst case.
   Report (Max_Probes = 7, "worst case probes" & Max_Probes'Image & ", expected 7");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (every Value 0 .. 10,000 vs an odd-number count; probes <= floor (log2 101) + 2, worst case 7)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;

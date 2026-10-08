pragma Ada_2022;
--  Own tests for Linear_Regression (see tests/SOURCES.txt).
--  Predict: least-squares line through (1, Y1) .. (4, Y4) evaluated at X, truncated toward zero.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Linear_Regression; use Linear_Regression;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
begin
   for Run in 1 .. 40_000 loop
      declare
         Y : array (1 .. 4) of Integer;
         X : constant Positive := Next (1, 4);
         Sy, Sxy, Num : Integer := 0;
      begin
         for I in 1 .. 4 loop Y (I) := Next (-100, 100); Sy := Sy + Y (I); Sxy := Sxy + I * Y (I); end loop;
         --  normal equations with n = 4, Sx = 10, Sxx = 30, determinant 4 * 30 - 10**2 = 20:
         --  intercept = (Sxx * Sy - Sx * Sxy) / 20, slope = (4 * Sxy - Sx * Sy) / 20
         Num := (30 * Sy - 10 * Sxy) + X * (4 * Sxy - 10 * Sy);
         Report (Predict (Y (1), Y (2), Y (3), Y (4), X) = Num / 20,
                 "Y" & Integer'Image (Y (1)) & Integer'Image (Y (2)) & Integer'Image (Y (3)) & Integer'Image (Y (4)) & " X" & Integer'Image (X));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

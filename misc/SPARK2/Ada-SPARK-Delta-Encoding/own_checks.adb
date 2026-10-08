pragma Ada_2022;
--  Own tests for Delta_Encoding (see tests/SOURCES.txt).
--  Net_Delta against the sum of the encoded deltas (delta-encode the stream, add up the deltas).
with Ada.Text_IO; use Ada.Text_IO;
with Delta_Encoding; use Delta_Encoding;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
   for Run in 1 .. 20000 loop
      declare
         N : constant Positive := Next (1, Max_Length);
         S : Sample_Array (1 .. N);
         Sum : Integer := 0;
      begin
         for K in 1 .. N loop
            S (K) := Sample (Integer'(case Next (0, 5) is when 0 => -128, when 1 => 127, when others => Next (-128, 127)));
         end loop;
         for K in 2 .. N loop Sum := Sum + (Integer (S (K)) - Integer (S (K - 1))); end loop;   --  delta encoding
         Report (Net_Delta (S) = Sum, "net delta, run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

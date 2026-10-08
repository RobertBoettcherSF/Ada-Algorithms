pragma Ada_2022;
--  Own tests for Delta_Encoding (see tests/SOURCES.txt).
--  Net_Delta against the sum of the encoded deltas (delta-encode the stream, add up the deltas).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Delta_Encoding; use Delta_Encoding;

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

pragma Ada_2022;
--  Own tests for Hamming_Weight (see tests/SOURCES.txt).
--  Weight against an own count by repeated division by 2 (exhaustive 0 .. 2**20, plus random values up to Input'Last).
with Ada.Text_IO; use Ada.Text_IO;
with Hamming_Weight; use Hamming_Weight;

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
   procedure Check (V : Input) is
      X : Natural := V; C : Natural := 0;
   begin
      while X > 0 loop C := C + X mod 2; X := X / 2; end loop;
      Report (Weight (V) = C, "Weight" & V'Image);
   end Check;
begin
   for V in 0 .. 2 ** 20 loop Check (V); end loop;
   for Run in 1 .. 20000 loop Check (Next (0, Input'Last)); end loop;
   Check (Input'Last);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

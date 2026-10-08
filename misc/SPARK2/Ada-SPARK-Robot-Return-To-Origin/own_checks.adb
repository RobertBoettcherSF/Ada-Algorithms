pragma Ada_2022;
--  Own tests for Robot_Origin (see tests/SOURCES.txt).
--  Returns_To_Origin: a U/D/L/R walk ends at the start iff #U = #D and #L = #R.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Robot_Origin; use Robot_Origin;

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
   M : Text;
begin
   for Run in 1 .. 20_000 loop
      declare
         L : constant Natural := Next (0, 32);
         U, D, Lf, R : Natural := 0;
      begin
         M := [others => 'X'];
         for I in 1 .. L loop
            case Next (0, 3) is
               when 0 => M (I) := 'U'; U := U + 1;
               when 1 => M (I) := 'D'; D := D + 1;
               when 2 => M (I) := 'L'; Lf := Lf + 1;
               when others => M (I) := 'R'; R := R + 1;
            end case;
         end loop;
         Report (Returns_To_Origin (M, L) = (U = D and then Lf = R), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

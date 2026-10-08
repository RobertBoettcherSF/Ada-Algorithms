pragma Ada_2022;
--  Own tests for To_Lower_Case (see tests/SOURCES.txt).
--  Lower_Case: A .. Z become a .. z in Input (1 .. Length); every other character and every position after Length is copied.
with Ada.Text_IO; use Ada.Text_IO;
with To_Lower_Case; use To_Lower_Case;

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
   I_T, O_T : Text;
begin
   for Run in 1 .. 20_000 loop
      declare
         L : constant Natural := Next (0, 32);
         Ok : Boolean := True;
         W : Character;
      begin
         for I in Index loop I_T (I) := Character'Val (Next (0, 255)); end loop;
         Lower_Case (I_T, L, O_T);
         for I in Index loop
            W := I_T (I);
            if I <= L and then W in 'A' .. 'Z' then
               W := Character'Val (Character'Pos (W) - Character'Pos ('A') + Character'Pos ('a'));
            end if;
            Ok := Ok and then O_T (I) = W;
         end loop;
         Report (Ok, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

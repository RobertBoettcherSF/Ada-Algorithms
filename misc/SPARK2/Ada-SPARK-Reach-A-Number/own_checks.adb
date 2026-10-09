pragma Ada_2022;
--  Own checks for Reach-A-Number (V&V sweep, agent A3, 2026-10-09; see
--  tests/SOURCES.txt). Reference: the set of positions reachable after K
--  moves (move I goes I steps left or right) is built step by step as a
--  Boolean table over -210 .. 210, and the answer is the first K whose set
--  holds Value (no parity or triangular-number formula). Exhaustive over
--  every Value in -100 .. 100.
with Ada.Text_IO;
with Reach_A_Number; use Reach_A_Number;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;
   subtype Pos is Integer range -210 .. 210;
   type Set is array (Pos) of Boolean;

   function Reference (V : Target) return Natural is
      Now : Set := [0 => True, others => False];
      Nxt : Set;
   begin
      for K in 0 .. 20 loop
         if Now (V) then
            return K;
         end if;
         Nxt := [others => False];
         for P in Pos loop
            if Now (P) then
               Nxt (P + (K + 1)) := True;
               Nxt (P - (K + 1)) := True;
            end if;
         end loop;
         Now := Nxt;
      end loop;
      raise Program_Error with "reference: not reached in 20 moves";
   end Reference;
begin
   for V in Target loop
      Checked := Checked + 1;
      if Minimum_Steps (V) /= Reference (V) then
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("  FAIL own check: Minimum_Steps (" & V'Image
                               & ") expected" & Reference (V)'Image);
      end if;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;

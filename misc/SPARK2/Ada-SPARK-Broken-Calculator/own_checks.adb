--  Own tests for Broken_Calculator (see tests/SOURCES.txt).
--  Minimum_Operations (Start, Target) = fewest operations "double" (X -> 2X) and "decrement"
--  (X -> X - 1) turning Start into Target; reference: own breadth-first search over 0 .. 64.
with Ada.Text_IO; use Ada.Text_IO;
with Broken_Calculator; use Broken_Calculator;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;

   subtype State is Natural range 0 .. 64;
   function Distance (From, To : State) return Natural is
      Dist : array (State) of Integer := [others => -1];
      Queue : array (1 .. State'Last + 1) of State;
      Head, Tail : Positive := 1;
   begin
      Dist (From) := 0; Queue (Tail) := From; Tail := Tail + 1;
      while Head < Tail loop
         declare
            X : constant State := Queue (Head);
         begin
            Head := Head + 1;
            if 2 * X <= State'Last and then Dist (2 * X) < 0 then
               Dist (2 * X) := Dist (X) + 1; Queue (Tail) := 2 * X; Tail := Tail + 1;
            end if;
            if X > 0 and then Dist (X - 1) < 0 then
               Dist (X - 1) := Dist (X) + 1; Queue (Tail) := X - 1; Tail := Tail + 1;
            end if;
         end;
      end loop;
      return Dist (To);
   end Distance;
begin
   for S in 1 .. 32 loop
      for T in 1 .. 32 loop
         Report (Minimum_Operations (S, T) = Distance (S, T),
                 "start" & Integer'Image (S) & " target" & Integer'Image (T));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

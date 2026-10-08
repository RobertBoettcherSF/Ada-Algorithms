--  Own tests for Design_HashSet (see tests/SOURCES.txt).
--  Model-based: random Add / Remove sequences against an own Boolean-array model.
with Ada.Text_IO; use Ada.Text_IO;
with Design_HashSet; use Design_HashSet;

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
   S : Set;
   Has : array (Element) of Boolean;
begin
   for Run in 1 .. 2_000 loop
      S := Empty;
      Has := [others => False];
      for Op in 1 .. 40 loop
         declare
            E : constant Element := Next (1, Capacity);
         begin
            if Next (0, 1) = 0 then
               Add (S, E); Has (E) := True;
            else
               Remove (S, E); Has (E) := False;
            end if;
            for Q in Element loop
               Report (Contains (S, Q) = Has (Q), "contains");
            end loop;
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

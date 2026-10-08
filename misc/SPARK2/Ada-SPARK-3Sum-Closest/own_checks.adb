--  Own tests for Three_Sum_Closest (see tests/SOURCES.txt).
--  Closest (Data, Length, Target) returns a sum of three distinct positions of Data (1 .. Length)
--  whose distance to Target is minimal; fewer than three values have no triple and are rejected.
with Ada.Text_IO; use Ada.Text_IO;
with Three_Sum_Closest; use Three_Sum_Closest;

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
   type Sum_Set is array (-3_000 .. 3_000) of Boolean;
   D : Values;

   procedure Check_Rejected (Len : Natural) is
   begin
      declare
         R : constant Integer := Closest (D, Len, 0);
      begin
         Report (False, "length" & Integer'Image (Len) & " accepted, returned" & Integer'Image (R));
      end;
   exception
      when Constraint_Error => Report (True, "rejected");
   end Check_Rejected;
begin
   for Trial in 1 .. 4_000 loop
      declare
         Len : constant Natural := Next (3, 12);
         Span : constant Integer := (if Trial mod 2 = 0 then 5 else 1_000);
         Sums : Sum_Set := [others => False];
         Target : constant Integer := Next (-3 * Span, 3 * Span);
         Best : Natural := Natural'Last;
      begin
         D := [others => 0];
         for I in 1 .. Len loop
            D (I) := Next (-Span, Span);
         end loop;
         for I in 1 .. Len loop
            for J in I + 1 .. Len loop
               for K in J + 1 .. Len loop
                  Sums (D (I) + D (J) + D (K)) := True;
                  Best := Natural'Min (Best, abs (D (I) + D (J) + D (K) - Target));
               end loop;
            end loop;
         end loop;
         declare
            R : constant Integer := Closest (D, Len, Target);
         begin
            Report (Sums (R) and then abs (R - Target) = Best, "trial" & Integer'Image (Trial));
         end;
      end;
   end loop;
   D := [others => 7];
   for Len in 0 .. 2 loop
      Check_Rejected (Len);
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

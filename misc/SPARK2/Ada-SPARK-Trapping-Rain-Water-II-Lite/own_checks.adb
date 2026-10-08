pragma Ada_2022;
--  Own tests for Trapping_Rain_Water_II_Lite (see tests/SOURCES.txt).
--  Water above position I = min (highest bar at or left of I, highest at or right of I) - Data (I);
--  own O(n^2) reference.
with Ada.Text_IO; use Ada.Text_IO;
with Trapping_Rain_Water_II_Lite; use Trapping_Rain_Water_II_Lite;

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
   function Ref (D : Heights; N : Length_Type) return Natural is
      S, L, R : Natural := 0;
   begin
      for I in 1 .. N loop
         L := 0; R := 0;
         for J in 1 .. I loop L := Natural'Max (L, D (J)); end loop;
         for J in I .. N loop R := Natural'Max (R, D (J)); end loop;
         S := S + Natural'Min (L, R) - D (I);
      end loop;
      return S;
   end Ref;
begin
   for Run in 1 .. 5000 loop
      declare
         D : Heights := [others => 0];
         N : constant Length_Type := (if Run mod 5 = 0 then 32 else Next (0, 32));
         Hi : constant Natural := (if Run mod 2 = 0 then 5 else 1000);
      begin
         for I in 1 .. N loop D (I) := Next (0, Hi); end loop;
         --  data past Length must be ignored
         for I in N + 1 .. 32 loop D (I) := Next (0, Hi); end loop;
         Report (Trapped (D, N) = Ref (D, N), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

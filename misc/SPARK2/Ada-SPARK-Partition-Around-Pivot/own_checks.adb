pragma Ada_2022;
--  Own tests for Partition_Around_Pivot (see tests/SOURCES.txt).
--  Partition: values <= Pivot first, then the larger ones, each group in input order (README: stable).
with Ada.Text_IO; use Ada.Text_IO;
with Partition_Around_Pivot; use Partition_Around_Pivot;

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
   A : Value_Array;
begin
   for Trial in 1 .. 50_000 loop
      for I in Index loop A (I) := Next (-10, 10); end loop;
      declare
         P : constant Value := Next (-10, 10);
         R : constant Value_Array := Partition (A, P);
         E : Value_Array;
         K : Natural := 0;
      begin
         for I in Index loop if A (I) <= P then K := K + 1; E (K) := A (I); end if; end loop;
         for I in Index loop if A (I) > P then K := K + 1; E (K) := A (I); end if; end loop;
         Report (R = E, "trial" & Integer'Image (Trial));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

pragma Ada_2022;
--  Own tests for Special_Array_With_X_Elements (see tests/SOURCES.txt).
--  Is_Special (A, X): exactly X of the 8 elements equal X (the folder's convention, fixed by tests.adb).
with Ada.Text_IO; use Ada.Text_IO;
with Special_Array_With_X_Elements; use Special_Array_With_X_Elements;

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
   A : Array_Of_Values;
begin
   for Run in 1 .. 20_000 loop
      declare
         X : constant Value := Next (0, 8);
         C : Natural := 0;
      begin
         for I in A'Range loop
            A (I) := (if Next (0, 1) = 0 then X else Next (0, 8));
            if A (I) = X then C := C + 1; end if;
         end loop;
         Report (Is_Special (A, X) = (C = X), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

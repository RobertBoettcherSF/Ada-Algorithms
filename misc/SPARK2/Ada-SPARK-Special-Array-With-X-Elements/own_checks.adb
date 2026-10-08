pragma Ada_2022;
--  Own tests for Special_Array_With_X_Elements (see tests/SOURCES.txt).
--  Is_Special (A, X): exactly X of the 8 elements equal X (the folder's convention, fixed by tests.adb).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Special_Array_With_X_Elements; use Special_Array_With_X_Elements;

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

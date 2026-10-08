pragma Ada_2022;
--  Own tests for Power_Of_Three (see tests/SOURCES.txt).
--  Is_Power: Value = 3**k for some k >= 0; own table of powers of three.
with Ada.Text_IO; use Ada.Text_IO;
with Power_Of_Three; use Power_Of_Three;

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
   function Pow3 (V : Positive) return Boolean is
      P : Long_Long_Integer := 1;
   begin
      while P < Long_Long_Integer (V) loop P := P * 3; end loop;
      return P = Long_Long_Integer (V);
   end Pow3;
begin
   for V in 1 .. 100_000 loop
      Report (Is_Power (V) = Pow3 (V), "V" & Integer'Image (V));
   end loop;
   declare
      P : Long_Long_Integer := 1;
   begin
      while P <= Long_Long_Integer (Input'Last) loop   --  every power in the domain and its neighbours
         for D in -1 .. 1 loop
            if P + Long_Long_Integer (D) in 1 .. Long_Long_Integer (Input'Last) then
               Report (Is_Power (Integer (P) + D) = (D = 0 or else Pow3 (Integer (P) + D)), "near" & Long_Long_Integer'Image (P));
            end if;
         end loop;
         P := P * 3;
      end loop;
   end;
   for Run in 1 .. 20_000 loop
      declare
         V : constant Positive := Next (1, Input'Last);
      begin
         Report (Is_Power (V) = Pow3 (V), "random" & Integer'Image (V));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

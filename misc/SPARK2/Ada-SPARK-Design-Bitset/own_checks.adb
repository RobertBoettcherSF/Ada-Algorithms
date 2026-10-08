pragma Ada_2022;
--  Own tests for Design_Bitset (see tests/SOURCES.txt).
--  Initialize / Include / Exclude / Contains / Cardinality against an own Boolean-array model.
with Ada.Text_IO; use Ada.Text_IO;
with Design_Bitset; use Design_Bitset;

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
   M : array (Bit_Index) of Boolean;
begin
   for Run in 1 .. 500 loop
      Initialize (S);
      M := [others => False];
      for Op in 1 .. 100 loop
         declare
            B : constant Bit_Index := Next (0, Capacity - 1);
            C : Natural := 0;
         begin
            if Next (0, 1) = 0 then Include (S, B); M (B) := True; else Exclude (S, B); M (B) := False; end if;
            for I in Bit_Index loop
               if M (I) then C := C + 1; end if;
               Report (Contains (S, I) = M (I), "run" & Integer'Image (Run) & " op" & Integer'Image (Op));
            end loop;
            Report (Cardinality (S) = C, "card run" & Integer'Image (Run));
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

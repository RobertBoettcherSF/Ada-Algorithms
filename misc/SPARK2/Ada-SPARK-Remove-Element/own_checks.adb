pragma Ada_2022;
--  Own tests for Remove_Element (see tests/SOURCES.txt).
--  Remove: afterwards Data (1 .. Length) holds exactly the old elements different from Target (as a multiset).
with Ada.Text_IO; use Ada.Text_IO;
with Remove_Element; use Remove_Element;

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
   D : Values;
   L : Length_Type;
   function Same_Multiset (A : Values; LA : Natural; B : Values; LB : Natural) return Boolean is
      CA, CB : Natural;
   begin
      if LA /= LB then return False; end if;
      for I in 1 .. LA loop
         CA := 0; CB := 0;
         for J in 1 .. LA loop
            if A (J) = A (I) then CA := CA + 1; end if;
            if B (J) = A (I) then CB := CB + 1; end if;
         end loop;
         if CA /= CB then return False; end if;
      end loop;
      return True;
   end Same_Multiset;
begin
   for Run in 1 .. 20_000 loop
      declare
         N : constant Natural := (if Next (0, 4) = 0 then 32 else Next (0, 32));
         R : constant Positive := Next (1, 6);
         T : constant Value := Next (-R, R);
         Keep : Values := [others => 0];
         K : Natural := 0;
      begin
         for I in Index loop D (I) := Next (-R, R); end loop;
         for I in 1 .. N loop
            if D (I) /= T then K := K + 1; Keep (K) := D (I); end if;
         end loop;
         L := N;
         Remove (D, L, T);
         Report (Same_Multiset (Keep, K, D, L), "run" & Integer'Image (Run) & " N" & Integer'Image (N) & " kept" & Integer'Image (K) & " got" & Integer'Image (L));
      end;
   end loop;
   --  full length, nothing to remove
   D := [for I in Index => I];
   L := 32;
   Remove (D, L, 0);
   Report (L = 32, "full array without Target: Length became" & Integer'Image (L));
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

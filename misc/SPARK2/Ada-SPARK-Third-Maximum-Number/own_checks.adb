--  Own tests for Third_Maximum_Number (see tests/SOURCES.txt).
--  For arrays with at least three distinct values, Third_Maximum must be the third largest distinct value.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Third_Maximum_Number; use Third_Maximum_Number;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   X : Int_Array;
   function Ref return Integer is
      Seen : Natural := 0;
   begin
      for V in reverse Value loop
         if (for some I in Index => X (I) = V) then
            Seen := Seen + 1;
            if Seen = 3 then return V; end if;
         end if;
      end loop;
      return Integer'First;
   end Ref;
begin
   --  shaped: 30 copies of 20, one 10 and one 5, at every pair of positions, so after sorting the
   --  third distinct value (5) sits in the last slot; also the same with the order of 10 and 5 swapped
   for I in Index loop
      for J in Index loop
         if I /= J then
            X := [others => 20]; X (I) := 10; X (J) := 5;
            Report (Third_Maximum (X) = 5, "third distinct value last after sorting" & I'Image & J'Image);
         end if;
      end loop;
   end loop;
   for Iter in 1 .. 6_000 loop
      declare
         Hi : constant Integer := (if Iter mod 2 = 0 then -30 else 32);
      begin
         for I in Index loop
            X (I) := Next (-32, Hi);
         end loop;
         if Ref /= Integer'First then
            Report (Third_Maximum (X) = Ref, "random" & Iter'Image);
         end if;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own distinct-value scan)");
end Own_Checks;

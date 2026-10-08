pragma Ada_2022;
--  Own tests for Design_Bitset (see tests/SOURCES.txt).
--  Initialize / Include / Exclude / Contains / Cardinality against an own Boolean-array model.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Design_Bitset; use Design_Bitset;

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

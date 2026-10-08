--  Own tests for Range_Sum_Query_Immutable (see tests/SOURCES.txt).
--  Query (A, L, R) must equal the sum of A (L .. R), for every L <= R.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Range_Sum_Query_Immutable; use Range_Sum_Query_Immutable;

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

   A : Values;
   S : Integer;
   Ok : Boolean;
begin
   for Iter in 1 .. 500 loop
      for I in Index loop
         A (I) := Next (0, (if Iter mod 2 = 0 then 1 else 10));
      end loop;
      Ok := True;
      for L in Index loop
         S := 0;
         for R in L .. Size loop
            S := S + A (R);
            if Query (A, L, R) /= S then Ok := False; end if;
         end loop;
      end loop;
      Report (Ok, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own direct-sum reference)");
end Own_Checks;

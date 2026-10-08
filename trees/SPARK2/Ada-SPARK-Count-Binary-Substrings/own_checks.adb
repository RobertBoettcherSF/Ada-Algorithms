--  Own tests for Count_Binary_Substrings (see tests/SOURCES.txt).
--  Count of substrings (by position) made of k equal characters followed by k
--  equal characters of the other kind.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Count_Binary_Substrings; use Count_Binary_Substrings;

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


   S : Text := [others => '0'];
   N : Length_Type;
   R : Count_Type;
begin
   for K in 1 .. 4_000 loop
      N := Next (0, 32);
      for I in 1 .. N loop
         S (I) := (if Next (0, (if K mod 2 = 0 then 1 else 3)) = 0 then '1' else '0');
      end loop;
      declare
         E : Natural := 0;
      begin
         for I in 1 .. N loop
            for H in 1 .. (N - I + 1) / 2 loop
               declare
                  Ok : Boolean := S (I) /= S (I + H);
               begin
                  for P in 0 .. H - 1 loop
                     Ok := Ok and then S (I + P) = S (I) and then S (I + H + P) = S (I + H);
                  end loop;
                  if Ok then
                     E := E + 1;
                  end if;
               end;
            end loop;
         end loop;
         Count_Substrings (S, N, R);
         Report (R = E, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-substrings reference)");
end Own_Checks;

--  Own tests for Longest_Substring_Without_Repeat (see tests/SOURCES.txt).
--  Longest = length of the longest substring without a repeated character.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Longest_Substring_Without_Repeat; use Longest_Substring_Without_Repeat;

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


   S : Text_Array;
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         S (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 2 else 6)));
      end loop;
      declare
         Best : Natural := 0;
      begin
         for I in Index loop
            for J in I .. Length loop
               declare
                  Uniq : Boolean := True;
               begin
                  for P in I .. J loop
                     for Q in P + 1 .. J loop
                        Uniq := Uniq and then S (P) /= S (Q);
                     end loop;
                  end loop;
                  if Uniq then
                     Best := Natural'Max (Best, J - I + 1);
                  end if;
               end;
            end loop;
         end loop;
         Report (Longest (S) = Best, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-substrings reference)");
end Own_Checks;

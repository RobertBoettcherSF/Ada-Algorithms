--  Own tests for Reverse_Vowels_Of_A_String (see tests/SOURCES.txt).
--  With vowels exactly at positions 2 and 5 (the precondition), the result swaps
--  them and keeps every other character.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Reverse_Vowels_Of_A_String; use Reverse_Vowels_Of_A_String;

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


   Vowels : constant String := "aeiou";
   Cons   : constant String := "bcdfghjklmnpqrstvwxz";
   T : Text_Array;
begin
   for K in 1 .. 4_000 loop
      for I in Index loop
         if I = 2 or else I = 5 then
            T (I) := Vowels (Next (Vowels'First, Vowels'Last));
         else
            T (I) := Cons (Next (Cons'First, Cons'Last));
         end if;
      end loop;
      declare
         R : constant Text_Array := Reverse_Vowels (T);
      begin
         Report (R (2) = T (5) and then R (5) = T (2) and then R (1) = T (1) and then R (3) = T (3)
                 and then R (4) = T (4) and then R (6) = T (6), "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own swap property)");
end Own_Checks;

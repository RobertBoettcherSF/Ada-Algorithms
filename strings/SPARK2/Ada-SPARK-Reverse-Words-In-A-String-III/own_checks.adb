--  Own tests for Reverse_Words_In_A_String_III (see tests/SOURCES.txt).
--  Every maximal run of non-space characters is reversed in place; spaces stay.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Reverse_Words_In_A_String_III; use Reverse_Words_In_A_String_III;

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


   T, O : Text := [others => ' '];
   N, M : Length_Type;
begin
   for K in 1 .. 4_000 loop
      N := Next (0, 32);
      for I in 1 .. N loop
         T (I) := (if Next (0, 3) = 0 then ' ' else Character'Val (Character'Pos ('a') + Next (0, 25)));
      end loop;
      Reverse_Words (T, N, O, M);
      declare
         E : String (1 .. N);
         I : Natural := 1;
         J : Natural;
      begin
         while I <= N loop
            if T (I) = ' ' then
               E (I) := ' ';
               I := I + 1;
            else
               J := I;
               while J < N and then T (J + 1) /= ' ' loop
                  J := J + 1;
               end loop;
               for P in I .. J loop
                  E (P) := T (I + J - P);
               end loop;
               I := J + 1;
            end if;
         end loop;
         Report (M = N and then String (O (1 .. M)) = E, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own word-reversal reference)");
end Own_Checks;

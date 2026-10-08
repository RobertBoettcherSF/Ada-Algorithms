--  Own tests for Edit_Distance (see tests/SOURCES.txt).
--  Distance must equal the Levenshtein distance of the two prefixes.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Edit_Distance; use Edit_Distance;

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


   --  Own reference: plain recursive Levenshtein distance (no memo; inputs are tiny).
   function Lev (A : String; B : String) return Natural is
   begin
      if A'Length = 0 then
         return B'Length;
      elsif B'Length = 0 then
         return A'Length;
      elsif A (A'Last) = B (B'Last) then
         return Lev (A (A'First .. A'Last - 1), B (B'First .. B'Last - 1));
      else
         return 1 + Natural'Min (Lev (A (A'First .. A'Last - 1), B),
                    Natural'Min (Lev (A, B (B'First .. B'Last - 1)),
                                 Lev (A (A'First .. A'Last - 1), B (B'First .. B'Last - 1))));
      end if;
   end Lev;

   function To_S (W : Word; N : Length) return String is
      R : String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Character'Val (Character'Pos ('a') + W (I));
      end loop;
      return R;
   end To_S;
   L, R : Word;
begin
   for LN in Length loop
      for RN in Length loop
         for K in 1 .. 150 loop
            for I in 1 .. 4 loop
               L (I) := Next (0, (if K mod 2 = 0 then 2 else 25));
               R (I) := Next (0, (if K mod 2 = 0 then 2 else 25));
            end loop;
            Report (Distance (L, R, LN, RN) = Lev (To_S (L, LN), To_S (R, RN)),
                    "random" & LN'Image & RN'Image);
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive Levenshtein reference)");
end Own_Checks;

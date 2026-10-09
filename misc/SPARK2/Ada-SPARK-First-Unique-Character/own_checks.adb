pragma Ada_2022;
--  Own checks for First-Unique-Character (V&V sweep, agent A3, 2026-10-09;
--  see tests/SOURCES.txt). Reference: one pass fills a 256-entry histogram
--  of the characters, a second pass returns the first position whose
--  character occurs once, else 0 (a different method from the code's
--  pairwise count). Inputs:
--  * every 8-character text over 'a' .. 'c' (6,561) and over 'a' .. 'd'
--    (65,536);
--  * 20,000 seeded random texts over all 256 characters, half of them
--    drawn from a 3-character pool so that repeats are common.
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with First_Unique_Character; use First_Unique_Character;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-First-Unique-Character";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Reference (T : Text_Array) return Index_Or_Zero is
      Hist : array (Character) of Natural := [others => 0];
   begin
      for C of T loop
         Hist (C) := Hist (C) + 1;
      end loop;
      for I in T'Range loop
         if Hist (T (I)) = 1 then
            return I;
         end if;
      end loop;
      return 0;
   end Reference;

   function Img (T : Text_Array) return String is
      S : String (1 .. Length);
   begin
      for I in T'Range loop
         S (I) := T (I);
      end loop;
      return S;
   end Img;

   procedure One (T : Text_Array) is
   begin
      Report (First_Unique (T) = Reference (T), "First_Unique " & Img (T));
   end One;

   procedure Exhaustive (Letters : Positive) is
      T : Text_Array;
      K : Natural;
   begin
      for Code in 0 .. Letters ** Length - 1 loop
         K := Code;
         for I in T'Range loop
            T (I) := Character'Val (Character'Pos ('a') + K mod Letters);
            K := K / Letters;
         end loop;
         One (T);
      end loop;
   end Exhaustive;
begin
   Exhaustive (3);
   Exhaustive (4);
   for R in 1 .. 20_000 loop
      declare
         T : Text_Array;
      begin
         for C of T loop
            C := (if R mod 2 = 0 then Character'Val (Next mod 256)
                  else Character'Val (Character'Pos ('x') + Next mod 3));
         end loop;
         One (T);
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;

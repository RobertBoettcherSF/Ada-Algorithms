--  Own checks (see tests/SOURCES.txt). Assume String_Metrics is wrong or does
--  nothing; compare it with references that use a different method:
--  * Levenshtein / OSA: the recursive definitions, evaluated top-down
--    without a table, on every pair of strings over {a, b, c} up to length 4;
--  * Hamming: a plain count of differing positions;
--  * Dice: unique bigram sets built by testing every bigram over the alphabet
--    for presence (substring search), not by scanning windows;
--  * Normalized Levenshtein: 1 - own distance / max length;
--  * Jaro-Winkler: properties (range, symmetry, identity, no shared letter).
pragma Ada_2022;
with Ada.Text_IO;
with String_Metrics; use String_Metrics;

procedure Own_Checks is
   Alpha : constant String := "abc";
   subtype Str_Index is Natural range 0 .. 120;  --  1 + 3 + 9 + 27 + 81 strings
   Checked : Natural := 0;

   function Nth (K : Str_Index) return String is
      Len  : Natural := 0;
      Base : Natural := 0;
      Size : Natural := 1;
   begin
      while K >= Base + Size loop
         Base := Base + Size;
         Size := Size * Alpha'Length;
         Len  := Len + 1;
      end loop;
      declare
         R : String (1 .. Len);
         V : Natural := K - Base;
      begin
         for I in reverse R'Range loop
            R (I) := Alpha (Alpha'First + V mod Alpha'Length);
            V := V / Alpha'Length;
         end loop;
         return R;
      end;
   end Nth;

   function Min3 (X, Y, Z : Natural) return Natural is
     (Natural'Min (X, Natural'Min (Y, Z)));

   --  Recursive definition on prefixes A (A'First .. A'First + I - 1).
   function Ref_Lev (A, B : String; I, J : Natural) return Natural is
   begin
      if I = 0 then
         return J;
      elsif J = 0 then
         return I;
      end if;
      return Min3 (Ref_Lev (A, B, I - 1, J) + 1,
                   Ref_Lev (A, B, I, J - 1) + 1,
                   Ref_Lev (A, B, I - 1, J - 1)
                     + (if A (A'First + I - 1) = B (B'First + J - 1) then 0 else 1));
   end Ref_Lev;

   function Ref_OSA (A, B : String; I, J : Natural) return Natural is
      D : Natural;
   begin
      if I = 0 then
         return J;
      elsif J = 0 then
         return I;
      end if;
      D := Min3 (Ref_OSA (A, B, I - 1, J) + 1,
                 Ref_OSA (A, B, I, J - 1) + 1,
                 Ref_OSA (A, B, I - 1, J - 1)
                   + (if A (A'First + I - 1) = B (B'First + J - 1) then 0 else 1));
      if I >= 2 and then J >= 2
        and then A (A'First + I - 1) = B (B'First + J - 2)
        and then A (A'First + I - 2) = B (B'First + J - 1)
      then
         D := Natural'Min (D, Ref_OSA (A, B, I - 2, J - 2) + 1);
      end if;
      return D;
   end Ref_OSA;

   function Contains (S : String; X, Y : Character) return Boolean is
   begin
      for I in S'First .. S'Last - 1 loop
         if S (I) = X and then S (I + 1) = Y then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Ref_Dice (A, B : String) return Float is
      TA, TB, Both : Natural := 0;
   begin
      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;
      for X of Alpha loop
         for Y of Alpha loop
            if Contains (A, X, Y) then TA := TA + 1; end if;
            if Contains (B, X, Y) then TB := TB + 1; end if;
            if Contains (A, X, Y) and then Contains (B, X, Y) then Both := Both + 1; end if;
         end loop;
      end loop;
      if TA + TB = 0 then
         return 0.0;
      end if;
      return 2.0 * Float (Both) / Float (TA + TB);
   end Ref_Dice;

   procedure Fail (What, A, B : String; Got, Want : String) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " (""" & A & """, """ & B
                            & """) gave " & Got & ", reference " & Want);
      raise Program_Error;
   end Fail;

   Eps : constant Float := 1.0E-5;
begin
   for KA in Str_Index loop
      for KB in Str_Index loop
         declare
            A  : constant String := Nth (KA);
            B  : constant String := Nth (KB);
            RL : constant Natural := Ref_Lev (A, B, A'Length, B'Length);
            RO : constant Natural := Ref_OSA (A, B, A'Length, B'Length);
            ML : constant Natural := Natural'Max (A'Length, B'Length);
            RN : constant Float := (if ML = 0 then 1.0 else 1.0 - Float (RL) / Float (ML));
            JW, JWr : Float;
            Shared  : Boolean := False;
         begin
            if Levenshtein (A, B) /= RL then
               Fail ("Levenshtein", A, B, Levenshtein (A, B)'Image, RL'Image);
            end if;
            if Damerau_Levenshtein_OSA (A, B) /= RO then
               Fail ("OSA", A, B, Damerau_Levenshtein_OSA (A, B)'Image, RO'Image);
            end if;
            if abs (Normalized_Levenshtein_Similarity (A, B) - RN) > Eps then
               Fail ("Normalized_Levenshtein", A, B,
                     Normalized_Levenshtein_Similarity (A, B)'Image, RN'Image);
            end if;
            if abs (Dice_Bigram (A, B) - Ref_Dice (A, B)) > Eps then
               Fail ("Dice_Bigram", A, B, Dice_Bigram (A, B)'Image, Ref_Dice (A, B)'Image);
            end if;
            if A'Length = B'Length then
               declare
                  H : Natural := 0;
               begin
                  for I in 0 .. A'Length - 1 loop
                     if A (A'First + I) /= B (B'First + I) then H := H + 1; end if;
                  end loop;
                  if Hamming (A, B) /= H then
                     Fail ("Hamming", A, B, Hamming (A, B)'Image, H'Image);
                  end if;
               end;
            end if;
            JW  := Jaro_Winkler_Similarity (A, B);
            JWr := Jaro_Winkler_Similarity (B, A);
            for C of A loop
               for D of B loop
                  Shared := Shared or else C = D;
               end loop;
            end loop;
            if JW < 0.0 or else JW > 1.0 + Eps or else abs (JW - JWr) > Eps
              or else (A = B and then abs (JW - 1.0) > Eps)
              or else (A /= B and then JW > 1.0 - Eps)
              or else (A'Length + B'Length > 0 and then not Shared and then JW > Eps)
            then
               Fail ("Jaro_Winkler properties", A, B, JW'Image, "in [0,1], symmetric, 1 iff equal, 0 without shared letter");
            end if;
            Checked := Checked + 1;
         end;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " string pairs (recursive edit distances, bigram sets by presence, counts)");
end Own_Checks;

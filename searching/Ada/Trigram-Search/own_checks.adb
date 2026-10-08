--  Own checks (see tests/SOURCES.txt). Assume Trigram_Search is wrong or does
--  nothing; compare every function with references that use a different
--  method: trigram sets are found by testing each of the 8 trigrams over
--  {a, b} for presence (character compares at each position) instead of
--  collecting and de-duplicating windows. All pairs of strings over {a, b}
--  of length 0 .. 7 (repeats and overlaps are common); the second argument is
--  also passed as a slice whose 'First is not 1.
pragma Ada_2022;
with Ada.Text_IO;
with Trigram_Search; use Trigram_Search;

procedure Own_Checks is
   Alpha : constant String := "ab";
   subtype Str_Index is Natural range 0 .. 254;  --  2**8 - 1 strings of length 0 .. 7
   subtype Tri_Index is Natural range 0 .. 7;
   Checked : Natural := 0;
   Eps : constant Float := 1.0E-5;

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

   function Tri (T : Tri_Index) return String is
     [Alpha (1 + T / 4), Alpha (1 + T / 2 mod 2), Alpha (1 + T mod 2)];

   function Has (S : String; T : Tri_Index) return Boolean is
      W : constant String := Tri (T);
   begin
      for I in S'First .. S'Last - 2 loop
         if S (I) = W (1) and then S (I + 1) = W (2) and then S (I + 2) = W (3) then
            return True;
         end if;
      end loop;
      return False;
   end Has;

   function Ref_Unique (S : String) return Natural is
      N : Natural := 0;
   begin
      for T in Tri_Index loop
         if Has (S, T) then N := N + 1; end if;
      end loop;
      return N;
   end Ref_Unique;

   procedure Fail (What, A, B, Got, Want : String) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " (""" & A & """, """ & B
                            & """) gave " & Got & ", reference " & Want);
      raise Program_Error;
   end Fail;

   function Rejects_Bad_Tri (Tri_Arg : String) return Boolean is
   begin
      return Has_Trigram ("abcabc", Tri_Arg) and then False;
   exception
      when Invalid_Argument => return True;
   end Rejects_Bad_Tri;
begin
   for KA in Str_Index loop
      declare
         A : constant String := Nth (KA);
      begin
         if Trigram_Count (A) /= Natural'Max (0, A'Length - 2) then
            Fail ("Trigram_Count", A, "", Trigram_Count (A)'Image, Natural'Max (0, A'Length - 2)'Image);
         end if;
         if Unique_Trigram_Count (A) /= Ref_Unique (A) then
            Fail ("Unique_Trigram_Count", A, "", Unique_Trigram_Count (A)'Image, Ref_Unique (A)'Image);
         end if;
         for T in Tri_Index loop
            if Has_Trigram (A, Tri (T)) /= Has (A, T) then
               Fail ("Has_Trigram", A, Tri (T), Has_Trigram (A, Tri (T))'Image, Has (A, T)'Image);
            end if;
         end loop;
         for KB in Str_Index loop
            declare
               B0  : constant String := 'x' & Nth (KB);
               B   : String renames B0 (2 .. B0'Last);   --  'First = 2
               S   : Natural := 0;
               Sub : Boolean := True;
               Ref : Float;
            begin
               for T in Tri_Index loop
                  if Has (A, T) and then Has (B, T) then S := S + 1; end if;
                  if Has (B, T) and then not Has (A, T) then Sub := False; end if;
               end loop;
               Ref := (if A'Length = 0 and then B'Length = 0 then 1.0
                       elsif A'Length < 3 or else B'Length < 3 then 0.0
                       else 2.0 * Float (S) / Float (Ref_Unique (A) + Ref_Unique (B)));
               if Shared_Trigrams (A, B) /= S then
                  Fail ("Shared_Trigrams", A, B, Shared_Trigrams (A, B)'Image, S'Image);
               end if;
               if abs (Dice_Coefficient (A, B) - Ref) > Eps then
                  Fail ("Dice_Coefficient", A, B, Dice_Coefficient (A, B)'Image, Ref'Image);
               end if;
               if Contains_Trigram (A, B) /= Sub then
                  Fail ("Contains_Trigram", A, B, Contains_Trigram (A, B)'Image, Sub'Image);
               end if;
               Checked := Checked + 1;
            end;
         end loop;
      end;
   end loop;
   if not (Rejects_Bad_Tri ("ab") and then Rejects_Bad_Tri ("abca") and then Rejects_Bad_Tri ("")) then
      Fail ("Has_Trigram rejects Tri'Length /= 3", "abcabc", "", "no raise", "Invalid_Argument");
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " string pairs (trigram sets by presence over {a, b}, lengths 0 .. 7)");
end Own_Checks;

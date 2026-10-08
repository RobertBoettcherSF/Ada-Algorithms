--  Own checks (see tests/SOURCES.txt). Assume Dice_Coefficient is wrong or
--  does nothing; compare every function with references that use a
--  different method: bigram sets are found by testing each of the 9 bigrams
--  over {a, b, c} for presence (substring search) instead of collecting and
--  de-duplicating windows. All pairs of strings over {a, b, c} of length
--  0 .. 5; the second argument is also passed as a slice whose 'First is not 1.
pragma Ada_2022;
with Ada.Text_IO;
with Dice_Coefficient; use Dice_Coefficient;

procedure Own_Checks is
   Alpha : constant String := "abc";
   subtype Str_Index is Natural range 0 .. 363;  --  1 + 3 + 9 + 27 + 81 + 243 strings
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

   function Has (S : String; X, Y : Character) return Boolean is
   begin
      for I in S'First .. S'Last - 1 loop
         if S (I) = X and then S (I + 1) = Y then
            return True;
         end if;
      end loop;
      return False;
   end Has;

   function Ref_Unique (S : String) return Natural is
      N : Natural := 0;
   begin
      for X of Alpha loop
         for Y of Alpha loop
            if Has (S, X, Y) then N := N + 1; end if;
         end loop;
      end loop;
      return N;
   end Ref_Unique;

   function Ref_Shared (A, B : String) return Natural is
      N : Natural := 0;
   begin
      for X of Alpha loop
         for Y of Alpha loop
            if Has (A, X, Y) and then Has (B, X, Y) then N := N + 1; end if;
         end loop;
      end loop;
      return N;
   end Ref_Shared;

   procedure Fail (What, A, B, Got, Want : String) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " (""" & A & """, """ & B
                            & """) gave " & Got & ", reference " & Want);
      raise Program_Error;
   end Fail;
begin
   for KA in Str_Index loop
      declare
         A : constant String := Nth (KA);
      begin
         if Bigram_Count (A) /= Natural'Max (0, A'Length - 1) then
            Fail ("Bigram_Count", A, "", Bigram_Count (A)'Image, Natural'Max (0, A'Length - 1)'Image);
         end if;
         if Unique_Bigram_Count (A) /= Ref_Unique (A) then
            Fail ("Unique_Bigram_Count", A, "", Unique_Bigram_Count (A)'Image, Ref_Unique (A)'Image);
         end if;
         for KB in Str_Index loop
            declare
               B0  : constant String := 'x' & Nth (KB);
               B   : String renames B0 (2 .. B0'Last);   --  'First = 2
               S   : constant Natural := Ref_Shared (A, B);
               D   : constant Natural := Ref_Unique (A) + Ref_Unique (B);
               Ref : constant Float :=
                 (if A'Length = 0 and then B'Length = 0 then 1.0
                  elsif D = 0 then 0.0
                  else 2.0 * Float (S) / Float (D));
            begin
               if Shared_Bigrams (A, B) /= S then
                  Fail ("Shared_Bigrams", A, B, Shared_Bigrams (A, B)'Image, S'Image);
               end if;
               if abs (Coefficient (A, B) - Ref) > Eps then
                  Fail ("Coefficient", A, B, Coefficient (A, B)'Image, Ref'Image);
               end if;
               Checked := Checked + 1;
            end;
         end loop;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " string pairs (bigram sets by presence over {a, b, c}, lengths 0 .. 5)");
end Own_Checks;

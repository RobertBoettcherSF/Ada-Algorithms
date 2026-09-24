--  Boyer_Moore_Horspool body — Horspool skip table (bad-character only).
--  Algorithm after Horspool (1980) / Wikipedia Boyer–Moore–Horspool and
--  Charras & Lecroq HORSPOOL
--  http://www-igm.univ-mlv.fr/~lecroq/string/node18.html

pragma Ada_2022;

package body Boyer_Moore_Horspool is

   function Ord (C : Character) return Alphabet_Index is
   begin
      return Character'Pos (C);
   end Ord;

   procedure Check_Bounds (Pattern, Text : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;
   end Check_Bounds;

   procedure Check_Pattern (Pattern : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
   end Check_Pattern;

   ---------------------------------------------------------------------------
   -- Horspool skip / bad-character table
   ---------------------------------------------------------------------------

   function Build_Bad_Character (Pattern : String) return Bad_Character_Table
   is
      M  : constant Natural := Pattern'Length;
      PF : constant Positive := Pattern'First;
      Bc : Bad_Character_Table;
   begin
      Check_Pattern (Pattern);

      for C in Alphabet_Index loop
         Bc (C) := M;
      end loop;

      --  Rightmost occurrence in x[0 .. m-2] wins (last write).
      --  The last pattern character is deliberately excluded so a match
      --  (or mismatch keyed on that slot) can still slide by the prior
      --  occurrence of the same symbol.
      for I in 0 .. M - 2 loop
         Bc (Ord (Pattern (PF + I))) := M - 1 - I;
      end loop;

      return Bc;
   end Build_Bad_Character;

   ---------------------------------------------------------------------------
   -- Naive oracle
   ---------------------------------------------------------------------------

   function Naive_Search (Pattern, Text : String) return Match_Index_Array is
      M : constant Natural := Pattern'Length;
      N : constant Natural := Text'Length;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         PF       : constant Positive := Pattern'First;
         TF       : constant Positive := Text'First;
         Ok       : Boolean;
      begin
         for Start in 0 .. N - M loop
            Ok := True;
            for K in 0 .. M - 1 loop
               if Pattern (PF + K) /= Text (TF + Start + K) then
                  Ok := False;
                  exit;
               end if;
            end loop;
            if Ok then
               Count := Count + 1;
               Buf (Count) := Start + 1;
            end if;
         end loop;
         return Buf (1 .. Count);
      end;
   end Naive_Search;

   ---------------------------------------------------------------------------
   -- Boyer–Moore–Horspool search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Bm_Bc    : constant Bad_Character_Table :=
                      Build_Bad_Character (Pattern);
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         J        : Natural := 0;
         I        : Integer;
         C        : Character;
      begin
         while J <= N - M loop
            --  Character under the last pattern position drives the shift.
            C := Text (TF + J + M - 1);

            --  Right-to-left compare of the current window.
            I := M - 1;
            while I >= 0
              and then Pattern (PF + I) = Text (TF + J + I)
            loop
               I := I - 1;
            end loop;

            if I < 0 then
               Count := Count + 1;
               Buf (Count) := J + 1;
            end if;

            --  Always advance by Horspool skip of C (no good-suffix).
            J := J + Bm_Bc (Ord (C));
         end loop;

         return Buf (1 .. Count);
      end;
   end Search;

end Boyer_Moore_Horspool;

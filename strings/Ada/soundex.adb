--  Soundex body — American Soundex (NARA; H/W do not separate, vowels/Y do).

pragma Ada_2022;

package body Soundex is

   ---------------------------------------------------------------------------
   -- Letter helpers
   ---------------------------------------------------------------------------

   function Is_Letter (C : Character) return Boolean is
   begin
      return (C in 'A' .. 'Z') or else (C in 'a' .. 'z');
   end Is_Letter;

   function To_Upper (C : Character) return Character is
   begin
      if C in 'a' .. 'z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('a') + Character'Pos ('A'));
      else
         return C;
      end if;
   end To_Upper;

   --  True for H/W (and h/w): dropped, but do *not* reset Prev, so equal
   --  consonant codes on either side still collapse (Ashcraft → A261).
   function Is_HW (C : Character) return Boolean is
      U : constant Character := To_Upper (C);
   begin
      return U = 'H' or else U = 'W';
   end Is_HW;

   --  American Soundex consonant / vowel map. Non-letters must not be
   --  passed here (caller filters). Returns 0 for A E I O U H W Y.
   function Map_Code (C : Character) return Natural is
      U : constant Character := To_Upper (C);
   begin
      case U is
         when 'B' | 'F' | 'P' | 'V' =>
            return 1;
         when 'C' | 'G' | 'J' | 'K' | 'Q' | 'S' | 'X' | 'Z' =>
            return 2;
         when 'D' | 'T' =>
            return 3;
         when 'L' =>
            return 4;
         when 'M' | 'N' =>
            return 5;
         when 'R' =>
            return 6;
         when others =>
            --  A E I O U H W Y
            return 0;
      end case;
   end Map_Code;

   function Digit_Char (Code : Natural) return Character is
     (Character'Val (Character'Pos ('0') + Code));

   ---------------------------------------------------------------------------
   -- Encode
   ---------------------------------------------------------------------------

   function Encode (Name : String) return Code_String is
      Result     : Code_String := "0000";
      Digits_Set : Natural := 0;  -- how many of the 3 digit slots filled
      Prev       : Natural := 0;
      First_Seen : Boolean := False;
   begin
      if Name'Length = 0 or else Name'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      for I in Name'Range loop
         declare
            C : constant Character := Name (I);
         begin
            if Is_Letter (C) then
               if not First_Seen then
                  Result (1) := To_Upper (C);
                  Prev := Map_Code (C);
                  First_Seen := True;
               elsif Digits_Set < 3 then
                  declare
                     Code : constant Natural := Map_Code (C);
                  begin
                     if Code = 0 then
                        --  Dropped letters. H/W leave Prev unchanged so
                        --  equal codes across H/W collapse. Vowels and Y
                        --  reset Prev so equal codes across a vowel are
                        --  both kept (NARA / Wikipedia American Soundex).
                        if not Is_HW (C) then
                           Prev := 0;
                        end if;
                     elsif Code /= Prev then
                        Digits_Set := Digits_Set + 1;
                        Result (1 + Digits_Set) := Digit_Char (Code);
                        Prev := Code;
                     else
                        --  Code = Prev: adjacent duplicate, skip.
                        null;
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;

      if not First_Seen then
         raise Invalid_Argument;
      end if;

      return Result;
   end Encode;

   ---------------------------------------------------------------------------
   -- Codes_Match
   ---------------------------------------------------------------------------

   function Codes_Match (A, B : String) return Boolean is
   begin
      return Encode (A) = Encode (B);
   end Codes_Match;

end Soundex;

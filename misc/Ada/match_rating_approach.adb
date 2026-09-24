--  Match Rating Approach body — Western Airlines / Wikipedia MRA encoding
--  and Apache Commons Codec-compatible L→R / R→L similarity comparison.

pragma Ada_2022;

package body Match_Rating_Approach is

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

   --  MRA vowels are A E I O U only. Y is treated as a consonant.
   function Is_Vowel (C : Character) return Boolean is
   begin
      return C = 'A' or else C = 'E' or else C = 'I'
        or else C = 'O' or else C = 'U';
   end Is_Vowel;

   ---------------------------------------------------------------------------
   -- Strip / encode helpers
   ---------------------------------------------------------------------------

   subtype Name_Buffer is String (1 .. Max_Len);

   procedure Strip_Letters
     (Name : String;
      Buf  : out Name_Buffer;
      Len  : out Natural)
   is
   begin
      Len := 0;
      for I in Name'Range loop
         if Is_Letter (Name (I)) then
            Len := Len + 1;
            Buf (Len) := To_Upper (Name (I));
         end if;
      end loop;
   end Strip_Letters;

   --  Delete vowels unless the vowel begins the (stripped) word.
   --  Matches Commons removeVowels: drop every A/E/I/O/U, then re-prefix
   --  the original first letter when it was a vowel.
   procedure Remove_Vowels (Buf : in out Name_Buffer; Len : in out Natural) is
      First       : Character;
      Out_Buf     : Name_Buffer;
      Out_Len     : Natural := 0;
      First_Vowel : Boolean;
   begin
      if Len = 0 then
         return;
      end if;
      First := Buf (1);
      First_Vowel := Is_Vowel (First);
      for I in 1 .. Len loop
         if not Is_Vowel (Buf (I)) then
            Out_Len := Out_Len + 1;
            Out_Buf (Out_Len) := Buf (I);
         end if;
      end loop;
      if First_Vowel then
         Buf (1) := First;
         Buf (2 .. Out_Len + 1) := Out_Buf (1 .. Out_Len);
         Len := Out_Len + 1;
      else
         Buf (1 .. Out_Len) := Out_Buf (1 .. Out_Len);
         Len := Out_Len;
      end if;
   end Remove_Vowels;

   --  Collapse adjacent identical letters (double consonants / YY / etc.).
   procedure Collapse_Doubles
     (Buf : in out Name_Buffer; Len : in out Natural)
   is
      Out_Buf : Name_Buffer;
      Out_Len : Natural := 0;
   begin
      if Len = 0 then
         return;
      end if;
      Out_Len := 1;
      Out_Buf (1) := Buf (1);
      for I in 2 .. Len loop
         if Buf (I) /= Out_Buf (Out_Len) then
            Out_Len := Out_Len + 1;
            Out_Buf (Out_Len) := Buf (I);
         end if;
      end loop;
      Buf (1 .. Out_Len) := Out_Buf (1 .. Out_Len);
      Len := Out_Len;
   end Collapse_Doubles;

   procedure Truncate_First3_Last3
     (Buf : in out Name_Buffer; Len : in out Natural)
   is
      Combined : String (1 .. Max_Code_Len);
   begin
      if Len <= Max_Code_Len then
         return;
      end if;
      Combined (1 .. 3) := Buf (1 .. 3);
      Combined (4 .. 6) := Buf (Len - 2 .. Len);
      Buf (1 .. Max_Code_Len) := Combined;
      Len := Max_Code_Len;
   end Truncate_First3_Last3;

   function Encode (Name : String) return String is
      Buf : Name_Buffer;
      Len : Natural;
   begin
      if Name'Length = 0 or else Name'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      Strip_Letters (Name, Buf, Len);
      if Len = 0 then
         raise Invalid_Argument;
      end if;

      Remove_Vowels (Buf, Len);
      Collapse_Doubles (Buf, Len);
      Truncate_First3_Last3 (Buf, Len);

      return Buf (1 .. Len);
   end Encode;

   function Minimum_Rating (Sum_Length : Natural) return Natural is
   begin
      if Sum_Length <= 4 then
         return 5;
      elsif Sum_Length <= 7 then
         return 4;
      elsif Sum_Length <= 11 then
         return 3;
      elsif Sum_Length = 12 then
         return 2;
      else
         return 1;
      end if;
   end Minimum_Rating;

   --  Commons Codec leftToRightThenRightToLeftProcessing:
   --  compare ORIGINAL characters at offset I from the left and from the
   --  right; blank matches in working copies; rating = |6 - longer_residual|.
   function Rating_Of_Encodings (EA, EB : String) return Natural is
      --  Working copies (1-based) for blanking; comparisons use EA / EB.
      WA : String (1 .. EA'Length);
      WB : String (1 .. EB'Length);
      A_Len : constant Natural := EA'Length;
      B_Len : constant Natural := EB'Length;
      Residual_A : Natural := 0;
      Residual_B : Natural := 0;
      Longer     : Natural;
   begin
      if A_Len = 0 and then B_Len = 0 then
         return 6;
      end if;

      WA := EA;
      WB := EB;

      declare
         B_Size : constant Integer := Integer (B_Len) - 1;
      begin
         for I in 0 .. Integer (A_Len) - 1 loop
            exit when I > B_Size;

            --  Left-to-right at offset I (original characters)
            if EA (EA'First + I) = EB (EB'First + I) then
               WA (1 + I) := ' ';
               WB (1 + I) := ' ';
            end if;

            --  Right-to-left at offset I (from the ends)
            if EA (EA'Last - I) = EB (EB'Last - I) then
               WA (A_Len - I) := ' ';
               WB (B_Len - I) := ' ';
            end if;
         end loop;
      end;

      for I in WA'Range loop
         if WA (I) /= ' ' then
            Residual_A := Residual_A + 1;
         end if;
      end loop;
      for I in WB'Range loop
         if WB (I) /= ' ' then
            Residual_B := Residual_B + 1;
         end if;
      end loop;

      Longer := Natural'Max (Residual_A, Residual_B);
      return abs (6 - Longer);
   end Rating_Of_Encodings;

   function Similarity_Rating (A, B : String) return Natural is
      EA : constant String := Encode (A);
      EB : constant String := Encode (B);
   begin
      if abs (Integer (EA'Length) - Integer (EB'Length)) >= 3 then
         return 0;
      end if;
      return Rating_Of_Encodings (EA, EB);
   end Similarity_Rating;

   function Compare (A, B : String) return Boolean is
      EA  : constant String := Encode (A);
      EB  : constant String := Encode (B);
      Sum : Natural;
      Min : Natural;
      Rat : Natural;
   begin
      if abs (Integer (EA'Length) - Integer (EB'Length)) >= 3 then
         return False;
      end if;
      Sum := EA'Length + EB'Length;
      Min := Minimum_Rating (Sum);
      Rat := Rating_Of_Encodings (EA, EB);
      return Rat >= Min;
   end Compare;

end Match_Rating_Approach;

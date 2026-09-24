--  Phonetic_Algorithms body — inline American Soundex, original NYSIIS,
--  original Metaphone, and MRA encode. No `with` of sibling packages.

pragma Ada_2022;

package body Phonetic_Algorithms is

   ---------------------------------------------------------------------------
   -- Shared letter helpers
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

   function Is_Vowel_AEIOU (C : Character) return Boolean is
   begin
      return C = 'A' or else C = 'E' or else C = 'I'
        or else C = 'O' or else C = 'U';
   end Is_Vowel_AEIOU;

   subtype Name_Buffer is String (1 .. Max_Len);

   ---------------------------------------------------------------------------
   -- American Soundex
   ---------------------------------------------------------------------------

   function Is_HW (C : Character) return Boolean is
      U : constant Character := To_Upper (C);
   begin
      return U = 'H' or else U = 'W';
   end Is_HW;

   function Soundex_Map (C : Character) return Natural is
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
            return 0;
      end case;
   end Soundex_Map;

   function Digit_Char (Code : Natural) return Character is
     (Character'Val (Character'Pos ('0') + Code));

   function Soundex (Name : String) return String is
      Result     : String (1 .. 4) := "0000";
      Digits_Set : Natural := 0;
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
                  Prev := Soundex_Map (C);
                  First_Seen := True;
               elsif Digits_Set < 3 then
                  declare
                     Code : constant Natural := Soundex_Map (C);
                  begin
                     if Code = 0 then
                        if not Is_HW (C) then
                           Prev := 0;
                        end if;
                     elsif Code /= Prev then
                        Digits_Set := Digits_Set + 1;
                        Result (1 + Digits_Set) := Digit_Char (Code);
                        Prev := Code;
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
   end Soundex;

   function Codes_Match_Soundex (A, B : String) return Boolean is
   begin
      return Soundex (A) = Soundex (B);
   end Codes_Match_Soundex;

   ---------------------------------------------------------------------------
   -- Original / strict NYSIIS (truncate to 6)
   ---------------------------------------------------------------------------

   NYSIIS_Max_Code : constant Positive := 6;

   function Starts_With
     (Buf : Name_Buffer; Len : Natural; Prefix : String) return Boolean
   is
   begin
      if Prefix'Length = 0 or else Len < Prefix'Length then
         return False;
      end if;
      return Buf (1 .. Prefix'Length) = Prefix;
   end Starts_With;

   function Ends_With
     (Buf : Name_Buffer; Len : Natural; Suffix : String) return Boolean
   is
   begin
      if Suffix'Length = 0 or else Len < Suffix'Length then
         return False;
      end if;
      return Buf (Len - Suffix'Length + 1 .. Len) = Suffix;
   end Ends_With;

   procedure NYSIIS_Apply_Prefix (Buf : in out Name_Buffer; Len : Natural) is
   begin
      if Starts_With (Buf, Len, "MAC") then
         Buf (1 .. 3) := "MCC";
      elsif Starts_With (Buf, Len, "KN") then
         Buf (1 .. 2) := "NN";
      elsif Starts_With (Buf, Len, "K") then
         Buf (1) := 'C';
      elsif Starts_With (Buf, Len, "PH") or else Starts_With (Buf, Len, "PF")
      then
         Buf (1 .. 2) := "FF";
      elsif Starts_With (Buf, Len, "SCH") then
         Buf (1 .. 3) := "SSS";
      end if;
   end NYSIIS_Apply_Prefix;

   procedure NYSIIS_Apply_Suffix
     (Buf : in out Name_Buffer; Len : in out Natural)
   is
   begin
      if Len < 2 then
         return;
      end if;
      if Ends_With (Buf, Len, "EE") or else Ends_With (Buf, Len, "IE") then
         Buf (Len - 1) := 'Y';
         Len := Len - 1;
      elsif Ends_With (Buf, Len, "DT")
        or else Ends_With (Buf, Len, "RT")
        or else Ends_With (Buf, Len, "RD")
        or else Ends_With (Buf, Len, "NT")
        or else Ends_With (Buf, Len, "ND")
      then
         Buf (Len - 1) := 'D';
         Len := Len - 1;
      end if;
   end NYSIIS_Apply_Suffix;

   procedure NYSIIS_Transcode_At
     (Buf : in out Name_Buffer;
      Len : Natural;
      I   : Positive)
   is
      Prev  : constant Character := Buf (I - 1);
      Curr  : constant Character := Buf (I);
      Nextc : constant Character :=
        (if I < Len then Buf (I + 1) else ' ');
      Anext : constant Character :=
        (if I + 1 < Len then Buf (I + 2) else ' ');
   begin
      if Curr = 'E' and then Nextc = 'V' then
         Buf (I) := 'A';
         if I < Len then
            Buf (I + 1) := 'F';
         end if;
         return;
      end if;

      if Is_Vowel_AEIOU (Curr) then
         Buf (I) := 'A';
         return;
      end if;

      case Curr is
         when 'Q' =>
            Buf (I) := 'G';
            return;
         when 'Z' =>
            Buf (I) := 'S';
            return;
         when 'M' =>
            Buf (I) := 'N';
            return;
         when 'K' =>
            if Nextc = 'N' then
               Buf (I) := 'N';
               if I < Len then
                  Buf (I + 1) := 'N';
               end if;
            else
               Buf (I) := 'C';
            end if;
            return;
         when others =>
            null;
      end case;

      if Curr = 'S' and then Nextc = 'C' and then Anext = 'H' then
         Buf (I) := 'S';
         if I < Len then
            Buf (I + 1) := 'S';
         end if;
         if I + 1 < Len then
            Buf (I + 2) := 'S';
         end if;
         return;
      end if;

      if Curr = 'P' and then Nextc = 'H' then
         Buf (I) := 'F';
         if I < Len then
            Buf (I + 1) := 'F';
         end if;
         return;
      end if;

      if Curr = 'H'
        and then (not Is_Vowel_AEIOU (Prev)
                  or else not Is_Vowel_AEIOU (Nextc))
      then
         Buf (I) := Prev;
         return;
      end if;

      if Curr = 'W' and then Is_Vowel_AEIOU (Prev) then
         Buf (I) := Prev;
         return;
      end if;
   end NYSIIS_Transcode_At;

   function NYSIIS (Name : String) return String is
      Buf     : Name_Buffer := [others => ' '];
      Len     : Natural := 0;
      Key     : String (1 .. Max_Len);
      Key_Len : Natural := 0;
   begin
      if Name'Length = 0 or else Name'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      for I in Name'Range loop
         if Is_Letter (Name (I)) then
            Len := Len + 1;
            Buf (Len) := To_Upper (Name (I));
         end if;
      end loop;

      if Len = 0 then
         raise Invalid_Argument;
      end if;

      NYSIIS_Apply_Prefix (Buf, Len);
      NYSIIS_Apply_Suffix (Buf, Len);

      Key_Len := 1;
      Key (1) := Buf (1);

      for I in 2 .. Len loop
         NYSIIS_Transcode_At (Buf, Len, I);
         if Buf (I) /= Buf (I - 1) then
            Key_Len := Key_Len + 1;
            Key (Key_Len) := Buf (I);
         end if;
      end loop;

      if Key_Len > 1 and then Key (Key_Len) = 'S' then
         Key_Len := Key_Len - 1;
      end if;
      if Key_Len > 2
        and then Key (Key_Len - 1) = 'A'
        and then Key (Key_Len) = 'Y'
      then
         Key (Key_Len - 1) := 'Y';
         Key_Len := Key_Len - 1;
      end if;
      if Key_Len > 1 and then Key (Key_Len) = 'A' then
         Key_Len := Key_Len - 1;
      end if;

      if Key_Len > NYSIIS_Max_Code then
         Key_Len := NYSIIS_Max_Code;
      end if;

      return Key (1 .. Key_Len);
   end NYSIIS;

   function Codes_Match_NYSIIS (A, B : String) return Boolean is
   begin
      return NYSIIS (A) = NYSIIS (B);
   end Codes_Match_NYSIIS;

   ---------------------------------------------------------------------------
   -- Original Metaphone (truncate to 4; digit 0 for TH)
   ---------------------------------------------------------------------------

   Metaphone_Max_Code : constant Positive := 4;

   function Is_Front_V (C : Character) return Boolean is
   begin
      return C = 'E' or else C = 'I' or else C = 'Y';
   end Is_Front_V;

   function Is_Varson (C : Character) return Boolean is
   begin
      return C = 'C' or else C = 'S' or else C = 'P'
        or else C = 'T' or else C = 'G';
   end Is_Varson;

   function Region_Match
     (Buf  : Name_Buffer;
      Len  : Natural;
      Pos  : Positive;
      Test : String) return Boolean
   is
   begin
      if Test'Length = 0 then
         return False;
      end if;
      if Pos + Test'Length - 1 > Len then
         return False;
      end if;
      return Buf (Pos .. Pos + Test'Length - 1) = Test;
   end Region_Match;

   function Metaphone (Word : String) return String is
      Buf      : Name_Buffer := [others => ' '];
      Len      : Natural := 0;
      Code     : String (1 .. Metaphone_Max_Code);
      Code_Len : Natural := 0;
      N        : Natural := 0;
      Symb     : Character;
      Hard     : Boolean;

      procedure Append (C : Character) is
      begin
         if Code_Len < Metaphone_Max_Code then
            Code_Len := Code_Len + 1;
            Code (Code_Len) := C;
         end if;
      end Append;

      function Prev_Is (C : Character) return Boolean is
      begin
         return N > 0 and then Buf (N) = C;
      end Prev_Is;

      function Next_Is (C : Character) return Boolean is
      begin
         return N + 1 < Len and then Buf (N + 2) = C;
      end Next_Is;

      function Is_Last return Boolean is
      begin
         return N + 1 = Len;
      end Is_Last;

      function Vowel_At (I : Natural) return Boolean is
      begin
         return I < Len and then Is_Vowel_AEIOU (Buf (I + 1));
      end Vowel_At;

      function Region (Test : String) return Boolean is
      begin
         return Region_Match (Buf, Len, N + 1, Test);
      end Region;

   begin
      if Word'Length = 0 or else Word'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      for I in Word'Range loop
         if Is_Letter (Word (I)) then
            Len := Len + 1;
            Buf (Len) := To_Upper (Word (I));
         end if;
      end loop;

      if Len = 0 then
         raise Invalid_Argument;
      end if;

      if Len = 1 then
         return Buf (1 .. 1);
      end if;

      declare
         First      : constant Character := Buf (1);
         Second     : constant Character := Buf (2);
         Drop_First : Boolean := False;
      begin
         if (First = 'K' or else First = 'G' or else First = 'P')
           and then Second = 'N'
         then
            Drop_First := True;
         elsif First = 'A' and then Second = 'E' then
            Drop_First := True;
         elsif First = 'W' and then Second = 'R' then
            Drop_First := True;
         elsif First = 'W' and then Second = 'H' then
            for I in 1 .. Len - 1 loop
               Buf (I) := Buf (I + 1);
            end loop;
            Len := Len - 1;
            Buf (1) := 'W';
         elsif First = 'X' then
            Buf (1) := 'S';
         end if;

         if Drop_First then
            for I in 1 .. Len - 1 loop
               Buf (I) := Buf (I + 1);
            end loop;
            Len := Len - 1;
         end if;
      end;

      if Len = 0 then
         raise Invalid_Argument;
      end if;

      while Code_Len < Metaphone_Max_Code and then N < Len loop
         Symb := Buf (N + 1);

         if Symb = 'C' or else not Prev_Is (Symb) then
            case Symb is
               when 'A' | 'E' | 'I' | 'O' | 'U' =>
                  if N = 0 then
                     Append (Symb);
                  end if;

               when 'B' =>
                  if not (Prev_Is ('M') and then Is_Last) then
                     Append (Symb);
                  end if;

               when 'C' =>
                  if Prev_Is ('S')
                    and then not Is_Last
                    and then Is_Front_V (Buf (N + 2))
                  then
                     null;
                  elsif Prev_Is ('S') and then Next_Is ('H') then
                     Append ('K');
                  elsif Region ("CIA") or else Next_Is ('H') then
                     Append ('X');
                  elsif not Is_Last and then Is_Front_V (Buf (N + 2)) then
                     Append ('S');
                  else
                     Append ('K');
                  end if;

               when 'D' =>
                  if N + 2 < Len
                    and then Next_Is ('G')
                    and then Is_Front_V (Buf (N + 3))
                  then
                     Append ('J');
                     N := N + 2;
                  else
                     Append ('T');
                  end if;

               when 'G' =>
                  if (N + 1 = Len - 1 and then Next_Is ('H'))
                    or else
                      (N + 1 < Len - 1
                       and then Next_Is ('H')
                       and then not Vowel_At (N + 2))
                  then
                     null;
                  elsif N > 0
                    and then (Region ("GN") or else Region ("GNED"))
                  then
                     null;
                  else
                     Hard := Prev_Is ('G');
                     if not Is_Last
                       and then Is_Front_V (Buf (N + 2))
                       and then not Hard
                     then
                        Append ('J');
                     else
                        Append ('K');
                     end if;
                  end if;

               when 'H' =>
                  if Is_Last then
                     null;
                  elsif N > 0 and then Is_Varson (Buf (N)) then
                     null;
                  elsif Vowel_At (N + 1) then
                     Append ('H');
                  end if;

               when 'F' | 'J' | 'L' | 'M' | 'N' | 'R' =>
                  Append (Symb);

               when 'K' =>
                  if N > 0 then
                     if not Prev_Is ('C') then
                        Append (Symb);
                     end if;
                  else
                     Append (Symb);
                  end if;

               when 'P' =>
                  if Next_Is ('H') then
                     Append ('F');
                  else
                     Append (Symb);
                  end if;

               when 'Q' =>
                  Append ('K');

               when 'S' =>
                  if Region ("SH")
                    or else Region ("SIO")
                    or else Region ("SIA")
                  then
                     Append ('X');
                  else
                     Append ('S');
                  end if;

               when 'T' =>
                  if Region ("TIA") or else Region ("TIO") then
                     Append ('X');
                  elsif Region ("TCH") then
                     null;
                  elsif Region ("TH") then
                     Append ('0');
                  else
                     Append ('T');
                  end if;

               when 'V' =>
                  Append ('F');

               when 'W' | 'Y' =>
                  if not Is_Last and then Vowel_At (N + 1) then
                     Append (Symb);
                  end if;

               when 'X' =>
                  Append ('K');
                  Append ('S');

               when 'Z' =>
                  Append ('S');

               when others =>
                  null;
            end case;
         end if;

         N := N + 1;
      end loop;

      if Code_Len = 0 then
         raise Invalid_Argument;
      end if;

      return Code (1 .. Code_Len);
   end Metaphone;

   function Codes_Match_Metaphone (A, B : String) return Boolean is
   begin
      return Metaphone (A) = Metaphone (B);
   end Codes_Match_Metaphone;

   ---------------------------------------------------------------------------
   -- Match Rating Approach encode (first3+last3, ≤6)
   ---------------------------------------------------------------------------

   MRA_Max_Code : constant Positive := 6;

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
      First_Vowel := Is_Vowel_AEIOU (First);
      for I in 1 .. Len loop
         if not Is_Vowel_AEIOU (Buf (I)) then
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
      Combined : String (1 .. MRA_Max_Code);
   begin
      if Len <= MRA_Max_Code then
         return;
      end if;
      Combined (1 .. 3) := Buf (1 .. 3);
      Combined (4 .. 6) := Buf (Len - 2 .. Len);
      Buf (1 .. MRA_Max_Code) := Combined;
      Len := MRA_Max_Code;
   end Truncate_First3_Last3;

   function Match_Rating_Encode (Name : String) return String is
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
   end Match_Rating_Encode;

end Phonetic_Algorithms;

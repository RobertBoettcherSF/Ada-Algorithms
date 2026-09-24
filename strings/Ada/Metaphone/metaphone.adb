--  Metaphone body — original Lawrence Philips Metaphone (truncate to
--  Max_Code_Len). Reference behaviour aligned with Apache Commons Codec
--  Metaphone (Brogden port); not PHP Metaphone; not Double Metaphone.

pragma Ada_2022;

package body Metaphone is

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

   function Is_Vowel_Char (C : Character) return Boolean is
   begin
      return C = 'A' or else C = 'E' or else C = 'I'
        or else C = 'O' or else C = 'U';
   end Is_Vowel_Char;

   function Is_Front_V (C : Character) return Boolean is
   begin
      return C = 'E' or else C = 'I' or else C = 'Y';
   end Is_Front_V;

   function Is_Varson (C : Character) return Boolean is
   begin
      --  VARSON = C S P T G (H silent after these)
      return C = 'C' or else C = 'S' or else C = 'P'
        or else C = 'T' or else C = 'G';
   end Is_Varson;

   ---------------------------------------------------------------------------
   -- Working-buffer helpers (1-based buffer of length Len)
   ---------------------------------------------------------------------------

   subtype Name_Buffer is String (1 .. Max_Len);

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

   ---------------------------------------------------------------------------
   -- Encode
   ---------------------------------------------------------------------------

   function Encode (Word : String) return String is
      Buf     : Name_Buffer := [others => ' '];
      Len     : Natural := 0;
      Code    : String (1 .. Max_Code_Len);
      Code_Len : Natural := 0;
      N       : Natural := 0;  -- 0-based index into Buf (1 .. Len)
      Symb    : Character;
      Hard    : Boolean;

      procedure Append (C : Character) is
      begin
         if Code_Len < Max_Code_Len then
            Code_Len := Code_Len + 1;
            Code (Code_Len) := C;
         end if;
      end Append;

      function Prev_Is (C : Character) return Boolean is
      begin
         return N > 0 and then Buf (N) = C;  -- Buf (N) is previous (1-based)
      end Prev_Is;

      function Next_Is (C : Character) return Boolean is
      begin
         return N + 1 < Len and then Buf (N + 2) = C;
      end Next_Is;

      function Is_Last return Boolean is
      begin
         return N + 1 = Len;
      end Is_Last;

      --  Is character at 0-based index I (Buf (I+1)) a vowel?
      function Vowel_At (I : Natural) return Boolean is
      begin
         return I < Len and then Is_Vowel_Char (Buf (I + 1));
      end Vowel_At;

      function Region (Test : String) return Boolean is
      begin
         return Region_Match (Buf, Len, N + 1, Test);
      end Region;

   begin
      if Word'Length = 0 or else Word'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      --  Strip non-letters and fold to upper case.
      for I in Word'Range loop
         if Is_Letter (Word (I)) then
            Len := Len + 1;
            Buf (Len) := To_Upper (Word (I));
         end if;
      end loop;

      if Len = 0 then
         raise Invalid_Argument;
      end if;

      --  Single letter is itself (Commons early return).
      if Len = 1 then
         return Buf (1 .. 1);
      end if;

      --  Prefix exceptions (KN|GN|PN|AE|WR drop first; X→S; WH→W).
      declare
         First : constant Character := Buf (1);
         Second : constant Character := Buf (2);
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
            --  WH → W : drop W, rewrite leading H as W.
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

      --  Main scan. N is 0-based; Buf is 1-based.
      while Code_Len < Max_Code_Len and then N < Len loop
         Symb := Buf (N + 1);

         --  Drop adjacent duplicates except C.
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
                     null;  --  SCI / SCE / SCY silent
                  elsif Prev_Is ('S') and then Next_Is ('H') then
                     Append ('K');  --  SCH → K
                  elsif Region ("CIA") or else Next_Is ('H') then
                     Append ('X');  --  CIA or CH → X
                  elsif not Is_Last and then Is_Front_V (Buf (N + 2)) then
                     Append ('S');  --  CI / CE / CY → S
                  else
                     Append ('K');
                  end if;

               when 'D' =>
                  if N + 2 < Len
                    and then Next_Is ('G')
                    and then Is_Front_V (Buf (N + 3))
                  then
                     Append ('J');  --  DGE / DGI / DGY
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
                     null;  --  GH silent at end or before consonant
                  elsif N > 0
                    and then (Region ("GN") or else Region ("GNED"))
                  then
                     null;  --  silent G in GN / GNED
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
                     null;  --  silent T in TCH
                  elsif Region ("TH") then
                     Append ('0');  --  TH → 0 (theta)
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
   end Encode;

   ---------------------------------------------------------------------------
   -- Codes_Match
   ---------------------------------------------------------------------------

   function Codes_Match (A, B : String) return Boolean is
   begin
      return Encode (A) = Encode (B);
   end Codes_Match;

end Metaphone;

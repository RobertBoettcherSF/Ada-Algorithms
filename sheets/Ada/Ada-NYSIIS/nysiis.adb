--  NYSIIS body — original / strict Taft NYSIIS (truncate to Max_Code_Len).
--  Reference behaviour aligned with Apache Commons Codec Nysiis (strict),
--  with trailing cleanup that never drops the first key letter (Ash → A).

pragma Ada_2022;

package body NYSIIS is

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

   function Is_Vowel (C : Character) return Boolean is
   begin
      return C = 'A' or else C = 'E' or else C = 'I'
        or else C = 'O' or else C = 'U';
   end Is_Vowel;

   ---------------------------------------------------------------------------
   -- Working-buffer helpers (1-based name buffer of length Len)
   ---------------------------------------------------------------------------

   subtype Name_Buffer is String (1 .. Max_Len);

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

   procedure Apply_Prefix (Buf : in out Name_Buffer; Len : Natural) is
   begin
      --  Order matches Apache Commons / Wikipedia: MAC, KN, K, PH|PF, SCH.
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
   end Apply_Prefix;

   procedure Apply_Suffix (Buf : in out Name_Buffer; Len : in out Natural) is
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
   end Apply_Suffix;

   --  Transcode remaining letter at position I; write result back into Buf
   --  starting at I (may overwrite 1..3 characters). Uses space as a
   --  sentinel for missing next / after-next (non-vowel).
   procedure Transcode_At
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

      if Is_Vowel (Curr) then
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
        and then (not Is_Vowel (Prev) or else not Is_Vowel (Nextc))
      then
         Buf (I) := Prev;
         return;
      end if;

      if Curr = 'W' and then Is_Vowel (Prev) then
         Buf (I) := Prev;
         return;
      end if;
      --  Otherwise leave Buf (I) unchanged.
   end Transcode_At;

   ---------------------------------------------------------------------------
   -- Encode
   ---------------------------------------------------------------------------

   function Encode (Name : String) return String is
      Buf      : Name_Buffer := [others => ' '];
      Len      : Natural := 0;
      Key      : String (1 .. Max_Len);
      Key_Len  : Natural := 0;
   begin
      if Name'Length = 0 or else Name'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      --  Strip non-letters and fold to upper case.
      for I in Name'Range loop
         if Is_Letter (Name (I)) then
            Len := Len + 1;
            Buf (Len) := To_Upper (Name (I));
         end if;
      end loop;

      if Len = 0 then
         raise Invalid_Argument;
      end if;

      Apply_Prefix (Buf, Len);
      Apply_Suffix (Buf, Len);

      --  Key starts with first character of (rewritten) name.
      Key_Len := 1;
      Key (1) := Buf (1);

      for I in 2 .. Len loop
         Transcode_At (Buf, Len, I);
         --  Append iff rewritten letter differs from previous rewritten letter.
         if Buf (I) /= Buf (I - 1) then
            Key_Len := Key_Len + 1;
            Key (Key_Len) := Buf (I);
         end if;
      end loop;

      --  Trailing cleanup; never drop the first key letter (Ash → A).
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

      --  Truncate to Max_Code_Len (unpadded).
      if Key_Len > Max_Code_Len then
         Key_Len := Max_Code_Len;
      end if;

      return Key (1 .. Key_Len);
   end Encode;

   ---------------------------------------------------------------------------
   -- Codes_Match
   ---------------------------------------------------------------------------

   function Codes_Match (A, B : String) return Boolean is
   begin
      return Encode (A) = Encode (B);
   end Codes_Match;

end NYSIIS;

--  Double_Metaphone body — Lawrence Philips Double Metaphone (truncate
--  each key to Max_Code_Len). Reference behaviour aligned with Apache
--  Commons Codec DoubleMetaphone; not original Metaphone; not Metaphone 3.

pragma Ada_2022;

package body Double_Metaphone is

   NUL : constant Character := Character'Val (0);

   subtype Name_Buffer is String (1 .. Max_Len);

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
        or else C = 'O' or else C = 'U' or else C = 'Y';
   end Is_Vowel;

   ---------------------------------------------------------------------------
   -- 0-based region helpers over Value (1 .. Len)
   ---------------------------------------------------------------------------

   function Char_At
     (Value : Name_Buffer;
      Len   : Natural;
      Index : Integer) return Character
   is
   begin
      if Index < 0 or else Index >= Len then
         return NUL;
      end if;
      return Value (Index + 1);
   end Char_At;

   function Contains
     (Value  : Name_Buffer;
      Len    : Natural;
      Start  : Integer;
      Length : Positive;
      A      : String) return Boolean
   is
   begin
      if Start < 0 or else Start + Length > Len then
         return False;
      end if;
      if A'Length /= Length then
         return False;
      end if;
      return Value (Start + 1 .. Start + Length) = A;
   end Contains;

   --  Packed token lists: each alternative is Length characters, no sep.
   function Contains_Tokens
     (Value  : Name_Buffer;
      Len    : Natural;
      Start  : Integer;
      Length : Positive;
      Tokens : String) return Boolean
   is
      N : constant Natural := Tokens'Length / Length;
   begin
      if Start < 0 or else Start + Length > Len then
         return False;
      end if;
      if Tokens'Length = 0 or else Tokens'Length mod Length /= 0 then
         return False;
      end if;
      declare
         Target : constant String :=
           Value (Start + 1 .. Start + Length);
      begin
         for K in 0 .. N - 1 loop
            declare
               Lo : constant Positive := Tokens'First + K * Length;
               Hi : constant Positive := Lo + Length - 1;
            begin
               if Target = Tokens (Lo .. Hi) then
                  return True;
               end if;
            end;
         end loop;
      end;
      return False;
   end Contains_Tokens;

   function Is_Slavo_Germanic
     (Value : Name_Buffer;
      Len   : Natural) return Boolean
   is
   begin
      for I in 1 .. Len loop
         if Value (I) = 'W' or else Value (I) = 'K' then
            return True;
         end if;
      end loop;
      if Len >= 2 then
         for I in 1 .. Len - 1 loop
            if Value (I .. I + 1) = "CZ" then
               return True;
            end if;
         end loop;
      end if;
      if Len >= 4 then
         for I in 1 .. Len - 3 loop
            if Value (I .. I + 3) = "WITZ" then
               return True;
            end if;
         end loop;
      end if;
      return False;
   end Is_Slavo_Germanic;

   function Is_Silent_Start
     (Value : Name_Buffer;
      Len   : Natural) return Boolean
   is
   begin
      if Len < 2 then
         return False;
      end if;
      declare
         P : constant String := Value (1 .. 2);
      begin
         return P = "GN" or else P = "KN" or else P = "PN"
           or else P = "WR" or else P = "PS";
      end;
   end Is_Silent_Start;

   ---------------------------------------------------------------------------
   -- Encode
   ---------------------------------------------------------------------------

   function Encode (Word : String) return Codes is
      Value : Name_Buffer := [others => ' '];
      Len   : Natural := 0;
      Has_Letter : Boolean := False;

      Primary_Buf   : String (1 .. Max_Code_Len) := [others => ' '];
      Alternate_Buf : String (1 .. Max_Code_Len) := [others => ' '];
      Prim_Len      : Natural := 0;
      Alt_Len       : Natural := 0;

      Index : Integer := 0;
      Slavo : Boolean;

      procedure Append_Primary (C : Character) is
      begin
         if Prim_Len < Max_Code_Len and then C /= ' ' then
            Prim_Len := Prim_Len + 1;
            Primary_Buf (Prim_Len) := C;
         elsif Prim_Len < Max_Code_Len and then C = ' ' then
            null;  --  space means "no primary symbol"
         end if;
      end Append_Primary;

      procedure Append_Alternate (C : Character) is
      begin
         --  Space means "do not add an alternate symbol" (Commons quirk).
         if Alt_Len < Max_Code_Len and then C /= ' ' then
            Alt_Len := Alt_Len + 1;
            Alternate_Buf (Alt_Len) := C;
         end if;
      end Append_Alternate;

      procedure Append_Primary_Str (S : String) is
      begin
         for C of S loop
            Append_Primary (C);
         end loop;
      end Append_Primary_Str;

      procedure Append_Alternate_Str (S : String) is
      begin
         for C of S loop
            Append_Alternate (C);
         end loop;
      end Append_Alternate_Str;

      procedure Append_Both (C : Character) is
      begin
         Append_Primary (C);
         Append_Alternate (C);
      end Append_Both;

      procedure Append_Both_Str (S : String) is
      begin
         Append_Primary_Str (S);
         Append_Alternate_Str (S);
      end Append_Both_Str;

      procedure Append_Pair (P, A : Character) is
      begin
         Append_Primary (P);
         Append_Alternate (A);
      end Append_Pair;

      procedure Append_Pair_Str (P, A : String) is
      begin
         Append_Primary_Str (P);
         Append_Alternate_Str (A);
      end Append_Pair_Str;

      function Is_Complete return Boolean is
        (Prim_Len >= Max_Code_Len and then Alt_Len >= Max_Code_Len);

      function Condition_C0 (Idx : Integer) return Boolean is
         C : Character;
      begin
         if Contains (Value, Len, Idx, 4, "CHIA") then
            return True;
         end if;
         if Idx <= 1 then
            return False;
         end if;
         if Is_Vowel (Char_At (Value, Len, Idx - 2)) then
            return False;
         end if;
         if not Contains (Value, Len, Idx - 1, 3, "ACH") then
            return False;
         end if;
         C := Char_At (Value, Len, Idx + 2);
         return (C /= 'I' and then C /= 'E')
           or else Contains_Tokens
             (Value, Len, Idx - 2, 6, "BACHERMACHER");
      end Condition_C0;

      function Condition_CH0 (Idx : Integer) return Boolean is
      begin
         if Idx /= 0 then
            return False;
         end if;
         if not Contains_Tokens (Value, Len, Idx + 1, 5, "HARACHARIS")
           and then not Contains_Tokens
             (Value, Len, Idx + 1, 3, "HORHYMHIAHEM")
         then
            return False;
         end if;
         return not Contains (Value, Len, 0, 5, "CHORE");
      end Condition_CH0;

      function Condition_CH1 (Idx : Integer) return Boolean is
      begin
         return Contains_Tokens (Value, Len, 0, 4, "VAN VON ")
           or else Contains (Value, Len, 0, 3, "SCH")
           or else Contains_Tokens
             (Value, Len, Idx - 2, 6, "ORCHESARCHITORCHID")
           or else Contains_Tokens (Value, Len, Idx + 2, 1, "TS")
           or else
             ((Contains_Tokens (Value, Len, Idx - 1, 1, "AOUE")
               or else Idx = 0)
              and then
                (Contains_Tokens
                   (Value, Len, Idx + 2, 1, "LRNMBHFVW ")
                 or else Idx + 1 = Len - 1));
      end Condition_CH1;

      function Condition_L0 (Idx : Integer) return Boolean is
      begin
         if Idx = Len - 3
           and then Contains_Tokens
             (Value, Len, Idx - 1, 4, "ILLOILLAALLE")
         then
            return True;
         end if;
         return (Contains_Tokens (Value, Len, Len - 2, 2, "ASOS")
                 or else Contains_Tokens (Value, Len, Len - 1, 1, "AO"))
           and then Contains (Value, Len, Idx - 1, 4, "ALLE");
      end Condition_L0;

      function Condition_M0 (Idx : Integer) return Boolean is
      begin
         if Char_At (Value, Len, Idx + 1) = 'M' then
            return True;
         end if;
         return Contains (Value, Len, Idx - 1, 3, "UMB")
           and then (Idx + 1 = Len - 1
                     or else Contains (Value, Len, Idx + 2, 2, "ER"));
      end Condition_M0;

      procedure Handle_AEIOUY (Idx : in out Integer) is
      begin
         if Idx = 0 then
            Append_Both ('A');
         end if;
         Idx := Idx + 1;
      end Handle_AEIOUY;

      procedure Handle_CC (Idx : in out Integer) is
      begin
         if Contains_Tokens (Value, Len, Idx + 2, 1, "IEH")
           and then not Contains (Value, Len, Idx + 2, 2, "HU")
         then
            if (Idx = 1 and then Char_At (Value, Len, Idx - 1) = 'A')
              or else Contains_Tokens
                (Value, Len, Idx - 1, 5, "UCCEEUCCES")
            then
               Append_Both_Str ("KS");
            else
               Append_Both ('X');
            end if;
            Idx := Idx + 3;
         else
            Append_Both ('K');
            Idx := Idx + 2;
         end if;
      end Handle_CC;

      procedure Handle_CH (Idx : in out Integer) is
      begin
         if Idx > 0 and then Contains (Value, Len, Idx, 4, "CHAE") then
            Append_Pair ('K', 'X');
            Idx := Idx + 2;
            return;
         end if;
         if Condition_CH0 (Idx) then
            Append_Both ('K');
            Idx := Idx + 2;
            return;
         end if;
         if Condition_CH1 (Idx) then
            Append_Both ('K');
            Idx := Idx + 2;
            return;
         end if;
         if Idx > 0 then
            if Contains (Value, Len, 0, 2, "MC") then
               Append_Both ('K');
            else
               Append_Pair ('X', 'K');
            end if;
         else
            Append_Both ('X');
         end if;
         Idx := Idx + 2;
      end Handle_CH;

      procedure Handle_C (Idx : in out Integer) is
      begin
         if Condition_C0 (Idx) then
            Append_Both ('K');
            Idx := Idx + 2;
         elsif Idx = 0 and then Contains (Value, Len, Idx, 6, "CAESAR")
         then
            Append_Both ('S');
            Idx := Idx + 2;
         elsif Contains (Value, Len, Idx, 2, "CH") then
            Handle_CH (Idx);
         elsif Contains (Value, Len, Idx, 2, "CZ")
           and then not Contains (Value, Len, Idx - 2, 4, "WICZ")
         then
            Append_Pair ('S', 'X');
            Idx := Idx + 2;
         elsif Contains (Value, Len, Idx + 1, 3, "CIA") then
            Append_Both ('X');
            Idx := Idx + 3;
         elsif Contains (Value, Len, Idx, 2, "CC")
           and then not (Idx = 1 and then Char_At (Value, Len, 0) = 'M')
         then
            Handle_CC (Idx);
         elsif Contains_Tokens (Value, Len, Idx, 2, "CKCGCQ") then
            Append_Both ('K');
            Idx := Idx + 2;
         elsif Contains_Tokens (Value, Len, Idx, 2, "CICECY") then
            if Contains_Tokens (Value, Len, Idx, 3, "CIOCIECIA") then
               Append_Pair ('S', 'X');
            else
               Append_Both ('S');
            end if;
            Idx := Idx + 2;
         else
            Append_Both ('K');
            if Contains (Value, Len, Idx + 1, 2, " C")
              or else Contains (Value, Len, Idx + 1, 2, " Q")
              or else Contains (Value, Len, Idx + 1, 2, " G")
            then
               Idx := Idx + 3;
            elsif Contains_Tokens (Value, Len, Idx + 1, 1, "CKQ")
              and then not Contains_Tokens
                (Value, Len, Idx + 1, 2, "CECI")
            then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_C;

      procedure Handle_D (Idx : in out Integer) is
      begin
         if Contains (Value, Len, Idx, 2, "DG") then
            if Contains_Tokens (Value, Len, Idx + 2, 1, "IEY") then
               Append_Both ('J');
               Idx := Idx + 3;
            else
               Append_Both_Str ("TK");
               Idx := Idx + 2;
            end if;
         elsif Contains_Tokens (Value, Len, Idx, 2, "DTDD") then
            Append_Both ('T');
            Idx := Idx + 2;
         else
            Append_Both ('T');
            Idx := Idx + 1;
         end if;
      end Handle_D;

      procedure Handle_GH (Idx : in out Integer) is
      begin
         if Idx > 0 and then not Is_Vowel (Char_At (Value, Len, Idx - 1))
         then
            Append_Both ('K');
            Idx := Idx + 2;
         elsif Idx = 0 then
            if Char_At (Value, Len, Idx + 2) = 'I' then
               Append_Both ('J');
            else
               Append_Both ('K');
            end if;
            Idx := Idx + 2;
         elsif (Idx > 1
                and then Contains_Tokens
                  (Value, Len, Idx - 2, 1, "BHD"))
           or else (Idx > 2
                    and then Contains_Tokens
                      (Value, Len, Idx - 3, 1, "BHD"))
           or else (Idx > 3
                    and then Contains_Tokens
                      (Value, Len, Idx - 4, 1, "BH"))
         then
            Idx := Idx + 2;
         else
            if Idx > 2
              and then Char_At (Value, Len, Idx - 1) = 'U'
              and then Contains_Tokens
                (Value, Len, Idx - 3, 1, "CGLRT")
            then
               Append_Both ('F');
            elsif Idx > 0
              and then Char_At (Value, Len, Idx - 1) /= 'I'
            then
               Append_Both ('K');
            end if;
            Idx := Idx + 2;
         end if;
      end Handle_GH;

      procedure Handle_G (Idx : in out Integer) is
      begin
         if Char_At (Value, Len, Idx + 1) = 'H' then
            Handle_GH (Idx);
         elsif Char_At (Value, Len, Idx + 1) = 'N' then
            if Idx = 1
              and then Is_Vowel (Char_At (Value, Len, 0))
              and then not Slavo
            then
               Append_Pair_Str ("KN", "N");
            elsif not Contains (Value, Len, Idx + 2, 2, "EY")
              and then Char_At (Value, Len, Idx + 1) /= 'Y'
              and then not Slavo
            then
               Append_Pair_Str ("N", "KN");
            else
               Append_Both_Str ("KN");
            end if;
            Idx := Idx + 2;
         elsif Contains (Value, Len, Idx + 1, 2, "LI") and then not Slavo
         then
            Append_Pair_Str ("KL", "L");
            Idx := Idx + 2;
         elsif Idx = 0
           and then
             (Char_At (Value, Len, Idx + 1) = 'Y'
              or else Contains_Tokens
                (Value, Len, Idx + 1, 2,
                 "ESEPEBELLEYIBILINIEIEIER"))
         then
            Append_Pair ('K', 'J');
            Idx := Idx + 2;
         elsif (Contains (Value, Len, Idx + 1, 2, "ER")
                or else Char_At (Value, Len, Idx + 1) = 'Y')
           and then not Contains_Tokens
             (Value, Len, 0, 6, "DANGERRANGERMANGER")
           and then not Contains_Tokens
             (Value, Len, Idx - 1, 1, "EI")
           and then not Contains_Tokens
             (Value, Len, Idx - 1, 3, "RGYOGY")
         then
            Append_Pair ('K', 'J');
            Idx := Idx + 2;
         elsif Contains_Tokens (Value, Len, Idx + 1, 1, "EIY")
           or else Contains_Tokens
             (Value, Len, Idx - 1, 4, "AGGIOGGI")
         then
            if Contains_Tokens (Value, Len, 0, 4, "VAN VON ")
              or else Contains (Value, Len, 0, 3, "SCH")
              or else Contains (Value, Len, Idx + 1, 2, "ET")
            then
               Append_Both ('K');
            elsif Contains (Value, Len, Idx + 1, 3, "IER") then
               Append_Both ('J');
            else
               Append_Pair ('J', 'K');
            end if;
            Idx := Idx + 2;
         else
            if Char_At (Value, Len, Idx + 1) = 'G' then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
            Append_Both ('K');
         end if;
      end Handle_G;

      procedure Handle_H (Idx : in out Integer) is
      begin
         if (Idx = 0 or else Is_Vowel (Char_At (Value, Len, Idx - 1)))
           and then Is_Vowel (Char_At (Value, Len, Idx + 1))
         then
            Append_Both ('H');
            Idx := Idx + 2;
         else
            Idx := Idx + 1;
         end if;
      end Handle_H;

      procedure Handle_J (Idx : in out Integer) is
      begin
         if Contains (Value, Len, Idx, 4, "JOSE")
           or else Contains (Value, Len, 0, 4, "SAN ")
         then
            if (Idx = 0 and then Char_At (Value, Len, Idx + 4) = ' ')
              or else Len = 4
              or else Contains (Value, Len, 0, 4, "SAN ")
            then
               Append_Both ('H');
            else
               Append_Pair ('J', 'H');
            end if;
            Idx := Idx + 1;
         else
            if Idx = 0 and then not Contains (Value, Len, Idx, 4, "JOSE")
            then
               Append_Pair ('J', 'A');
            elsif Is_Vowel (Char_At (Value, Len, Idx - 1))
              and then not Slavo
              and then
                (Char_At (Value, Len, Idx + 1) = 'A'
                 or else Char_At (Value, Len, Idx + 1) = 'O')
            then
               Append_Pair ('J', 'H');
            elsif Idx = Len - 1 then
               Append_Pair ('J', ' ');
            elsif not Contains_Tokens
                (Value, Len, Idx + 1, 1, "LTKSNMBZ")
              and then not Contains_Tokens
                (Value, Len, Idx - 1, 1, "SKL")
            then
               Append_Both ('J');
            end if;

            if Char_At (Value, Len, Idx + 1) = 'J' then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_J;

      procedure Handle_L (Idx : in out Integer) is
      begin
         if Char_At (Value, Len, Idx + 1) = 'L' then
            if Condition_L0 (Idx) then
               Append_Primary ('L');
            else
               Append_Both ('L');
            end if;
            Idx := Idx + 2;
         else
            Idx := Idx + 1;
            Append_Both ('L');
         end if;
      end Handle_L;

      procedure Handle_P (Idx : in out Integer) is
      begin
         if Char_At (Value, Len, Idx + 1) = 'H' then
            Append_Both ('F');
            Idx := Idx + 2;
         else
            Append_Both ('P');
            if Contains_Tokens (Value, Len, Idx + 1, 1, "PB") then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_P;

      procedure Handle_R (Idx : in out Integer) is
      begin
         if Idx = Len - 1
           and then not Slavo
           and then Contains (Value, Len, Idx - 2, 2, "IE")
           and then not Contains_Tokens
             (Value, Len, Idx - 4, 2, "MEMA")
         then
            Append_Alternate ('R');
         else
            Append_Both ('R');
         end if;
         if Char_At (Value, Len, Idx + 1) = 'R' then
            Idx := Idx + 2;
         else
            Idx := Idx + 1;
         end if;
      end Handle_R;

      procedure Handle_SC (Idx : in out Integer) is
      begin
         if Char_At (Value, Len, Idx + 2) = 'H' then
            if Contains_Tokens
              (Value, Len, Idx + 3, 2, "OOERENUYEDEM")
            then
               if Contains_Tokens (Value, Len, Idx + 3, 2, "EREN") then
                  Append_Pair_Str ("X", "SK");
               else
                  Append_Both_Str ("SK");
               end if;
            elsif Idx = 0
              and then not Is_Vowel (Char_At (Value, Len, 3))
              and then Char_At (Value, Len, 3) /= 'W'
            then
               Append_Pair ('X', 'S');
            else
               Append_Both ('X');
            end if;
         elsif Contains_Tokens (Value, Len, Idx + 2, 1, "IEY") then
            Append_Both ('S');
         else
            Append_Both_Str ("SK");
         end if;
         Idx := Idx + 3;
      end Handle_SC;

      procedure Handle_S (Idx : in out Integer) is
      begin
         if Contains_Tokens (Value, Len, Idx - 1, 3, "ISLYSL") then
            Idx := Idx + 1;
         elsif Idx = 0 and then Contains (Value, Len, Idx, 5, "SUGAR")
         then
            Append_Pair ('X', 'S');
            Idx := Idx + 1;
         elsif Contains (Value, Len, Idx, 2, "SH") then
            if Contains_Tokens
              (Value, Len, Idx + 1, 4, "HEIMHOEKHOLMHOLZ")
            then
               Append_Both ('S');
            else
               Append_Both ('X');
            end if;
            Idx := Idx + 2;
         elsif Contains_Tokens (Value, Len, Idx, 3, "SIOSIA")
           or else Contains (Value, Len, Idx, 4, "SIAN")
         then
            if Slavo then
               Append_Both ('S');
            else
               Append_Pair ('S', 'X');
            end if;
            Idx := Idx + 3;
         elsif (Idx = 0
                and then Contains_Tokens
                  (Value, Len, Idx + 1, 1, "MNLW"))
           or else Contains (Value, Len, Idx + 1, 1, "Z")
         then
            Append_Pair ('S', 'X');
            if Contains (Value, Len, Idx + 1, 1, "Z") then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         elsif Contains (Value, Len, Idx, 2, "SC") then
            Handle_SC (Idx);
         else
            if Idx = Len - 1
              and then Contains_Tokens
                (Value, Len, Idx - 2, 2, "AIOI")
            then
               Append_Alternate ('S');
            else
               Append_Both ('S');
            end if;
            if Contains_Tokens (Value, Len, Idx + 1, 1, "SZ") then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_S;

      procedure Handle_T (Idx : in out Integer) is
      begin
         if Contains (Value, Len, Idx, 4, "TION")
           or else Contains_Tokens (Value, Len, Idx, 3, "TIATCH")
         then
            Append_Both ('X');
            Idx := Idx + 3;
         elsif Contains (Value, Len, Idx, 2, "TH")
           or else Contains (Value, Len, Idx, 3, "TTH")
         then
            if Contains_Tokens (Value, Len, Idx + 2, 2, "OMAM")
              or else Contains_Tokens (Value, Len, 0, 4, "VAN VON ")
              or else Contains (Value, Len, 0, 3, "SCH")
            then
               Append_Both ('T');
            else
               Append_Pair ('0', 'T');
            end if;
            Idx := Idx + 2;
         else
            Append_Both ('T');
            if Contains_Tokens (Value, Len, Idx + 1, 1, "TD") then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_T;

      procedure Handle_W (Idx : in out Integer) is
      begin
         if Contains (Value, Len, Idx, 2, "WR") then
            Append_Both ('R');
            Idx := Idx + 2;
         elsif Idx = 0
           and then
             (Is_Vowel (Char_At (Value, Len, Idx + 1))
              or else Contains (Value, Len, Idx, 2, "WH"))
         then
            if Is_Vowel (Char_At (Value, Len, Idx + 1)) then
               Append_Pair ('A', 'F');
            else
               Append_Both ('A');
            end if;
            Idx := Idx + 1;
         elsif (Idx = Len - 1
                and then Is_Vowel (Char_At (Value, Len, Idx - 1)))
           or else Contains_Tokens
             (Value, Len, Idx - 1, 5, "EWSKIEWSKYOWSKIOWSKY")
           or else Contains (Value, Len, 0, 3, "SCH")
         then
            Append_Alternate ('F');
            Idx := Idx + 1;
         elsif Contains_Tokens (Value, Len, Idx, 4, "WICZWITZ") then
            Append_Pair_Str ("TS", "FX");
            Idx := Idx + 4;
         else
            Idx := Idx + 1;
         end if;
      end Handle_W;

      procedure Handle_X (Idx : in out Integer) is
      begin
         if Idx = 0 then
            Append_Both ('S');
            Idx := Idx + 1;
         else
            if not
              (Idx = Len - 1
               and then
                 (Contains_Tokens (Value, Len, Idx - 3, 3, "IAUEAU")
                  or else Contains_Tokens
                    (Value, Len, Idx - 2, 2, "AUOU")))
            then
               Append_Both_Str ("KS");
            end if;
            if Contains_Tokens (Value, Len, Idx + 1, 1, "CX") then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_X;

      procedure Handle_Z (Idx : in out Integer) is
      begin
         if Char_At (Value, Len, Idx + 1) = 'H' then
            Append_Both ('J');
            Idx := Idx + 2;
         else
            if Contains_Tokens (Value, Len, Idx + 1, 2, "ZOZIZA")
              or else
                (Slavo
                 and then Idx > 0
                 and then Char_At (Value, Len, Idx - 1) /= 'T')
            then
               Append_Pair_Str ("S", "TS");
            else
               Append_Both ('S');
            end if;
            if Char_At (Value, Len, Idx + 1) = 'Z' then
               Idx := Idx + 2;
            else
               Idx := Idx + 1;
            end if;
         end if;
      end Handle_Z;

   begin
      if Word'Length = 0 then
         raise Invalid_Argument;
      end if;
      if Word'Length > Max_Len then
         raise Invalid_Argument;
      end if;

      --  Clean: fold letters to upper; keep spaces; drop other non-letters.
      --  Leading/trailing spaces trimmed like Commons.
      declare
         First : Natural := Word'First;
         Last  : Natural := Word'Last;
      begin
         while First <= Last and then Word (First) = ' ' loop
            First := First + 1;
         end loop;
         while Last >= First and then Word (Last) = ' ' loop
            Last := Last - 1;
         end loop;
         if First > Last then
            raise Invalid_Argument;
         end if;
         for I in First .. Last loop
            declare
               C : Character := Word (I);
            begin
               if Is_Letter (C) then
                  C := To_Upper (C);
                  Len := Len + 1;
                  Value (Len) := C;
                  Has_Letter := True;
               elsif C = ' ' then
                  Len := Len + 1;
                  Value (Len) := ' ';
               else
                  null;  --  drop punctuation / digits
               end if;
            end;
         end loop;
      end;

      if not Has_Letter or else Len = 0 then
         raise Invalid_Argument;
      end if;

      Slavo := Is_Slavo_Germanic (Value, Len);
      if Is_Silent_Start (Value, Len) then
         Index := 1;
      else
         Index := 0;
      end if;

      while not Is_Complete and then Index <= Len - 1 loop
         case Char_At (Value, Len, Index) is
            when 'A' | 'E' | 'I' | 'O' | 'U' | 'Y' =>
               Handle_AEIOUY (Index);
            when 'B' =>
               Append_Both ('P');
               if Char_At (Value, Len, Index + 1) = 'B' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'C' =>
               Handle_C (Index);
            when 'D' =>
               Handle_D (Index);
            when 'F' =>
               Append_Both ('F');
               if Char_At (Value, Len, Index + 1) = 'F' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'G' =>
               Handle_G (Index);
            when 'H' =>
               Handle_H (Index);
            when 'J' =>
               Handle_J (Index);
            when 'K' =>
               Append_Both ('K');
               if Char_At (Value, Len, Index + 1) = 'K' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'L' =>
               Handle_L (Index);
            when 'M' =>
               Append_Both ('M');
               if Condition_M0 (Index) then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'N' =>
               Append_Both ('N');
               if Char_At (Value, Len, Index + 1) = 'N' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'P' =>
               Handle_P (Index);
            when 'Q' =>
               Append_Both ('K');
               if Char_At (Value, Len, Index + 1) = 'Q' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'R' =>
               Handle_R (Index);
            when 'S' =>
               Handle_S (Index);
            when 'T' =>
               Handle_T (Index);
            when 'V' =>
               Append_Both ('F');
               if Char_At (Value, Len, Index + 1) = 'V' then
                  Index := Index + 2;
               else
                  Index := Index + 1;
               end if;
            when 'W' =>
               Handle_W (Index);
            when 'X' =>
               Handle_X (Index);
            when 'Z' =>
               Handle_Z (Index);
            when others =>
               Index := Index + 1;
         end case;
      end loop;

      if Prim_Len = 0 then
         raise Invalid_Argument;
      end if;

      --  If alternate never diverged and stayed empty while primary grew
      --  only via Append_Primary, copy primary into alternate for a
      --  stable "no alternate" representation equal to primary when the
      --  buffers match on shared Append_Both path. Commons always fills
      --  both in parallel for Append_Both; Alternate_Len may lag only on
      --  Append_Primary-only (Spanish LL) or Append_Alternate-only.
      declare
         Result : Codes;
      begin
         Result.Primary (1 .. Prim_Len) := Primary_Buf (1 .. Prim_Len);
         Result.Primary_Length := Prim_Len;
         Result.Alternate (1 .. Alt_Len) := Alternate_Buf (1 .. Alt_Len);
         Result.Alternate_Length := Alt_Len;
         return Result;
      end;
   end Encode;

   function Primary (Word : String) return String is
      C : constant Codes := Encode (Word);
   begin
      return C.Primary (1 .. C.Primary_Length);
   end Primary;

   function Alternate (Word : String) return String is
      C : constant Codes := Encode (Word);
   begin
      return C.Alternate (1 .. C.Alternate_Length);
   end Alternate;

   function Codes_Match (A, B : String) return Boolean is
      CA : constant Codes := Encode (A);
      CB : constant Codes := Encode (B);

      function Key_Of
        (C : Codes;
         Which : Positive) return String
      is
      begin
         if Which = 1 then
            return C.Primary (1 .. C.Primary_Length);
         elsif C.Alternate_Length > 0 then
            return C.Alternate (1 .. C.Alternate_Length);
         else
            return "";
         end if;
      end Key_Of;
   begin
      for IA in 1 .. 2 loop
         declare
            KA : constant String := Key_Of (CA, IA);
         begin
            if KA'Length > 0 then
               for IB in 1 .. 2 loop
                  declare
                     KB : constant String := Key_Of (CB, IB);
                  begin
                     if KB'Length > 0 and then KA = KB then
                        return True;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
      return False;
   end Codes_Match;

end Double_Metaphone;

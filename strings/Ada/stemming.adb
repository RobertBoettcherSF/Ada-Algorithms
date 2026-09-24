--  Stemming — package body (Porter 1980 + simple suffix stripper).

pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Stemming is

   -------------------------------------------------------------------------
   -- Lowercasing
   -------------------------------------------------------------------------

   function To_Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('A') + Character'Pos ('a'));
      else
         return C;
      end if;
   end To_Lower;

   function To_Lower (S : String) return String is
      Result : String (S'Range);
   begin
      if S'Length > Max_Word_Length then
         raise Invalid_Argument;
      end if;
      for I in S'Range loop
         Result (I) := To_Lower (S (I));
      end loop;
      return Result;
   end To_Lower;

   -------------------------------------------------------------------------
   -- Porter letter classification
   -------------------------------------------------------------------------

   function Is_Vowel (C : Character) return Boolean is
      L : constant Character := To_Lower (C);
   begin
      return L = 'a' or else L = 'e' or else L = 'i'
        or else L = 'o' or else L = 'u';
   end Is_Vowel;

   function Is_Consonant_At (Word : String; Index : Positive) return Boolean is
      C : constant Character := To_Lower (Word (Index));
   begin
      if Is_Vowel (C) then
         return False;
      end if;
      if C = 'y' then
         --  Y is a consonant at the start; otherwise vowel iff preceded by
         --  a consonant, consonant iff preceded by a vowel.
         if Index = Word'First then
            return True;
         end if;
         return not Is_Consonant_At (Word, Index - 1);
      end if;
      return True;
   end Is_Consonant_At;

   function Contains_Vowel (Stem : String) return Boolean is
   begin
      for I in Stem'Range loop
         if not Is_Consonant_At (Stem, I) then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Vowel;

   function Measure_M (Stem : String) return Natural is
      I     : Natural;
      Count : Natural := 0;
   begin
      if Stem'Length = 0 then
         return 0;
      end if;
      I := Stem'First;
      while I <= Stem'Last and then Is_Consonant_At (Stem, I) loop
         I := I + 1;
      end loop;
      loop
         exit when I > Stem'Last;
         while I <= Stem'Last and then not Is_Consonant_At (Stem, I) loop
            I := I + 1;
         end loop;
         exit when I > Stem'Last;
         while I <= Stem'Last and then Is_Consonant_At (Stem, I) loop
            I := I + 1;
         end loop;
         Count := Count + 1;
      end loop;
      return Count;
   end Measure_M;

   function Ends_Double_Consonant (Stem : String) return Boolean is
   begin
      if Stem'Length < 2 then
         return False;
      end if;
      declare
         A : constant Character := To_Lower (Stem (Stem'Last - 1));
         B : constant Character := To_Lower (Stem (Stem'Last));
      begin
         return A = B and then Is_Consonant_At (Stem, Stem'Last);
      end;
   end Ends_Double_Consonant;

   function Ends_CVC (Stem : String) return Boolean is
   begin
      if Stem'Length < 3 then
         return False;
      end if;
      declare
         Last : constant Character := To_Lower (Stem (Stem'Last));
      begin
         if Last = 'w' or else Last = 'x' or else Last = 'y' then
            return False;
         end if;
         return Is_Consonant_At (Stem, Stem'Last)
           and then not Is_Consonant_At (Stem, Stem'Last - 1)
           and then Is_Consonant_At (Stem, Stem'Last - 2);
      end;
   end Ends_CVC;

   -------------------------------------------------------------------------
   -- Unbounded helpers
   -------------------------------------------------------------------------

   function Ends_With (Buf : Unbounded_String; Suffix : String) return Boolean is
      L : constant Natural := Length (Buf);
   begin
      if Suffix'Length > L then
         return False;
      end if;
      return Slice (Buf, L - Suffix'Length + 1, L) = Suffix;
   end Ends_With;

   function Stem_Before
     (Buf : Unbounded_String; Suffix_Len : Natural) return String
   is
      L : constant Natural := Length (Buf);
   begin
      if Suffix_Len >= L then
         return "";
      end if;
      return Slice (Buf, 1, L - Suffix_Len);
   end Stem_Before;

   procedure Replace_Suffix
     (Buf        : in out Unbounded_String;
      Old_Suffix : String;
      New_Suffix : String)
   is
      L : constant Natural := Length (Buf);
   begin
      if Old_Suffix'Length >= L then
         Buf := To_Unbounded_String (New_Suffix);
      else
         Buf := To_Unbounded_String
           (Slice (Buf, 1, L - Old_Suffix'Length) & New_Suffix);
      end if;
   end Replace_Suffix;

   --  Min_M = 0 means condition (m > 0); Min_M = 1 means (m > 1).
   procedure Try_Rule
     (Buf        : in out Unbounded_String;
      Old_Suffix : String;
      New_Suffix : String;
      Min_M      : Natural;
      Applied    : in out Boolean)
   is
   begin
      if Applied then
         return;
      end if;
      if not Ends_With (Buf, Old_Suffix) then
         return;
      end if;
      declare
         Stem : constant String := Stem_Before (Buf, Old_Suffix'Length);
      begin
         if Measure_M (Stem) > Min_M then
            Replace_Suffix (Buf, Old_Suffix, New_Suffix);
            Applied := True;
         end if;
      end;
   end Try_Rule;

   -------------------------------------------------------------------------
   -- Porter steps 1a–5b
   -------------------------------------------------------------------------

   procedure Step_1a (Buf : in out Unbounded_String) is
   begin
      if Ends_With (Buf, "sses") then
         Replace_Suffix (Buf, "sses", "ss");
      elsif Ends_With (Buf, "ies") then
         Replace_Suffix (Buf, "ies", "i");
      elsif Ends_With (Buf, "ss") then
         null;
      elsif Ends_With (Buf, "s") then
         Replace_Suffix (Buf, "s", "");
      end if;
   end Step_1a;

   procedure Step_1b_Followup (Buf : in out Unbounded_String) is
      Stem : constant String := To_String (Buf);
   begin
      if Ends_With (Buf, "at") then
         Replace_Suffix (Buf, "at", "ate");
      elsif Ends_With (Buf, "bl") then
         Replace_Suffix (Buf, "bl", "ble");
      elsif Ends_With (Buf, "iz") then
         Replace_Suffix (Buf, "iz", "ize");
      elsif Ends_Double_Consonant (Stem) then
         declare
            Last : constant Character := To_Lower (Stem (Stem'Last));
         begin
            if Last /= 'l' and then Last /= 's' and then Last /= 'z' then
               Replace_Suffix (Buf, Stem (Stem'Last .. Stem'Last), "");
            end if;
         end;
      elsif Measure_M (Stem) = 1 and then Ends_CVC (Stem) then
         Append (Buf, "e");
      end if;
   end Step_1b_Followup;

   procedure Step_1b (Buf : in out Unbounded_String) is
   begin
      if Ends_With (Buf, "eed") then
         declare
            Stem : constant String := Stem_Before (Buf, 3);
         begin
            if Measure_M (Stem) > 0 then
               Replace_Suffix (Buf, "eed", "ee");
            end if;
         end;
      elsif Ends_With (Buf, "ed") then
         declare
            Stem : constant String := Stem_Before (Buf, 2);
         begin
            if Contains_Vowel (Stem) then
               Replace_Suffix (Buf, "ed", "");
               Step_1b_Followup (Buf);
            end if;
         end;
      elsif Ends_With (Buf, "ing") then
         declare
            Stem : constant String := Stem_Before (Buf, 3);
         begin
            if Contains_Vowel (Stem) then
               Replace_Suffix (Buf, "ing", "");
               Step_1b_Followup (Buf);
            end if;
         end;
      end if;
   end Step_1b;

   procedure Step_1c (Buf : in out Unbounded_String) is
   begin
      if Ends_With (Buf, "y") then
         declare
            Stem : constant String := Stem_Before (Buf, 1);
         begin
            if Contains_Vowel (Stem) then
               Replace_Suffix (Buf, "y", "i");
            end if;
         end;
      end if;
   end Step_1c;

   procedure Step_2 (Buf : in out Unbounded_String) is
      Applied : Boolean := False;

      procedure R (Old : String; New_S : String) is
      begin
         Try_Rule (Buf, Old, New_S, Min_M => 0, Applied => Applied);
      end R;
   begin
      --  Longest suffixes first so the longest matching S1 wins.
      R ("ational", "ate");
      R ("ization", "ize");
      R ("iveness", "ive");
      R ("fulness", "ful");
      R ("ousness", "ous");
      R ("tional",  "tion");
      R ("biliti",  "ble");
      R ("aliti",   "al");
      R ("iviti",   "ive");
      R ("ation",   "ate");
      R ("alism",   "al");
      R ("ousli",   "ous");
      R ("entli",   "ent");
      R ("enci",    "ence");
      R ("anci",    "ance");
      R ("izer",    "ize");
      R ("abli",    "able");
      R ("alli",    "al");
      R ("ator",    "ate");
      R ("eli",     "e");
   end Step_2;

   procedure Step_3 (Buf : in out Unbounded_String) is
      Applied : Boolean := False;

      procedure R (Old : String; New_S : String) is
      begin
         Try_Rule (Buf, Old, New_S, Min_M => 0, Applied => Applied);
      end R;
   begin
      R ("icate", "ic");
      R ("ative", "");
      R ("alize", "al");
      R ("iciti", "ic");
      R ("ical",  "ic");
      R ("ful",   "");
      R ("ness",  "");
   end Step_3;

   procedure Step_4 (Buf : in out Unbounded_String) is
      Applied : Boolean := False;

      procedure R (Old : String) is
      begin
         Try_Rule (Buf, Old, "", Min_M => 1, Applied => Applied);
      end R;

      procedure R_ION is
      begin
         if Applied then
            return;
         end if;
         if not Ends_With (Buf, "ion") then
            return;
         end if;
         declare
            Stem : constant String := Stem_Before (Buf, 3);
         begin
            if Measure_M (Stem) > 1
              and then Stem'Length > 0
              and then (To_Lower (Stem (Stem'Last)) = 's'
                        or else To_Lower (Stem (Stem'Last)) = 't')
            then
               Replace_Suffix (Buf, "ion", "");
               Applied := True;
            end if;
         end;
      end R_ION;
   begin
      --  Longer suffixes before shorter overlapping ones.
      R ("ement");
      R ("ance");
      R ("ence");
      R ("able");
      R ("ible");
      R ("ment");
      R ("ant");
      R ("ent");
      R_ION;
      R ("ism");
      R ("ate");
      R ("iti");
      R ("ous");
      R ("ive");
      R ("ize");
      R ("ou");
      R ("al");
      R ("er");
      R ("ic");
   end Step_4;

   procedure Step_5a (Buf : in out Unbounded_String) is
   begin
      if not Ends_With (Buf, "e") then
         return;
      end if;
      declare
         Stem : constant String := Stem_Before (Buf, 1);
         M    : constant Natural := Measure_M (Stem);
      begin
         if M > 1 then
            Replace_Suffix (Buf, "e", "");
         elsif M = 1 and then not Ends_CVC (Stem) then
            Replace_Suffix (Buf, "e", "");
         end if;
      end;
   end Step_5a;

   procedure Step_5b (Buf : in out Unbounded_String) is
      Stem : constant String := To_String (Buf);
   begin
      if Stem'Length > 0
        and then Measure_M (Stem) > 1
        and then Ends_Double_Consonant (Stem)
        and then To_Lower (Stem (Stem'Last)) = 'l'
      then
         Replace_Suffix (Buf, "l", "");
      end if;
   end Step_5b;

   -------------------------------------------------------------------------
   -- Public stemmers
   -------------------------------------------------------------------------

   function Porter_Stem (Word : String) return String is
      Buf : Unbounded_String;
   begin
      if Word'Length > Max_Word_Length then
         raise Invalid_Argument;
      end if;
      if Word'Length = 0 then
         return "";
      end if;
      Buf := To_Unbounded_String (To_Lower (Word));
      if Length (Buf) <= 2 then
         return To_String (Buf);
      end if;
      Step_1a (Buf);
      Step_1b (Buf);
      Step_1c (Buf);
      Step_2 (Buf);
      Step_3 (Buf);
      Step_4 (Buf);
      Step_5a (Buf);
      Step_5b (Buf);
      return To_String (Buf);
   end Porter_Stem;

   function Simple_Stem (Word : String) return String is
      W        : constant String := To_Lower (Word);
      Min_Keep : constant := 3;
   begin
      if W'Length > Max_Word_Length then
         raise Invalid_Argument;
      end if;
      if W'Length = 0 then
         return "";
      end if;
      if W'Length >= Min_Keep + 3
        and then W (W'Last - 2 .. W'Last) = "ing"
      then
         return W (W'First .. W'Last - 3);
      elsif W'Length >= Min_Keep + 2
        and then W (W'Last - 1 .. W'Last) = "ed"
      then
         return W (W'First .. W'Last - 2);
      elsif W'Length >= Min_Keep + 2
        and then W (W'Last - 1 .. W'Last) = "ly"
      then
         return W (W'First .. W'Last - 2);
      elsif W'Length >= Min_Keep + 2
        and then W (W'Last - 1 .. W'Last) = "es"
      then
         return W (W'First .. W'Last - 2);
      elsif W'Length >= Min_Keep + 1
        and then W (W'Last) = 's'
        and then W (W'Last - 1) /= 's'
      then
         return W (W'First .. W'Last - 1);
      else
         return W;
      end if;
   end Simple_Stem;

   function Suffix_Strip (Word : String) return String is
   begin
      return Simple_Stem (Word);
   end Suffix_Strip;

   function Stem_Word (Word : String) return String is
   begin
      return Porter_Stem (Word);
   end Stem_Word;

end Stemming;

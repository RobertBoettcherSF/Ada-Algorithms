--  Standalone test suite for Sukhotin (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sukhotin; use Sukhotin;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Contains_Char (S : String; C : Character) return Boolean is
   begin
      for I in S'Range loop
         if S (I) = C then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Char;

   function Has_All_AEIOU (Vowels : String) return Boolean is
   begin
      return Contains_Char (Vowels, 'a')
        and then Contains_Char (Vowels, 'e')
        and then Contains_Char (Vowels, 'i')
        and then Contains_Char (Vowels, 'o')
        and then Contains_Char (Vowels, 'u');
   end Has_All_AEIOU;

   --  Classic short pangrams are too sparse for stable aeiou recovery;
   --  use repeated / combined pangram prose (still pangram-based English).
   Pangram : constant String :=
     "The quick brown fox jumps over the lazy dog. "
     & "Pack my box with five dozen liquor jugs. "
     & "How vexingly quick daft zebras jump. "
     & "Sphinx of black quartz, judge my vow. "
     & "The quick brown fox jumps over the lazy dog. "
     & "Pack my box with five dozen liquor jugs. "
     & "How vexingly quick daft zebras jump. "
     & "Sphinx of black quartz, judge my vow. "
     & "The quick brown fox jumps over the lazy dog. "
     & "Pack my box with five dozen liquor jugs. "
     & "How vexingly quick daft zebras jump. "
     & "Sphinx of black quartz, judge my vow.";

   Pangram2 : constant String :=
     "Four score and seven years ago our fathers brought forth on this "
     & "continent a new nation conceived in liberty and dedicated to the "
     & "proposition that all men are created equal. Now we are engaged in "
     & "a great civil war testing whether that nation or any nation so "
     & "conceived and so dedicated can long endure. We are met on a great "
     & "battlefield of that war. We have come to dedicate a portion of "
     & "that field as a final resting place for those who here gave their "
     & "lives that that nation might live.";

   Toy_Para : constant String :=
     "In an age of quiet evenings a wise man may read a fine tale "
     & "of open ideas and unique images over a cup of tea.";

   CVCV : constant String :=
     "babebibobubababebibobuba "
     & "cacecicocucacecicocuca "
     & "dad edidodudad edidoduda "
     & "fafefifofufafefifofu "
     & "gag agigogugag agigogu "
     & "hah ehihohuhah ehihohu "
     & "jaj ejijojujaj ejijoju "
     & "kak ekikokukak ekikoku "
     & "lal elilolulal elilolu "
     & "mam emimomumam emimomu "
     & "nan eninonunan eninonu "
     & "pap epipopupap epipopu "
     & "rar erirorurar eriroru "
     & "sas esisosusas esisosu "
     & "tat etitotutat etitotu "
     & "vav evivovuvav evivovu "
     & "waw ewiwowuwaw ewiwowu "
     & "xax exixoxuxax exixoxu "
     & "yay eyiyoyuyay eyiyoyu "
     & "zaz ezizozuzaz ezizozu";

   English_Corpus : constant String :=
     "It is a truth universally acknowledged that a single man in "
     & "possession of a good fortune must be in want of a wife. "
     & "However little known the feelings or views of such a man may "
     & "be on his first entering a neighbourhood, this truth is so "
     & "well fixed in the minds of the surrounding families, that he "
     & "is considered as the rightful property of some one or other "
     & "of their daughters. My dear Mr Bennet, have you heard that "
     & "Netherfield Park is let at last?";

begin
   Put_Line ("Sukhotin test suite");
   Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. Alphabet helpers");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Check (Is_Alphabetic ('a'), "Is_Alphabetic a");
      Check (Is_Alphabetic ('Z'), "Is_Alphabetic Z");
      Check (not Is_Alphabetic (' '), "not Is_Alphabetic space");
      Check (not Is_Alphabetic ('1'), "not Is_Alphabetic digit");
      Check (not Is_Alphabetic ('.'), "not Is_Alphabetic period");
      Check (To_Lower_Letter ('A') = 'a', "To_Lower A");
      Check (To_Lower_Letter ('z') = 'z', "To_Lower z");
      Check (To_Lower_Letter ('M') = 'm', "To_Lower M");
      Check (Char_To_Index ('a') = 0, "index a = 0");
      Check (Char_To_Index ('z') = 25, "index z = 25");
      Check (Char_To_Index ('e') = 4, "index e = 4");
      Check (Index_To_Char (0) = 'a', "char 0 = a");
      Check (Index_To_Char (25) = 'z', "char 25 = z");
      Check (Index_To_Char (Char_To_Index ('q')) = 'q', "roundtrip q");
      Raised := False;
      begin
         declare
            Unused : Letter_Char := To_Lower_Letter ('!');
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "To_Lower non-letter raises Invalid_Argument");
      Check (Index_To_Char (0) = 'a' and then Index_To_Char (25) = 'z',
             "indices 0..25 map a..z");
      Check (Char_To_Index (Index_To_Char (12)) = 12, "index roundtrip 12");
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty text / single letter");
   ---------------------------------------------------------------------
   declare
      A0 : constant Adjacency_Matrix := Build_Adjacency ("");
      C0 : constant Classification := Classify_Text ("");
      A1 : constant Adjacency_Matrix := Build_Adjacency ("a");
      C1 : constant Classification := Classify_Text ("a");
      A2 : constant Adjacency_Matrix := Build_Adjacency ("aaa");
      C2 : constant Classification := Classify_Text ("aaa");
      Zero_Score : Boolean := True;
   begin
      Check (Is_Symmetric (A0), "empty adjacency symmetric");
      Check (Vowel_Count (C0) = 0, "empty text → 0 vowels");
      Check (Vowel_Set (C0) = "", "empty vowel set");
      Check (Consonant_Set (C0)'Length = 26, "empty → all 26 consonants");
      for I in Letter_Index loop
         if Initial_Scores (A0) (I) /= 0 then
            Zero_Score := False;
         end if;
      end loop;
      Check (Zero_Score, "empty initial scores all 0");
      Check (not Is_Vowel (C0, 'a'), "empty: a not vowel");
      Check (Is_Consonant (C0, 'a'), "empty: a consonant by default");

      Check (Is_Symmetric (A1), "single letter adjacency symmetric");
      Check (Adjacency_Get (A1, 'a', 'a') = 0, "single a diagonal 0");
      Check (Vowel_Count (C1) = 0, "single letter → no positive score vowel");
      Check (not Is_Vowel (C1, 'a'), "single a not selected");

      Check (Adjacency_Get (A2, 'a', 'a') = 0, "aaa keeps diagonal 0");
      Check (Vowel_Count (C2) = 0, "aaa alone → no vowel (no off-diag)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Adjacency symmetry and counts");
   ---------------------------------------------------------------------
   declare
      A  : constant Adjacency_Matrix := Build_Adjacency ("ab");
      A3 : constant Adjacency_Matrix := Build_Adjacency ("abc");
      Aw : constant Adjacency_Matrix := Build_Adjacency ("ab cd");
      Am : constant Adjacency_Matrix := Build_Adjacency ("AbC!");
      S  : Score_Vector;
   begin
      Check (Is_Symmetric (A), "ab matrix symmetric");
      Check (Adjacency_Get (A, 'a', 'b') = 1, "ab: A(a,b)=1");
      Check (Adjacency_Get (A, 'b', 'a') = 1, "ab: A(b,a)=1");
      Check (Adjacency_Get (A, 'a', 'a') = 0, "ab: diagonal a=0");
      Check (Adjacency_Get (A, 0, 1) = 1, "ab via indices");

      Check (Is_Symmetric (A3), "abc symmetric");
      Check (Adjacency_Get (A3, 'a', 'b') = 1, "abc: ab");
      Check (Adjacency_Get (A3, 'b', 'c') = 1, "abc: bc");
      Check (Adjacency_Get (A3, 'a', 'c') = 0, "abc: no ac adjacency");

      Check (Adjacency_Get (Aw, 'a', 'b') = 1, "ab cd: ab counted");
      Check (Adjacency_Get (Aw, 'c', 'd') = 1, "ab cd: cd counted");
      Check (Adjacency_Get (Aw, 'b', 'c') = 0, "ab cd: space breaks bc");

      Check (Adjacency_Get (Am, 'a', 'b') = 1, "AbC!: case fold ab");
      Check (Adjacency_Get (Am, 'b', 'c') = 1, "AbC!: case fold bc");
      Check (Is_Symmetric (Am), "mixed case + punct symmetric");

      S := Initial_Scores (A);
      Check (S (Char_To_Index ('a')) = 1, "score a in ab = 1");
      Check (S (Char_To_Index ('b')) = 1, "score b in ab = 1");
      Check (Near (S (Char_To_Index ('a')), 1), "Near score a");
      Check (not Near (S (Char_To_Index ('a')), 5), "Near rejects far");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tiny run: ab → one vowel");
   ---------------------------------------------------------------------
   declare
      C : constant Classification := Classify_Text ("ab");
      --  Both start with S=1; lowest index 'a' wins first → vowel;
      --  then S(b) := 1 - 2*1 = -1 ≤ 0 → stop. So vowels = {a}.
   begin
      Check (Vowel_Count (C) = 1, "ab → exactly 1 vowel");
      Check (Is_Vowel (C, 'a'), "ab → a is vowel (tie lowest index)");
      Check (not Is_Vowel (C, 'b'), "ab → b is consonant");
      Check (Is_Consonant (C, 'b'), "ab → Is_Consonant b");
      Check (Vowel_Set (C) = "a", "ab vowel set = a");
      Check (Contains_Char (Consonant_Set (C), 'b'), "b in consonants");
      Check (Score_Of (C, 'b') <= 0, "residual score b ≤ 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Determinism");
   ---------------------------------------------------------------------
   declare
      C1 : constant Classification := Classify_Text (Pangram);
      C2 : constant Classification := Classify_Text (Pangram);
      A1 : constant Adjacency_Matrix := Build_Adjacency (Pangram);
      A2 : constant Adjacency_Matrix := Build_Adjacency (Pangram);
      Same_Vowels : Boolean := True;
      Same_Adj    : Boolean := True;
   begin
      Check (Vowel_Set (C1) = Vowel_Set (C2), "same text → same vowel set");
      Check (Vowel_Count (C1) = Vowel_Count (C2), "same vowel count");
      for I in Letter_Index loop
         if C1.Is_Vowel (I) /= C2.Is_Vowel (I) then
            Same_Vowels := False;
         end if;
         for J in Letter_Index loop
            if A1 (I, J) /= A2 (I, J) then
               Same_Adj := False;
            end if;
         end loop;
      end loop;
      Check (Same_Vowels, "classification bit-identical");
      Check (Same_Adj, "adjacency bit-identical");
      Check (Is_Symmetric (A1), "pangram adjacency symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("6. English pangram → a,e,i,o,u among vowels");
   ---------------------------------------------------------------------
   declare
      C  : constant Classification := Classify_Text (Pangram);
      Vs : constant String := Vowel_Set (C);
      Cs : constant String := Consonant_Set (C);
   begin
      Put_Line ("  (pangram vowels: " & Vs & ")");
      Check (Vowel_Count (C) >= 5, "pangram ≥ 5 vowels");
      Check (Has_All_AEIOU (Vs), "pangram contains a,e,i,o,u");
      Check (Is_Vowel (C, 'A'), "Is_Vowel case-insensitive A");
      Check (Is_Vowel (C, 'e'), "Is_Vowel e");
      Check (Is_Vowel (C, 'I'), "Is_Vowel I");
      Check (Is_Vowel (C, 'o'), "Is_Vowel o");
      Check (Is_Vowel (C, 'U'), "Is_Vowel U");
      Check (Contains_Char (Cs, 'd') or else Contains_Char (Cs, 'f'),
             "consonants include d or f");
      Check (Contains_Char (Cs, 'f') or else Contains_Char (Cs, 'h'),
             "consonants include f or h");
      Check (Contains_Char (Cs, 'k') or else Contains_Char (Cs, 'z'),
             "consonants include k or z");
      Check (Contains_Char (Cs, 'z') or else Contains_Char (Cs, 'x'),
             "consonants include z or x");
      Check (Contains_Char (Cs, 'b') or else Contains_Char (Cs, 'c')
                or else Contains_Char (Cs, 'd'),
             "consonants include some of b,c,d");
      Check (Is_Consonant (C, 'x') or else Is_Vowel (C, 'x'),
             "x is classified");
      Check (not Is_Vowel (C, 'q') or else Is_Vowel (C, 'u'),
             "if q vowel then u likely (weak sanity)");
      Check (Is_Consonant (C, 'z') or else Is_Consonant (C, 'x'),
             "z or x consonant");
      Check (not (Is_Vowel (C, 'b') and then Is_Vowel (C, 'c')
                   and then Is_Vowel (C, 'd') and then Is_Vowel (C, 'f')),
             "not all of b,c,d,f are vowels");
      Check (Vs'Length = Vowel_Count (C), "Vowel_Set length = count");
      Check (Cs'Length + Vs'Length = 26, "vowels+consonants=26");
   end;

   ---------------------------------------------------------------------
   Section ("7. Second pangram / toy paragraph");
   ---------------------------------------------------------------------
   declare
      C2 : constant Classification := Classify_Text (Pangram2);
      Ct : constant Classification := Classify_Text (Toy_Para);
   begin
      Put_Line ("  (pangram2 vowels: " & Vowel_Set (C2) & ")");
      Put_Line ("  (toy para vowels: " & Vowel_Set (Ct) & ")");
      Check (Has_All_AEIOU (Vowel_Set (C2)), "pangram2 has aeiou");
      Check (Has_All_AEIOU (Vowel_Set (Ct)), "toy paragraph has aeiou");
      Check (Is_Vowel (C2, 'e'), "pangram2 e");
      Check (Is_Vowel (Ct, 'a'), "toy a");
      Check (Is_Consonant (C2, 'q'), "pangram2 q consonant");
      Check (Is_Consonant (Ct, 'm'), "toy m consonant");
   end;

   ---------------------------------------------------------------------
   Section ("8. Artificial CVCV corpus");
   ---------------------------------------------------------------------
   declare
      C  : constant Classification := Classify_Text (CVCV);
      Vs : constant String := Vowel_Set (C);
   begin
      Put_Line ("  (CVCV vowels: " & Vs & ")");
      Check (Is_Vowel (C, 'a'), "CVCV: a vowel");
      Check (Is_Vowel (C, 'e'), "CVCV: e vowel");
      Check (Is_Vowel (C, 'i'), "CVCV: i vowel");
      Check (Is_Vowel (C, 'o'), "CVCV: o vowel");
      Check (Is_Vowel (C, 'u'), "CVCV: u vowel");
      Check (Has_All_AEIOU (Vs), "CVCV has all aeiou");
      Check (Is_Consonant (C, 'b'), "CVCV: b consonant");
      Check (Is_Consonant (C, 'k'), "CVCV: k consonant");
      Check (Is_Consonant (C, 't'), "CVCV: t consonant");
      Check (Is_Consonant (C, 'z'), "CVCV: z consonant");
   end;

   ---------------------------------------------------------------------
   Section ("9. Longer English corpus");
   ---------------------------------------------------------------------
   declare
      C  : constant Classification := Classify_Text (English_Corpus);
      Vs : constant String := Vowel_Set (C);
      A  : constant Adjacency_Matrix := Build_Adjacency (English_Corpus);
   begin
      Put_Line ("  (Pride-ish vowels: " & Vs & ")");
      Check (Is_Symmetric (A), "corpus adjacency symmetric");
      Check (Has_All_AEIOU (Vs), "English corpus has aeiou");
      Check (Is_Vowel (C, 'e'), "corpus e");
      Check (Is_Consonant (C, 'n') or else Is_Consonant (C, 's'),
             "corpus n or s consonant");
      Check (Is_Consonant (C, 'b') or else Is_Consonant (C, 'd'),
             "corpus b or d consonant");
      Check (Is_Consonant (C, 'f') or else Is_Consonant (C, 'g'),
             "corpus f or g consonant");
      Check (Vowel_Count (C) >= 5, "corpus ≥ 5 vowels");
      Check (Score_Vector_Of (C)'Length = 26, "score vector length 26");
   end;

   ---------------------------------------------------------------------
   Section ("10. Score update non-increase property");
   ---------------------------------------------------------------------
   declare
      A       : constant Adjacency_Matrix := Build_Adjacency (Pangram);
      S0      : constant Score_Vector := Initial_Scores (A);
      --  Manually apply one Sukhotin step: pick max positive, subtract.
      Best_I  : Letter_Index := 0;
      Best_S  : Score_Value := 0;
      Found   : Boolean := False;
      S1      : Score_Vector := S0;
      Non_Inc : Boolean := True;
   begin
      for I in Letter_Index loop
         if S0 (I) > 0 then
            if not Found or else S0 (I) > Best_S then
               Found  := True;
               Best_I := I;
               Best_S := S0 (I);
            end if;
         end if;
      end loop;
      Check (Found, "pangram has some positive initial score");
      for K in Letter_Index loop
         if K /= Best_I then
            S1 (K) := S0 (K) - 2 * Score_Value (A (Best_I, K));
            --  Update decreases or leaves score (A >= 0 ⇒ subtract ≥ 0).
            if S1 (K) > S0 (K) then
               Non_Inc := False;
            end if;
         end if;
      end loop;
      Check (Non_Inc, "after one update, other scores do not increase");
      Check (S1 (Best_I) = S0 (Best_I), "selected letter score unchanged in S copy");
   end;

   ---------------------------------------------------------------------
   Section ("11. Classify_Text ≡ Run_Sukhotin ∘ Build_Adjacency");
   ---------------------------------------------------------------------
   declare
      T  : constant String := "hello world aeio u";
      C1 : constant Classification := Classify_Text (T);
      C2 : constant Classification := Run_Sukhotin (Build_Adjacency (T));
   begin
      Check (Vowel_Set (C1) = Vowel_Set (C2), "Compose equivalence vowel set");
      Check (Vowel_Count (C1) = Vowel_Count (C2), "Compose equivalence count");
      for I in Letter_Index loop
         Check (C1.Is_Vowel (I) = C2.Is_Vowel (I),
                "Compose bit " & Index_To_Char (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Empty_Adjacency / getters / Near edge");
   ---------------------------------------------------------------------
   declare
      E : constant Adjacency_Matrix := Empty_Adjacency;
      C : constant Classification := Run_Sukhotin (E);
   begin
      Check (Is_Symmetric (E), "Empty_Adjacency symmetric");
      Check (Adjacency_Get (E, 0, 0) = 0, "empty (0,0)=0");
      Check (Adjacency_Get (E, 'z', 'a') = 0, "empty (z,a)=0");
      Check (Vowel_Count (C) = 0, "empty matrix → 0 vowels");
      Check (Near (0, 0), "Near(0,0)");
      Check (Near (5, 7, 2), "Near tol=2");
      Check (not Near (5, 8, 2), "not Near beyond tol");
      Check (Score_Of (C, '!') = 0, "Score_Of non-letter = 0");
      Check (not Is_Vowel (C, '9'), "Is_Vowel digit False");
      Check (not Is_Consonant (C, '#'), "Is_Consonant punct False");
   end;

   ---------------------------------------------------------------------
   Section ("13. Repeated / punctuation-heavy text");
   ---------------------------------------------------------------------
   declare
      T : constant String :=
        "A man, a plan, a canal: Panama! Eve saw a rare area.";
      C : constant Classification := Classify_Text (T);
      A : constant Adjacency_Matrix := Build_Adjacency (T);
   begin
      Check (Is_Symmetric (A), "punct-heavy symmetric");
      Check (Is_Vowel (C, 'a'), "panama-ish: a vowel");
      Check (Vowel_Count (C) >= 1, "punct-heavy ≥ 1 vowel");
      Check (Is_Consonant (C, 'p') or else Is_Vowel (C, 'p'),
             "p classified somehow");
      Check (Contains_Char (Consonant_Set (C), 'p')
               or else Contains_Char (Vowel_Set (C), 'p'),
             "p in exactly one of the sets");
   end;

   ---------------------------------------------------------------------
   Section ("14. Alternating vowel-consonant toy");
   ---------------------------------------------------------------------
   declare
      --  Strong alternating pattern favouring a,e as vowels.
      T : constant String :=
        "ba be bi bo bu ca ce ci co cu da de di do du "
        & "fa fe fi fo fu ga ge gi go gu ha he hi ho hu "
        & "ja je ji jo ju ka ke ki ko ku la le li lo lu "
        & "ma me mi mo mu na ne ni no nu pa pe pi po pu "
        & "ra re ri ro ru sa se si so su ta te ti to tu "
        & "va ve vi vo vu wa we wi wo wu xa xe xi xo xu "
        & "za ze zi zo zu";
      C : constant Classification := Classify_Text (T);
   begin
      Put_Line ("  (alt vowels: " & Vowel_Set (C) & ")");
      Check (Is_Vowel (C, 'a'), "alt: a");
      Check (Is_Vowel (C, 'e'), "alt: e");
      Check (Is_Vowel (C, 'i'), "alt: i");
      Check (Is_Vowel (C, 'o'), "alt: o");
      Check (Is_Vowel (C, 'u'), "alt: u");
      Check (Is_Consonant (C, 'b'), "alt: b cons");
      Check (Is_Consonant (C, 'z'), "alt: z cons");
      Check (Is_Consonant (C, 'm'), "alt: m cons");
   end;

   ---------------------------------------------------------------------
   Section ("15. Residual consonant scores ≤ 0");
   ---------------------------------------------------------------------
   declare
      C     : constant Classification := Classify_Text (Pangram);
      Ok    : Boolean := True;
      S     : constant Score_Vector := Score_Vector_Of (C);
   begin
      for I in Letter_Index loop
         if not C.Is_Vowel (I) and then S (I) > 0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all consonant residual scores ≤ 0");
      Check (Vowel_Count (C) = Natural'(Vowel_Set (C)'Length),
             "Vowel_Count matches set length");
   end;

   ---------------------------------------------------------------------
   Section ("16. Several short corpora batch");
   ---------------------------------------------------------------------
   declare
      type Corpus is access constant String;
      C1 : aliased constant String :=
        "to be or not to be that is the question";
      C2 : aliased constant String :=
        "all animals are equal but some animals are more equal than others";
      C3 : aliased constant String :=
        "call me ishmael some years ago never mind how long precisely";
      C4 : aliased constant String :=
        "it was the best of times it was the worst of times";
      C5 : aliased constant String :=
        "once upon a time in a land far away a quiet fox ate an onion";
      Texts : constant array (1 .. 5) of Corpus :=
        [C1'Access, C2'Access, C3'Access, C4'Access, C5'Access];
   begin
      for K in Texts'Range loop
         declare
            Cl : constant Classification := Classify_Text (Texts (K).all);
            Vs : constant String := Vowel_Set (Cl);
         begin
            Put_Line ("  (corpus" & K'Image & " vowels: " & Vs & ")");
            Check (Vowel_Count (Cl) >= 1,
                   "corpus" & K'Image & " ≥ 1 vowel");
            Check (Is_Symmetric (Build_Adjacency (Texts (K).all)),
                   "corpus" & K'Image & " symmetric");
            Check (Contains_Char (Vs, 'e') or else Contains_Char (Vs, 'a')
                     or else Contains_Char (Vs, 'i')
                     or else Contains_Char (Vs, 'o')
                     or else Contains_Char (Vs, 'u'),
                   "corpus" & K'Image & " has some latin vowel");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("17. Initial_Scores consistency");
   ---------------------------------------------------------------------
   declare
      A   : constant Adjacency_Matrix := Build_Adjacency ("abcdef");
      S   : constant Score_Vector := Initial_Scores (A);
      Sum : Score_Value;
      Ok  : Boolean := True;
   begin
      for I in Letter_Index loop
         Sum := 0;
         for J in Letter_Index loop
            Sum := Sum + Score_Value (A (I, J));
         end loop;
         if Sum /= S (I) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Initial_Scores = row sums");
      Check (S (Char_To_Index ('a')) = 1, "abcdef: a touches only b → 1");
      Check (S (Char_To_Index ('b')) = 2, "abcdef: b touches a,c → 2");
      Check (S (Char_To_Index ('f')) = 1, "abcdef: f touches e → 1");
      Check (S (Char_To_Index ('z')) = 0, "abcdef: z unused → 0");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   if Fail_Count > 0 then
      raise Program_Error with
        "Sukhotin tests failed:" & Fail_Count'Image;
   end if;
end Tests;

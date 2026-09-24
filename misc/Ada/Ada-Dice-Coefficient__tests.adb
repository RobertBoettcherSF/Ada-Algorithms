--  Standalone test suite for Dice_Coefficient (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Dice_Coefficient; use Dice_Coefficient;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Eps : constant Float := 1.0E-5;

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

   --  Non-static wrappers avoid -gnatwa constant-condition warnings.
   function F (X : Float) return Float is (X);
   function N (X : Natural) return Natural is (X);

   function Near (Got, Expect : Float) return Boolean is
   begin
      return abs (Got - Expect) <= Eps;
   end Near;

   function In_Unit (X : Float) return Boolean is
   begin
      return X >= 0.0 and then X <= 1.0;
   end In_Unit;

   function BC (S : String) return Natural is (Bigram_Count (S));
   function UC (S : String) return Natural is (Unique_Bigram_Count (S));
   function SB (A, B : String) return Natural is (Shared_Bigrams (A, B));
   function DC (A, B : String) return Float is (Coefficient (A, B));

   function BC_Raises (S : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Bigram_Count (S);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end BC_Raises;

   function UC_Raises (S : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Unique_Bigram_Count (S);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end UC_Raises;

   function SB_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Shared_Bigrams (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SB_Raises;

   function DC_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Coefficient (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DC_Raises;

   function Make_Same (L : Natural; C : Character) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := C;
      end loop;
      return R;
   end Make_Same;

   function Make_Alpha (L : Natural) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := Character'Val (Character'Pos ('a') + (K - 1) mod 26);
      end loop;
      return R;
   end Make_Alpha;

   function Make_Digits (L : Natural) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := Character'Val (Character'Pos ('0') + (K - 1) mod 10);
      end loop;
      return R;
   end Make_Digits;

   --  Slice with non-1 'First for arbitrary bounds checks.
   function Shifted (S : String) return String is
      R : String (5 .. 5 + S'Length - 1);
   begin
      for K in S'Range loop
         R (5 + (K - S'First)) := S (K);
      end loop;
      return R;
   end Shifted;

   --  Reconstruct Dice from Shared / Unique for formula cross-checks.
   function Formula_Dice (A, B : String) return Float is
      UA : constant Natural := Unique_Bigram_Count (A);
      UB : constant Natural := Unique_Bigram_Count (B);
      Inter : constant Natural := Shared_Bigrams (A, B);
      Denom : constant Natural := UA + UB;
   begin
      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;
      if Denom = 0 then
         return 0.0;
      end if;
      return 2.0 * Float (Inter) / Float (Denom);
   end Formula_Dice;

begin
   Put_Line ("Dice_Coefficient test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);

   ------------------------------------------------------------------
   Section ("1. Bigram_Count — empty and short");
   ------------------------------------------------------------------
   Check (BC ("") = N (0), "empty → 0");
   Check (BC ("a") = N (0), "single → 0");
   Check (BC ("Z") = N (0), "single Z → 0");
   Check (BC ("ab") = N (1), "ab → 1");
   Check (BC ("abc") = N (2), "abc → 2");
   Check (BC ("abcd") = N (3), "abcd → 3");
   Check (BC ("hello") = N (4), "hello → 4");
   Check (BC ("night") = N (4), "night → 4");
   Check (BC ("cheese") = N (5), "cheese → 5");
   Check (BC (Make_Same (10, 'x')) = N (9), "10 xs → 9");
   Check (BC (Make_Alpha (26)) = N (25), "alpha26 → 25");
   Check (BC (" ") = N (0), "single space → 0");
   Check (BC ("  ") = N (1), "two spaces → 1");

   ------------------------------------------------------------------
   Section ("2. Unique_Bigram_Count");
   ------------------------------------------------------------------
   Check (UC ("") = N (0), "empty unique → 0");
   Check (UC ("a") = N (0), "single unique → 0");
   Check (UC ("ab") = N (1), "ab unique → 1");
   Check (UC ("abc") = N (2), "abc unique → 2");
   Check (UC ("aaa") = N (1), "aaa → one unique aa");
   Check (UC ("aaaa") = N (1), "aaaa → one unique aa");
   Check (UC ("abab") = N (2), "abab → ab,ba");
   Check (UC ("abba") = N (3), "abba → ab,bb,ba");
   Check (UC ("hello") = N (4), "hello all distinct");
   Check (UC ("cheese") = N (5), "cheese all distinct");
   Check (UC (Make_Same (20, 'q')) = N (1), "20 qs → 1 unique");
   Check (UC ("night") = N (4), "night unique 4");
   Check (UC ("nacht") = N (4), "nacht unique 4");

   ------------------------------------------------------------------
   Section ("3. Shared_Bigrams — unique intersection");
   ------------------------------------------------------------------
   Check (SB ("", "") = N (0), "empty/empty shared 0");
   Check (SB ("", "ab") = N (0), "empty/ab shared 0");
   Check (SB ("a", "b") = N (0), "singles shared 0");
   Check (SB ("ab", "ab") = N (1), "ab/ab shared 1");
   Check (SB ("ab", "cd") = N (0), "ab/cd shared 0");
   Check (SB ("abc", "bcd") = N (1), "abc/bcd share bc");
   Check (SB ("night", "nacht") = N (1), "night/nacht share ht");
   Check (SB ("cheese", "chese") = N (4), "cheese/chese share 4");
   Check (SB ("hello", "yellow") = N (3), "hello/yellow share el,ll,lo");
   --  abcdef bigrams: ab bc cd de ef; defghi: de ef fg gh hi → share de,ef = 2
   Check (SB ("abcdef", "defghi") = N (2), "abcdef/defghi share de,ef");
   Check (SB ("night", "night") = N (4), "identical night shared 4");
   Check (SB ("abc", "xyz") = N (0), "abc/xyz disjoint");
   Check (SB ("aaa", "aaaa") = N (1), "aaa/aaaa share aa");

   ------------------------------------------------------------------
   Section ("4. Coefficient — edge cases (empty / short)");
   ------------------------------------------------------------------
   Check (Near (DC ("", ""), F (1.0)), "both empty → 1");
   Check (Near (DC ("", "a"), F (0.0)), "empty vs a → 0");
   Check (Near (DC ("a", ""), F (0.0)), "a vs empty → 0");
   Check (Near (DC ("", "abc"), F (0.0)), "empty vs abc → 0");
   Check (Near (DC ("xyz", ""), F (0.0)), "xyz vs empty → 0");
   Check (Near (DC ("a", "b"), F (0.0)), "two singles → 0 (denom 0)");
   Check (Near (DC ("a", "a"), F (0.0)), "same single → 0 (denom 0)");
   Check (Near (DC ("x", "yz"), F (0.0)), "single vs double → 0");
   Check (Near (DC ("ab", "c"), F (0.0)), "double vs single → 0");
   Check (Near (DC ("", Make_Same (10, 'x')), F (0.0)), "empty vs 10");
   Check (Near (DC (Make_Same (7, 'z'), ""), F (0.0)), "7 vs empty");

   ------------------------------------------------------------------
   Section ("5. Coefficient — identical and bounds");
   ------------------------------------------------------------------
   Check (Near (DC ("ab", "ab"), F (1.0)), "ab=ab → 1");
   Check (Near (DC ("abc", "abc"), F (1.0)), "abc=abc → 1");
   Check (Near (DC ("abcd", "abcd"), F (1.0)), "abcd=abcd → 1");
   Check (Near (DC ("hello", "hello"), F (1.0)), "hello=hello → 1");
   Check (Near (DC ("night", "night"), F (1.0)), "night=night → 1");
   Check (Near (DC ("cheese", "cheese"), F (1.0)), "cheese=cheese → 1");
   Check (Near (DC (Make_Same (20, 'q'), Make_Same (20, 'q')), F (1.0)),
          "identical 20 qs → 1");
   Check (Near (DC (Make_Alpha (50), Make_Alpha (50)), F (1.0)),
          "identical alpha-50 → 1");
   declare
      D : constant Float := DC ("abcdef", "xyzuvw");
   begin
      Check (Near (D, F (0.0)), "disjoint → 0");
      Check (In_Unit (D), "disjoint in [0,1]");
   end;
   declare
      D : constant Float := DC ("abcdef", "defghi");
   begin
      Check (Near (D, F (0.4)), "abcdef/defghi → 0.4");
      Check (In_Unit (D), "partial overlap in [0,1]");
   end;
   declare
      D : constant Float := DC ("abcde", "bcdef");
   begin
      Check (In_Unit (D), "shift overlap in [0,1]");
      Check (D > 0.0 and then D < 1.0, "shift strictly between");
   end;
   Check (Near (DC ("aaa", "aaaa"), F (1.0)), "aaa/aaaa unique aa → 1");
   Check (Near (DC ("ABC", "abc"), F (0.0)), "case mismatch → 0");

   ------------------------------------------------------------------
   Section ("6. Known Wikipedia / classic pairs");
   ------------------------------------------------------------------
   --  night / nacht → 0.25
   Check (Near (DC ("night", "nacht"), F (0.25)), "night/nacht = 0.25");
   Check (Near (DC ("nacht", "night"), F (0.25)), "nacht/night symmetric");
   --  cheese / chese → 8/9
   Check (Near (DC ("cheese", "chese"), F (8.0 / 9.0)),
          "cheese/chese = 8/9");
   Check (Near (DC ("chese", "cheese"), F (8.0 / 9.0)),
          "chese/cheese symmetric");
   --  healed / sealed: he,ea,al,le,ed vs se,ea,al,le,ed → share 4 of 5+5
   Check (Near (DC ("healed", "sealed"), F (0.8)),
          "healed/sealed = 0.8");
   --  abcd / abce
   Check (Near (DC ("abcd", "abce"),
                F (2.0 * 2.0 / (3.0 + 3.0))),
          "abcd/abce = 4/6");

   ------------------------------------------------------------------
   Section ("7. Symmetry and reflexivity");
   ------------------------------------------------------------------
   Check (Near (DC ("hello", "yellow"), DC ("yellow", "hello")),
          "commutative hello/yellow");
   Check (Near (DC ("kitten", "sitting"), DC ("sitting", "kitten")),
          "commutative kitten/sitting");
   Check (Near (DC ("night", "nacht"), DC ("nacht", "night")),
          "commutative night/nacht");
   Check (Near (DC ("color", "colour"), DC ("colour", "color")),
          "commutative color/colour");
   Check (Near (DC ("abc", "xyz"), DC ("xyz", "abc")),
          "commutative abc/xyz");
   declare
      S : constant String := "abracadabra";
   begin
      Check (Near (DC (S, S), F (1.0)), "reflexive abracadabra");
   end;
   declare
      S : constant String := Make_Alpha (40);
   begin
      Check (Near (DC (S, S), F (1.0)), "reflexive alpha40");
   end;
   Check (SB ("hello", "yellow") = SB ("yellow", "hello"),
          "Shared commutative");

   ------------------------------------------------------------------
   Section ("8. Case sensitivity");
   ------------------------------------------------------------------
   Check (Near (DC ("AbC", "abc"), F (0.0)), "AbC/abc Dice 0");
   --  Hello: He,el,ll,lo vs hello: he,el,ll,lo → share el,ll,lo → 6/8
   Check (Near (DC ("Hello", "hello"), F (0.75)), "Hello/hello share 3/4");
   Check (Near (DC ("HELLO", "hello"), F (0.0)), "HELLO/hello 0");
   Check (Near (DC ("ABC", "ABC"), F (1.0)), "ABC/ABC 1");
   Check (Near (DC ("aB", "Ab"), F (0.0)), "aB/Ab no shared");
   Check (BC ("Ab") = N (1), "Ab count 1");
   Check (UC ("AaAa") = N (2), "AaAa → Aa,aA");

   ------------------------------------------------------------------
   Section ("9. Spaces, punctuation, digits");
   ------------------------------------------------------------------
   Check (BC ("a b") = N (2), "a b → 2 bigrams");
   Check (Near (DC ("a b", "a b"), F (1.0)), "space identical");
   Check (Near (DC ("12", "12"), F (1.0)), "digits identical");
   Check (Near (DC ("12", "23"), F (0.0)), "12/23 disjoint");
   Check (Near (DC ("1-2", "1-2"), F (1.0)), "punct identical");
   Check (SB ("hi!", "hi?") = N (1), "hi!/hi? share hi");
   Check (Near (DC ("hi!", "hi?"), F (2.0 / 4.0)), "hi!/hi? = 0.5");
   Check (BC ("...") = N (2), "dots occurrences 2");
   Check (UC ("...") = N (1), "dots unique 1");

   ------------------------------------------------------------------
   Section ("10. Non-1'First string slices");
   ------------------------------------------------------------------
   declare
      S1 : constant String := Shifted ("night");
      S2 : constant String := Shifted ("nacht");
   begin
      Check (S1'First /= 1, "shifted First /= 1");
      Check (Near (DC (S1, S2), F (0.25)), "shifted night/nacht");
      Check (BC (S1) = N (4), "shifted night count");
      Check (UC (S1) = N (4), "shifted night unique");
      Check (SB (S1, S2) = N (1), "shifted shared");
   end;
   declare
      S : constant String := Shifted ("cheese");
      T : constant String := Shifted ("chese");
   begin
      Check (Near (DC (S, T), F (8.0 / 9.0)), "shifted cheese/chese");
   end;
   Check (Near (DC (Shifted ("ab"), Shifted ("ab")), F (1.0)),
          "shifted ab=ab");

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument — Max_Len");
   ------------------------------------------------------------------
   declare
      Over : constant String := Make_Same (Max_Len + 1, 'x');
      Ok   : constant String := Make_Same (Max_Len, 'y');
   begin
      Check (BC_Raises (Over), "Bigram_Count raises on Max_Len+1");
      Check (UC_Raises (Over), "Unique raises on Max_Len+1");
      Check (SB_Raises (Over, "ab"), "Shared raises left over");
      Check (SB_Raises ("ab", Over), "Shared raises right over");
      Check (DC_Raises (Over, "ab"), "Coeff raises left over");
      Check (DC_Raises ("ab", Over), "Coeff raises right over");
      Check (not BC_Raises (Ok), "Bigram_Count accepts Max_Len");
      Check (not DC_Raises (Ok, "ab"), "Coeff accepts Max_Len left");
      Check (BC (Ok) = Max_Len - 1, "Max_Len occurrences");
      Check (UC (Ok) = N (1), "Max_Len all-same unique 1");
   end;

   ------------------------------------------------------------------
   Section ("12. Modest sizes and Max_Len boundary helpers");
   ------------------------------------------------------------------
   Check (Near (DC (Make_Alpha (100), Make_Alpha (100)), F (1.0)),
          "alpha100 identical");
   Check (Near (DC (Make_Digits (80), Make_Digits (80)), F (1.0)),
          "digits80 identical");
   declare
      A : constant String := Make_Alpha (60);
      B : constant String := Make_Alpha (60);
      --  B shifted by rotating: start at 'b'
      C : String (1 .. 60);
   begin
      for K in 1 .. 60 loop
         C (K) := Character'Val
           (Character'Pos ('a') + (K) mod 26);
      end loop;
      Check (Near (DC (A, B), F (1.0)), "alpha60 twin");
      --  Full alphabet cycle: rotate-by-1 yields the same unique bigram set
      Check (Near (DC (A, C), F (1.0)), "alpha60 vs rotated same unique set");
      Check (In_Unit (DC (A, Make_Digits (60))), "alpha vs digits in unit");
      Check (Near (DC (A, Make_Digits (60)), F (0.0)), "alpha vs digits 0");
   end;
   Check (BC (Make_Same (1, 'z')) = N (0), "len1 count 0");
   Check (BC (Make_Same (2, 'z')) = N (1), "len2 count 1");
   Check (BC (Make_Same (3, 'z')) = N (2), "len3 count 2");

   ------------------------------------------------------------------
   Section ("13. Cross-checks: Shared vs Dice formula");
   ------------------------------------------------------------------
   declare
      procedure Cross (A, B : String; Label : String) is
         Got : constant Float := DC (A, B);
         Exp : constant Float := Formula_Dice (A, B);
      begin
         Check (Near (Got, Exp), "formula " & Label);
         Check (In_Unit (Got), "unit " & Label);
      end Cross;
   begin
      Cross ("night", "nacht", "night/nacht");
      Cross ("cheese", "chese", "cheese/chese");
      Cross ("hello", "yellow", "hello/yellow");
      Cross ("kitten", "sitting", "kitten/sitting");
      Cross ("abcdef", "defghi", "abcdef/defghi");
      Cross ("abc", "xyz", "abc/xyz");
      Cross ("aaa", "aaaa", "aaa/aaaa");
      Cross ("healed", "sealed", "healed/sealed");
      Cross ("color", "colour", "color/colour");
      Cross ("", "", "empty/empty");
      Cross ("a", "b", "a/b");
      Cross ("ab", "ab", "ab/ab");
   end;

   ------------------------------------------------------------------
   Section ("14. Occurrences vs unique (multiset contrast)");
   ------------------------------------------------------------------
   Check (BC ("aaa") = N (2), "aaa occ 2");
   Check (UC ("aaa") = N (1), "aaa unique 1");
   Check (BC ("aaaa") = N (3), "aaaa occ 3");
   Check (UC ("aaaa") = N (1), "aaaa unique 1");
   Check (BC ("ababab") = N (5), "ababab occ 5");
   Check (UC ("ababab") = N (2), "ababab unique ab,ba");
   Check (BC ("abcabc") = N (5), "abcabc occ 5");
   Check (UC ("abcabc") = N (3), "abcabc unique 3 (ab,bc,ca)");
   Check (Near (DC ("abab", "baba"),
                F (2.0 * 2.0 / (2.0 + 2.0))),
          "abab/baba = 1 (same unique set)");

   ------------------------------------------------------------------
   Section ("15. Exhaustive tiny alphabet pairs");
   ------------------------------------------------------------------
   declare
      Letters : constant String := "abcd";
   begin
      for I in Letters'Range loop
         for J in Letters'Range loop
            declare
               A : constant String := Letters (I .. I);
               B : constant String := Letters (J .. J);
            begin
               Check (Near (DC (A, B), F (0.0)),
                      "single pair denom0");
            end;
         end loop;
      end loop;
   end;
   --  All length-2 pairs from {a,b,c}
   declare
      Pairs : constant array (1 .. 9) of String (1 .. 2) :=
        ["aa", "ab", "ac", "ba", "bb", "bc", "ca", "cb", "cc"];
   begin
      for I in Pairs'Range loop
         Check (Near (DC (Pairs (I), Pairs (I)), F (1.0)),
                "len2 reflexive");
         for J in Pairs'Range loop
            declare
               D : constant Float := DC (Pairs (I), Pairs (J));
            begin
               Check (In_Unit (D), "len2 pair in unit");
               if I = J then
                  Check (Near (D, F (1.0)), "len2 equal → 1");
               elsif Pairs (I) = Pairs (J) then
                  null;
               else
                  --  Distinct bigrams → 0
                  Check (Near (D, F (0.0)), "distinct bigrams → 0");
               end if;
            end;
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("16. One-character edits (fuzzy intuition)");
   ------------------------------------------------------------------
   declare
      D1 : constant Float := DC ("kitten", "sitting");
      D2 : constant Float := DC ("kitten", "kitten");
      D3 : constant Float := DC ("kitten", "zzzzzz");
   begin
      Check (In_Unit (D1), "kitten/sitting in unit");
      Check (Near (D2, F (1.0)), "kitten identical");
      Check (Near (D3, F (0.0)), "kitten/zzzzzz 0");
      Check (D1 > D3, "edit closer than junk");
      Check (D2 > D1, "identical > edit");
   end;
   declare
      D1 : constant Float := DC ("color", "colour");
      D2 : constant Float := DC ("color", "colourx");
   begin
      Check (In_Unit (D1), "color/colour in unit");
      Check (D1 > 0.0, "color/colour > 0");
      Check (In_Unit (D2), "color/colourx in unit");
   end;
   --  book: bo,oo,ok; back: ba,ac,ck → disjoint → 0
   Check (Near (DC ("book", "back"), F (0.0)), "book/back disjoint");
   Check (DC ("book", "books") > 0.5, "book/books high overlap");

   ------------------------------------------------------------------
   Section ("17. Jaccard relation DSC = 2J/(1+J)");
   ------------------------------------------------------------------
   declare
      procedure Jaccard_Check (A, B : String; Label : String) is
         Inter : constant Natural := Shared_Bigrams (A, B);
         UA    : constant Natural := Unique_Bigram_Count (A);
         UB    : constant Natural := Unique_Bigram_Count (B);
         Union : constant Natural := UA + UB - Inter;
         D     : constant Float := DC (A, B);
         J, D_From_J : Float;
      begin
         if Union = 0 then
            Check (True, "Jaccard skip empty-union " & Label);
            return;
         end if;
         J := Float (Inter) / Float (Union);
         D_From_J := 2.0 * J / (1.0 + J);
         Check (Near (D, D_From_J), "DSC=2J/(1+J) " & Label);
      end Jaccard_Check;
   begin
      Jaccard_Check ("night", "nacht", "night/nacht");
      Jaccard_Check ("cheese", "chese", "cheese/chese");
      Jaccard_Check ("hello", "yellow", "hello/yellow");
      Jaccard_Check ("healed", "sealed", "healed/sealed");
      Jaccard_Check ("abcdef", "defghi", "abcdef/defghi");
      Jaccard_Check ("kitten", "sitting", "kitten/sitting");
      Jaccard_Check ("abc", "abc", "abc/abc");
      Jaccard_Check ("ab", "cd", "ab/cd");
   end;

   ------------------------------------------------------------------
   Section ("18. Latin-1 octets and binary-ish characters");
   ------------------------------------------------------------------
   declare
      C1 : constant Character := Character'Val (200);
      C2 : constant Character := Character'Val (201);
      S1 : constant String := [C1, C2];
      S2 : constant String := [C1, C2];
      S3 : constant String := [C2, C1];
   begin
      Check (Near (DC (S1, S2), F (1.0)), "latin1 identical");
      Check (Near (DC (S1, S3), F (0.0)), "latin1 reversed disjoint");
      Check (BC (S1) = N (1), "latin1 count");
   end;
   declare
      N1 : constant String := [ASCII.NUL, 'a'];
   begin
      Check (Near (DC (N1, N1), F (1.0)), "NUL-a identical");
   end;

   ------------------------------------------------------------------
   Section ("19. Additional occurrence / uniqueness table");
   ------------------------------------------------------------------
   Check (BC ("xy") = UC ("xy"), "xy occ=unique");
   Check (BC ("xyz") = UC ("xyz"), "xyz occ=unique");
   Check (BC ("aaaaa") > UC ("aaaaa"), "aaaaa occ>unique");
   Check (BC ("mississippi") >= UC ("mississippi"),
          "mississippi occ>=unique");
   Check (UC ("mississippi") > N (0), "mississippi unique > 0");
   Check (Near (DC ("mississippi", "mississippi"), F (1.0)),
          "mississippi reflexive");
   Check (SB ("miss", "miss") = UC ("miss"),
          "identical shared = unique");
   Check (SB ("abc", "ab") = N (1), "abc/ab share ab");
   Check (Near (DC ("abc", "ab"), F (2.0 * 1.0 / (2.0 + 1.0))),
          "abc/ab = 2/3");
   Check (Near (DC ("ab", "abc"), F (2.0 / 3.0)), "ab/abc = 2/3");

   ------------------------------------------------------------------
   Section ("20. Bounds stress and random-ish ladders");
   ------------------------------------------------------------------
   for L in 2 .. 30 loop
      declare
         S : constant String := Make_Alpha (L);
         D : constant Float := DC (S, S);
      begin
         Check (Near (D, F (1.0)), "ladder identical");
         Check (BC (S) = L - 1, "ladder count");
      end;
   end loop;
   for L in 2 .. 15 loop
      declare
         S : constant String := Make_Same (L, 'm');
      begin
         Check (UC (S) = N (1), "all-same unique 1");
         Check (Near (DC (S, Make_Same (L + 3, 'm')), F (1.0)),
                "all-same different lens → 1");
      end;
   end loop;

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

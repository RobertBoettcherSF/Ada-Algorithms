--  Standalone test suite for Trigram_Search (main program).

pragma Ada_2022;

with Ada.Text_IO;    use Ada.Text_IO;
with Trigram_Search; use Trigram_Search;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Eps : constant Float := 1.0E-5;

   procedure Check (Condition : Boolean;
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function N (X : Natural) return Natural is (X);
   function F (X : Float) return Float is (X);

   function Near (Got, Expect : Float) return Boolean is
   begin
      return abs (Got - Expect) <= Eps;
   end Near;

   function Count_Raises (S : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Trigram_Count (S);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Count_Raises;

   function Unique_Raises (S : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Unique_Trigram_Count (S);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Unique_Raises;

   function Shared_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Shared_Trigrams (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Shared_Raises;

   function Dice_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Dice_Coefficient (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dice_Raises;

   function Contains_Raises (H, Nd : String) return Boolean is
      Unused : Boolean;
   begin
      Unused := Contains_Trigram (H, Nd);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Contains_Raises;

   function Has_Raises (H, Tri : String) return Boolean is
      Unused : Boolean;
   begin
      Unused := Has_Trigram (H, Tri);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Has_Raises;

   --  Build a string of length L filled with cycling 'a'..'z'.
   function Make_Alpha (L : Natural) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := Character'Val (Character'Pos ('a') + (K - 1) mod 26);
      end loop;
      return R;
   end Make_Alpha;

   --  String of L identical characters.
   function Make_Same (L : Natural; C : Character) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := C;
      end loop;
      return R;
   end Make_Same;

begin
   Put_Line ("Trigram_Search test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);

   -----------------------------------------------------------------
   Section ("1. Trigram_Count — empty and short");
   -----------------------------------------------------------------
   Check (Trigram_Count ("") = N (0), "empty → 0");
   Check (Trigram_Count ("a") = N (0), "len 1 → 0");
   Check (Trigram_Count ("ab") = N (0), "len 2 → 0");
   Check (Trigram_Count ("abc") = N (1), "len 3 → 1");
   Check (Trigram_Count ("abcd") = N (2), "len 4 → 2");
   Check (Trigram_Count ("abcde") = N (3), "len 5 → 3");
   Check (Trigram_Count ("hello") = N (3), "hello → 3");
   Check (Trigram_Count ("trigram") = N (5), "trigram → 5");
   Check (Trigram_Count ("   ") = N (1), "three spaces → 1");
   Check (Trigram_Count ("a b") = N (1), "a b → 1");

   -----------------------------------------------------------------
   Section ("2. Unique_Trigram_Count");
   -----------------------------------------------------------------
   Check (Unique_Trigram_Count ("") = N (0), "empty unique 0");
   Check (Unique_Trigram_Count ("ab") = N (0), "short unique 0");
   Check (Unique_Trigram_Count ("abc") = N (1), "abc unique 1");
   Check (Unique_Trigram_Count ("aaaa") = N (1), "aaaa → one unique aaa");
   Check (Unique_Trigram_Count ("aaa") = N (1), "aaa → one unique");
   Check (Unique_Trigram_Count ("abab") = N (2), "abab → aba,bab");
   --  windows: abc,bca,cab,abc → unique {abc,bca,cab} = 3
   Check (Unique_Trigram_Count ("abcabc") = N (3), "abcabc unique 3");
   Check (Unique_Trigram_Count ("abcdef") = N (4), "abcdef unique 4");
   Check (Unique_Trigram_Count ("xyzxyz") = N (3), "xyzxyz unique 3");
   Check (Unique_Trigram_Count ("mississippi") =
            Unique_Trigram_Count ("mississippi"), "idempotent miss");

   -----------------------------------------------------------------
   Section ("3. Shared_Trigrams — unique intersection");
   -----------------------------------------------------------------
   Check (Shared_Trigrams ("", "") = N (0), "both empty shared 0");
   Check (Shared_Trigrams ("ab", "abc") = N (0), "short A shared 0");
   Check (Shared_Trigrams ("abc", "ab") = N (0), "short B shared 0");
   Check (Shared_Trigrams ("abc", "abc") = N (1), "identical abc → 1");
   Check (Shared_Trigrams ("abcd", "abcd") = N (2), "identical abcd → 2");
   Check (Shared_Trigrams ("abc", "xyz") = N (0), "disjoint → 0");
   Check (Shared_Trigrams ("abcdef", "defghi") = N (1),
          "abcdef ∩ defghi → def");
   Check (Shared_Trigrams ("hello", "yellow") = Shared_Trigrams ("yellow", "hello"),
          "shared commutative");
   Check (Shared_Trigrams ("abcde", "bcdef") = N (2),
          "abcde ∩ bcdef → bcd,cde");
   Check (Shared_Trigrams ("aaa", "aaaa") = N (1), "aaa ∩ aaaa → aaa");
   Check (Shared_Trigrams ("trigram", "diagram") >= N (1),
          "trigram/diagram share ≥1");
   Check (Shared_Trigrams ("kitten", "sitting") >= N (1),
          "kitten/sitting share ≥1");
   Check (Shared_Trigrams ("abc", "ABC") = N (0), "case-sensitive no share");

   -----------------------------------------------------------------
   Section ("4. Dice_Coefficient — edge cases");
   -----------------------------------------------------------------
   Check (Near (Dice_Coefficient ("", ""), F (1.0)), "both empty → 1");
   Check (Near (Dice_Coefficient ("", "a"), F (0.0)), "empty vs a → 0");
   Check (Near (Dice_Coefficient ("a", ""), F (0.0)), "a vs empty → 0");
   Check (Near (Dice_Coefficient ("ab", "ab"), F (0.0)), "both short → 0");
   Check (Near (Dice_Coefficient ("ab", "abc"), F (0.0)), "one short → 0");
   Check (Near (Dice_Coefficient ("abc", "ab"), F (0.0)), "other short → 0");
   Check (Near (Dice_Coefficient ("a", "b"), F (0.0)), "two singles → 0");
   Check (Near (Dice_Coefficient ("xy", "yz"), F (0.0)), "two doubles → 0");

   -----------------------------------------------------------------
   Section ("5. Dice_Coefficient — identical and bounds");
   -----------------------------------------------------------------
   Check (Near (Dice_Coefficient ("abc", "abc"), F (1.0)), "abc=abc → 1");
   Check (Near (Dice_Coefficient ("abcd", "abcd"), F (1.0)), "abcd=abcd → 1");
   Check (Near (Dice_Coefficient ("hello", "hello"), F (1.0)), "hello=hello → 1");
   Check (Near (Dice_Coefficient ("trigram", "trigram"), F (1.0)),
          "trigram=trigram → 1");
   declare
      D : constant Float := Dice_Coefficient ("abcdef", "xyzuvw");
   begin
      Check (Near (D, F (0.0)), "disjoint → 0");
      Check (D >= F (0.0) and then D <= F (1.0), "disjoint in [0,1]");
   end;
   declare
      D : constant Float := Dice_Coefficient ("abcdef", "defghi");
      --  TA={abc,bcd,cde,def} TB={def,efg,fgh,ghi} ∩={def} → 2*1/(4+4)=0.25
   begin
      Check (Near (D, F (0.25)), "abcdef/defghi → 0.25");
   end;
   declare
      D : constant Float := Dice_Coefficient ("abcde", "bcdef");
      --  TA={abc,bcd,cde} TB={bcd,cde,def} ∩=2 → 4/6 ≈ 0.666...
   begin
      Check (Near (D, 4.0 / 6.0), "abcde/bcdef → 4/6");
      Check (D > F (0.0) and then D < F (1.0), "partial in (0,1)");
   end;
   Check (Near (Dice_Coefficient ("aaa", "aaaa"), F (1.0)),
          "aaa/aaaa both {aaa} → 1");
   Check (Near (Dice_Coefficient ("ABC", "abc"), F (0.0)),
          "case differs → 0");

   -----------------------------------------------------------------
   Section ("6. Dice symmetry and reflexivity");
   -----------------------------------------------------------------
   Check (Near (Dice_Coefficient ("hello", "yellow"),
                Dice_Coefficient ("yellow", "hello")),
          "Dice commutative hello/yellow");
   Check (Near (Dice_Coefficient ("kitten", "sitting"),
                Dice_Coefficient ("sitting", "kitten")),
          "Dice commutative kitten/sitting");
   Check (Near (Dice_Coefficient ("night", "nacht"),
                Dice_Coefficient ("nacht", "night")),
          "Dice commutative night/nacht");
   declare
      S : constant String := "abracadabra";
   begin
      Check (Near (Dice_Coefficient (S, S), F (1.0)), "reflexive abracadabra");
   end;
   declare
      S : constant String := Make_Alpha (40);
   begin
      Check (Near (Dice_Coefficient (S, S), F (1.0)), "reflexive alpha40");
   end;

   -----------------------------------------------------------------
   Section ("7. Contains_Trigram — fuzzy containment");
   -----------------------------------------------------------------
   Check (Contains_Trigram ("hello", ""), "vacuous empty needle");
   Check (Contains_Trigram ("hello", "ab"), "vacuous short needle");
   Check (Contains_Trigram ("", "ab"), "vacuous short in empty hay");
   Check (not (Contains_Trigram ("", "abc")), "needle trigram, empty hay");
   Check (not (Contains_Trigram ("ab", "abc")), "short hay vs abc");
   Check (Contains_Trigram ("abcdef", "abc"), "abc in abcdef");
   Check (Contains_Trigram ("abcdef", "cde"), "cde in abcdef");
   Check (Contains_Trigram ("abcdef", "def"), "def in abcdef");
   Check (not (Contains_Trigram ("abcdef", "xyz")), "xyz not in abcdef");
   Check (Contains_Trigram ("abcdef", "bcd"), "bcd in abcdef");
   Check (Contains_Trigram ("abcdef", "abcdef"), "self containment");
   Check (Contains_Trigram ("aaaa", "aaa"), "aaa in aaaa");
   Check (Contains_Trigram ("hello world", "llo"), "llo in hello world");
   Check (Contains_Trigram ("hello world", "wor"), "wor in hello world");
   Check (not (Contains_Trigram ("hello world", "xyz")), "xyz not in hello world");
   --  Needle with several unique trigrams all present
   Check (Contains_Trigram ("abcdefgh", "abcdef"), "abcdef trigrams ⊆ abcdefgh");
   Check (not (Contains_Trigram ("abcdef", "abcdefgh")), "longer needle not contained");
   Check (not (Contains_Trigram ("ABC", "abc")), "case-sensitive contain");

   -----------------------------------------------------------------
   Section ("8. Has_Trigram — single window membership");
   -----------------------------------------------------------------
   Check (Has_Trigram ("abcdef", "abc"), "has abc");
   Check (Has_Trigram ("abcdef", "bcd"), "has bcd");
   Check (Has_Trigram ("abcdef", "cde"), "has cde");
   Check (Has_Trigram ("abcdef", "def"), "has def");
   Check (not (Has_Trigram ("abcdef", "xyz")), "no xyz");
   Check (not (Has_Trigram ("abcdef", "abx")), "no abx");
   Check (Has_Trigram ("aaa", "aaa"), "has aaa");
   Check (not (Has_Trigram ("ab", "abc")), "short hay no window");
   Check (not (Has_Trigram ("", "abc")), "empty hay no window");
   Check (Has_Trigram ("hello", "ell"), "has ell");
   Check (not (Has_Trigram ("hello", "Hel")), "case miss Hel");
   Check (Has_Trigram ("a b c", "a b"), "has a b with space");
   Check (Has_Trigram ("a b c", " b "), "has  b ");
   Check (Has_Trigram ("a b c", "b c"), "has b c");

   -----------------------------------------------------------------
   Section ("9. Case sensitivity");
   -----------------------------------------------------------------
   Check (Trigram_Count ("AbC") = N (1), "AbC count 1");
   Check (Shared_Trigrams ("AbC", "abc") = N (0), "AbC vs abc share 0");
   Check (Near (Dice_Coefficient ("AbC", "abc"), F (0.0)), "AbC/abc Dice 0");
   Check (Has_Trigram ("AbCdEf", "AbC"), "has AbC");
   Check (not (Has_Trigram ("AbCdEf", "abc")), "no abc in AbCdEf");
   Check (not (Contains_Trigram ("Hello", "hel")), "Hello ⊈ hel");
   Check (Contains_Trigram ("Hello", "Hel"), "Hel ⊆ Hello");
   Check (Unique_Trigram_Count ("AaA") = N (1), "AaA unique 1");
   Check (Shared_Trigrams ("ABCDE", "abcde") = N (0), "all-caps vs lower");

   -----------------------------------------------------------------
   Section ("10. One-character edits (fuzzy intuition)");
   -----------------------------------------------------------------
   declare
      D1 : constant Float := Dice_Coefficient ("kitten", "sitting");
      D2 : constant Float := Dice_Coefficient ("kitten", "kitten");
      D3 : constant Float := Dice_Coefficient ("kitten", "zzzzzz");
   begin
      Check (D1 > F (0.0) and then D1 < F (1.0), "kitten/sitting partial");
      Check (Near (D2, F (1.0)), "kitten identical");
      Check (Near (D3, F (0.0)), "kitten/zzzzzz none");
      Check (D1 > D3, "edit closer than unrelated");
   end;
   declare
      D1 : constant Float := Dice_Coefficient ("color", "colour");
      D2 : constant Float := Dice_Coefficient ("color", "xxxxxx");
   begin
      Check (D1 > D2, "color/colour > color/xxxxxx");
      Check (D1 > F (0.0), "color/colour share something");
   end;
   declare
      D1 : constant Float := Dice_Coefficient ("night", "nacht");
   begin
      Check (D1 >= F (0.0) and then D1 <= F (1.0), "night/nacht bounds");
   end;
   Check (Shared_Trigrams ("book", "back") >= N (0), "book/back shared ≥0");
   Check (Dice_Coefficient ("book", "back") < F (1.0), "book ≠ back");

   -----------------------------------------------------------------
   Section ("11. Spaces, punctuation, digits");
   -----------------------------------------------------------------
   Check (Trigram_Count ("a b c") = N (3), "a b c count 3");
   Check (Has_Trigram ("foo-bar", "o-b"), "has o-b");
   Check (Has_Trigram ("foo-bar", "foo"), "has foo");
   Check (Has_Trigram ("12345", "234"), "digits 234");
   Check (Near (Dice_Coefficient ("12 34", "12 34"), F (1.0)),
          "ident with space");
   Check (Shared_Trigrams ("a,b,c", "x,b,y") >= N (0), "punct shared ok");
   Check (Unique_Trigram_Count ("...") = N (1), "dots unique 1");
   Check (Has_Trigram ("...", "..."), "has ...");

   -----------------------------------------------------------------
   Section ("12. Non-1'First string slices");
   -----------------------------------------------------------------
   declare
      Buf : constant String (5 .. 10) := "abcdef";
   begin
      Check (Trigram_Count (Buf) = N (4), "slice First=5 count");
      Check (Unique_Trigram_Count (Buf) = N (4), "slice unique 4");
      Check (Has_Trigram (Buf, "abc"), "slice has abc");
      Check (Has_Trigram (Buf, "def"), "slice has def");
      Check (Near (Dice_Coefficient (Buf, Buf), F (1.0)), "slice reflexive");
      Check (Contains_Trigram (Buf, "bcd"), "slice contains bcd");
   end;
   declare
      Buf : constant String (2 .. 6) := "hello";
   begin
      Check (Trigram_Count (Buf) = N (3), "First=2 hello count");
      Check (Has_Trigram (Buf, "ell"), "First=2 has ell");
   end;

   -----------------------------------------------------------------
   Section ("13. Invalid_Argument — Max_Len and Has_Trigram");
   -----------------------------------------------------------------
   declare
      Big : constant String := Make_Alpha (Max_Len + 1);
      Ok  : constant String := Make_Alpha (Max_Len);
   begin
      Check (Count_Raises (Big), "Trigram_Count over Max_Len");
      Check (Unique_Raises (Big), "Unique over Max_Len");
      Check (Shared_Raises (Big, "abc"), "Shared A over Max_Len");
      Check (Shared_Raises ("abc", Big), "Shared B over Max_Len");
      Check (Dice_Raises (Big, "abc"), "Dice A over Max_Len");
      Check (Dice_Raises ("abc", Big), "Dice B over Max_Len");
      Check (Contains_Raises (Big, "abc"), "Contains hay over Max_Len");
      Check (Contains_Raises ("abc", Big), "Contains needle over Max_Len");
      Check (Has_Raises (Big, "abc"), "Has hay over Max_Len");
      Check (not Count_Raises (Ok), "Trigram_Count at Max_Len ok");
      Check (Trigram_Count (Ok) = Max_Len - 2, "count at Max_Len");
   end;
   Check (Has_Raises ("abcdef", "ab"), "Has Tri length 2");
   Check (Has_Raises ("abcdef", "abcd"), "Has Tri length 4");
   Check (Has_Raises ("abcdef", ""), "Has Tri length 0");
   Check (not Has_Raises ("abcdef", "abc"), "Has Tri length 3 ok");

   -----------------------------------------------------------------
   Section ("14. Modest sizes and Max_Len boundary");
   -----------------------------------------------------------------
   declare
      A50 : constant String := Make_Alpha (50);
      A51 : constant String := Make_Alpha (51);
      Same : constant String := Make_Same (30, 'x');
   begin
      Check (Trigram_Count (A50) = N (48), "alpha50 count 48");
      Check (Unique_Trigram_Count (A50) = N (26), "alpha50 unique 26 (a-z period)");
      Check (Near (Dice_Coefficient (A50, A50), F (1.0)), "alpha50 Dice 1");
      Check (Shared_Trigrams (A50, A51) = N (26), "alpha50/51 share 26");
      Check (Dice_Coefficient (A50, A51) > F (0.5), "alpha50/51 Dice > 0.5");
      Check (Unique_Trigram_Count (Same) = N (1), "xxxx… unique 1");
      Check (Near (Dice_Coefficient (Same, Same), F (1.0)), "samexxx Dice 1");
      Check (Contains_Trigram (A50, A50 (1 .. 10)), "prefix contain");
      Check (not Contains_Trigram (A50 (1 .. 10), A50), "prefix not reverse-contain");
   end;
   declare
      A200 : constant String := Make_Alpha (200);
      B200 : constant String := Make_Same (200, 'z');
   begin
      Check (Trigram_Count (A200) = N (198), "alpha200 count");
      Check (Unique_Trigram_Count (A200) = N (26), "alpha200 unique 26");
      Check (Near (Dice_Coefficient (A200, A200), F (1.0)), "alpha200 Dice 1");
      Check (Near (Dice_Coefficient (A200, B200), F (0.0)),
             "alpha vs zzz Dice 0");
      Check (Shared_Trigrams (A200, B200) = N (0), "alpha/zzz share 0");
   end;
   declare
      --  Stay well under Max_Len for comfort, but exercise hundreds.
      A400 : constant String := Make_Alpha (400);
   begin
      Check (Trigram_Count (A400) = N (398), "alpha400 count");
      Check (Near (Dice_Coefficient (A400, A400), F (1.0)), "alpha400 Dice 1");
      Check (Contains_Trigram (A400, "abc"), "abc in alpha400");
      Check (Has_Trigram (A400, "xyz"), "xyz in alpha400 cycle");
   end;

   -----------------------------------------------------------------
   Section ("15. Cross-checks: Shared vs Dice formula");
   -----------------------------------------------------------------
   declare
      procedure Cross (A, B, Label : String) is
         Ua : constant Natural := Unique_Trigram_Count (A);
         Ub : constant Natural := Unique_Trigram_Count (B);
         Sh : constant Natural := Shared_Trigrams (A, B);
         D  : constant Float := Dice_Coefficient (A, B);
         Expect : Float;
      begin
         if A'Length = 0 and then B'Length = 0 then
            Check (Near (D, F (1.0)), Label & " empty pair");
         elsif A'Length < 3 or else B'Length < 3 then
            Check (Near (D, F (0.0)), Label & " short pair");
         else
            Expect := 2.0 * Float (Sh) / Float (Ua + Ub);
            Check (Near (D, Expect), Label & " Dice=2∩/(|A|+|B|)");
            Check (Sh <= Ua and then Sh <= Ub, Label & " ∩ ≤ each");
         end if;
      end Cross;
   begin
      Cross ("hello", "yellow", "hello/yellow");
      Cross ("kitten", "sitting", "kitten/sitting");
      Cross ("abcdef", "defghi", "abcdef/defghi");
      Cross ("abc", "xyz", "abc/xyz");
      Cross ("trigram", "diagram", "trigram/diagram");
      Cross ("aaaa", "aaa", "aaaa/aaa");
      Cross ("night", "nacht", "night/nacht");
      Cross ("color", "colour", "color/colour");
      Cross (Make_Alpha (20), Make_Alpha (25), "alpha20/25");
      Cross ("", "", "empty/empty");
      Cross ("ab", "abc", "ab/abc");
   end;

   -----------------------------------------------------------------
   Section ("16. Occurrences vs unique (multiset contrast)");
   -----------------------------------------------------------------
   --  "aaaa" has 2 occurrence windows, both "aaa" → unique 1
   Check (Trigram_Count ("aaaa") = N (2), "aaaa occ 2");
   Check (Unique_Trigram_Count ("aaaa") = N (1), "aaaa unique 1");
   Check (Trigram_Count ("ababab") = N (4), "ababab occ 4");
   --  windows: aba,bab,aba,bab → unique {aba,bab}=2
   Check (Unique_Trigram_Count ("ababab") = N (2), "ababab unique 2");
   Check (Shared_Trigrams ("aaaa", "aaa") = N (1), "set not multiset");
   Check (Near (Dice_Coefficient ("aaaa", "aaa"), F (1.0)),
          "set Dice ignores multiplicity");

   -----------------------------------------------------------------
   Section ("17. Exhaustive tiny alphabet pairs");
   -----------------------------------------------------------------
   declare
      function Tiny (K : Positive) return String is
      begin
         case K is
            when 1 => return "";
            when 2 => return "a";
            when 3 => return "ab";
            when 4 => return "abc";
            when 5 => return "abd";
            when others => return "bcd";
         end case;
      end Tiny;
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            declare
               D : constant Float := Dice_Coefficient (Tiny (I), Tiny (J));
            begin
               Check (D >= F (0.0) and then D <= F (1.0),
                      "tiny bounds I=" & I'Image & " J=" & J'Image);
               Check (Near (D, Dice_Coefficient (Tiny (J), Tiny (I))),
                      "tiny sym I=" & I'Image & " J=" & J'Image);
            end;
         end loop;
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("18. Contains vs Has consistency");
   -----------------------------------------------------------------
   Check (Contains_Trigram ("abcdefghij", "cde") =
            Has_Trigram ("abcdefghij", "cde"),
          "single-trigram needle ≡ Has");
   Check (Contains_Trigram ("abcdefghij", "xyz") =
            Has_Trigram ("abcdefghij", "xyz"),
          "missing single ≡ Has");
   Check (Has_Trigram ("mississippi", "ssi"), "ssi in mississippi");
   Check (Has_Trigram ("mississippi", "iss"), "iss in mississippi");
   Check (Has_Trigram ("mississippi", "ppi"), "ppi in mississippi");
   Check (Contains_Trigram ("mississippi", "issi"), "issi trigrams ⊆ mississippi");

   -----------------------------------------------------------------
   Section ("19. Known hand-computed Dice");
   -----------------------------------------------------------------
   --  "gab" vs "nab": TA={gab} TB={nab} ∩=∅ → 0
   Check (Near (Dice_Coefficient ("gab", "nab"), F (0.0)), "gab/nab → 0");
   --  "gara" vs "gara": identity → 1
   Check (Near (Dice_Coefficient ("gara", "gara"), F (1.0)), "gara id");
   --  "he" vs "he": both short → 0
   Check (Near (Dice_Coefficient ("he", "he"), F (0.0)), "he/he short 0");
   --  Wikipedia-style intuition: "night" / "nacht"
   --  night → nig,igh,ght (3); nacht → nac,ach,cht (3); ∩=∅ → 0
   Check (Unique_Trigram_Count ("night") = N (3), "night unique 3");
   Check (Unique_Trigram_Count ("nacht") = N (3), "nacht unique 3");
   Check (Shared_Trigrams ("night", "nacht") = N (0), "night/nacht ∩ 0");
   Check (Near (Dice_Coefficient ("night", "nacht"), F (0.0)),
          "night/nacht Dice 0 (char trigrams)");
   --  With bigrams one often shares "ht"; character trigrams do not.
   --  "al" padded: use longer German/English pair that shares
   Check (Shared_Trigrams ("Schreiben", "schreibe") >= N (0),
          "Schreiben/schreibe (case)");
   Check (Shared_Trigrams ("schreiben", "schreibe") >= N (4),
          "schreiben/schreibe share many");

   -----------------------------------------------------------------
   Section ("20. Additional occurrence / uniqueness table");
   -----------------------------------------------------------------
   Check (Trigram_Count ("a") = Unique_Trigram_Count ("a"), "len1 both 0");
   Check (Trigram_Count ("xy") = Unique_Trigram_Count ("xy"), "len2 both 0");
   Check (Trigram_Count ("xyz") = Unique_Trigram_Count ("xyz"), "len3 equal");
   Check (Trigram_Count ("xyzz") = N (2), "xyzz occ 2");
   Check (Unique_Trigram_Count ("xyzz") = N (2), "xyzz unique 2");
   Check (Trigram_Count ("xxxx") = N (2), "xxxx occ 2");
   Check (Unique_Trigram_Count ("xxxx") = N (1), "xxxx unique 1");
   Check (Trigram_Count ("abab") = N (2), "abab occ 2");
   Check (Unique_Trigram_Count ("abab") = N (2), "abab unique 2");
   Check (Trigram_Count ("abcabcabc") = N (7), "abcabcabc occ 7");
   Check (Unique_Trigram_Count ("abcabcabc") = N (3),
          "abcabcabc unique 3");

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

--  Standalone test suite for String_Metrics (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with String_Metrics; use String_Metrics;

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
   function N (X : Natural) return Natural is (X);
   function F (X : Float) return Float is (X);
   function Near (Got, Expect : Float) return Boolean is
   begin
      return abs (Got - Expect) <= Eps;
   end Near;

   function Lev (A, B : String) return Natural is
     (Levenshtein (A, B));

   function OSA (A, B : String) return Natural is
     (Damerau_Levenshtein_OSA (A, B));

   function Ham (A, B : String) return Natural is
     (Hamming (A, B));

   function JW (A, B : String; P : Float := 0.1) return Float is
     (Jaro_Winkler_Similarity (A, B, P));

   function Dice (A, B : String) return Float is
     (Dice_Bigram (A, B));

   function NLev (A, B : String) return Float is
     (Normalized_Levenshtein_Similarity (A, B));

   function Lev_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Levenshtein (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Lev_Raises;

   function OSA_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Damerau_Levenshtein_OSA (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end OSA_Raises;

   function Ham_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Hamming (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Ham_Raises;

   function JW_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Jaro_Winkler_Similarity (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end JW_Raises;

   function Dice_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Dice_Bigram (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dice_Raises;

   function NLev_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Normalized_Levenshtein_Similarity (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end NLev_Raises;

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

   --  Slice with non-1 First for index-independence checks.
   function Slice_ABC return String is
      Buf : constant String (5 .. 7) := "abc";
   begin
      return Buf;
   end Slice_ABC;

begin
   Put_Line ("String_Metrics survey test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);

   ------------------------------------------------------------------
   -- Levenshtein
   ------------------------------------------------------------------
   Section ("1. Levenshtein empty / identical");
   Check (Lev ("", "") = N (0), "Lev empty/empty = 0");
   Check (Lev ("", "a") = N (1), "Lev empty/a = 1");
   Check (Lev ("a", "") = N (1), "Lev a/empty = 1");
   Check (Lev ("", "abc") = N (3), "Lev empty/abc = 3");
   Check (Lev ("xyz", "") = N (3), "Lev xyz/empty = 3");
   Check (Lev ("", Make_Same (10, 'x')) = N (10), "Lev empty vs 10");
   Check (Lev ("a", "a") = N (0), "Lev identical a");
   Check (Lev ("hello", "hello") = N (0), "Lev identical hello");
   Check (Lev (Make_Same (20, 'q'), Make_Same (20, 'q')) = N (0),
          "Lev identical 20 qs");
   Check (Lev (Make_Alpha (50), Make_Alpha (50)) = N (0),
          "Lev identical alpha50");

   Section ("2. Levenshtein classic examples");
   Check (Lev ("kitten", "sitting") = N (3), "Lev kitten/sitting = 3");
   Check (Lev ("sitting", "kitten") = N (3), "Lev sitting/kitten = 3");
   Check (Lev ("saturday", "sunday") = N (3), "Lev saturday/sunday = 3");
   Check (Lev ("sunday", "saturday") = N (3), "Lev sunday/saturday = 3");
   Check (Lev ("book", "back") = N (2), "Lev book/back = 2");
   Check (Lev ("flaw", "lawn") = N (2), "Lev flaw/lawn = 2");
   Check (Lev ("gumbo", "gambol") = N (2), "Lev gumbo/gambol = 2");
   Check (Lev ("ca", "abc") = N (3), "Lev ca/abc = 3");

   Section ("3. Levenshtein single edits");
   Check (Lev ("a", "b") = N (1), "Lev substitute");
   Check (Lev ("ab", "a") = N (1), "Lev delete last");
   Check (Lev ("a", "ab") = N (1), "Lev insert last");
   Check (Lev ("abc", "ac") = N (1), "Lev delete middle");
   Check (Lev ("ac", "abc") = N (1), "Lev insert middle");
   Check (Lev ("abc", "xbc") = N (1), "Lev sub first");
   Check (Lev ("abc", "axc") = N (1), "Lev sub middle");
   Check (Lev ("abc", "abx") = N (1), "Lev sub last");
   Check (Lev ("ab", "ba") = N (2), "Lev transposition costs 2");
   Check (Lev ("abc", "acb") = N (2), "Lev adjacent swap 2");

   Section ("4. Levenshtein symmetry / cases");
   Check (Lev ("Abc", "abc") = N (1), "Lev case sensitive");
   Check (Lev ("ABC", "abc") = N (3), "Lev all case diff");
   Check (Lev ("hello", "hallo") = N (1), "Lev hello/hallo");
   Check (Lev ("algorithm", "altruistic") = N (6),
          "Lev algorithm/altruistic");
   Check (Lev (Make_Alpha (5), Make_Digits (5)) = N (5),
          "Lev alpha5 vs digits5");
   Check (Lev ("aa", "aaaa") = N (2), "Lev aa/aaaa");
   Check (Lev ("aaaa", "aa") = N (2), "Lev aaaa/aa");
   Check (Lev ("xyz", "abc") = N (3), "Lev all different");
   Check (Lev (Slice_ABC, "abc") = N (0), "Lev non-1 First slice");
   Check (Lev ("abc", Slice_ABC) = N (0), "Lev vs non-1 First");

   ------------------------------------------------------------------
   -- Damerau–Levenshtein OSA
   ------------------------------------------------------------------
   Section ("5. OSA empty / identical");
   Check (OSA ("", "") = N (0), "OSA empty/empty = 0");
   Check (OSA ("", "a") = N (1), "OSA empty/a = 1");
   Check (OSA ("a", "") = N (1), "OSA a/empty = 1");
   Check (OSA ("", "abcd") = N (4), "OSA empty/abcd = 4");
   Check (OSA ("a", "a") = N (0), "OSA identical a");
   Check (OSA ("hello", "hello") = N (0), "OSA identical hello");
   Check (OSA (Make_Alpha (30), Make_Alpha (30)) = N (0),
          "OSA identical alpha30");

   Section ("6. OSA vs Levenshtein transposition");
   Check (OSA ("ab", "ba") = N (1), "OSA ab/ba = 1");
   Check (Lev ("ab", "ba") = N (2), "Lev ab/ba = 2 (contrast)");
   Check (OSA ("abc", "acb") = N (1), "OSA abc/acb = 1");
   Check (OSA ("acb", "abc") = N (1), "OSA acb/abc = 1");
   Check (OSA ("ca", "abc") = N (3), "OSA ca/abc = 3");
   Check (OSA ("CA", "ABC") = N (3), "OSA CA/ABC = 3 (case)");
   Check (OSA ("kitten", "sitting") = N (3), "OSA kitten/sitting = 3");
   Check (OSA ("saturday", "sunday") = N (3), "OSA saturday/sunday");
   Check (OSA ("a", "b") = N (1), "OSA substitute");
   Check (OSA ("ab", "a") = N (1), "OSA delete");

   Section ("7. OSA more cases");
   Check (OSA ("ba", "ab") = N (1), "OSA ba/ab = 1");
   Check (OSA ("abcd", "acbd") = N (1), "OSA abcd/acbd transpose");
   Check (OSA ("abcdef", "abcfed") = N (2), "OSA two nearby swaps");
   Check (OSA ("hello", "hlelo") = N (1), "OSA hello/hlelo");
   Check (OSA ("hello", "heoll") = N (2), "OSA hello/heoll");
   Check (OSA ("12", "21") = N (1), "OSA 12/21");
   Check (OSA ("123", "132") = N (1), "OSA 123/132");
   Check (OSA ("xyz", "zyx") = N (2), "OSA xyz/zyx");
   Check (OSA (Slice_ABC, "abc") = N (0), "OSA non-1 First");
   Check (OSA ("Abc", "abc") = N (1), "OSA case sensitive");

   ------------------------------------------------------------------
   -- Hamming
   ------------------------------------------------------------------
   Section ("8. Hamming basics");
   Check (Ham ("", "") = N (0), "Ham empty/empty = 0");
   Check (Ham ("a", "a") = N (0), "Ham identical a");
   Check (Ham ("a", "b") = N (1), "Ham a/b = 1");
   Check (Ham ("abc", "abc") = N (0), "Ham identical abc");
   Check (Ham ("abc", "abd") = N (1), "Ham abc/abd = 1");
   Check (Ham ("abc", "axc") = N (1), "Ham abc/axc = 1");
   Check (Ham ("abc", "xbc") = N (1), "Ham abc/xbc = 1");
   Check (Ham ("abc", "xyz") = N (3), "Ham abc/xyz = 3");
   Check (Ham ("1011101", "1001001") = N (2), "Ham classic bits");
   Check (Ham ("karolin", "kathrin") = N (3), "Ham karolin/kathrin");

   Section ("9. Hamming more / unequal");
   Check (Ham ("karolin", "kerstin") = N (3), "Ham karolin/kerstin");
   Check (Ham ("1011", "1011") = N (0), "Ham identical 1011");
   Check (Ham ("0000", "1111") = N (4), "Ham all differ");
   Check (Ham ("AbC", "abc") = N (2), "Ham case sensitive");
   Check (Ham (Make_Same (8, 'x'), Make_Same (8, 'x')) = N (0),
          "Ham 8 identical");
   Check (Ham (Make_Alpha (10), Make_Alpha (10)) = N (0),
          "Ham alpha10 same");
   Check (Ham (Make_Alpha (10), Make_Digits (10)) = N (10),
          "Ham alpha vs digits");
   Check (Ham_Raises ("a", "ab"), "Ham unequal a/ab raises");
   Check (Ham_Raises ("ab", "a"), "Ham unequal ab/a raises");
   Check (Ham_Raises ("", "a"), "Ham unequal empty/a raises");
   Check (Ham_Raises ("abc", "ab"), "Ham unequal abc/ab raises");
   Check (Ham (Slice_ABC, "abc") = N (0), "Ham non-1 First");

   ------------------------------------------------------------------
   -- Jaro–Winkler
   ------------------------------------------------------------------
   Section ("10. Jaro-Winkler empty / identical");
   Check (Near (JW ("", ""), F (1.0)), "JW empty/empty = 1");
   Check (Near (JW ("", "a"), F (0.0)), "JW empty/a = 0");
   Check (Near (JW ("a", ""), F (0.0)), "JW a/empty = 0");
   Check (Near (JW ("a", "a"), F (1.0)), "JW identical a");
   Check (Near (JW ("hello", "hello"), F (1.0)), "JW identical hello");
   Check (Near (JW (Make_Same (15, 'z'), Make_Same (15, 'z')), F (1.0)),
          "JW identical 15 zs");
   Check (Near (JW ("", "abc"), F (0.0)), "JW empty/abc = 0");
   Check (Near (JW ("xyz", ""), F (0.0)), "JW xyz/empty = 0");

   Section ("11. Jaro-Winkler known values");
   --  Classic: MARTHA / MARHTA ≈ 0.9611
   Check (Near (JW ("MARTHA", "MARHTA"), F (0.9611111)),
          "JW MARTHA/MARHTA ~0.9611");
   --  DWAYNE / DUANE ≈ 0.84
   Check (Near (JW ("DWAYNE", "DUANE"), F (0.84)),
          "JW DWAYNE/DUANE ~0.84");
   --  CRATE / TRACE ≈ 0.7333 (Jaro; Winkler may boost if prefix)
   declare
      S : constant Float := JW ("CRATE", "TRACE");
   begin
      Check (S > F (0.7) and then S < F (0.85),
             "JW CRATE/TRACE in (0.7,0.85)");
   end;
   Check (Near (JW ("abc", "abc"), F (1.0)), "JW abc/abc");
   Check (Near (JW ("abc", "xyz"), F (0.0)), "JW abc/xyz = 0");
   Check (JW ("hello", "hallo") > F (0.8), "JW hello/hallo high");
   Check (JW ("jones", "johnson") > F (0.8), "JW jones/johnson");
   Check (Near (JW ("a", "b"), F (0.0)), "JW a/b = 0");
   Check (Near (JW ("ab", "ba"), F (0.0)), "JW ab/ba = 0 (window 0)");
   Check (Near (JW ("aaaa", "aaaa"), F (1.0)), "JW aaaa/aaaa");

   Section ("12. Jaro-Winkler prefix / P / case");
   Check (JW ("prefix_same_long", "prefix_same_xxxx") >
          JW ("xxxx_same_long", "yyyy_same_xxxx"),
          "JW prefix boost helps");
   Check (Near (JW ("ABC", "abc"), F (0.0)), "JW case sensitive no match");
   Check (Near (JW ("Test", "Test", 0.0), F (1.0)), "JW P=0 identical");
   declare
      S01 : constant Float := JW ("MARTHA", "MARHTA", 0.1);
      S00 : constant Float := JW ("MARTHA", "MARHTA", 0.0);
   begin
      Check (S01 >= S00, "JW P=0.1 >= P=0 for MARTHA");
   end;
   Check (Near (JW (Slice_ABC, "abc"), F (1.0)), "JW non-1 First");
   Check (JW ("short", "shirt") > F (0.8), "JW short/shirt");
   Check (JW ("dicksonx", "dixon") > F (0.8), "JW dicksonx/dixon");
   Check (Near (JW ("x", "x"), F (1.0)), "JW single identical");
   Check (Near (JW ("xy", "xy"), F (1.0)), "JW xy/xy");
   Check (JW ("abcdefgh", "abc_efgh") > F (0.85), "JW near miss");

   ------------------------------------------------------------------
   -- Dice bigram
   ------------------------------------------------------------------
   Section ("13. Dice empty / short");
   Check (Near (Dice ("", ""), F (1.0)), "Dice empty/empty = 1");
   Check (Near (Dice ("", "a"), F (0.0)), "Dice empty/a = 0");
   Check (Near (Dice ("a", ""), F (0.0)), "Dice a/empty = 0");
   Check (Near (Dice ("a", "a"), F (0.0)), "Dice a/a no bigrams = 0");
   Check (Near (Dice ("a", "b"), F (0.0)), "Dice a/b = 0");
   Check (Near (Dice ("ab", "ab"), F (1.0)), "Dice ab/ab = 1");
   Check (Near (Dice ("ab", "xy"), F (0.0)), "Dice ab/xy = 0");
   Check (Near (Dice ("", "ab"), F (0.0)), "Dice empty/ab = 0");

   Section ("14. Dice known / unique sets");
   --  night / nacht: bigrams {ni,ig,gh,ht} / {na,ac,ch,ht}; intersect {ht}
   --  DSC = 2*1 / (4+4) = 0.25
   Check (Near (Dice ("night", "nacht"), F (0.25)),
          "Dice night/nacht = 0.25");
   Check (Near (Dice ("nacht", "night"), F (0.25)),
          "Dice nacht/night = 0.25");
   Check (Near (Dice ("hello", "hello"), F (1.0)), "Dice hello/hello");
   --  aaa → unique {aa}; identical → 1
   Check (Near (Dice ("aaa", "aaa"), F (1.0)), "Dice aaa/aaa unique");
   Check (Near (Dice ("aaaa", "aaa"), F (1.0)), "Dice aaaa/aaa both {aa}");
   --  abcab: unique {ab,bc,ca} vs abc: {ab,bc} → inter 2, |A|=3 |B|=2
   --  DSC = 2*2/(3+2) = 0.8
   Check (Near (Dice ("abcab", "abc"), F (0.8)), "Dice abcab/abc = 0.8");
   Check (Near (Dice ("abc", "abcab"), F (0.8)), "Dice abc/abcab = 0.8");
   Check (Near (Dice ("ab", "abc"), F (2.0 / 3.0)),
          "Dice ab/abc = 2/3");
   Check (Dice ("healed", "sealed") > F (0.5), "Dice healed/sealed");
   Check (Near (Dice ("gg", "gg"), F (1.0)), "Dice gg/gg");

   Section ("15. Dice more cases");
   Check (Near (Dice ("AB", "ab"), F (0.0)), "Dice case sensitive");
   Check (Near (Dice (Slice_ABC, "abc"), F (1.0)), "Dice non-1 First");
   Check (Near (Dice ("xy", "yx"), F (0.0)), "Dice xy/yx no share");
   --  abab → unique {ab,ba}; baba → unique {ba,ab}; DSC = 1.0
   Check (Near (Dice ("abab", "baba"), F (1.0)),
          "Dice abab/baba unique = 1");
   Check (Near (Dice ("12", "12"), F (1.0)), "Dice 12/12");
   Check (Near (Dice ("123", "124"), F (0.5)), "Dice 123/124 = 0.5");
   --  123:{12,23} 124:{12,24} inter 1 → 2/4 = 0.5
   Check (Near (Dice ("test", "testing"),
                F (2.0 * 3.0 / (3.0 + 6.0))),
          "Dice test/testing");
   --  test:{te,es,st}=3; testing:{te,es,st,ti,in,ng}=6; inter 3
   Check (Near (Dice (Make_Alpha (4), Make_Alpha (4)), F (1.0)),
          "Dice alpha4 identical");
   Check (Dice (Make_Alpha (5), Make_Digits (5)) < F (0.01),
          "Dice alpha vs digits ~0");

   ------------------------------------------------------------------
   -- Normalized Levenshtein
   ------------------------------------------------------------------
   Section ("16. Normalized Levenshtein");
   Check (Near (NLev ("", ""), F (1.0)), "NLev empty/empty = 1");
   Check (Near (NLev ("", "a"), F (0.0)), "NLev empty/a = 0");
   Check (Near (NLev ("a", ""), F (0.0)), "NLev a/empty = 0");
   Check (Near (NLev ("a", "a"), F (1.0)), "NLev a/a = 1");
   Check (Near (NLev ("hello", "hello"), F (1.0)), "NLev hello/hello");
   Check (Near (NLev ("kitten", "sitting"),
                F (1.0 - 3.0 / 7.0)),
          "NLev kitten/sitting");
   Check (Near (NLev ("abc", "xyz"), F (0.0)), "NLev abc/xyz = 0");
   Check (Near (NLev ("ab", "ba"), F (0.0)), "NLev ab/ba = 0");
   --  Lev=2, max=2 → 0
   Check (Near (NLev ("a", "b"), F (0.0)), "NLev a/b = 0");
   Check (Near (NLev ("abc", "ab"), F (1.0 - 1.0 / 3.0)),
          "NLev abc/ab");
   Check (Near (NLev ("book", "back"), F (1.0 - 2.0 / 4.0)),
          "NLev book/back = 0.5");
   Check (Near (NLev (Slice_ABC, "abc"), F (1.0)), "NLev non-1 First");
   Check (NLev ("hello", "hallo") > F (0.7), "NLev hello/hallo");
   Check (Near (NLev ("aa", "aaaa"), F (1.0 - 2.0 / 4.0)),
          "NLev aa/aaaa = 0.5");
   Check (Near (NLev (Make_Same (5, 'x'), Make_Same (5, 'y')), F (0.0)),
          "NLev all different same len");

   ------------------------------------------------------------------
   -- Cross-metric / survey properties
   ------------------------------------------------------------------
   Section ("17. Cross-metric relations");
   Check (OSA ("ab", "ba") < Lev ("ab", "ba"),
          "OSA < Lev for transposition");
   Check (OSA ("kitten", "sitting") = Lev ("kitten", "sitting"),
          "OSA = Lev when no transposition path");
   Check (Ham ("abc", "abd") = Lev ("abc", "abd"),
          "Ham = Lev for equal-len single sub");
   Check (Ham ("abc", "xyz") = Lev ("abc", "xyz"),
          "Ham = Lev all-sub equal len");
   Check (Near (NLev ("x", "x"), JW ("x", "x")),
          "NLev and JW both 1 for identical");
   Check (Near (Dice ("ab", "ab"), F (1.0))
            and then Near (JW ("ab", "ab"), F (1.0)),
          "Dice and JW identical ab");
   Check (Lev ("sam", "samuel") = N (3), "Lev sam/samuel = 3");
   Check (OSA ("sam", "samuel") = N (3), "OSA sam/samuel = 3");
   Check (Dice ("sam", "samuel") > F (0.0), "Dice sam/samuel > 0");
   Check (JW ("sam", "samuel") > F (0.8), "JW sam/samuel high");

   Section ("18. Symmetry smoke");
   Check (Lev ("foo", "bar") = Lev ("bar", "foo"), "Lev symmetric");
   Check (OSA ("foo", "bar") = OSA ("bar", "foo"), "OSA symmetric");
   Check (Ham ("foo", "bar") = Ham ("bar", "foo"), "Ham symmetric");
   Check (Near (JW ("foo", "bar"), JW ("bar", "foo")), "JW symmetric");
   Check (Near (Dice ("foo", "bar"), Dice ("bar", "foo")),
          "Dice symmetric");
   Check (Near (NLev ("foo", "bar"), NLev ("bar", "foo")),
          "NLev symmetric");
   --  Latin-1 opaque Character values:
   Check (Lev (Character'Val (200) & "", Character'Val (201) & "") = N (1),
          "Lev Latin-1 differ");
   Check (Ham (Character'Val (200) & "x", Character'Val (200) & "y") = N (1),
          "Ham Latin-1 one differ");
   Check (Near (Dice ("café", "café"), F (1.0)),
          "Dice identical cafe with accents");

   ------------------------------------------------------------------
   -- Bounds / Invalid_Argument
   ------------------------------------------------------------------
   Section ("19. Invalid_Argument Max_Len");
   declare
      Over : constant String := Make_Same (Max_Len + 1, 'x');
      Ok   : constant String := Make_Same (Max_Len, 'x');
      Tiny : constant String := "a";
   begin
      Check (Lev_Raises (Over, Tiny), "Lev oversize A raises");
      Check (Lev_Raises (Tiny, Over), "Lev oversize B raises");
      Check (OSA_Raises (Over, Tiny), "OSA oversize A raises");
      Check (OSA_Raises (Tiny, Over), "OSA oversize B raises");
      Check (Ham_Raises (Over, Over), "Ham oversize raises");
      Check (JW_Raises (Over, Tiny), "JW oversize A raises");
      Check (JW_Raises (Tiny, Over), "JW oversize B raises");
      Check (Dice_Raises (Over, Tiny), "Dice oversize A raises");
      Check (Dice_Raises (Tiny, Over), "Dice oversize B raises");
      Check (NLev_Raises (Over, Tiny), "NLev oversize A raises");
      Check (NLev_Raises (Tiny, Over), "NLev oversize B raises");
      --  Max_Len itself is allowed
      Check (Lev (Ok, Ok) = N (0), "Lev Max_Len identical ok");
      Check (OSA (Ok, Ok) = N (0), "OSA Max_Len identical ok");
      Check (Ham (Ok, Ok) = N (0), "Ham Max_Len identical ok");
      Check (Near (JW (Ok, Ok), F (1.0)), "JW Max_Len identical ok");
      Check (Near (Dice (Ok, Ok), F (1.0)), "Dice Max_Len identical ok");
      Check (Near (NLev (Ok, Ok), F (1.0)), "NLev Max_Len identical ok");
   end;

   Section ("20. Longer educational strings");
   Check (Lev (Make_Alpha (40), Make_Alpha (40)) = N (0),
          "Lev alpha40");
   Check (Lev (Make_Alpha (20), Make_Alpha (25)) = N (5),
          "Lev alpha20/25 = 5");
   Check (OSA (Make_Digits (12), Make_Digits (12)) = N (0),
          "OSA digits12");
   Check (Ham (Make_Digits (16), Make_Digits (16)) = N (0),
          "Ham digits16");
   declare
      A : constant String := Make_Alpha (16);
      B : String := A;
   begin
      B (8) := 'Z';
      Check (Ham (A, B) = N (1), "Ham one flip in alpha16");
      Check (Lev (A, B) = N (1), "Lev one flip in alpha16");
   end;
   Check (Dice (Make_Alpha (8), Make_Alpha (8)) > F (0.99),
          "Dice alpha8 identical");
   Check (JW (Make_Alpha (8), Make_Alpha (8)) > F (0.99),
          "JW alpha8 identical");
   Check (NLev (Make_Alpha (8), Make_Digits (8)) < F (0.01),
          "NLev alpha vs digits ~0");
   Check (Lev ("intention", "execution") = N (5),
          "Lev intention/execution = 5");
   Check (OSA ("intention", "execution") = N (5),
          "OSA intention/execution = 5");

   Section ("21. Additional Levenshtein battery");
   Check (Lev ("a", "aa") = N (1), "Lev a/aa");
   Check (Lev ("aa", "a") = N (1), "Lev aa/a");
   Check (Lev ("abc", "def") = N (3), "Lev abc/def");
   Check (Lev ("abcdef", "azced") = N (3), "Lev abcdef/azced");
   Check (Lev ("ocean", "osean") = N (1), "Lev ocean/osean");
   Check (Lev ("phone", "phony") = N (1), "Lev phone/phony = 1");
   Check (Lev ("", Make_Alpha (1)) = N (1), "Lev empty/alpha1");
   Check (Lev (Make_Alpha (1), Make_Alpha (1)) = N (0), "Lev alpha1");
   Check (Lev ("Tor", "Tor") = N (0), "Lev Tor/Tor");
   Check (Lev ("Tor", "Turing") = N (4), "Lev Tor/Turing");
   Check (Lev ("cat", "dog") = N (3), "Lev cat/dog");
   Check (Lev ("cat", "cats") = N (1), "Lev cat/cats");
   Check (Lev ("cats", "cat") = N (1), "Lev cats/cat");
   Check (Lev ("meilenstein", "levenshtein") = N (4),
          "Lev meilenstein/levenshtein");
   Check (Lev ("levenshtein", "meilenstein") = N (4),
          "Lev levenshtein/meilenstein");

   Section ("22. Additional OSA battery");
   Check (OSA ("a", "aa") = N (1), "OSA a/aa");
   Check (OSA ("ca", "abc") = N (3), "OSA ca/abc again");
   Check (OSA ("abc", "ca") = N (3), "OSA abc/ca");
   Check (OSA ("EH", "HE") = N (1), "OSA EH/HE");
   Check (OSA ("ACE", "AEC") = N (1), "OSA ACE/AEC");
   Check (OSA ("ACE", "CEA") = N (2), "OSA ACE/CEA");
   Check (OSA ("12345", "12354") = N (1), "OSA 12345/12354");
   Check (OSA ("12345", "12435") = N (1), "OSA 12435 transpose");
   Check (OSA ("abcdef", "abdcfe") = N (2), "OSA two transpositions");
   Check (OSA ("smtih", "smith") = N (1), "OSA smtih/smith");
   Check (OSA ("smith", "smtih") = N (1), "OSA smith/smtih");
   Check (OSA ("orntra", "contra") = N (2), "OSA orntra/contra");
   Check (OSA ("", Make_Same (5, 'q')) = N (5), "OSA empty/5q");
   Check (OSA (" Tor ", " Tor ") = N (0), "OSA spaces identical");
   Check (OSA ("a b", "ab") = N (1), "OSA a b/ab");

   Section ("23. Additional Hamming battery");
   Check (Ham ("00", "01") = N (1), "Ham 00/01");
   Check (Ham ("11", "00") = N (2), "Ham 11/00");
   Check (Ham ("rust", "rust") = N (0), "Ham rust/rust");
   Check (Ham ("rust", "rast") = N (1), "Ham rust/rast");
   Check (Ham ("1010", "0101") = N (4), "Ham 1010/0101");
   Check (Ham ("same", "same") = N (0), "Ham same/same");
   Check (Ham ("Same", "same") = N (1), "Ham Same/same");
   Check (Ham_Raises ("len", "length"), "Ham len/length raises");
   Check (Ham_Raises ("longer", "short"), "Ham longer/short raises");
   Check (Ham ("!!!", "!!!") = N (0), "Ham punct identical");
   Check (Ham ("!!!", "!!?") = N (1), "Ham punct one differ");
   Check (Ham ("  ", "  ") = N (0), "Ham spaces");
   Check (Ham ("  ", " x") = N (1), "Ham space vs x");
   Check (Ham (Make_Same (1, 'Z'), Make_Same (1, 'Z')) = N (0),
          "Ham single Z");
   Check (Ham (Make_Same (1, 'Z'), Make_Same (1, 'Y')) = N (1),
          "Ham Z/Y");

   Section ("24. Additional JW battery");
   Check (Near (JW ("TRATE", "TRACE"), JW ("TRACE", "TRATE")),
          "JW TRATE/TRACE symmetric");
   Check (JW ("winkler", "winkle") > F (0.9), "JW winkler/winkle");
   Check (JW ("abc", "ab") > F (0.7), "JW abc/ab");
   Check (Near (JW ("zzzz", "xxxx"), F (0.0)), "JW zzzz/xxxx = 0");
   Check (JW ("Henry", "Henri") > F (0.85), "JW Henry/Henri");
   Check (JW ("Jennifer", "Jenny") > F (0.8), "JW Jennifer/Jenny");
   Check (Near (JW ("", ""), JW ("", "", 0.25)), "JW empty P variants");
   Check (JW ("prefix", "prefxy", 0.1) >= JW ("prefix", "prefxy", 0.0),
          "JW larger P >= smaller P");
   Check (Near (JW ("aa", "aa"), F (1.0)), "JW aa/aa");
   Check (JW ("abcdef", "abcxef") > F (0.85), "JW abcdef/abcxef");
   Check (JW ("123456", "123465") > F (0.9), "JW near digit transpose");
   Check (Near (JW ("q", "q"), F (1.0)), "JW q/q");
   Check (Near (JW ("q", "r"), F (0.0)), "JW q/r");
   Check (JW ("search", "serach") > F (0.9), "JW search/serach");
   Check (JW ("distance", "similarity") < F (0.7),
          "JW distance/similarity moderate/low");

   Section ("25. Additional Dice battery");
   Check (Near (Dice ("ab", "ba"), F (0.0)), "Dice ab/ba = 0");
   --  aba:{ab,ba}; bab:{ba,ab}; inter 2 → DSC = 1.0
   Check (Near (Dice ("aba", "bab"), F (1.0)), "Dice aba/bab = 1");
   Check (Near (Dice ("abcd", "abce"), F (2.0 * 2.0 / (3.0 + 3.0))),
          "Dice abcd/abce = 2/3");
   Check (Near (Dice ("hi", "hi"), F (1.0)), "Dice hi/hi");
   Check (Near (Dice ("hi", "ho"), F (0.0)), "Dice hi/ho");
   Check (Dice ("banana", "bandana") > F (0.5), "Dice banana/bandana");
   Check (Near (Dice ("ggg", "gg"), F (1.0)), "Dice ggg/gg");
   Check (Near (Dice ("  ", "  "), F (1.0)), "Dice two spaces");
   Check (Dice ("hello world", "hello there") > F (0.3),
          "Dice hello phrases");
   Check (Near (Dice ("xy", "xyz"), F (2.0 / 3.0)), "Dice xy/xyz");
   Check (Near (Dice ("abcd", "dcba"), F (0.0)), "Dice abcd/dcba = 0");
   Check (Near (Dice ("aa", "ab"), F (0.0)), "Dice aa/ab");
   Check (Near (Dice ("ababab", "ababab"), F (1.0)), "Dice ababab");
   Check (Dice ("string", "strings") > F (0.7), "Dice string/strings");

   Section ("26. Additional NLev battery");
   Check (Near (NLev ("cat", "cats"), F (1.0 - 1.0 / 4.0)),
          "NLev cat/cats");
   Check (Near (NLev ("saturday", "sunday"), F (1.0 - 3.0 / 8.0)),
          "NLev saturday/sunday");
   Check (Near (NLev ("x", "xy"), F (0.5)), "NLev x/xy = 0.5");
   Check (Near (NLev ("xy", "x"), F (0.5)), "NLev xy/x = 0.5");
   Check (Near (NLev ("aaaa", "aaab"), F (0.75)), "NLev aaaa/aaab");
   Check (Near (NLev ("", "abcd"), F (0.0)), "NLev empty/abcd");
   Check (Near (NLev ("same", "same"), F (1.0)), "NLev same/same");
   Check (NLev ("almost", "algost") > F (0.8), "NLev almost/algost");
   Check (Near (NLev ("ab", "cd"), F (0.0)), "NLev ab/cd");
   Check (Near (NLev ("abc", "adc"), F (1.0 - 1.0 / 3.0)),
          "NLev abc/adc");
   Check (Near (NLev (Make_Same (3, 'a'), Make_Same (3, 'a')), F (1.0)),
          "NLev 3a/3a");
   Check (Near (NLev (Make_Same (3, 'a'), Make_Same (3, 'b')), F (0.0)),
          "NLev 3a/3b");
   Check (Near (NLev ("flaw", "lawn"), F (0.5)), "NLev flaw/lawn = 0.5");
   Check (Near (NLev ("gumbo", "gambol"), F (1.0 - 2.0 / 6.0)),
          "NLev gumbo/gambol");
   Check (Near (NLev ("Tor", "Turing"), F (1.0 - 4.0 / 6.0)),
          "NLev Tor/Turing");

   Section ("27. Identity and zero patterns");
   Check (Lev ("z", "z") = OSA ("z", "z")
            and then Lev ("z", "z") = Ham ("z", "z"),
          "all distances 0 on identical z");
   Check (Near (JW ("z", "z"), F (1.0))
            and then Near (NLev ("z", "z"), F (1.0)),
          "similarities 1 on identical z");
   Check (Lev ("qq", "zz") = N (2), "Lev qq/zz");
   Check (OSA ("qq", "zz") = N (2), "OSA qq/zz");
   Check (Ham ("qq", "zz") = N (2), "Ham qq/zz");
   Check (Near (Dice ("qq", "zz"), F (0.0)), "Dice qq/zz");
   Check (Near (JW ("qq", "zz"), F (0.0)), "JW qq/zz");
   Check (Near (NLev ("qq", "zz"), F (0.0)), "NLev qq/zz");
   Check (Lev ("abcd", "abdc") = N (2), "Lev abcd/abdc");
   Check (OSA ("abcd", "abdc") = N (1), "OSA abcd/abdc = 1");
   Check (Ham ("abcd", "abdc") = N (2), "Ham abcd/abdc = 2");

   Section ("28. Whitespace and punctuation");
   Check (Lev ("a b", "ab") = N (1), "Lev a b/ab");
   Check (Ham ("a b", "a c") = N (1), "Ham a b/a c");
   Check (Near (Dice ("a,", "a,"), F (1.0)), "Dice a,/a,");
   Check (Near (JW ("Mr.", "Mr."), F (1.0)), "JW Mr.");
   Check (Lev ("...", "???") = N (3), "Lev dots/qmarks");
   Check (OSA ("()", ")(") = N (1), "OSA ()/)( transpose");
   Check (Ham ("()", ")(") = N (2), "Ham ()/)(");
   Check (Near (Dice ("!!", "!!"), F (1.0)), "Dice !!/!!");
   Check (Near (NLev ("a b", "ab"), F (1.0 - 1.0 / 3.0)),
          "NLev a b/ab");
   Check (Lev ("tab" & Character'Val (9) & "x", "tab x") >= N (1),
          "Lev tab vs space");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("Total: " & Natural'Image (Pass_Count + Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILURES");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

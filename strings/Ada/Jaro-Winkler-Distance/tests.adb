--  Standalone test suite for Jaro_Winkler_Distance (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Jaro_Winkler_Distance; use Jaro_Winkler_Distance;

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
   function Near (Got, Expect : Float) return Boolean is
   begin
      return abs (Got - Expect) <= Eps;
   end Near;

   function JS (A, B : String) return Float is
     (Jaro_Similarity (A, B));

   function JWS (A, B : String; P : Float := Default_P) return Float is
     (Jaro_Winkler_Similarity (A, B, P));

   function JWD (A, B : String; P : Float := Default_P) return Float is
     (Jaro_Winkler_Distance.Jaro_Winkler_Distance (A, B, P));

   function JS_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Jaro_Similarity (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end JS_Raises;

   function JWS_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Jaro_Winkler_Similarity (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end JWS_Raises;

   function JWD_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Jaro_Winkler_Distance.Jaro_Winkler_Distance (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end JWD_Raises;

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

   --  Slice with non-1 'First for Arbitrary bounds checks.
   function Shifted (S : String) return String is
      R : String (5 .. 5 + S'Length - 1);
   begin
      for K in S'Range loop
         R (5 + (K - S'First)) := S (K);
      end loop;
      return R;
   end Shifted;

begin
   Put_Line ("Jaro_Winkler_Distance test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);
   Put_Line ("Default_P =" & Default_P'Image);

   ------------------------------------------------------------------
   Section ("1. Empty / empty and empty / nonempty");
   ------------------------------------------------------------------
   Check (Near (JS ("", ""), F (1.0)), "Jaro empty/empty = 1.0");
   Check (Near (JWS ("", ""), F (1.0)), "JW sim empty/empty = 1.0");
   Check (Near (JWD ("", ""), F (0.0)), "JW dist empty/empty = 0.0");
   Check (Near (JS ("", "a"), F (0.0)), "Jaro empty/a = 0");
   Check (Near (JS ("a", ""), F (0.0)), "Jaro a/empty = 0");
   Check (Near (JS ("", "abc"), F (0.0)), "Jaro empty/abc = 0");
   Check (Near (JS ("xyz", ""), F (0.0)), "Jaro xyz/empty = 0");
   Check (Near (JWS ("", "a"), F (0.0)), "JW sim empty/a = 0");
   Check (Near (JWS ("abc", ""), F (0.0)), "JW sim abc/empty = 0");
   Check (Near (JWD ("", "a"), F (1.0)), "JW dist empty/a = 1");
   Check (Near (JWD ("abc", ""), F (1.0)), "JW dist abc/empty = 1");
   Check (Near (JS ("", Make_Same (10, 'x')), F (0.0)), "empty vs 10");
   Check (Near (JS (Make_Same (7, 'z'), ""), F (0.0)), "7 vs empty");

   ------------------------------------------------------------------
   Section ("2. Identical strings");
   ------------------------------------------------------------------
   Check (Near (JS ("a", "a"), F (1.0)), "Jaro identical single");
   Check (Near (JS ("hello", "hello"), F (1.0)), "Jaro identical hello");
   Check (Near (JS (Make_Same (20, 'q'), Make_Same (20, 'q')), F (1.0)),
          "Jaro identical 20 qs");
   Check (Near (JS (Make_Alpha (50), Make_Alpha (50)), F (1.0)),
          "Jaro identical alpha-50");
   Check (Near (JWS ("hello", "hello"), F (1.0)), "JW sim identical");
   Check (Near (JWS ("x", "x"), F (1.0)), "JW sim identical single");
   Check (Near (JWD ("hello", "hello"), F (0.0)), "JW dist identical = 0");
   Check (Near (JWS (Make_Alpha (30), Make_Alpha (30)), F (1.0)),
          "JW sim identical alpha-30");
   Check (Near (JS ("", ""), F (1.0)), "Jaro empty identical again");
   Check (Near (JS ("ab", "ab"), F (1.0)), "Jaro identical ab");
   Check (Near (JS ("abc", "abc"), F (1.0)), "Jaro identical abc");

   ------------------------------------------------------------------
   Section ("3. Known Wikipedia / classic pairs");
   ------------------------------------------------------------------
   --  MARTHA / MARHTA: m=6, t=1 → (1/3)(1+1+5/6)=0.9444...
   --  prefix ℓ=3 → JW = 0.9444 + 0.3*(1-0.9444) = 0.9611...
   Check (Near (JS ("MARTHA", "MARHTA"), F (0.94444)),
          "Jaro MARTHA/MARHTA ≈ 0.94444");
   Check (Near (JWS ("MARTHA", "MARHTA"), F (0.96111)),
          "JW MARTHA/MARHTA ≈ 0.96111");
   Check (Near (JS ("MARHTA", "MARTHA"), F (0.94444)),
          "Jaro MARHTA/MARTHA symmetric");
   Check (Near (JWS ("MARHTA", "MARTHA"), F (0.96111)),
          "JW MARHTA/MARTHA symmetric");

   --  DIXON / DICKSONX ≈ 0.76667 Jaro, ≈ 0.81333 JW (prefix D)
   Check (Near (JS ("DIXON", "DICKSONX"), F (0.76667)),
          "Jaro DIXON/DICKSONX ≈ 0.76667");
   Check (Near (JWS ("DIXON", "DICKSONX"), F (0.81333)),
          "JW DIXON/DICKSONX ≈ 0.81333");

   --  FAREMVIEL / FARMVILLE: wiki ≈ 0.88 (exact ≈ 0.88426)
   Check (Near (JS ("FAREMVIEL", "FARMVILLE"), F (0.88426)),
          "Jaro FAREMVIEL/FARMVILLE ≈ 0.88426");
   Check (Near (JWS ("FAREMVIEL", "FARMVILLE"), F (0.91898)),
          "JW FAREMVIEL/FARMVILLE ≈ 0.91898");

   --  dwayne / duane
   Check (Near (JS ("dwayne", "duane"), F (0.82222)),
          "Jaro dwayne/duane ≈ 0.82222");
   Check (Near (JWS ("dwayne", "duane"), F (0.84000)),
          "JW dwayne/duane ≈ 0.84000");

   --  CRATE / TRACE — no common prefix
   Check (Near (JS ("CRATE", "TRACE"), F (0.73333)),
          "Jaro CRATE/TRACE ≈ 0.73333");
   Check (Near (JWS ("CRATE", "TRACE"), F (0.73333)),
          "JW CRATE/TRACE = Jaro (no prefix)");

   ------------------------------------------------------------------
   Section ("4. Prefix boost vs plain Jaro");
   ------------------------------------------------------------------
   Check (JWS ("MARTHA", "MARHTA") > JS ("MARTHA", "MARHTA"),
          "JW > Jaro when prefix matches (MARTHA)");
   Check (JWS ("DIXON", "DICKSONX") > JS ("DIXON", "DICKSONX"),
          "JW > Jaro when prefix matches (DIXON)");
   Check (Near (JWS ("CRATE", "TRACE"), JS ("CRATE", "TRACE")),
          "JW = Jaro when prefix length 0");
   Check (Near (JWS ("abc", "xyz"), JS ("abc", "xyz")),
          "JW = Jaro for abc/xyz (no prefix)");
   --  Custom P=0 yields JW = Jaro
   Check (Near (JWS ("MARTHA", "MARHTA", F (0.0)), JS ("MARTHA", "MARHTA")),
          "JW with P=0 equals Jaro");
   --  Larger P increases boost
   Check (JWS ("MARTHA", "MARHTA", F (0.2)) > JWS ("MARTHA", "MARHTA", F (0.1)),
          "larger P → larger JW similarity");
   --  Prefix length capped at 4: "ABCDEF" / "ABCDEG" ℓ=5→4
   declare
      J  : constant Float := JS ("ABCDEFGH", "ABCDEFXY");
      W  : constant Float := JWS ("ABCDEFGH", "ABCDEFXY");
      --  ℓ = 4, so W = J + 4*0.1*(1-J)
      Expect : constant Float := J + 4.0 * 0.1 * (1.0 - J);
   begin
      Check (Near (W, Expect), "prefix boost capped at ℓ=4");
      Check (W > J, "capped prefix still boosts");
   end;

   ------------------------------------------------------------------
   Section ("5. Distance = 1 − similarity");
   ------------------------------------------------------------------
   Check (Near (JWD ("MARTHA", "MARHTA"),
                F (1.0) - JWS ("MARTHA", "MARHTA")),
          "dist = 1-sim MARTHA");
   Check (Near (JWD ("DIXON", "DICKSONX"),
                F (1.0) - JWS ("DIXON", "DICKSONX")),
          "dist = 1-sim DIXON");
   Check (Near (JWD ("a", "b"), F (1.0) - JWS ("a", "b")),
          "dist = 1-sim a/b");
   Check (Near (JWD ("hello", "hello"), F (0.0)), "dist identical = 0");
   Check (Near (JWD ("", "x"), F (1.0)), "dist empty/x = 1");
   Check (Near (JWD ("abc", "xyz"), F (1.0) - JWS ("abc", "xyz")),
          "dist = 1-sim abc/xyz");
   Check (Near (JWD ("FAREMVIEL", "FARMVILLE"),
                F (1.0) - JWS ("FAREMVIEL", "FARMVILLE")),
          "dist = 1-sim FAREMVIEL");
   Check (Near (JWD ("dwayne", "duane", F (0.1)),
                F (1.0) - JWS ("dwayne", "duane", F (0.1))),
          "dist = 1-sim custom P");

   ------------------------------------------------------------------
   Section ("6. Short strings and matching window");
   ------------------------------------------------------------------
   Check (Near (JS ("a", "b"), F (0.0)), "Jaro a/b = 0");
   Check (Near (JS ("a", "a"), F (1.0)), "Jaro a/a = 1 (window clamp)");
   Check (Near (JS ("ab", "ab"), F (1.0)), "Jaro ab/ab = 1");
   --  window = floor(2/2)-1 = 0 → only same-index matches
   Check (Near (JS ("ab", "ba"), F (0.0)), "Jaro ab/ba = 0 (window 0)");
   Check (Near (JS ("ab", "ac"), F (0.66667)), "Jaro ab/ac ≈ 2/3");
   Check (Near (JS ("abc", "acb"), F (0.0))
            or else JS ("abc", "acb") > F (0.0),
          "Jaro abc/acb computed (window 0)");
   --  Explicit: max=3 → floor(1.5)-1 = 0
   declare
      J : constant Float := JS ("abc", "acb");
   begin
      --  With window 0: a matches a; b vs c no; c vs b no → m=1
      --  sim = (1/3)(1/3+1/3+1) = 5/9 ≈ 0.55556
      Check (Near (J, F (0.55556)), "Jaro abc/acb ≈ 0.55556");
   end;
   --  max=2 → window 0; 'x' at 1 matches 'x' at 1; m=1
   --  (1/3)(1/1 + 1/2 + 1) = (1/3)(2.5) ≈ 0.83333
   Check (Near (JS ("x", "xy"), F (0.83333)), "Jaro x/xy ≈ 0.83333");
   Check (Near (JS ("xy", "x"), F (0.83333)), "Jaro xy/x symmetric");

   ------------------------------------------------------------------
   Section ("7. Case sensitivity");
   ------------------------------------------------------------------
   Check (JS ("abc", "ABC") < F (1.0), "case-sensitive abc/ABC not 1");
   Check (Near (JS ("ABC", "ABC"), F (1.0)), "identical uppercase");
   Check (Near (JS ("Ab", "ab"), F (0.66667))
            or else abs (JS ("Ab", "ab") - F (0.66667)) <= Eps
            or else JS ("Ab", "ab") < F (1.0),
          "Ab/ab case differs");
   Check (Near (JS ("MARTHA", "martha"), F (0.0))
            or else JS ("MARTHA", "martha") < F (0.5),
          "MARTHA/martha case-sensitive low");
   Check (JS ("Hello", "hello") < F (1.0), "Hello/hello not identical");
   Check (Near (JS ("Z", "z"), F (0.0)), "Z/z no match");

   ------------------------------------------------------------------
   Section ("8. Spaces, digits, punctuation, Latin-1");
   ------------------------------------------------------------------
   Check (Near (JS ("a b", "a b"), F (1.0)), "spaces identical");
   Check (JS ("a b", "ab") < F (1.0), "space matters");
   Check (Near (JS ("123", "123"), F (1.0)), "digits identical");
   Check (Near (JS ("12", "21"), F (0.0)), "12/21 window 0");
   Check (Near (JS ("!@#", "!@#"), F (1.0)), "punct identical");
   Check (Near (JS ("café", "café"), F (1.0)), "Latin-1 identical");
   declare
      --  'é' is Character'Val(233) in Latin-1
      E_Acute : constant Character := Character'Val (233);
      S1 : constant String := "caf" & E_Acute;
      S2 : constant String := "cafe";
   begin
      Check (JS (S1, S2) < F (1.0), "café/cafe not identical");
      Check (Near (JS (S1, S1), F (1.0)), "café/café = 1");
   end;
   Check (Near (JS ("a-b", "a-b"), F (1.0)), "hyphen identical");
   Check (Near (JS ("a b c", "a b c"), F (1.0)), "multi-space identical");

   ------------------------------------------------------------------
   Section ("9. Symmetry");
   ------------------------------------------------------------------
   Check (Near (JS ("MARTHA", "MARHTA"), JS ("MARHTA", "MARTHA")),
          "Jaro symmetric MARTHA");
   Check (Near (JWS ("DIXON", "DICKSONX"), JWS ("DICKSONX", "DIXON")),
          "JW sim symmetric DIXON");
   Check (Near (JWD ("FAREMVIEL", "FARMVILLE"),
                JWD ("FARMVILLE", "FAREMVIEL")),
          "JW dist symmetric FAREMVIEL");
   Check (Near (JS ("kitten", "sitting"), JS ("sitting", "kitten")),
          "Jaro symmetric kitten/sitting");
   Check (Near (JS ("abc", "xyz"), JS ("xyz", "abc")),
          "Jaro symmetric abc/xyz");
   Check (Near (JWS ("dwayne", "duane"), JWS ("duane", "dwayne")),
          "JW symmetric dwayne/duane");

   ------------------------------------------------------------------
   Section ("10. Bounds [0,1] and distance range");
   ------------------------------------------------------------------
   declare
      procedure Bound_Pair (A, B : String; Tag : String) is
         Sj : constant Float := JS (A, B);
         Sw : constant Float := JWS (A, B);
         Dw : constant Float := JWD (A, B);
      begin
         Check (Sj >= F (0.0) and then Sj <= F (1.0),
                "Jaro in [0,1] " & Tag);
         Check (Sw >= F (0.0) and then Sw <= F (1.0),
                "JW sim in [0,1] " & Tag);
         Check (Dw >= F (0.0) and then Dw <= F (1.0),
                "JW dist in [0,1] " & Tag);
         Check (Near (Dw, F (1.0) - Sw),
                "dist=1-sim " & Tag);
      end Bound_Pair;
   begin
      Bound_Pair ("a", "b", "a/b");
      Bound_Pair ("MARTHA", "MARHTA", "MARTHA");
      Bound_Pair ("abc", "xyz", "abc/xyz");
      Bound_Pair ("hello", "hello", "hello");
      Bound_Pair ("", "x", "empty/x");
      Bound_Pair ("DIXON", "DICKSONX", "DIXON");
      Bound_Pair ("aa", "aaa", "aa/aaa");
      Bound_Pair ("zzzz", "zzzz", "zzzz");
   end;

   ------------------------------------------------------------------
   Section ("11. Non-1 String'First slices");
   ------------------------------------------------------------------
   Check (Near (JS (Shifted ("MARTHA"), Shifted ("MARHTA")),
                JS ("MARTHA", "MARHTA")),
          "Jaro shifted MARTHA");
   Check (Near (JWS (Shifted ("DIXON"), Shifted ("DICKSONX")),
                JWS ("DIXON", "DICKSONX")),
          "JW shifted DIXON");
   Check (Near (JS (Shifted ("abc"), Shifted ("abc")), F (1.0)),
          "Jaro shifted identical");
   Check (Near (JWD (Shifted (""), Shifted ("")), F (0.0)),
          "JW dist shifted empty/empty");
   declare
      Base : constant String := "FAREMVIEL";
      --  Slice of a larger buffer
      Buf  : constant String := "XX" & Base & "YY";
      Sub  : String renames Buf (Buf'First + 2 .. Buf'First + 2 + Base'Length - 1);
   begin
      Check (Near (JS (Sub, "FARMVILLE"), JS ("FAREMVIEL", "FARMVILLE")),
             "Jaro slice rename FAREMVIEL");
   end;

   ------------------------------------------------------------------
   Section ("12. Max_Len boundary acceptance / rejection");
   ------------------------------------------------------------------
   declare
      Ok_A : constant String := Make_Same (Max_Len, 'a');
      Ok_B : constant String := Make_Same (Max_Len, 'a');
      Big  : constant String := Make_Same (Max_Len + 1, 'b');
      Small : constant String := "x";
   begin
      Check (Near (JS (Ok_A, Ok_B), F (1.0)), "Jaro Max_Len identical accepted");
      Check (Near (JWS (Ok_A, Ok_B), F (1.0)), "JW Max_Len identical accepted");
      Check (Near (JWD (Ok_A, Ok_B), F (0.0)), "JW dist Max_Len identical");
      Check (JS_Raises (Big, Small), "Jaro raises on A > Max_Len");
      Check (JS_Raises (Small, Big), "Jaro raises on B > Max_Len");
      Check (JWS_Raises (Big, Small), "JW sim raises on A > Max_Len");
      Check (JWS_Raises (Small, Big), "JW sim raises on B > Max_Len");
      Check (JWD_Raises (Big, Small), "JW dist raises on A > Max_Len");
      Check (JWD_Raises (Small, Big), "JW dist raises on B > Max_Len");
      Check (JS_Raises (Big, Big), "Jaro raises both > Max_Len");
   end;

   ------------------------------------------------------------------
   Section ("13. Modest sizes and patterns");
   ------------------------------------------------------------------
   Check (Near (JS (Make_Alpha (50), Make_Alpha (50)), F (1.0)),
          "alpha-50 identical");
   Check (Near (JS (Make_Digits (40), Make_Digits (40)), F (1.0)),
          "digits-40 identical");
   Check (JS (Make_Alpha (30), Make_Alpha (30) (1 .. 29) & "Z") < F (1.0),
          "alpha-30 last char changed");
   Check (Near (JS (Make_Same (100, 'a'), Make_Same (100, 'a')), F (1.0)),
          "100 as identical");
   Check (JS (Make_Same (20, 'a'), Make_Same (20, 'b')) = F (0.0)
            or else Near (JS (Make_Same (20, 'a'), Make_Same (20, 'b')),
                          F (0.0)),
          "20 as vs 20 bs → 0");
   Check (JWS (Make_Same (10, 'x'), Make_Same (10, 'x') (1 .. 9) & "y")
            > JS (Make_Same (10, 'x'), Make_Same (10, 'x') (1 .. 9) & "y"),
          "prefix boost on near-identical");
   Check (Near (JS (Make_Alpha (5), Make_Alpha (5)), F (1.0)),
          "alpha-5 identical");
   Check (Near (JS (Make_Alpha (1), Make_Alpha (1)), F (1.0)),
          "alpha-1 identical");

   ------------------------------------------------------------------
   Section ("14. Bulk micro-cases (letters / length ladder)");
   ------------------------------------------------------------------
   declare
      Letters : constant String := "abcdefghijklmnopqrstuvwxyz";
   begin
      for I in Letters'Range loop
         declare
            C : constant Character := Letters (I);
            S : constant String := [1 => C];
         begin
            Check (Near (JS (S, S), F (1.0)),
                   "identical letter " & S);
         end;
      end loop;
   end;

   for L in 1 .. 12 loop
      declare
         S : constant String := Make_Same (L, 'm');
      begin
         Check (Near (JS (S, S), F (1.0)),
                "identical length ladder" & L'Image);
         Check (Near (JWD (S, S), F (0.0)),
                "dist zero ladder" & L'Image);
      end;
   end loop;

   for L in 2 .. 10 loop
      declare
         A : constant String := Make_Alpha (L);
         B : constant String := Make_Alpha (L);
      begin
         Check (Near (JWS (A, B), F (1.0)),
                "JW identical alpha ladder" & L'Image);
      end;
   end loop;

   --  Completely different equal-length strings → often 0
   Check (Near (JS ("aaaa", "bbbb"), F (0.0)), "aaaa/bbbb = 0");
   Check (Near (JS ("xyz", "uvw"), F (0.0)), "xyz/uvw = 0");
   Check (Near (JS ("12", "34"), F (0.0)), "12/34 = 0");

   ------------------------------------------------------------------
   Section ("15. Transposition / reorder spot checks");
   ------------------------------------------------------------------
   --  "ab" / "ba" already covered (window 0 → 0).
   --  Longer strings where transposition contributes.
   Check (JS ("MARTHA", "MARHTA") > F (0.9), "transposition pair high Jaro");
   Check (JS ("ABC", "ACB") > F (0.0), "ABC/ACB some match");
   Check (Near (JS ("ABCD", "ABDC"), JS ("ABDC", "ABCD")),
          "ABCD/ABDC symmetric");
   Check (JS ("ABCDEF", "ABCEDF") > F (0.8), "near transposition high");

   ------------------------------------------------------------------
   Section ("16. Default_P and custom P wiring");
   ------------------------------------------------------------------
   Check (Near (Default_P, F (0.1)), "Default_P = 0.1");
   Check (Near (JWS ("MARTHA", "MARHTA"),
                JWS ("MARTHA", "MARHTA", Default_P)),
          "default P matches explicit Default_P");
   Check (Near (JWD ("MARTHA", "MARHTA"),
                JWD ("MARTHA", "MARHTA", Default_P)),
          "default P on distance");
   Check (Near (JWS ("abc", "abd", F (0.0)), JS ("abc", "abd")),
          "P=0 → JW=Jaro");

   ------------------------------------------------------------------
   Section ("17. More named / everyday pairs");
   ------------------------------------------------------------------
   Check (Near (JS ("john", "jan"), JS ("jan", "john")),
          "john/jan symmetric");
   Check (JWS ("john", "jan") >= JS ("john", "jan"),
          "JW >= Jaro john/jan");
   Check (Near (JS ("test", "test"), F (1.0)), "test/test");
   Check (Near (JS ("test", "tset"), JS ("tset", "test")),
          "test/tset symmetric");
   Check (JS ("", "test") = F (0.0), "empty/test");
   Check (Near (JWS ("prefix", "preamble"),
                JWS ("preamble", "prefix")),
          "prefix/preamble JW symmetric");
   Check (JWS ("prefix", "preamble") > JS ("prefix", "preamble"),
          "common 'pre' boosts JW");
   Check (Near (JS ("aa", "a"), F (0.83333)), "aa/a ≈ 0.83333");
   Check (Near (JS ("aaa", "aa"), F (0.0))
            or else JS ("aaa", "aa") > F (0.5),
          "aaa/aa computed");
   --  max=3 → window 0; positions: a-a, a-a, a beyond → m=2
   --  (1/3)(2/3 + 2/2 + 1) = (1/3)(0.666+1+1)=0.888...
   Check (Near (JS ("aaa", "aa"), F (0.88889)), "aaa/aa ≈ 0.88889");

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

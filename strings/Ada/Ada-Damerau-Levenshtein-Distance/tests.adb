--  Standalone test suite for Damerau_Levenshtein_Distance (OSA; main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Damerau_Levenshtein_Distance; use Damerau_Levenshtein_Distance;

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

   function Dist (A, B : String) return Natural is
     (Distance (A, B));

   function Sim (A, B : String) return Float is
     (Similarity (A, B));

   function Dist_Raises (A, B : String) return Boolean is
      Unused : Natural;
   begin
      Unused := Distance (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function Sim_Raises (A, B : String) return Boolean is
      Unused : Float;
   begin
      Unused := Similarity (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sim_Raises;

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

begin
   Put_Line ("Damerau_Levenshtein_Distance (OSA) test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);

   Section ("1. Empty / empty and empty / nonempty");
   Check (Dist ("", "") = N (0), "Distance empty/empty = 0");
   Check (Near (Sim ("", ""), F (1.0)), "Similarity empty/empty = 1.0");
   Check (Dist ("", "a") = N (1), "Distance empty/a = 1");
   Check (Dist ("a", "") = N (1), "Distance a/empty = 1");
   Check (Dist ("", "abc") = N (3), "Distance empty/abc = 3");
   Check (Dist ("xyz", "") = N (3), "Distance xyz/empty = 3");
   Check (Dist ("", Make_Same (10, 'x')) = N (10), "empty vs 10 chars");
   Check (Dist (Make_Same (7, 'z'), "") = N (7), "7 chars vs empty");
   Check (Near (Sim ("", "a"), F (0.0)), "Similarity empty/a = 0");
   Check (Near (Sim ("abc", ""), F (0.0)), "Similarity abc/empty = 0");

   Section ("2. Identical strings");
   Check (Dist ("a", "a") = N (0), "identical single char");
   Check (Dist ("hello", "hello") = N (0), "identical hello");
   Check (Dist (Make_Same (20, 'q'), Make_Same (20, 'q')) = N (0),
          "identical 20 qs");
   Check (Dist (Make_Alpha (50), Make_Alpha (50)) = N (0),
          "identical alpha-50");
   Check (Near (Sim ("hello", "hello"), F (1.0)), "Similarity identical");
   Check (Near (Sim ("x", "x"), F (1.0)), "Similarity identical single");
   Check (Near (Sim (Make_Alpha (30), Make_Alpha (30)), F (1.0)),
          "Similarity identical alpha-30");

   Section ("3. Single insert / delete / substitute");
   Check (Dist ("a", "ab") = N (1), "insert one at end");
   Check (Dist ("ab", "a") = N (1), "delete one at end");
   Check (Dist ("a", "b") = N (1), "substitute one");
   Check (Dist ("cat", "cats") = N (1), "insert s");
   Check (Dist ("cats", "cat") = N (1), "delete s");
   Check (Dist ("cat", "bat") = N (1), "sub c to b");
   Check (Dist ("cat", "cut") = N (1), "sub a to u");
   Check (Dist ("cat", "car") = N (1), "sub t to r");
   Check (Dist ("abc", "xabc") = N (1), "insert at start");
   Check (Dist ("xabc", "abc") = N (1), "delete at start");
   Check (Dist ("abc", "axbc") = N (1), "insert in middle");
   Check (Dist ("axbc", "abc") = N (1), "delete in middle");
   Check (Dist ("abc", "adc") = N (1), "sub middle");
   Check (Dist ("color", "colour") = N (1), "color/colour insert u");
   Check (Dist ("colour", "color") = N (1), "colour/color delete u");

   Section ("4. Adjacent transposition (OSA hallmark)");
   Check (Dist ("ab", "ba") = N (1), "ab/ba transposition = 1");
   Check (Dist ("ba", "ab") = N (1), "ba/ab transposition = 1");
   Check (Dist ("ca", "ac") = N (1), "ca/ac transposition = 1");
   Check (Dist ("oh", "ho") = N (1), "oh/ho transposition = 1");
   Check (Dist ("abc", "acb") = N (1), "abc/acb swap bc");
   Check (Dist ("abc", "bac") = N (1), "abc/bac swap ab");
   Check (Dist ("abcd", "acbd") = N (1), "abcd/acbd swap bc");
   Check (Dist ("abcd", "abdc") = N (1), "abcd/abdc swap cd");
   Check (Dist ("xyz", "xzy") = N (1), "xyz/xzy swap yz");
   Check (Dist ("test", "tset") = N (1), "test/tset swap es");
   Check (Dist ("hello", "hlelo") = N (1), "hello/hlelo swap el");
   Check (Dist ("plauge", "plague") = N (1), "plauge/plague = 1");
   Check (Dist ("plague", "plauge") = N (1), "plague/plauge = 1");
   Check (Dist ("aeb", "abe") = N (1), "aeb/abe swap eb");
   Check (Dist ("12345", "12435") = N (1), "12345/12435 swap 34");
   Check (Dist ("abcdefgh", "acbdefgh") = N (1), "abcdefgh swap bc");
   Check (Dist ("abcdef", "abdcef") = N (1), "abcdef/abdcef swap cd");
   Check (Dist ("FUCK", "FCUK") = N (1), "FUCK/FCUK swap UC");
   Check (Dist ("smell", "shell") = N (1), "smell/shell sub or near");
   Check (Near (Sim ("ab", "ba"), F (0.5)), "Similarity ab/ba = 0.5");

   Section ("5. OSA vs unrestricted DL marker (ca/abc)");
   --  Unrestricted DL(ca, abc) = 2; OSA = 3 (substring not re-edited).
   Check (Dist ("ca", "abc") = N (3), "OSA ca/abc = 3 (not unrestricted 2)");
   Check (Dist ("abc", "ca") = N (3), "OSA abc/ca = 3 sym");
   Check (Dist ("CA", "ABC") = N (3), "OSA CA/ABC = 3");
   Check (Dist ("AC", "CA") = N (1), "OSA AC/CA = 1 (feeds triangle note)");

   Section ("6. Known Wikipedia / classic pairs (also valid Levenshtein)");
   Check (Dist ("kitten", "sitting") = N (3), "kitten/sitting = 3");
   Check (Dist ("sitting", "kitten") = N (3), "sitting/kitten = 3 sym");
   Check (Dist ("saturday", "sunday") = N (3), "saturday/sunday = 3");
   Check (Dist ("sunday", "saturday") = N (3), "sunday/saturday = 3");
   Check (Dist ("flaw", "lawn") = N (2), "flaw/lawn = 2");
   Check (Dist ("lawn", "flaw") = N (2), "lawn/flaw = 2");
   Check (Dist ("gumbo", "gambol") = N (2), "gumbo/gambol = 2");
   Check (Dist ("book", "back") = N (2), "book/back = 2");
   Check (Dist ("intention", "execution") = N (5),
          "intention/execution = 5");
   Check (Dist ("horse", "ros") = N (3), "horse/ros = 3");
   Check (Dist ("ros", "horse") = N (3), "ros/horse = 3");
   Check (Dist ("meilenstein", "levenshtein") = N (4),
          "meilenstein/levenshtein = 4");
   Check (Dist ("jones", "johnson") = N (4), "jones/johnson = 4");
   Check (Near (Sim ("kitten", "sitting"), F (1.0 - 3.0 / 7.0)),
          "Similarity kitten/sitting");
   Check (Near (Sim ("saturday", "sunday"), F (1.0 - 3.0 / 8.0)),
          "Similarity saturday/sunday");

   Section ("7. Multi-transposition and mixed edits");
   Check (Dist ("abcdef", "abcfed") = N (2), "abcdef/abcfed two swaps");
   Check (Dist ("abc", "cba") = N (2), "abc/cba = 2");
   Check (Dist ("cba", "abc") = N (2), "cba/abc = 2");
   Check (Dist ("ababab", "bababa") = N (2), "ababab/bababa = 2");
   Check (Dist ("ifhs", "fish") = N (2), "ifhs/fish = 2");
   Check (Dist ("a cat", "an act") = N (2), "a cat/an act = 2 OSA");
   Check (Dist ("abcd", "dcba") = N (3), "abcd/dcba = 3 OSA");
   Check (Dist ("hello", "hleol") = Dist ("hleol", "hello"),
          "hello/hleol sym");

   Section ("8. Prefixes / suffixes / shared fragments");
   Check (Dist ("abc", "abcdef") = N (3), "prefix abc of abcdef");
   Check (Dist ("abcdef", "abc") = N (3), "abcdef vs prefix abc");
   Check (Dist ("def", "abcdef") = N (3), "suffix def of abcdef");
   Check (Dist ("abcdef", "def") = N (3), "abcdef vs suffix def");
   Check (Dist ("abc", "xbc") = N (1), "share bc");
   Check (Dist ("abc", "abx") = N (1), "share ab");
   Check (Dist ("aaaa", "aa") = N (2), "aaaa vs aa");
   Check (Dist ("aa", "aaaa") = N (2), "aa vs aaaa");
   Check (Dist ("abab", "ab") = N (2), "abab vs ab");
   Check (Dist ("xyz", "xy") = N (1), "xyz vs xy");
   Check (Dist ("hello world", "hello") = N (6), "hello world vs hello");
   Check (Dist ("test", "testing") = N (3), "test/testing");

   Section ("9. Symmetry");
   Check (Dist ("abc", "def") = Dist ("def", "abc"), "sym abc/def");
   Check (Dist ("kitten", "sitting") = Dist ("sitting", "kitten"),
          "sym kitten");
   Check (Dist ("ab", "ba") = Dist ("ba", "ab"), "sym ab/ba");
   Check (Dist ("a", "bbbb") = Dist ("bbbb", "a"), "sym a/bbbb");
   Check (Dist ("12", "12345") = Dist ("12345", "12"), "sym digits");
   Check (Near (Sim ("abc", "xyz"), Sim ("xyz", "abc")),
          "Similarity symmetric");
   Check (Near (Sim ("ab", "ba"), Sim ("ba", "ab")),
          "Similarity ab/ba symmetric");

   Section ("10. Bounds and non-negativity");
   Check (Dist ("p", "q") >= N (0), "non-negative p/q");
   Check (Dist ("foo", "foo") = N (0), "zero iff equal equal case");
   Check (Dist ("foo", "bar") > N (0), "zero iff equal unequal case");
   Check (Dist ("abc", "a") >= N (2), "lower abs m-n abc/a");
   Check (Dist ("abc", "a") <= N (3), "upper max m n abc/a");
   Check (Dist ("", "abcd") = N (4), "bound empty/abcd");
   Check (Dist ("aaaa", "bbbb") = N (4), "all-sub same length");
   Check (Dist ("abc", "xyz") <= N (3), "upper max for abc/xyz");
   Check (Dist ("ab", "cdef") >= N (2), "lower abs 2-4");
   Check (Dist ("ab", "ba") <= N (2), "OSA ab/ba <= Lev upper 2");
   Check (Dist ("ca", "abc") <= N (3), "OSA ca/abc <= Lev 3");

   Section ("11. Case sensitivity and Character semantics");
   Check (Dist ("a", "A") = N (1), "case-sensitive a/A");
   Check (Dist ("Abc", "abc") = N (1), "case Abc/abc");
   Check (Dist ("HELLO", "hello") = N (5), "HELLO/hello all differ");
   Check (Dist ("Test", "test") = N (1), "Test/test");
   Check (Dist ("Ab", "bA") = N (1), "Ab/bA adjacent transp = 1");
   Check (Dist (" ", "a") = N (1), "space vs a");
   Check (Dist ("a b", "ab") = N (1), "a b vs ab delete space");
   Check (Dist ("1", "2") = N (1), "digit 1/2");
   Check (Dist ("!", "?") = N (1), "punctuation");
   Check (Dist ("a" & Character'Val (10), "a") = N (1), "newline vs none");
   Check (Dist ([Character'Val (233)],
                [Character'Val (232)]) = N (1),
          "Latin-1 e-acute vs e-grave");
   Check (Dist ([Character'Val (255)],
                [Character'Val (255)]) = N (0),
          "Latin-1 identical 255");

   Section ("12. Non-1 String First slices");
   declare
      Buf : constant String (5 .. 10) := "kitten";
      Sit : constant String (3 .. 9) := "sitting";
   begin
      Check (Dist (Buf, Sit) = N (3), "slice kitten/sitting First/=1");
      Check (Dist (Buf (5 .. 7), "kit") = N (0), "slice kit identical");
      Check (Dist (Buf (5 .. 5), Sit (3 .. 3)) = N (1), "slice k vs s");
   end;
   declare
      Big : constant String (10 .. 19) := "abcdefghij";
   begin
      Check (Dist (Big (10 .. 12), Big (15 .. 17)) = N (3),
             "disjoint slices abc/fgh");
      Check (Dist (Big (10 .. 14), Big (10 .. 14)) = N (0),
             "same slice identical");
      Check (Dist (Big (10 .. 11), "ba") = N (1),
             "slice ab/ba transposition");
   end;

   Section ("13. Similarity bounds and formula");
   Check (Near (Sim ("a", "b"), F (0.0)), "Similarity a/b = 0");
   Check (Near (Sim ("aa", "ab"), F (0.5)), "Similarity aa/ab = 0.5");
   Check (Near (Sim ("abc", "abc"), F (1.0)), "Similarity abc/abc");
   Check (Sim ("x", "y") >= F (0.0) and then Sim ("x", "y") <= F (1.0),
          "Similarity in 0 1 x/y");
   Check (Sim ("kitten", "sitting") >= F (0.0)
            and then Sim ("kitten", "sitting") <= F (1.0),
          "Similarity in 0 1 kitten");
   Check (Near (Sim ("ab", "abc"), F (1.0 - 1.0 / 3.0)),
          "Similarity ab/abc formula");
   Check (Near (Sim ("aaaa", "bbbb"), F (0.0)), "Similarity all-sub = 0");
   Check (Near (Sim ("", "xyz"), F (0.0)), "Similarity empty/xyz = 0");
   Check (Near (Sim ("ab", "ba"), F (1.0 - 1.0 / 2.0)),
          "Similarity ab/ba formula");
   Check (Near (Sim ("ca", "abc"), F (1.0 - 3.0 / 3.0)),
          "Similarity ca/abc = 0");

   Section ("14. Progressive edits");
   Check (Dist ("a", "a") = N (0), "prog 0 edits");
   Check (Dist ("a", "b") = N (1), "prog 1 sub");
   Check (Dist ("ab", "cd") = N (2), "prog 2 sub");
   Check (Dist ("abc", "def") = N (3), "prog 3 sub");
   Check (Dist ("abcd", "efgh") = N (4), "prog 4 sub");
   Check (Dist ("", "abcde") = N (5), "prog 5 inserts");
   Check (Dist ("abcde", "") = N (5), "prog 5 deletes");
   Check (Dist ("aaaaa", "bbbbb") = N (5), "prog 5 all-sub");
   Check (Dist ("abcde", "abXde") = N (1), "prog middle sub");
   Check (Dist ("abcde", "abde") = N (1), "prog middle del");
   Check (Dist ("abde", "abcde") = N (1), "prog middle ins");
   Check (Dist ("abcde", "abdce") = N (1), "prog middle transp");

   Section ("15. Repeated characters and patterns");
   Check (Dist ("aaa", "aaaa") = N (1), "aaa/aaaa");
   Check (Dist ("aaaa", "aaa") = N (1), "aaaa/aaa");
   Check (Dist ("aaaa", "bbbb") = N (4), "aaaa/bbbb");
   Check (Dist ("aaab", "aaac") = N (1), "aaab/aaac");
   Check (Dist ("mississippi", "missouri") =
             Dist ("missouri", "mississippi"),
          "mississippi/missouri sym");
   Check (Dist ("bookkeeper", "bookkeeper") = N (0), "bookkeeper identical");
   Check (Dist ("abcabc", "abc") = N (3), "abcabc/abc");
   Check (Dist ("xxxxxx", "x") = N (5), "xxxxxx/x");
   Check (Dist ("xyxyxy", "xy") = N (4), "xyxyxy/xy");
   Check (Dist ("aabb", "abab") = N (1), "aabb/abab transp or edit");

   Section ("16. Modest sizes and Max_Len boundary");
   declare
      A50  : constant String := Make_Alpha (50);
      A50b : constant String := Make_Alpha (50);
      A100 : constant String := Make_Alpha (100);
      D50  : constant String := Make_Digits (50);
   begin
      Check (Dist (A50, A50b) = N (0), "alpha-50 identical");
      Check (Dist (A50, D50) = N (50), "alpha-50 vs digits-50");
      Check (Dist (A100, A100) = N (0), "alpha-100 identical");
      Check (Dist (A50, A100) = N (50), "alpha-50 vs alpha-100 prefix");
   end;
   declare
      A200 : constant String := Make_Same (200, 'a');
      B200 : constant String := Make_Same (200, 'b');
      A199 : constant String := Make_Same (199, 'a');
   begin
      Check (Dist (A200, A200) = N (0), "200 identical as");
      Check (Dist (A200, B200) = N (200), "200 a vs 200 b");
      Check (Dist (A200, A199) = N (1), "200 a vs 199 a");
   end;
   declare
      Exact : constant String := Make_Same (Max_Len, 'z');
      Over  : constant String := Make_Same (Max_Len + 1, 'z');
      Tiny  : constant String := "ok";
   begin
      Check (Dist (Exact, Exact) = N (0), "Max_Len identical accepted");
      Check (Dist (Exact, Tiny) = N (Max_Len),
             "Max_Len zs vs ok = Max_Len");
      Check (Dist_Raises (Over, Tiny), "Distance raises over Max_Len A");
      Check (Dist_Raises (Tiny, Over), "Distance raises over Max_Len B");
      Check (Dist_Raises (Over, Over), "Distance raises both over");
      Check (Sim_Raises (Over, Tiny), "Similarity raises over Max_Len");
      Check (not Dist_Raises (Exact, Tiny),
             "Distance accepts exactly Max_Len");
      Check (not Sim_Raises (Exact, Exact),
             "Similarity accepts exactly Max_Len");
   end;
   Check (Dist (Make_Alpha (30), Make_Alpha (40)) = N (10),
          "alpha-30 vs alpha-40");
   Check (Dist (Make_Same (25, 'x'), Make_Same (25, 'y')) = N (25),
          "25 x vs 25 y");
   Check (Dist (Make_Same (1, 'a'), Make_Same (100, 'a')) = N (99),
          "1 a vs 100 a");

   Section ("17. Invalid_Argument guards");
   Check (Dist_Raises (Make_Same (Max_Len + 1, 'a'), "b"),
          "raises A = Max_Len+1");
   Check (Dist_Raises ("b", Make_Same (Max_Len + 1, 'a')),
          "raises B = Max_Len+1");
   Check (Dist_Raises (Make_Same (Max_Len + 5, 'x'),
                       Make_Same (Max_Len + 5, 'y')),
          "raises both oversized");
   Check (Sim_Raises (Make_Same (Max_Len + 1, 'a'), ""),
          "Sim raises oversized A");
   Check (Sim_Raises ("", Make_Same (Max_Len + 1, 'a')),
          "Sim raises oversized B");
   Check (not Dist_Raises ("", ""), "empty does not raise");
   Check (not Dist_Raises (Make_Same (Max_Len, 'a'),
                           Make_Same (Max_Len, 'b')),
          "exactly Max_Len both does not raise");

   Section ("18. More educational / spelling pairs");
   Check (Dist ("algorithm", "altruistic") =
             Dist ("altruistic", "algorithm"),
          "algorithm/altruistic sym");
   Check (Dist ("hello", "hallo") = N (1), "hello/hallo");
   Check (Dist ("world", "word") = N (1), "world/word");
   Check (Dist ("edit", "distance") = Dist ("distance", "edit"),
          "edit/distance sym");
   Check (Dist ("Ada", "ada") = N (1), "Ada/ada");
   Check (Dist ("GNAT", "gnat") = N (4), "GNAT/gnat");
   Check (Dist ("0123", "01234") = N (1), "digit append");
   Check (Dist ("foo bar", "foo  bar") = N (1), "extra space");
   Check (Dist ("a", "aaa") = N (2), "a/aaa");
   Check (Dist ("same", "same") = N (0), "same/same");
   Check (Dist ("teh", "the") = N (1), "teh/the classic typo");
   Check (Dist ("recieve", "receive") = N (1), "recieve/receive transp");
   Check (Dist ("adn", "and") = N (1), "adn/and transp");
   Check (Dist ("fro", "for") = N (1), "fro/for transp");

   Section ("19. Bulk micro-cases (letters)");
   declare
      Letters : constant String := "abcdefghijklmnopqrstuvwxyz";
   begin
      for I in Letters'Range loop
         Check (Dist ([Letters (I)], [Letters (I)]) = N (0),
                "ident letter " & Letters (I));
      end loop;
      for I in Letters'First .. Letters'Last - 1 loop
         Check (Dist ([Letters (I)], [Letters (I + 1)]) = N (1),
                "adj letters " & Letters (I) & "/" & Letters (I + 1));
         declare
            Pair : constant String :=
              Letters (I) & Letters (I + 1);
            Swapped : constant String :=
              Letters (I + 1) & Letters (I);
         begin
            Check (Dist (Pair, Swapped) = N (1),
                   "transp " & Pair & "/" & Swapped);
         end;
      end loop;
   end;

   Section ("20. Bulk micro-cases (length ladder)");
   for L in 0 .. 15 loop
      declare
         A : constant String := Make_Same (L, 'a');
         B : constant String := Make_Same (L, 'b');
         C : constant String := Make_Same (L + 1, 'a');
      begin
         Check (Dist (A, A) = N (0), "ladder ident L=" & L'Image);
         if L > 0 then
            Check (Dist (A, B) = N (L), "ladder all-sub L=" & L'Image);
         end if;
         Check (Dist (A, C) = N (1), "ladder +1 L=" & L'Image);
         Check (Dist (A, "") = N (L), "ladder vs empty L=" & L'Image);
      end;
   end loop;

   Section ("21. Similarity bulk cross-checks");
   for L in 1 .. 12 loop
      declare
         A : constant String := Make_Same (L, 'a');
         B : constant String := Make_Same (L, 'b');
         D : constant Natural := Dist (A, B);
         Expected : constant Float := 1.0 - Float (D) / Float (L);
      begin
         Check (Near (Sim (A, B), Expected),
                "Sim formula all-sub L=" & L'Image);
         Check (Near (Sim (A, A), F (1.0)),
                "Sim identical L=" & L'Image);
      end;
   end loop;
   for L in 1 .. 10 loop
      declare
         A : constant String := Make_Alpha (L);
         B : constant String := Make_Alpha (L + 3);
         D : constant Natural := Dist (A, B);
         Denom : constant Natural := L + 3;
         Expected : constant Float := 1.0 - Float (D) / Float (Denom);
      begin
         Check (Near (Sim (A, B), Expected),
                "Sim formula alpha L/" & Natural'Image (L + 3));
         Check (D = N (3), "alpha prefix gap 3 L=" & L'Image);
      end;
   end loop;

   Section ("22. Mixed operations scripts");
   Check (Dist ("abc", "ab") = N (1), "mix delete c");
   Check (Dist ("ab", "abc") = N (1), "mix insert c");
   Check (Dist ("abc", "adc") = N (1), "mix sub b to d");
   Check (Dist ("abc", "axc") = N (1), "mix sub b to x");
   Check (Dist ("abc", "aXcY") = N (2), "mix abc/aXcY");
   Check (Dist ("park", "spark") = N (1), "park/spark");
   Check (Dist ("spark", "park") = N (1), "spark/park");
   Check (Dist ("apple", "apply") = N (1), "apple/apply");
   Check (Dist ("apple", "aple") = N (1), "apple/aple");
   Check (Dist ("banana", "bandana") = N (1), "banana/bandana");
   Check (Dist ("orange", "apple") = Dist ("apple", "orange"),
          "orange/apple sym");
   Check (Dist ("twelve", "eleven") = Dist ("eleven", "twelve"),
          "twelve/eleven sym");
   Check (Dist ("ahoy", "ahoy") = N (0), "ahoy identical");
   Check (Dist ("ahoy", "aohy") = N (1), "ahoy/aohy transp");

   Section ("23. Final invariants");
   Check (Dist ("", "") = Dist ("", ""), "reflex empty");
   Check (Near (Sim ("xyz", "xyz"), F (1.0)), "final sim identical");
   Check (Dist ("q", "q") = N (0), "final q/q");
   Check (Dist ("q", "r") = N (1), "final q/r");
   Check (Dist ("qr", "rq") = N (1), "final qr/rq transp");
   Check (Pass_Count > N (0), "suite recorded passes");

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

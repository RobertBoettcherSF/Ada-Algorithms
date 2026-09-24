--  Standalone test suite for Bitap_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO;     use Ada.Text_IO;
with Bitap_Algorithm; use Bitap_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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
   function N (X : Integer) return Integer is (X);
   function Nat (X : Natural) return Natural is (X);

   function Exact_Raises (Text, Pattern : String) return Boolean is
      Unused : Integer;
   begin
      Unused := Find_Exact (Text, Pattern);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   function Contains_Raises (Text, Pattern : String) return Boolean is
      Unused : Boolean;
   begin
      Unused := Contains_Exact (Text, Pattern);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Contains_Raises;

   function Approx_Raises
     (Text, Pattern : String; K : Natural) return Boolean
   is
      Unused : Integer;
   begin
      Unused := Find_Approx (Text, Pattern, K);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Approx_Raises;

   --  Brute-force Levenshtein (oracle for approx tests).
   function Lev (A, B : String) return Natural is
      La : constant Natural := A'Length;
      Lb : constant Natural := B'Length;
   begin
      if La = 0 then
         return Lb;
      end if;
      if Lb = 0 then
         return La;
      end if;
      if A = B then
         return 0;
      end if;
      declare
         Prev : array (0 .. Lb) of Natural;
         Curr : array (0 .. Lb) of Natural;
         Cost : Natural;
      begin
         for J in 0 .. Lb loop
            Prev (J) := J;
         end loop;
         for I in 1 .. La loop
            Curr (0) := I;
            for J in 1 .. Lb loop
               if A (A'First + I - 1) = B (B'First + J - 1) then
                  Cost := 0;
               else
                  Cost := 1;
               end if;
               Curr (J) :=
                 Natural'Min
                   (Curr (J - 1) + 1,
                    Natural'Min (Prev (J) + 1, Prev (J - 1) + Cost));
            end loop;
            for Jj in 0 .. Lb loop
               Prev (Jj) := Curr (Jj);
            end loop;
         end loop;
         return Prev (Lb);
      end;
   end Lev;

   --  Leftmost start of a substring within Lev ≤ K (oracle).
   function Oracle_Approx
     (Text, Pattern : String; K : Natural) return Integer
   is
      M : constant Positive := Pattern'Length;
   begin
      if Text'Length = 0 then
         return Not_Found;
      end if;
      for S in Text'Range loop
         for E in S .. Text'Last loop
            if abs (Integer (E - S + 1) - Integer (M)) <= Integer (K)
              and then Lev (Text (S .. E), Pattern) <= K
            then
               return Integer (S);
            end if;
         end loop;
      end loop;
      return Not_Found;
   end Oracle_Approx;

   function Make_Same (L : Natural; C : Character) return String is
      R : String (1 .. L);
   begin
      for I in 1 .. L loop
         R (I) := C;
      end loop;
      return R;
   end Make_Same;

   function Make_Alpha (L : Natural) return String is
      R : String (1 .. L);
   begin
      for I in 1 .. L loop
         R (I) := Character'Val (Character'Pos ('a') + (I - 1) mod 26);
      end loop;
      return R;
   end Make_Alpha;

begin
   Put_Line ("Bitap_Algorithm test suite");
   Put_Line ("Max_Text_Len =" & Max_Text_Len'Image
             & "  Max_Pattern_Len =" & Max_Pattern_Len'Image);

   -----------------------------------------------------------------
   Section ("1. Exact — empty text / misses");
   -----------------------------------------------------------------
   Check (Find_Exact ("", "a") = N (Not_Found), "empty text / a → NF");
   Check (Find_Exact ("", "abc") = N (Not_Found), "empty text / abc → NF");
   Check (Find_Exact ("hello", "xyz") = N (Not_Found), "hello / xyz → NF");
   Check (Find_Exact ("abc", "abcd") = N (Not_Found), "pattern longer → NF");
   Check (Find_Exact ("aaaa", "b") = N (Not_Found), "aaaa / b → NF");
   Check (Find_Exact ("abc", "x") = N (Not_Found), "abc / x → NF");
   Check (not Contains_Exact ("hello", "XYZ"), "Contains miss XYZ");
   Check (not Contains_Exact ("", "z"), "Contains empty text");

   -----------------------------------------------------------------
   Section ("2. Exact — first / middle / last hits");
   -----------------------------------------------------------------
   Check (Find_Exact ("hello", "h") = N (1), "hello / h → 1");
   Check (Find_Exact ("hello", "e") = N (2), "hello / e → 2");
   Check (Find_Exact ("hello", "o") = N (5), "hello / o → 5");
   Check (Find_Exact ("hello", "he") = N (1), "hello / he → 1");
   Check (Find_Exact ("hello", "el") = N (2), "hello / el → 2");
   Check (Find_Exact ("hello", "ll") = N (3), "hello / ll → 3");
   Check (Find_Exact ("hello", "lo") = N (4), "hello / lo → 4");
   Check (Find_Exact ("hello", "hello") = N (1), "hello / hello → 1");
   Check (Find_Exact ("hello", "ell") = N (2), "hello / ell → 2");
   Check (Find_Exact ("abc", "abc") = N (1), "abc / abc → 1");
   Check (Find_Exact ("xabc", "abc") = N (2), "xabc / abc → 2");
   Check (Find_Exact ("abcx", "abc") = N (1), "abcx / abc → 1");
   Check (Find_Exact ("xxabcxx", "abc") = N (3), "xxabcxx / abc → 3");
   Check (Contains_Exact ("hello", "ell"), "Contains ell");
   Check (Contains_Exact ("hello", "hello"), "Contains hello");
   Check (Contains_Exact ("a", "a"), "Contains singleton");

   -----------------------------------------------------------------
   Section ("3. Exact — overlaps and repeats");
   -----------------------------------------------------------------
   Check (Find_Exact ("aaaa", "aa") = N (1), "aaaa / aa first");
   Check (Find_Exact ("aaaa", "aaa") = N (1), "aaaa / aaa first");
   Check (Find_Exact ("ababab", "bab") = N (2), "ababab / bab → 2");
   Check (Find_Exact ("banana", "ana") = N (2), "banana / ana → 2");
   Check (Find_Exact ("banana", "an") = N (2), "banana / an → 2");
   Check (Find_Exact ("mississippi", "issi") = N (2), "mississippi / issi");
   Check (Find_Exact ("mississippi", "ssi") = N (3), "mississippi / ssi");
   Check (Find_Exact ("mississippi", "ppi") = N (9), "mississippi / ppi");

   -----------------------------------------------------------------
   Section ("4. Exact — case, digits, spaces, punctuation");
   -----------------------------------------------------------------
   Check (Find_Exact ("Hello", "hello") = N (Not_Found), "case miss");
   Check (Find_Exact ("Hello", "Hello") = N (1), "case hit");
   Check (Find_Exact ("Hello", "H") = N (1), "case H");
   Check (Find_Exact ("aBcDe", "BcD") = N (2), "mixed case BcD");
   Check (Find_Exact ("abc123", "123") = N (4), "digits");
   Check (Find_Exact ("a b c", "b") = N (3), "space-separated b");
   Check (Find_Exact ("a b c", " ") = N (2), "space char");
   Check (Find_Exact ("foo,bar", ",") = N (4), "comma");
   Check (Find_Exact ("a.b.c", ".b.") = N (2), "dots");
   Check (Find_Exact ("x" & ASCII.LF & "y", "" & ASCII.LF) = N (2),
          "newline");

   -----------------------------------------------------------------
   Section ("5. Exact — non-1 String'First slices");
   -----------------------------------------------------------------
   declare
      Buf : constant String := "XXXneedleYYY";
      --  Slice with First = 4
      Sli : String renames Buf (4 .. 9);
   begin
      Check (Sli = "needle", "slice is needle");
      Check (Find_Exact (Sli, "needle") = N (4), "slice full → 4");
      Check (Find_Exact (Sli, "eed") = N (5), "slice eed → 5");
      Check (Find_Exact (Sli, "n") = N (4), "slice n → 4");
      Check (Find_Exact (Sli, "e") = N (5), "slice first e → 5");
      Check (Contains_Exact (Sli, "dle"), "slice Contains dle");
   end;

   -----------------------------------------------------------------
   Section ("6. Exact — Invalid_Argument");
   -----------------------------------------------------------------
   Check (Exact_Raises ("abc", ""), "exact empty pattern");
   Check (Contains_Raises ("abc", ""), "contains empty pattern");
   Check (Exact_Raises ("x", Make_Alpha (64)), "pattern len 64");
   Check (Exact_Raises ("x", Make_Same (100, 'a')), "pattern len 100");
   declare
      Big : constant String := Make_Same (Max_Text_Len + 1, 'a');
   begin
      Check (Exact_Raises (Big, "a"), "text > Max_Text_Len");
   end;
   --  Boundary OK: pattern length 63, text length Max_Text_Len not needed
   Check (Find_Exact (Make_Alpha (63), Make_Alpha (63)) = N (1),
          "pattern len 63 exact hit");
   Check (Find_Exact ("abc", Make_Alpha (63)) = N (Not_Found),
          "pattern 63 miss in short text");

   -----------------------------------------------------------------
   Section ("7. Approx K=0 reduces to exact");
   -----------------------------------------------------------------
   Check (Find_Approx ("hello", "ell", Nat (0)) = N (2), "K0 ell");
   Check (Find_Approx ("hello", "xyz", Nat (0)) = N (Not_Found), "K0 miss");
   Check (Find_Approx ("abc", "abc", Nat (0)) = N (1), "K0 full");
   Check (Find_Approx ("", "a", Nat (0)) = N (Not_Found), "K0 empty text");
   Check (Find_Approx ("banana", "ana", Nat (0)) = N (2), "K0 ana");
   Check (Find_Approx ("xabc", "abc", Nat (0)) = N (2), "K0 xabc");
   Check (Approx_Raises ("abc", "", Nat (0)), "K0 empty pattern raises");

   -----------------------------------------------------------------
   Section ("8. Approx K=1 — substitution / insertion / deletion");
   -----------------------------------------------------------------
   Check (Find_Approx ("cot", "cat", Nat (1)) = N (1), "sub cot~cat");
   Check (Find_Approx ("caxt", "cat", Nat (1)) = N (1), "ins caxt~cat");
   Check (Find_Approx ("ct", "cat", Nat (1)) = N (1), "del ct~cat");
   Check (Find_Approx ("xxcatxx", "cot", Nat (1)) = N (3), "cot in xxcatxx");
   Check (Find_Approx ("hello", "hallo", Nat (1)) = N (1), "hallo~hello");
   Check (Find_Approx ("hello", "helo", Nat (1)) = N (1), "helo~hello");
   Check (Find_Approx ("abcdef", "abXdef", Nat (1)) = N (1), "abXdef");
   Check (Find_Approx ("abcd", "axcd", Nat (1)) = N (1), "axcd~abcd");
   Check (Find_Approx ("x", "y", Nat (1)) = N (1), "single sub");
   Check (Find_Approx ("abc", "adc", Nat (1)) = N (1), "adc~abc");
   Check (Find_Approx ("abc", "ab", Nat (1)) = N (1), "ab in abc K1");
   Check (Find_Approx ("abc", "abcd", Nat (1)) = N (1), "abcd~abc K1");
   Check (Find_Approx ("The quick brown fox", "quik", Nat (1)) = N (5),
          "quik~quick");
   Check (Find_Approx ("kitten", "sitten", Nat (1)) = N (1), "sitten");
   Check (Find_Approx ("color", "colour", Nat (1)) = N (1), "colour~color");

   -----------------------------------------------------------------
   Section ("9. Approx K=2 and higher");
   -----------------------------------------------------------------
   Check (Find_Approx ("abc", "xyz", Nat (2)) = N (Not_Found),
          "abc/xyz K2 still NF (dist 3)");
   Check (Find_Approx ("abc", "xyz", Nat (3)) = N (1), "abc/xyz K3");
   Check (Find_Approx ("kitten", "sitting", Nat (3)) = N (1),
          "kitten/sitting K3");
   Check (Find_Approx ("abcd", "xy", Nat (2)) = N (1), "xy in abcd K2");
   Check (Find_Approx ("abcdef", "abXYef", Nat (2)) = N (1), "two subs");
   Check (Find_Approx ("axc", "abc", Nat (1)) = N (1), "axc~abc");
   Check (Find_Approx ("ac", "abc", Nat (1)) = N (1), "ac~abc del");
   Check (Find_Approx ("abbc", "abc", Nat (1)) = N (1), "abbc~abc ins");
   Check (Find_Approx ("zzzz", "cat", Nat (2)) = N (Not_Found),
          "zzzz/cat K2 NF");
   Check (Find_Approx ("zzzz", "cat", Nat (3)) = N (1), "zzzz/cat K3");

   -----------------------------------------------------------------
   Section ("10. Approx — misses and empty text");
   -----------------------------------------------------------------
   Check (Find_Approx ("", "cat", Nat (1)) = N (Not_Found), "empty K1");
   Check (Find_Approx ("", "cat", Nat (5)) = N (Not_Found), "empty K5");
   Check (Find_Approx ("hello", "xyz", Nat (1)) = N (Not_Found),
          "hello/xyz K1 NF");
   Check (Find_Approx ("ab", "wxyz", Nat (1)) = N (Not_Found),
          "short text long pat K1");
   Check (Find_Approx ("same", "same", Nat (2)) = N (1), "identical K2");

   -----------------------------------------------------------------
   Section ("11. Approx — Invalid_Argument");
   -----------------------------------------------------------------
   Check (Approx_Raises ("abc", "", Nat (1)), "approx empty pattern");
   Check (Approx_Raises ("x", Make_Alpha (64), Nat (1)), "approx pat 64");
   Check (Approx_Raises ("hello", "ell", Nat (64)), "K=64 > Max");
   Check (Approx_Raises ("hello", "ell", Max_Pattern_Len + 1),
          "K = Max+1");
   declare
      Big : constant String := Make_Same (Max_Text_Len + 1, 'b');
   begin
      Check (Approx_Raises (Big, "b", Nat (1)), "approx text too long");
   end;
   --  K = Max_Pattern_Len is allowed
   Check (Find_Approx ("a", "b", Max_Pattern_Len) = N (1),
          "K=Max single char sub");

   -----------------------------------------------------------------
   Section ("12. Approx — non-1 String'First");
   -----------------------------------------------------------------
   declare
      Buf : constant String := "YYcaxtZZ";
      Sli : String renames Buf (3 .. 6);  -- "caxt"
   begin
      Check (Find_Approx (Sli, "cat", Nat (1)) = N (3),
             "slice caxt~cat → 3");
      Check (Find_Approx (Sli, "cat", Nat (0)) = N (Not_Found),
             "slice exact cat miss");
   end;

   -----------------------------------------------------------------
   Section ("13. Approx vs oracle (hand cases)");
   -----------------------------------------------------------------
   declare
      procedure Cross
        (Text, Pattern : String; K : Natural; Label : String)
      is
         Got : constant Integer := Find_Approx (Text, Pattern, K);
         Exp : constant Integer := Oracle_Approx (Text, Pattern, K);
      begin
         Check (Got = Exp, Label & " got" & Got'Image & " exp" & Exp'Image);
      end Cross;
   begin
      Cross ("hello", "ell", 0, "cross ell K0");
      Cross ("hello", "hallo", 1, "cross hallo");
      Cross ("caxt", "cat", 1, "cross caxt");
      Cross ("ct", "cat", 1, "cross ct");
      Cross ("cot", "cat", 1, "cross cot");
      Cross ("xxcatxx", "cot", 1, "cross xxcatxx");
      Cross ("abcdef", "abXdef", 1, "cross abXdef");
      Cross ("kitten", "sitting", 3, "cross kitten");
      Cross ("abc", "xyz", 2, "cross abc/xyz K2");
      Cross ("abc", "xyz", 3, "cross abc/xyz K3");
      Cross ("banana", "bana", 0, "cross bana");
      Cross ("mississippi", "miss", 0, "cross miss");
      Cross ("abcd", "xy", 2, "cross xy K2");
      Cross ("color", "colour", 1, "cross colour");
      Cross ("The quick brown fox", "quik", 1, "cross quik");
   end;

   -----------------------------------------------------------------
   Section ("14. Random short strings vs oracle");
   -----------------------------------------------------------------
   declare
      --  Tiny deterministic LCG (mod 2^31) for reproducibility.
      type U32 is mod 2**31;
      Seed : U32 := 42;

      function Rand (Modulus : Positive) return Natural is
      begin
         Seed := Seed * 1103515245 + 12345;
         return Natural (Seed mod U32 (Modulus));
      end Rand;

      Alphabet : constant String := "abcde";
      Trials   : constant := 100;
      Failures : Natural := 0;
   begin
      for T in 1 .. Trials loop
         declare
            Nlen : constant Natural := Rand (16);
            Mlen : constant Positive := 1 + Rand (6);
            K    : constant Natural := Rand (4);
            Text : String (1 .. Nlen);
            Pat  : String (1 .. Mlen);
            Got, Exp : Integer;
         begin
            for I in 1 .. Nlen loop
               Text (I) := Alphabet (1 + Rand (Alphabet'Length));
            end loop;
            for I in 1 .. Mlen loop
               Pat (I) := Alphabet (1 + Rand (Alphabet'Length));
            end loop;
            Got := Find_Approx (Text, Pat, K);
            Exp := Oracle_Approx (Text, Pat, K);
            if Got /= Exp then
               Failures := Failures + 1;
               Check (False,
                      "rand#" & T'Image
                      & " text=[" & Text & "] pat=[" & Pat & "] K="
                      & K'Image & " got" & Got'Image & " exp" & Exp'Image);
            else
               Pass_Count := Pass_Count + 1;
               Put_Line ("  PASS: rand#" & T'Image);
            end if;
         end;
      end loop;
      Check (Failures = Nat (0),
             "random oracle summary: 0 fails in" & Trials'Image & " trials");
   end;

   -----------------------------------------------------------------
   Section ("15. Longer exact patterns and texts");
   -----------------------------------------------------------------
   declare
      Pat  : constant String := Make_Alpha (40);
      Text : constant String :=
        Make_Same (10, 'z') & Pat & Make_Same (10, 'z');
   begin
      Check (Find_Exact (Text, Pat) = N (11), "alpha40 embedded → 11");
      Check (Find_Approx (Text, Pat, Nat (0)) = N (11), "alpha40 K0");
      Check (Contains_Exact (Text, Pat), "alpha40 Contains");
   end;
   declare
      Pat : constant String := Make_Same (63, 'q');
      Txt : constant String := Make_Same (20, 'x') & Pat;
   begin
      Check (Find_Exact (Txt, Pat) = N (21), "63 q's → 21");
      Check (Find_Approx (Txt, Pat, Nat (0)) = N (21), "63 q's K0");
   end;
   declare
      --  Near-miss at K=1: flip one character in a length-20 pattern.
      Base : constant String := Make_Alpha (20);
      Mut  : String := Base;
   begin
      Mut (10) := 'Z';
      Check (Find_Exact (Base, Mut) = N (Not_Found), "mut exact miss");
      Check (Find_Approx (Base, Mut, Nat (1)) = N (1), "mut K1 hit");
      Check (Find_Approx (Base, Mut, Nat (0)) = N (Not_Found), "mut K0 miss");
   end;

   -----------------------------------------------------------------
   Section ("16. Contains_Exact vs Find_Exact equivalence");
   -----------------------------------------------------------------
   declare
      procedure Eq (Text, Pattern : String; Label : String) is
         F : Integer;
         C : Boolean;
      begin
         begin
            F := Find_Exact (Text, Pattern);
            C := Contains_Exact (Text, Pattern);
            Check (C = (F /= Not_Found), Label);
         exception
            when Invalid_Argument =>
               Check (Contains_Raises (Text, Pattern),
                      Label & " both raise");
         end;
      end Eq;
   begin
      Eq ("hello", "ell", "eq ell");
      Eq ("hello", "xyz", "eq xyz");
      Eq ("", "a", "eq empty text");
      Eq ("abcabc", "cab", "eq cab");
      Eq ("a", "a", "eq a");
      Eq ("a", "b", "eq miss");
   end;

   -----------------------------------------------------------------
   Section ("17. First / middle / last approx placements");
   -----------------------------------------------------------------
   Check (Find_Approx ("Xabcdef", "abXdef", Nat (1)) = N (2),
          "approx middle start");
   Check (Find_Approx ("abcdefY", "abcdeX", Nat (1)) = N (1),
          "approx first start");
   Check (Find_Approx ("ZZcot", "cat", Nat (1)) = N (3),
          "approx last-ish cot");
   Check (Find_Approx ("cat", "cat", Nat (2)) = N (1), "exact under K2");
   Check (Find_Approx ("at", "cat", Nat (1)) = N (1), "leading del");
   Check (Find_Approx ("ca", "cat", Nat (1)) = N (1), "trailing del");
   Check (Find_Approx ("cXat", "cat", Nat (1)) = N (1), "internal ins");

   -----------------------------------------------------------------
   Section ("18. Boundary K and pattern lengths");
   -----------------------------------------------------------------
   Check (Find_Approx ("abcdef", "a", Nat (0)) = N (1), "pat len 1");
   Check (Find_Approx ("zzzz", "a", Nat (1)) = N (1), "any→a K1");
   Check (Find_Exact ("q", "q") = N (1), "singleton exact");
   Check (Find_Exact (Make_Alpha (1), "a") = N (1), "Make_Alpha1");
   Check (not Exact_Raises (Make_Alpha (63), "a"), "pat 63 vs short OK raise?");
   --  Pattern of length 63 searching in itself
   Check (Find_Exact (Make_Alpha (63), Make_Alpha (63)) /= N (Not_Found),
          "63 self hit");
   Check (Find_Approx (Make_Alpha (30), Make_Alpha (30), Nat (2)) = N (1),
          "alpha30 K2 identical");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

--  Standalone test suite for Longest_Common_Substring (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Longest_Common_Substring; use Longest_Common_Substring;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static wrapper avoids -gnatwc constant-condition warnings.
   function S (X : String) return String is (X);

   function Len_AB (Left, Right : String) return Natural is
     (Length (A => Left, B => Right));

   function Find_AB (Left, Right : String) return String is
     (Find (A => Left, B => Right));

   function Brute_AB (Left, Right : String) return Natural is
     (Brute_Force_Length (A => Left, B => Right));

   function Raises_Invalid (Left, Right : String) return Boolean is
   begin
      declare
         Unused : constant Natural := Len_AB (Left, Right);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Raises_Invalid;

   function Find_Raises (Left, Right : String) return Boolean is
   begin
      declare
         Unused : constant String := Find_AB (Left, Right);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   function Is_Substring (Sub, Haystack : String) return Boolean is
   begin
      if Sub'Length = 0 then
         return True;
      end if;
      if Sub'Length > Haystack'Length then
         return False;
      end if;
      for Offset in 0 .. Haystack'Length - Sub'Length loop
         declare
            Ok : Boolean := True;
         begin
            for K in 0 .. Sub'Length - 1 loop
               if Haystack (Haystack'First + Offset + K)
                 /= Sub (Sub'First + K)
               then
                  Ok := False;
                  exit;
               end if;
            end loop;
            if Ok then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Is_Substring;

   procedure Expect_Length
     (Left, Right : String;
      Expected    : Natural;
      Label       : String)
   is
   begin
      Check (Len_AB (Left, Right) = Expected, Label & " Length");
      Check (Len_AB (Left => Right, Right => Left) = Expected,
             Label & " Length symmetric");
   end Expect_Length;

   procedure Expect_Find
     (Left, Right : String;
      Expected    : String;
      Label       : String)
   is
      Got : constant String := Find_AB (Left, Right);
   begin
      Check (Got = Expected, Label & " Find");
      Check (Got'Length = Len_AB (Left, Right),
             Label & " Find length matches");
      Check (Is_Substring (Got, Left) and then Is_Substring (Got, Right),
             Label & " Find is substring of both");
   end Expect_Find;

   procedure Expect_DP_Eq_Brute
     (Left, Right : String;
      Label       : String)
   is
   begin
      Check (Len_AB (Left, Right) = Brute_AB (Left, Right),
             Label & " DP=brute");
   end Expect_DP_Eq_Brute;

   procedure Check_Sym_Pair (Left, Right : String; Label : String) is
      FA : constant String := Find_AB (Left, Right);
      FB : constant String := Find_AB (Left => Right, Right => Left);
   begin
      Check (FA'Length = FB'Length, Label & " sym len");
      Check (Is_Substring (FA, Left) and then Is_Substring (FA, Right),
             Label & " FA valid");
      Check (Is_Substring (FB, Left) and then Is_Substring (FB, Right),
             Label & " FB valid");
   end Check_Sym_Pair;

begin
   Ada.Text_IO.Put_Line ("Longest_Common_Substring tests");
   Ada.Text_IO.Put_Line ("==============================");

   ------------------------------------------------------------------
   Section ("1. Empty / trivial");
   ------------------------------------------------------------------
   Expect_Length (S (""), S (""), 0, "both empty");
   Expect_Find   (S (""), S (""), "", "both empty");
   Expect_Length (S (""), S ("abc"), 0, "empty A");
   Expect_Find   (S (""), S ("abc"), "", "empty A");
   Expect_Length (S ("abc"), S (""), 0, "empty B");
   Expect_Find   (S ("xyz"), S (""), "", "empty B");
   Expect_Length (S ("a"), S ("a"), 1, "single equal");
   Expect_Find   (S ("a"), S ("a"), "a", "single equal");
   Expect_Length (S ("a"), S ("b"), 0, "single different");
   Expect_Find   (S ("a"), S ("b"), "", "single different");

   ------------------------------------------------------------------
   Section ("2. Identical strings");
   ------------------------------------------------------------------
   Expect_Length (S ("hello"), S ("hello"), 5, "hello");
   Expect_Find   (S ("hello"), S ("hello"), "hello", "hello");
   Expect_Length (S ("ABABC"), S ("ABABC"), 5, "ABABC identical");
   Expect_Find   (S ("xyz"), S ("xyz"), "xyz", "xyz identical");
   Expect_Length (S ("x"), S ("x"), 1, "x identical");

   ------------------------------------------------------------------
   Section ("3. Known Wikipedia / textbook examples");
   ------------------------------------------------------------------
   Expect_Length (S ("ABABC"), S ("BABCA"), 4, "ABABC/BABCA");
   Expect_Find   (S ("ABABC"), S ("BABCA"), "BABC", "ABABC/BABCA");

   Expect_Length (S ("GeeksforGeeks"), S ("GeeksQuiz"), 5, "Geeks");
   Expect_Find   (S ("GeeksforGeeks"), S ("GeeksQuiz"), "Geeks", "Geeks");

   Expect_Length (S ("abcdxyz"), S ("xyzabcd"), 4, "abcd");
   Expect_Find   (S ("abcdxyz"), S ("xyzabcd"), "abcd", "abcd");

   Expect_Length (S ("zxabcdezy"), S ("yzabcdezx"), 6, "abcdez");
   Expect_Find   (S ("zxabcdezy"), S ("yzabcdezx"), "abcdez", "abcdez");

   Expect_Length (S ("OldSite:GeeksforGeeks.org"),
                  S ("NewSite:GeeksQuiz.com"), 10, "Site:Geeks");
   Expect_Find   (S ("OldSite:GeeksforGeeks.org"),
                  S ("NewSite:GeeksQuiz.com"),
                  "Site:Geeks", "Site:Geeks");

   ------------------------------------------------------------------
   Section ("4. No common characters");
   ------------------------------------------------------------------
   Expect_Length (S ("abc"), S ("XYZ"), 0, "case-sensitive none");
   Expect_Find   (S ("abc"), S ("XYZ"), "", "case-sensitive none");
   Expect_Length (S ("123"), S ("abc"), 0, "digits vs letters");
   Expect_Find   (S ("aaa"), S ("bbb"), "", "aaa/bbb");

   ------------------------------------------------------------------
   Section ("5. Partial overlap / prefixes / suffixes");
   ------------------------------------------------------------------
   Expect_Length (S ("abcdef"), S ("defghi"), 3, "def suffix-prefix");
   Expect_Find   (S ("abcdef"), S ("defghi"), "def", "def suffix-prefix");
   Expect_Length (S ("abcdef"), S ("xyzabc"), 3, "abc prefix-suffix");
   Expect_Find   (S ("abcdef"), S ("xyzabc"), "abc", "abc prefix-suffix");
   Expect_Length (S ("aaaa"), S ("aa"), 2, "aaaa/aa");
   Expect_Find   (S ("aaaa"), S ("aa"), "aa", "aaaa/aa");
   Expect_Length (S ("banana"), S ("anana"), 5, "banana/anana");
   Expect_Find   (S ("banana"), S ("anana"), "anana", "banana/anana");
   Expect_Length (S ("ABAB"), S ("BABA"), 3, "ABAB/BABA");
   Expect_Find   (S ("ABAB"), S ("BABA"), "ABA", "ABAB/BABA");

   ------------------------------------------------------------------
   Section ("6. Tie-breaking (row-major first strict max)");
   ------------------------------------------------------------------
   Expect_Find (S ("xxAYxx"), S ("zzAYzz"), "AY", "AY unique max");
   Expect_Find (S ("abXcd"), S ("abYcd"), "ab", "ab before cd");
   Expect_Length (S ("aaaba"), S ("baaaa"), 3, "aaa run");
   declare
      F : constant String := Find_AB (S ("aaaba"), S ("baaaa"));
   begin
      Check (F'Length = 3, "aaa run Find len");
      Check (Is_Substring (F, S ("aaaba"))
             and then Is_Substring (F, S ("baaaa")),
             "aaa run Find valid");
   end;

   ------------------------------------------------------------------
   Section ("7. DP ≡ brute-force on small cases");
   ------------------------------------------------------------------
   Expect_DP_Eq_Brute (S (""), S (""), "empty");
   Expect_DP_Eq_Brute (S ("a"), S ("a"), "a/a");
   Expect_DP_Eq_Brute (S ("a"), S ("b"), "a/b");
   Expect_DP_Eq_Brute (S ("abc"), S ("xyz"), "abc/xyz");
   Expect_DP_Eq_Brute (S ("ABABC"), S ("BABCA"), "wiki pair");
   Expect_DP_Eq_Brute (S ("GeeksforGeeks"), S ("GeeksQuiz"), "Geeks");
   Expect_DP_Eq_Brute (S ("abcdxyz"), S ("xyzabcd"), "abcdxyz");
   Expect_DP_Eq_Brute (S ("banana"), S ("anana"), "banana");
   Expect_DP_Eq_Brute (S ("ABAB"), S ("BABA"), "ABAB/BABA");
   Expect_DP_Eq_Brute (S ("hello"), S ("hello"), "identical");
   Expect_DP_Eq_Brute (S ("abcdef"), S ("defghi"), "def");
   Expect_DP_Eq_Brute (S ("xxAYxx"), S ("zzAYzz"), "AY");
   Expect_DP_Eq_Brute (S ("abXcd"), S ("abYcd"), "abXcd");
   Expect_DP_Eq_Brute (S ("aaaba"), S ("baaaa"), "runs");
   Expect_DP_Eq_Brute (S ("12345"), S ("34567"), "digits");
   Expect_DP_Eq_Brute (S ("The quick"), S ("quick fox"), "words");

   ------------------------------------------------------------------
   Section ("8. Bounds / Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Big : constant String (1 .. Max_Length + 1) := [others => 'x'];
      Ok  : constant String (1 .. Max_Length) := [others => 'y'];
   begin
      Check (Raises_Invalid (Big, S ("a")), "Length oversize A");
      Check (Raises_Invalid (S ("a"), Big), "Length oversize B");
      Check (Find_Raises (Big, Ok), "Find oversize A");
      Check (Find_Raises (Ok, Big), "Find oversize B");
      Check (Len_AB (Ok, Ok) = Max_Length, "Max_Length identical ok");
      Check (Find_AB (Ok, Ok) = Ok, "Max_Length Find identical");
   end;

   ------------------------------------------------------------------
   Section ("9. Non-1-based slices");
   ------------------------------------------------------------------
   declare
      Buf   : constant String (5 .. 14) := "0123456789";
      Left  : String renames Buf (5 .. 9);
      Right : String renames Buf (8 .. 12);
   begin
      Expect_Length (Left, Right, 2, "slice 01234/34567");
      Expect_Find   (Left, Right, "34", "slice 01234/34567");
      Expect_DP_Eq_Brute (Left, Right, "slice");
   end;

   ------------------------------------------------------------------
   Section ("10. Symmetry of Find length");
   ------------------------------------------------------------------
   Check_Sym_Pair (S ("ABABC"), S ("BABCA"), "wiki");
   Check_Sym_Pair (S ("GeeksforGeeks"), S ("GeeksQuiz"), "Geeks");
   Check_Sym_Pair (S ("banana"), S ("anana"), "banana");
   Check_Sym_Pair (S ("abcdef"), S ("xyz"), "abcdef/xyz");
   Check_Sym_Pair (S ("same"), S ("same"), "same");

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

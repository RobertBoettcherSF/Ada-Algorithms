--  Standalone test suite for Longest_Common_Subsequence (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Longest_Common_Subsequence; use Longest_Common_Subsequence;

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

   function Len_SO (Left, Right : String) return Natural is
     (Length_Space_Optimized (A => Left, B => Right));

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

   function SO_Raises (Left, Right : String) return Boolean is
   begin
      declare
         Unused : constant Natural := Len_SO (Left, Right);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end SO_Raises;

   --  True iff Needle is a (possibly non-contiguous) subsequence of Haystack.
   function Is_Subsequence (Needle, Haystack : String) return Boolean is
      J : Natural := Haystack'First;
   begin
      if Needle'Length = 0 then
         return True;
      end if;
      if Needle'Length > Haystack'Length then
         return False;
      end if;

      for I in Needle'Range loop
         declare
            Found : Boolean := False;
         begin
            while J <= Haystack'Last loop
               if Haystack (J) = Needle (I) then
                  Found := True;
                  J     := J + 1;
                  exit;
               end if;
               J := J + 1;
            end loop;
            if not Found then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Subsequence;

   procedure Expect_Length
     (Left, Right : String;
      Expected    : Natural;
      Label       : String)
   is
   begin
      Check (Len_AB (Left, Right) = Expected, Label & " Length");
      Check (Len_AB (Left => Right, Right => Left) = Expected,
             Label & " Length symmetric");
      Check (Len_SO (Left, Right) = Expected, Label & " Length_SO");
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
             Label & " Find length matches Length");
      Check (Is_Subsequence (Got, Left)
             and then Is_Subsequence (Got, Right),
             Label & " Find is subsequence of both");
   end Expect_Find;

   --  Check Find length / subsequence property without fixing the witness.
   procedure Expect_Find_Valid
     (Left, Right : String;
      Expected_Len : Natural;
      Label        : String)
   is
      Got : constant String := Find_AB (Left, Right);
   begin
      Check (Got'Length = Expected_Len, Label & " Find len");
      Check (Got'Length = Len_AB (Left, Right),
             Label & " Find matches Length");
      Check (Is_Subsequence (Got, Left)
             and then Is_Subsequence (Got, Right),
             Label & " Find is subsequence");
   end Expect_Find_Valid;

begin
   Ada.Text_IO.Put_Line ("Longest_Common_Subsequence tests");
   Ada.Text_IO.Put_Line ("================================");

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
   Expect_Length (S ("AGCAT"), S ("AGCAT"), 5, "AGCAT identical");
   Expect_Find   (S ("xyz"), S ("xyz"), "xyz", "xyz identical");
   Expect_Length (S ("x"), S ("x"), 1, "x identical");

   ------------------------------------------------------------------
   Section ("3. Wikipedia AGCAT / GAC");
   ------------------------------------------------------------------
   --  LCS length 2; witnesses among {AC, GC, GA}.
   --  Find(AGCAT, GAC) with Wikipedia tie-break yields "AC".
   Expect_Length (S ("AGCAT"), S ("GAC"), 2, "AGCAT/GAC");
   Expect_Find   (S ("AGCAT"), S ("GAC"), "AC", "AGCAT/GAC");
   Expect_Find_Valid (S ("GAC"), S ("AGCAT"), 2, "GAC/AGCAT");

   ------------------------------------------------------------------
   Section ("4. Other known textbook examples");
   ------------------------------------------------------------------
   --  ABCD / ACBAD → LCS length 3 (ABD or ACD).
   Expect_Length (S ("ABCD"), S ("ACBAD"), 3, "ABCD/ACBAD");
   Expect_Find_Valid (S ("ABCD"), S ("ACBAD"), 3, "ABCD/ACBAD");

   Expect_Length (S ("XMJYAUZ"), S ("MZJAWXU"), 4, "XMJYAUZ/MZJAWXU");
   Expect_Find   (S ("XMJYAUZ"), S ("MZJAWXU"), "MJAU", "XMJYAUZ/MZJAWXU");

   Expect_Length (S ("abc"), S ("ac"), 2, "abc/ac");
   Expect_Find   (S ("abc"), S ("ac"), "ac", "abc/ac");

   Expect_Length (S ("abcde"), S ("ace"), 3, "abcde/ace");
   Expect_Find   (S ("abcde"), S ("ace"), "ace", "abcde/ace");

   ------------------------------------------------------------------
   Section ("5. No common characters");
   ------------------------------------------------------------------
   Expect_Length (S ("abc"), S ("XYZ"), 0, "case-sensitive none");
   Expect_Find   (S ("abc"), S ("XYZ"), "", "case-sensitive none");
   Expect_Length (S ("123"), S ("abc"), 0, "digits vs letters");
   Expect_Find   (S ("aaa"), S ("bbb"), "", "aaa/bbb");

   ------------------------------------------------------------------
   Section ("6. Partial / interleaved");
   ------------------------------------------------------------------
   Expect_Length (S ("abcdef"), S ("defghi"), 3, "def");
   Expect_Find   (S ("abcdef"), S ("defghi"), "def", "def");
   Expect_Length (S ("axbycz"), S ("abc"), 3, "axbycz/abc");
   Expect_Find   (S ("axbycz"), S ("abc"), "abc", "axbycz/abc");
   Expect_Length (S ("banana"), S ("atana"), 4, "banana/atana");
   Expect_Find_Valid (S ("banana"), S ("atana"), 4, "banana/atana");
   Expect_Length (S ("aaaa"), S ("aa"), 2, "aaaa/aa");
   Expect_Find   (S ("aaaa"), S ("aa"), "aa", "aaaa/aa");

   ------------------------------------------------------------------
   Section ("7. Find length matches Length + subsequence");
   ------------------------------------------------------------------
   declare
      procedure Check_Pair (Left, Right : String; Label : String) is
         Got : constant String := Find_AB (Left, Right);
      begin
         Check (Got'Length = Len_AB (Left, Right),
                Label & " Find=Length");
         Check (Is_Subsequence (Got, Left)
                and then Is_Subsequence (Got, Right),
                Label & " subsequence");
         Check (Len_SO (Left, Right) = Len_AB (Left, Right),
                Label & " SO=DP");
      end Check_Pair;
   begin
      Check_Pair (S ("AGCAT"), S ("GAC"), "AGCAT/GAC");
      Check_Pair (S ("ABCD"), S ("ACBAD"), "ABCD/ACBAD");
      Check_Pair (S ("XMJYAUZ"), S ("MZJAWXU"), "XMJYAUZ");
      Check_Pair (S ("hello"), S ("hello"), "hello");
      Check_Pair (S ("abc"), S ("XYZ"), "abc/XYZ");
      Check_Pair (S ("axbycz"), S ("abc"), "axbycz");
      Check_Pair (S ("banana"), S ("atana"), "banana");
      Check_Pair (S ("The quick brown"), S ("quiet crow"), "words");
   end;

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
      Check (SO_Raises (Big, S ("a")), "SO oversize A");
      Check (Len_AB (Ok, Ok) = Max_Length, "Max_Length identical ok");
      Check (Find_AB (Ok, Ok) = Ok, "Max_Length Find identical");
      Check (Len_SO (Ok, Ok) = Max_Length, "Max_Length SO identical");
   end;

   ------------------------------------------------------------------
   Section ("9. Non-1-based slices");
   ------------------------------------------------------------------
   declare
      Buf   : constant String (5 .. 14) := "0123456789";
      Left  : String renames Buf (5 .. 9);   -- "01234"
      Right : String renames Buf (8 .. 12);  -- "34567"
   begin
      Expect_Length (Left, Right, 2, "slice 01234/34567");
      Expect_Find   (Left, Right, "34", "slice 01234/34567");
   end;

   ------------------------------------------------------------------
   Section ("10. Diff / edit-distance connection (length only)");
   ------------------------------------------------------------------
   --  Insertion/deletion-only edit distance d' = |A|+|B|-2·LCS.
   declare
      A1 : constant String := S ("AGCAT");
      B1 : constant String := S ("GAC");
      L  : constant Natural := Len_AB (A1, B1);
      D  : constant Natural := A1'Length + B1'Length - 2 * L;
   begin
      Check (L = 2, "edit LCS len");
      Check (D = 4, "edit d' = 5+3-4");
   end;

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

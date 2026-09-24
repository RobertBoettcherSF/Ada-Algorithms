--  Standalone test suite for Burstsort (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  A'First is always 1; Max_N = 32. Sortedness is proved by SPARK;
--  multiset / permutation equality is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Burstsort; use Burstsort;

procedure Tests
  with SPARK_Mode => Off
is

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
   function Nat (X : Natural) return Natural is (X);
   function Boo (X : Boolean) return Boolean is (X);
   function Str (X : String) return String is (X);

   procedure Reference_Sort (A : in out String_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Bounded_String := A (I);
            J   : Integer := Integer (I) - 1;
         begin
            while J >= Integer (A'First) and then Key < A (J) loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
   end Reference_Sort;

   function Same (A, B : String_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         declare
            J : constant Positive := B'First + (I - A'First);
         begin
            if A (I).Length /= B (J).Length then
               return False;
            end if;
            if A (I).Length > 0
              and then A (I).Data (1 .. A (I).Length)
                /= B (J).Data (1 .. B (J).Length)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Same;

   function Is_Permutation (A, B : String_Array) return Boolean is
      SA : String_Array := A;
      SB : String_Array := B;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      Reference_Sort (SA);
      Reference_Sort (SB);
      return Same (SA, SB);
   end Is_Permutation;

   function Copy_Of (A : String_Array) return String_Array is
   begin
      return String_Array'(A);
   end Copy_Of;

   procedure Expect_Sorted (Src : String_Array; Label : String) is
      A : String_Array := Copy_Of (Src);
      R : String_Array := Copy_Of (Src);
      O : constant String_Array := Copy_Of (Src);
   begin
      Sort (A);
      Reference_Sort (R);
      Check (Boo (Is_Sorted (A)), Label & " Is_Sorted");
      Check (Same (A, R), Label & " matches reference");
      Check (Is_Permutation (A, O), Label & " permutation");
   end Expect_Sorted;

   Seed : Natural := 42;

   function Next_Mod (Modulus : Positive) return Natural is
      Mult : constant := 1_103_515_245;
      Add  : constant := 12_345;
      X    : Natural;
   begin
      X := Natural ((Long_Long_Integer (Seed) * Mult + Add)
                    mod 2_147_483_647);
      Seed := X;
      return X rem Modulus;
   end Next_Mod;

   function Random_String (Max_Len : Natural) return Bounded_String is
      Len : constant Natural :=
        (if Max_Len = 0 then 0 else Next_Mod (Max_Len + 1));
      S   : String (1 .. Len);
   begin
      for I in S'Range loop
         S (I) := Character'Val (Character'Pos ('a') + Next_Mod (26));
      end loop;
      return Make (S);
   end Random_String;

   function Random_Array
     (Len : Natural; Max_Len : Natural) return String_Array
   is
      A : String_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Random_String (Max_Len);
      end loop;
      return A;
   end Random_Array;

   function A1 (X : String) return String_Array is
   begin
      return String_Array'(1 => Make (X));
   end A1;

   function A2 (X, Y : String) return String_Array is
   begin
      return String_Array'(Make (X), Make (Y));
   end A2;

   function A3 (X, Y, Z : String) return String_Array is
   begin
      return String_Array'(Make (X), Make (Y), Make (Z));
   end A3;

   function A4 (A, B, C, D : String) return String_Array is
   begin
      return String_Array'(Make (A), Make (B), Make (C), Make (D));
   end A4;

   function A5 (A, B, C, D, E : String) return String_Array is
   begin
      return String_Array'
        (Make (A), Make (B), Make (C), Make (D), Make (E));
   end A5;

begin
   Put_Line ("Burstsort (SPARK) tests");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Empty / singleton / trivial");
   ---------------------------------------------------------------------
   declare
      Empty : String_Array (1 .. 0);
      One   : String_Array := A1 ("only");
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Sort (Empty);
      Check (Boo (Is_Sorted (Empty)), "empty Sort no-op");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted before");
      Sort (One);
      Check (Boo (Is_Sorted (One)), "singleton Sort no-op");
      Check (Str (To_String (One (1))) = "only", "singleton value preserved");
   end;

   ---------------------------------------------------------------------
   Section ("2. Already sorted / reverse / duplicates");
   ---------------------------------------------------------------------
   Expect_Sorted (A3 ("a", "b", "c"), "already sorted abc");
   Expect_Sorted (A3 ("c", "b", "a"), "reverse cba");
   Expect_Sorted (A5 ("x", "x", "x", "x", "x"), "all duplicates");
   Expect_Sorted (A4 ("aa", "aa", "ab", "b"), "mixed duplicates");
   Expect_Sorted (A2 ("", ""), "two empty strings");
   Expect_Sorted (A3 ("", "a", "a"), "empty among letters");

   ---------------------------------------------------------------------
   Section ("3. Prefix relationships");
   ---------------------------------------------------------------------
   Expect_Sorted (A4 ("a", "ab", "abc", "abcd"), "nested prefixes asc");
   Expect_Sorted (A4 ("abcd", "abc", "ab", "a"), "nested prefixes desc");
   Expect_Sorted
     (A5 ("she", "sells", "sea", "shells", "shore"), "classic shells");
   Expect_Sorted
     (A5 ("test", "testing", "tester", "tested", "tea"), "test* family");

   ---------------------------------------------------------------------
   Section ("4. Make / To_String / ordering helpers");
   ---------------------------------------------------------------------
   Check (Str (To_String (Make ("hi"))) = "hi", "Make/To_String round-trip");
   Check (Nat (Make ("").Length) = 0, "Make empty length 0");
   Check (Boo (Make ("a") < Make ("b")), "a < b");
   Check (Boo (Make ("ab") < Make ("abc")), "ab < abc (shorter)");
   Check (Boo (Make ("abc") <= Make ("abc")), "abc <= abc");
   Check (Boo (not (Make ("z") < Make ("a"))), "not z < a");
   Check (Boo (Make ("z") > Make ("a")), "z > a");

   ---------------------------------------------------------------------
   Section ("5. Burst threshold stress (force bursts)");
   ---------------------------------------------------------------------
   declare
      N   : constant := 20;
      Src : String_Array (1 .. N);
   begin
      for I in Src'Range loop
         declare
            Suffix : constant String :=
              Character'Val (Character'Pos ('a') + (I - 1) mod 26)
              & Character'Val (Character'Pos ('a') + (I / 26) mod 26);
         begin
            Src (I) := Make ("pre_" & Suffix);
         end;
      end loop;
      Expect_Sorted (Src, "shared prefix n=20");
   end;

   declare
      N   : constant := 16;
      Src : String_Array (1 .. N);
   begin
      for I in Src'Range loop
         Src (I) := Make ("aaaaaaaa");
      end loop;
      Expect_Sorted (Src, "identical long strings n=16");
   end;

   ---------------------------------------------------------------------
   Section ("6. Random strings vs reference");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (2, 8), "random n=2");
   Expect_Sorted (Random_Array (5, 12), "random n=5");
   Expect_Sorted (Random_Array (8, 10), "random n=8");
   Expect_Sorted (Random_Array (16, 8), "random n=16");
   Expect_Sorted (Random_Array (32, 6), "random n=32 Max_N");

   ---------------------------------------------------------------------
   Section ("7. In_Bounds at Max_N / empty");
   ---------------------------------------------------------------------
   declare
      Full : String_Array (1 .. Max_N);
      Emp  : String_Array (1 .. 0);
   begin
      for I in Full'Range loop
         Full (I) := Make ("x");
      end loop;
      Check (In_Bounds (Full), "Max_N In_Bounds");
      Check (In_Bounds (Emp), "empty In_Bounds again");
      Expect_Sorted (Full, "all-x Max_N");
   end;

   ---------------------------------------------------------------------
   Section ("8. Is_Sorted negative / positive");
   ---------------------------------------------------------------------
   declare
      Bad  : String_Array := A3 ("c", "a", "b");
      Good : constant String_Array := A3 ("a", "b", "c");
   begin
      Check (Boo (not Is_Sorted (Bad)), "unsorted detected");
      Check (Boo (Is_Sorted (Good)), "sorted detected");
      Sort (Bad);
      Check (Boo (Is_Sorted (Bad)), "unsorted becomes sorted");
      Check (Same (Bad, Good), "c,a,b -> a,b,c");
   end;

   ---------------------------------------------------------------------
   Section ("9. Digits / mixed printable");
   ---------------------------------------------------------------------
   Expect_Sorted
     (A5 ("10", "2", "1", "20", "12"), "numeric strings lex");
   Expect_Sorted
     (A4 ("Zebra", "apple", "Banana", "apple"), "case-sensitive ASCII");
   Expect_Sorted (A1 (""), "single empty");
   Expect_Sorted (A2 ("z", ""), "empty and z");

   ---------------------------------------------------------------------
   Section ("10. More random / edges");
   ---------------------------------------------------------------------
   Expect_Sorted (Random_Array (3, 1), "random n=3 len≤1");
   Expect_Sorted (Random_Array (7, 4), "random n=7");
   Expect_Sorted (Random_Array (11, 6), "random n=11");
   Expect_Sorted (Random_Array (25, 3), "random n=25 short");
   Expect_Sorted (A4 ("same", "same", "diff", "same"), "triple same");
   Expect_Sorted (A5 ("", "", "a", "", "b"), "many empties");

   --  Force many bursts: > Burst_Threshold strings with shared prefix.
   declare
      Src : String_Array (1 .. 12);
   begin
      for I in Src'Range loop
         Src (I) := Make
           ("burst" & Character'Val (Character'Pos ('a') + I - 1));
      end loop;
      Expect_Sorted (Src, "burst family n=12");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

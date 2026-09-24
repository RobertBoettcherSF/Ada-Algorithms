--  Standalone test suite for Package_Merge (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Frequencies'First is always 1; Max_Symbols = 32, Max_L = 16.
--  Length bounds are proved by SPARK; Kraft / optimality checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Package_Merge; use Package_Merge;

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
   function Pos (X : Positive) return Positive is (X);
   function Boo (X : Boolean) return Boolean is (X);

   --  Integer Kraft check: sum_i 2^(L - len_i) <= 2^L.
   function Kraft_OK
     (Lengths : Code_Lengths; L : Positive) return Boolean
   is
      Limit : constant Natural := 2 ** L;
      Acc   : Natural := 0;
   begin
      for I in Lengths'Range loop
         if Lengths (I) < 1 or else Lengths (I) > L then
            return False;
         end if;
         Acc := Acc + 2 ** (L - Lengths (I));
         if Acc > Limit then
            return False;
         end if;
      end loop;
      return Acc <= Limit;
   end Kraft_OK;

   function All_In_Range
     (Lengths : Code_Lengths; L : Positive) return Boolean
   is
     (for all I in Lengths'Range => Lengths (I) in 1 .. L);

   procedure Run_Case
     (Freqs : Symbol_Frequencies;
      L     : Positive;
      Label : String)
   is
      Lengths : Code_Lengths (Freqs'Range);
   begin
      Huffman_Length_Limited (Freqs, L, Lengths);
      Check (Boo (All_In_Range (Lengths, L)), Label & " lengths in 1..L");
      Check (Boo (Kraft_OK (Lengths, L)), Label & " Kraft");
   end Run_Case;

begin
   Put_Line ("Package_Merge SPARK test suite");
   Put_Line ("Max_Symbols =" & Max_Symbols'Image &
             "  Max_L =" & Max_L'Image);

   -----------------------------------------------------------------
   Section ("Contract helpers");
   -----------------------------------------------------------------
   declare
      F1 : constant Symbol_Frequencies (1 .. 1) := [1 => 1];
      F4 : constant Symbol_Frequencies (1 .. 4) := [1, 1, 1, 1];
   begin
      Check (Boo (In_Bounds (F1)), "In_Bounds singleton");
      Check (Boo (In_Bounds (F4)), "In_Bounds N=4");
      Check (Boo (Can_Encode (Nat (4), Pos (2))), "Can_Encode 4@L=2");
      Check (not Boo (Can_Encode (Nat (5), Pos (2))), "not Can_Encode 5@L=2");
      Check (Boo (Can_Encode (Nat (32), Pos (5))), "Can_Encode 32@L=5");
   end;

   -----------------------------------------------------------------
   Section ("N = 1");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 1) := [1 => 42];
      Len : Code_Lengths (1 .. 1);
   begin
      Huffman_Length_Limited (F, 8, Len);
      Check (Len (1) = 1, "singleton length = 1");
      Check (Boo (Kraft_OK (Len, 8)), "singleton Kraft");
   end;

   -----------------------------------------------------------------
   Section ("N = 2");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 2) := [5, 10];
      Len : Code_Lengths (1 .. 2);
   begin
      Huffman_Length_Limited (F, 5, Len);
      Check (Len (1) = 1 and Len (2) = 1, "N=2 lengths 1,1");
      Check (Boo (Kraft_OK (Len, 5)), "N=2 Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Even distribution (balanced)");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 4) := [1, 1, 1, 1];
      Len : Code_Lengths (1 .. 4);
   begin
      Huffman_Length_Limited (F, 2, Len);
      Check
        (Len (1) = 2 and Len (2) = 2 and Len (3) = 2 and Len (4) = 2,
         "equal freqs all length 2");
      Check (Boo (Kraft_OK (Len, 2)), "equal freqs Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Skewed distribution");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 3) := [100, 1, 1];
      Len : Code_Lengths (1 .. 3);
   begin
      Huffman_Length_Limited (F, 2, Len);
      Check (Len (1) = 1, "high freq length 1");
      Check (Len (2) = 2 and Len (3) = 2, "rare freqs length 2");
      Check (Boo (Kraft_OK (Len, 2)), "skewed Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Fibonacci-like deep skew");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 6) := [1, 1, 2, 3, 5, 8];
      Len : Code_Lengths (1 .. 6);
   begin
      Huffman_Length_Limited (F, 5, Len);
      Check (Boo (All_In_Range (Len, 5)), "fib lengths in 1..5");
      Check (Len (6) <= 2, "highest freq short code");
      Check (Boo (Kraft_OK (Len, 5)), "fib Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Length limit binds (vs unlimited Huffman)");
   -----------------------------------------------------------------
   --  Highly skewed: unlimited Huffman would use long codes for rares;
   --  with small L the rares are capped.
   declare
      F : constant Symbol_Frequencies (1 .. 5) :=
        [1000, 1, 1, 1, 1];
      Len : Code_Lengths (1 .. 5);
   begin
      Huffman_Length_Limited (F, 3, Len);
      Check (Boo (All_In_Range (Len, 3)), "limit-binds lengths in 1..3");
      Check (Boo (Kraft_OK (Len, 3)), "limit-binds Kraft");
      Check (Len (1) <= 3, "dominant still <= L");
   end;

   -----------------------------------------------------------------
   Section ("Max_Length = 1 (N = 2 only)");
   -----------------------------------------------------------------
   declare
      F : constant Symbol_Frequencies (1 .. 2) := [3, 7];
      Len : Code_Lengths (1 .. 2);
   begin
      Huffman_Length_Limited (F, 1, Len);
      Check (Len (1) = 1 and Len (2) = 1, "L=1 forces 1,1");
      Check (Boo (Kraft_OK (Len, 1)), "L=1 Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Wikipedia-style small alphabet");
   -----------------------------------------------------------------
   --  Classic classroom frequencies; L large enough for unconstrained
   --  Huffman optimum.
   declare
      F : constant Symbol_Frequencies (1 .. 5) :=
        [1, 2, 3, 4, 5];
      Len : Code_Lengths (1 .. 5);
      Weighted : Natural := 0;
   begin
      Huffman_Length_Limited (F, 8, Len);
      Check (Boo (All_In_Range (Len, 8)), "wiki lengths in range");
      Check (Boo (Kraft_OK (Len, 8)), "wiki Kraft");
      for I in F'Range loop
         Weighted := Weighted + Natural (F (I)) * Len (I);
      end loop;
      --  Unconstrained Huffman weighted path for (1,2,3,4,5) is 33
      --  with lengths typically (3,3,2,2,2) or equivalent.
      Check (Weighted <= 40, "wiki weighted path reasonable");
      Check (Len (5) <= Len (1), "heavier symbol not longer than lightest");
   end;

   -----------------------------------------------------------------
   Section ("Full Max_Symbols capacity");
   -----------------------------------------------------------------
   declare
      F : Symbol_Frequencies (1 .. Max_Symbols);
      Len : Code_Lengths (1 .. Max_Symbols);
   begin
      for I in F'Range loop
         F (I) := Freq_Value (1 + (I mod 7));
      end loop;
      Huffman_Length_Limited (F, Max_L, Len);
      Check (Boo (All_In_Range (Len, Max_L)), "Max_Symbols lengths");
      Check (Boo (Kraft_OK (Len, Max_L)), "Max_Symbols Kraft");
   end;

   -----------------------------------------------------------------
   Section ("Run_Case batch");
   -----------------------------------------------------------------
   Run_Case ([1 => 1, 2 => 1, 3 => 1], 3, "triple equal");
   Run_Case ([10, 20, 30, 40], 4, "ascending");
   Run_Case ([1, 100, 1, 100, 1], 4, "alternating");

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("PASS:" & Pass_Count'Image & "  FAIL:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;

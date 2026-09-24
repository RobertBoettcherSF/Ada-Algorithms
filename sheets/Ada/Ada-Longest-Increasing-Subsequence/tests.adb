--  Standalone test suite for Longest_Increasing_Subsequence (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Longest_Increasing_Subsequence; use Longest_Increasing_Subsequence;

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

   --  Non-static wrapper avoids treating literals as unused.
   function A (X : Int_Array) return Int_Array is (X);

   function Empty_Seq return Int_Array is
      E : constant Int_Array (1 .. 0) := [1 .. 0 => 0];
   begin
      return E;
   end Empty_Seq;

   function Is_Strictly_Increasing (S : Int_Array) return Boolean is
   begin
      if S'Length <= 1 then
         return True;
      end if;
      for I in S'First .. S'Last - 1 loop
         if S (I) >= S (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Increasing;

   --  True iff Sub appears as a (not necessarily contiguous) subsequence
   --  of Src, preserving order.
   function Is_Subsequence (Sub, Src : Int_Array) return Boolean is
      J : Integer := Src'First;
   begin
      if Sub'Length = 0 then
         return True;
      end if;
      if Src'Length = 0 then
         return False;
      end if;
      for I in Sub'Range loop
         declare
            Found : Boolean := False;
         begin
            while J <= Src'Last loop
               if Src (J) = Sub (I) then
                  Found := True;
                  J := J + 1;
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

   function Length_Raises (X : Int_Array) return Boolean is
   begin
      declare
         Unused : constant Positive := Length (X);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Length_Raises;

   function Length_DP_Raises (X : Int_Array) return Boolean is
   begin
      declare
         Unused : constant Positive := Length_DP (X);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Length_DP_Raises;

   function Find_Raises (X : Int_Array) return Boolean is
   begin
      declare
         Unused : constant Int_Array := Find (X);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   procedure Expect_Length
     (X        : Int_Array;
      Expected : Positive;
      Label    : String)
   is
      Ln : constant Positive := Length (A (X));
   begin
      Check (Ln = Expected, Label & " Length");
      if X'Length <= Max_Length_DP then
         Check (Length_DP (A (X)) = Expected, Label & " Length_DP");
         Check (Length_DP (A (X)) = Ln, Label & " DP ≡ n log n");
      end if;
   end Expect_Length;

   procedure Expect_Find
     (X        : Int_Array;
      Expected : Positive;
      Label    : String)
   is
      Got : constant Int_Array := Find (A (X));
   begin
      Check (Got'Length = Expected, Label & " Find length");
      Check (Is_Strictly_Increasing (Got), Label & " Find increasing");
      Check (Is_Subsequence (Got, X), Label & " Find subsequence");
      Check (Got'Length = Length (A (X)), Label & " Find ≡ Length");
   end Expect_Find;

   procedure Expect_Case
     (X        : Int_Array;
      Expected : Positive;
      Label    : String)
   is
   begin
      Expect_Length (X, Expected, Label);
      Expect_Find (X, Expected, Label);
   end Expect_Case;

   procedure Expect_Unique
     (X, Witness : Int_Array;
      Label      : String)
   is
      Got : constant Int_Array := Find (A (X));
   begin
      Check (Got = Witness, Label & " unique Find");
   end Expect_Unique;

begin
   Ada.Text_IO.Put_Line ("Longest_Increasing_Subsequence tests");
   Ada.Text_IO.Put_Line ("====================================");

   ------------------------------------------------------------------
   Section ("1. Wikipedia Van der Corput example");
   ------------------------------------------------------------------
   --  First 16 terms of the binary Van der Corput sequence; LIS length 6.
   --  Witnesses include 0,2,6,9,11,15 and 0,4,6,9,13,15.
   declare
      V : constant Int_Array :=
        [0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15];
   begin
      Expect_Case (V, 6, "van der Corput");
   end;

   ------------------------------------------------------------------
   Section ("2. Decreasing → length 1");
   ------------------------------------------------------------------
   Expect_Case ([5, 4, 3, 2, 1], 1, "5..1");
   Expect_Case ([9, 8, 7], 1, "9,8,7");
   Expect_Case ([2, 1], 1, "2,1");
   Expect_Case ([0, -1, -2, -3], 1, "0..-3");
   Expect_Case ([100, 50, 25, 12, 6, 3, 1], 1, "halving");

   ------------------------------------------------------------------
   Section ("3. Already sorted → length n");
   ------------------------------------------------------------------
   Expect_Case ([1], 1, "singleton");
   Expect_Case ([1, 2], 2, "1,2");
   Expect_Case ([1, 2, 3, 4, 5], 5, "1..5");
   Expect_Case ([-4, -1, 0, 2, 9], 5, "sorted mixed");
   Expect_Case ([10, 20, 30, 40], 4, "10,20,30,40");

   ------------------------------------------------------------------
   Section ("4. All equal → length 1 (strict)");
   ------------------------------------------------------------------
   Expect_Case ([7, 7, 7, 7], 1, "four 7s");
   Expect_Case ([0, 0], 1, "two 0s");
   Expect_Case ([-3, -3, -3], 1, "three -3s");

   ------------------------------------------------------------------
   Section ("5. Known examples");
   ------------------------------------------------------------------
   Expect_Case ([10, 9, 2, 5, 3, 7, 101, 18], 4, "leetcode 300");
   Expect_Case ([0, 1, 0, 3, 2, 3], 4, "0,1,0,3,2,3");
   Expect_Case ([3, 10, 2, 1, 20], 3, "3,10,2,1,20");
   Expect_Case ([50, 3, 10, 7, 40, 80], 4, "50,3,10,7,40,80");
   Expect_Case ([10, 22, 9, 33, 21, 50, 41, 60, 80], 6, "geeks 6");
   Expect_Case ([4, 10, 4, 3, 8, 9], 3, "4,10,4,3,8,9");
   Expect_Case ([1, 3, 2, 4], 3, "1,3,2,4");
   Expect_Case ([1, 3, 2], 2, "1,3,2");
   Expect_Case ([3, 1, 2], 2, "3,1,2");
   Expect_Case ([1, 2, 0], 2, "1,2,0");
   Expect_Unique ([3, 1, 2], [1, 2], "3,1,2");
   Expect_Unique ([1, 2, 0], [1, 2], "1,2,0");
   Expect_Unique ([1, 2, 3, 4], [1, 2, 3, 4], "sorted unique");
   Expect_Unique ([1], [1], "singleton unique");

   ------------------------------------------------------------------
   Section ("6. Zigzag / mixed");
   ------------------------------------------------------------------
   Expect_Case ([1, 3, 2, 5, 4, 7, 6], 4, "zigzag");
   Expect_Case ([2, 6, 3, 4, 1, 2, 9, 5, 8], 5, "mixed 5");
   Expect_Case ([9, 1, 8, 2, 7, 3, 6, 4, 5], 5, "interleave");
   Expect_Case ([5, 1, 4, 2, 3], 3, "5,1,4,2,3");

   ------------------------------------------------------------------
   Section ("7. Negatives and extremes");
   ------------------------------------------------------------------
   Expect_Case ([-5, -1, -4, 0, 3, 2], 4, "negatives");
   Expect_Case ([Integer'Last, Integer'First, 0], 2, "int extremes");
   Expect_Case ([Integer'First, Integer'First + 1, Integer'Last], 3,
                "int span");
   Expect_Case ([-10, -20, -5, -1], 3, "all negative");

   ------------------------------------------------------------------
   Section ("8. Empty / oversize → Invalid_Argument");
   ------------------------------------------------------------------
   Check (Length_Raises (Empty_Seq), "Length empty");
   Check (Length_DP_Raises (Empty_Seq), "Length_DP empty");
   Check (Find_Raises (Empty_Seq), "Find empty");

   declare
      Big : constant Int_Array (1 .. Max_Length + 1) := [others => 1];
   begin
      Check (Length_Raises (Big), "Length oversize");
      Check (Find_Raises (Big), "Find oversize");
   end;

   declare
      Big_DP : constant Int_Array (1 .. Max_Length_DP + 1) := [others => 2];
   begin
      Check (Length_DP_Raises (Big_DP), "Length_DP oversize");
      Check (Length (Big_DP) = 1, "Length still ok above DP max");
      Check (Find (Big_DP)'Length = 1, "Find still ok above DP max");
   end;

   declare
      At_DP : constant Int_Array (1 .. Max_Length_DP) := [others => 0];
   begin
      Check (Length_DP (At_DP) = 1, "Length_DP at Max_Length_DP");
      Check (Length (At_DP) = 1, "Length at Max_Length_DP");
   end;

   ------------------------------------------------------------------
   Section ("9. Non-1-based slices");
   ------------------------------------------------------------------
   declare
      Buf   : constant Int_Array (5 .. 10) := [3, 1, 4, 1, 5, 9];
      Slice : Int_Array renames Buf (6 .. 9);  -- 1,4,1,5
   begin
      Expect_Case (Buf, 4, "slice 5..10");
      Expect_Case (Slice, 3, "slice 6..9");
   end;

   ------------------------------------------------------------------
   Section ("10. DP ≡ n log n on extra sequences");
   ------------------------------------------------------------------
   declare
      procedure Agree (X : Int_Array; Label : String) is
      begin
         Check (Length (A (X)) = Length_DP (A (X)), Label);
         Check (Find (A (X))'Length = Length (A (X)), Label & " Find len");
      end Agree;
   begin
      Agree ([8, 3, 4, 6, 5, 2, 9, 7], "extra a");
      Agree ([1, 5, 2, 6, 3, 7, 4, 8], "extra b");
      Agree ([20, 1, 19, 2, 18, 3], "extra c");
      Agree ([4], "extra singleton");
      Agree ([4, 5], "extra pair inc");
      Agree ([5, 4], "extra pair dec");
      Agree ([1, 1, 2, 2, 3, 3], "pairs equals");
      Agree ([-1, 2, -1, 2, -1, 2], "alt -1/2");
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

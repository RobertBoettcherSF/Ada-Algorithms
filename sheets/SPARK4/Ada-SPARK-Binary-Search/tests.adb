--  Standalone test suite for Binary_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Sentinel is always 0 (indices are 1 .. N).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Binary_Search; use Binary_Search;

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
   function Idx (X : Index) return Index is (X);
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);

   function Linear_Find (A : Element_Array; Key : Integer) return Index is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return I;
         end if;
      end loop;
      return 0;
   end Linear_Find;

   function Linear_First (A : Element_Array; Key : Integer) return Index is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return I;
         end if;
      end loop;
      return 0;
   end Linear_First;

   function Linear_Last (A : Element_Array; Key : Integer) return Index is
   begin
      for I in reverse A'Range loop
         if A (I) = Key then
            return I;
         end if;
      end loop;
      return 0;
   end Linear_Last;

   procedure Expect_Hit
     (A : Element_Array; Key : Integer; Label : String)
   is
      Got : constant Index := Find (A, Key);
   begin
      Check (Got >= 1 and then Got <= A'Last, Label & " in range");
      if Got >= 1 and then Got <= A'Last then
         Check (A (Got) = Key, Label & " value matches");
      else
         Check (False, Label & " value matches");
      end if;
   end Expect_Hit;

   procedure Expect_Miss
     (A : Element_Array; Key : Integer; Label : String)
   is
   begin
      Check (Idx (Find (A, Key)) = 0, Label & " Find sentinel");
      Check (Idx (Find_First (A, Key)) = 0, Label & " Find_First sentinel");
      Check (Idx (Find_Last (A, Key)) = 0, Label & " Find_Last sentinel");
   end Expect_Miss;

   procedure Expect_First_Last
     (A : Element_Array; Key : Integer;
      First_Idx, Last_Idx : Index; Label : String)
   is
   begin
      Check (Idx (Find_First (A, Key)) = First_Idx, Label & " Find_First");
      Check (Idx (Find_Last (A, Key)) = Last_Idx, Label & " Find_Last");
      Check (Find (A, Key) >= First_Idx
             and then Find (A, Key) <= Last_Idx,
             Label & " Find in [first,last]");
   end Expect_First_Last;

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

begin
   Put_Line ("Binary_Search (SPARK) tests");
   Put_Line ("===========================");

   Section ("1. Empty and singleton");
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Idx (Find (Empty, 0)) = 0, "empty Find sentinel");
      Check (Idx (Find_First (Empty, 0)) = 0, "empty Find_First sentinel");
      Check (Idx (Find_Last (Empty, 0)) = 0, "empty Find_Last sentinel");

      Check (Is_Sorted (One), "singleton Is_Sorted");
      Check (Idx (Find (One, 42)) = 1, "singleton hit");
      Check (Idx (Find_First (One, 42)) = 1, "singleton Find_First hit");
      Check (Idx (Find_Last (One, 42)) = 1, "singleton Find_Last hit");
      Expect_Miss (One, 41, "singleton miss low");
      Expect_Miss (One, 43, "singleton miss high");
   end;

   Section ("2. Small sorted hits and misses");
   declare
      A : constant Element_Array (1 .. 7) := [1, 3, 5, 7, 9, 11, 13];
   begin
      Check (Is_Sorted (A), "small Is_Sorted");
      for K of Element_Array'[1, 3, 5, 7, 9, 11, 13] loop
         Expect_Hit (A, K, "hit key=" & Integer'Image (K));
         Check (Find_First (A, K) = Find_Last (A, K),
                "unique first=last key=" & Integer'Image (K));
      end loop;
      Expect_Miss (A, 0, "miss below");
      Expect_Miss (A, 2, "miss between 1 and 3");
      Expect_Miss (A, 8, "miss between 7 and 9");
      Expect_Miss (A, 14, "miss above");
   end;

   Section ("3. Duplicates -- Find_First / Find_Last");
   declare
      W : constant Element_Array (1 .. 8) := [1, 2, 3, 4, 4, 5, 6, 7];
      D : constant Element_Array (1 .. 8) := [1, 2, 4, 4, 4, 5, 6, 7];
      All4 : constant Element_Array (1 .. 5) := [4, 4, 4, 4, 4];
      Ends : constant Element_Array (1 .. 6) := [9, 9, 10, 11, 11, 11];
   begin
      Expect_First_Last (W, 4, 4, 5, "wiki two 4s");
      Expect_First_Last (D, 4, 3, 5, "wiki three 4s");
      Expect_First_Last (All4, 4, 1, 5, "all equal");
      Expect_First_Last (Ends, 9, 1, 2, "dup at start");
      Expect_First_Last (Ends, 11, 4, 6, "dup at end");
      Expect_Miss (All4, 3, "all-equal miss low");
      Expect_Miss (All4, 5, "all-equal miss high");
   end;

   Section ("4. Negatives, zero, mixed domain");
   declare
      A : constant Element_Array (1 .. 7) := [-100, -50, -1, 0, 1, 50, 100];
   begin
      for K of Element_Array'[-100, -50, -1, 0, 1, 50, 100] loop
         Expect_Hit (A, K, "signed hit" & Integer'Image (K));
      end loop;
      Expect_Miss (A, -99, "signed miss");
      Expect_Miss (A, 2, "signed miss 2");
   end;

   Section ("5. Power-of-two and odd lengths");
   declare
      P2  : Element_Array (1 .. 8);
      Odd : Element_Array (1 .. 9);
   begin
      for I in P2'Range loop
         P2 (I) := I * 10;
      end loop;
      for I in Odd'Range loop
         Odd (I) := I * 10;
      end loop;
      Check (Idx (Find (P2, 10)) = 1, "p2 first");
      Check (Idx (Find (P2, 80)) = 8, "p2 last");
      Check (Idx (Find (P2, 40)) = 4, "p2 mid");
      Expect_Miss (P2, 45, "p2 miss");
      Check (Idx (Find (Odd, 50)) = 5, "odd mid");
      Check (Idx (Find (Odd, 90)) = 9, "odd last");
      Expect_Miss (Odd, 0, "odd miss");
   end;

   Section ("6. Max_N vs linear reference");
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
      Keys : constant Element_Array :=
        [1, 2, N / 2, N - 1, N, -1, N + 1, 42, 17, 33];
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Check (In_Bounds (A), "Max_N In_Bounds");
      Check (Is_Sorted (A), "Max_N Is_Sorted");

      for K of Keys loop
         declare
            Got : constant Index := Find (A, K);
            Ref : constant Index := Linear_Find (A, K);
         begin
            Check (Got = Ref,
                   "Max_N Find matches linear key=" & Integer'Image (K));
            Check (Find_First (A, K) = Linear_First (A, K),
                   "Max_N First matches linear key=" & Integer'Image (K));
            Check (Find_Last (A, K) = Linear_Last (A, K),
                   "Max_N Last matches linear key=" & Integer'Image (K));
         end;
      end loop;
   end;

   Section ("7. Duplicates at Max_N scale vs linear");
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := ((I - 1) / 4) + 1;
      end loop;

      for V in 1 .. 5 loop
         Check (Find_First (A, V) = Linear_First (A, V),
                "dup First V=" & Integer'Image (V));
         Check (Find_Last (A, V) = Linear_Last (A, V),
                "dup Last V=" & Integer'Image (V));
         declare
            Got : constant Index := Find (A, V);
         begin
            Check (Got >= Find_First (A, V)
                   and then Got <= Find_Last (A, V),
                   "dup Find in plateau V=" & Integer'Image (V));
         end;
      end loop;
      Expect_Miss (A, 0, "dup miss 0");
      Expect_Miss (A, 10_000, "dup miss high");
   end;

   Section ("8. Random queries on sorted random array");
   declare
      N : constant := Max_N;
      A : Element_Array (1 .. N);
   begin
      Seed := 99;
      for I in A'Range loop
         A (I) := Integer (Next_Mod (1_000));
      end loop;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (I);
            J   : Integer := I - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
      Check (Is_Sorted (A), "random Is_Sorted");

      for Trial in 1 .. 15 loop
         declare
            K   : constant Integer := Integer (Next_Mod (1_000));
            Got : constant Index := Find (A, K);
            Ref : constant Index := Linear_Find (A, K);
         begin
            if Ref = 0 then
               Check (Idx (Got) = 0,
                      "rand miss trial" & Integer'Image (Trial));
            else
               Check (Idx (Got) >= 1
                      and then Idx (Got) <= Index (A'Last)
                      and then A (Got) = K,
                      "rand hit trial" & Integer'Image (Trial));
               Check (Find_First (A, K) = Linear_First (A, K),
                      "rand First trial" & Integer'Image (Trial));
               Check (Find_Last (A, K) = Linear_Last (A, K),
                      "rand Last trial" & Integer'Image (Trial));
            end if;
         end;
      end loop;
   end;

   Section ("9. Two-element and boundary keys");
   declare
      T : constant Element_Array (1 .. 2) := [5, 10];
   begin
      Check (Idx (Find (T, 5)) = 1, "two-el first");
      Check (Idx (Find (T, 10)) = 2, "two-el second");
      Expect_Miss (T, 7, "two-el between");
      Expect_Miss (T, 4, "two-el below");
      Expect_Miss (T, 11, "two-el above");
   end;

   Section ("10. Is_Sorted / In_Bounds helpers");
   declare
      Good : constant Element_Array (1 .. 4) := [1, 2, 2, 9];
      Bad  : constant Element_Array (1 .. 4) := [1, 3, 2, 4];
      Cap  : Element_Array (1 .. Max_N);
   begin
      Check (Is_Sorted (Good), "Good Is_Sorted");
      Check (not Is_Sorted (Bad), "Bad not Is_Sorted");
      Check (In_Bounds (Good), "Good In_Bounds");
      for I in Cap'Range loop
         Cap (I) := I;
      end loop;
      Check (In_Bounds (Cap), "Cap In_Bounds at Max_N");
      Check (Nat (Max_N) = 64, "Max_N = 64");
      Check (Int (Find (Good, 2)) in 2 .. 3, "Good Find plateau");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

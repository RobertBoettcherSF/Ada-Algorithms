--  Standalone test suite for Binary_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Binary_Search; use Binary_Search;

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

   function Linear_Find (A : Element_Array; Key : Integer) return Integer is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;
      return Integer (A'First) - 1;
   end Linear_Find;

   function Linear_First (A : Element_Array; Key : Integer) return Integer is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;
      return Integer (A'First) - 1;
   end Linear_First;

   function Linear_Last (A : Element_Array; Key : Integer) return Integer is
   begin
      for I in reverse A'Range loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;
      return Integer (A'First) - 1;
   end Linear_Last;

   function Find_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Find (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   function First_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Find_First (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end First_Raises;

   function Last_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Find_Last (A, Key);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Last_Raises;

   procedure Expect_Hit
     (A : Element_Array; Key : Integer; Label : String)
   is
      Got : constant Integer := Find (A, Key);
   begin
      Check (Got >= Integer (A'First) and then Got <= Integer (A'Last),
             Label & " in range");
      if Got >= Integer (A'First) and then Got <= Integer (A'Last) then
         Check (A (Natural (Got)) = Key, Label & " value matches");
      else
         Check (False, Label & " value matches");
      end if;
   end Expect_Hit;

   procedure Expect_Miss
     (A : Element_Array; Key : Integer; Label : String)
   is
      Sent : constant Integer := Integer (A'First) - 1;
   begin
      Check (Find (A, Key) = Sent, Label & " Find sentinel");
      Check (Find_First (A, Key) = Sent, Label & " Find_First sentinel");
      Check (Find_Last (A, Key) = Sent, Label & " Find_Last sentinel");
   end Expect_Miss;

   procedure Expect_First_Last
     (A : Element_Array; Key : Integer;
      First_Idx, Last_Idx : Integer; Label : String)
   is
   begin
      Check (Find_First (A, Key) = First_Idx, Label & " Find_First");
      Check (Find_Last (A, Key) = Last_Idx, Label & " Find_Last");
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
   Section ("1. Empty and singleton");
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
      Z     : constant Element_Array (0 .. 0) := [0 => 7];
   begin
      Check (Find (Empty, 0) = 0, "empty Find sentinel (First-1=0)");
      Check (Find_First (Empty, 0) = 0, "empty Find_First sentinel");
      Check (Find_Last (Empty, 0) = 0, "empty Find_Last sentinel");

      Check (Find (One, 42) = 1, "singleton hit");
      Check (Find_First (One, 42) = 1, "singleton Find_First hit");
      Check (Find_Last (One, 42) = 1, "singleton Find_Last hit");
      Expect_Miss (One, 41, "singleton miss low");
      Expect_Miss (One, 43, "singleton miss high");

      Check (Find (Z, 7) = 0, "0-based singleton hit");
      Check (Find (Z, 8) = -1, "0-based singleton miss sentinel -1");
   end;

   Section ("2. Small sorted hits and misses");
   declare
      A : constant Element_Array (1 .. 7) := [1, 3, 5, 7, 9, 11, 13];
   begin
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

   Section ("5. Non-1 A'First bounds");
   declare
      A : constant Element_Array (10 .. 14) := [10, 20, 30, 40, 50];
      B : constant Element_Array (0 .. 3) := [2, 4, 6, 8];
   begin
      Check (Find (A, 30) = 12, "First=10 hit mid");
      Check (Find_First (A, 30) = 12, "First=10 Find_First");
      Check (Find_Last (A, 30) = 12, "First=10 Find_Last");
      Check (Find (A, 99) = 9, "First=10 miss sentinel 9");
      Check (Find (B, 6) = 2, "0-based hit");
      Check (Find (B, 1) = -1, "0-based miss sentinel -1");
   end;

   Section ("6. Power-of-two and odd lengths");
   declare
      P2 : Element_Array (1 .. 8);
      Odd : Element_Array (1 .. 9);
   begin
      for I in P2'Range loop
         P2 (I) := I * 10;
      end loop;
      for I in Odd'Range loop
         Odd (I) := I * 10;
      end loop;
      Check (Find (P2, 10) = 1, "p2 first");
      Check (Find (P2, 80) = 8, "p2 last");
      Check (Find (P2, 40) = 4, "p2 mid");
      Expect_Miss (P2, 45, "p2 miss");
      Check (Find (Odd, 50) = 5, "odd mid");
      Check (Find (Odd, 90) = 9, "odd last");
      Expect_Miss (Odd, 0, "odd miss");
   end;

   Section ("7. Large n vs linear reference");
   declare
      N : constant := 5_000;
      A : Element_Array (1 .. N);
      Keys : constant Element_Array :=
        [1, 2, N / 2, N - 1, N, -1, N + 1, 42, 999, 2500];
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;

      for K of Keys loop
         declare
            Got : constant Integer := Find (A, K);
            Ref : constant Integer := Linear_Find (A, K);
         begin
            Check (Got = Ref,
                   "large Find matches linear key=" & Integer'Image (K));
            Check (Find_First (A, K) = Linear_First (A, K),
                   "large First matches linear key=" & Integer'Image (K));
            Check (Find_Last (A, K) = Linear_Last (A, K),
                   "large Last matches linear key=" & Integer'Image (K));
         end;
      end loop;
   end;

   Section ("8. Large n with duplicates vs linear");
   declare
      N : constant := 2_000;
      A : Element_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := ((I - 1) / 20) + 1;
      end loop;

      for V in 1 .. 5 loop
         Check (Find_First (A, V) = Linear_First (A, V),
                "dup First V=" & Integer'Image (V));
         Check (Find_Last (A, V) = Linear_Last (A, V),
                "dup Last V=" & Integer'Image (V));
         declare
            Got : constant Integer := Find (A, V);
         begin
            Check (Got >= Find_First (A, V)
                   and then Got <= Find_Last (A, V),
                   "dup Find in plateau V=" & Integer'Image (V));
         end;
      end loop;
      Expect_Miss (A, 0, "dup miss 0");
      Expect_Miss (A, 10_000, "dup miss high");
   end;

   Section ("9. Random queries on sorted random array");
   declare
      N : constant := 1_000;
      A : Element_Array (1 .. N);
   begin
      Seed := 99;
      for I in A'Range loop
         A (I) := Integer (Next_Mod (10_000));
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

      for Trial in 1 .. 15 loop
         declare
            K   : constant Integer := Integer (Next_Mod (10_000));
            Got : constant Integer := Find (A, K);
            Ref : constant Integer := Linear_Find (A, K);
         begin
            if Ref < Integer (A'First) then
               Check (Got = Ref,
                      "rand miss trial" & Integer'Image (Trial));
            else
               Check (Got >= Integer (A'First)
                      and then Got <= Integer (A'Last)
                      and then A (Natural (Got)) = K,
                      "rand hit trial" & Integer'Image (Trial));
               Check (Find_First (A, K) = Linear_First (A, K),
                      "rand First trial" & Integer'Image (Trial));
               Check (Find_Last (A, K) = Linear_Last (A, K),
                      "rand Last trial" & Integer'Image (Trial));
            end if;
         end;
      end loop;
   end;

   Section ("10. Invalid_Argument when length > Max_N");
   declare
      Big : constant Element_Array (0 .. Max_N) := [others => 0];
   begin
      Check (Find_Raises (Big, 0), "Find raises on oversized");
      Check (First_Raises (Big, 0), "Find_First raises on oversized");
      Check (Last_Raises (Big, 0), "Find_Last raises on oversized");
   end;

   declare
      Ok : Element_Array (1 .. 100);
   begin
      for I in Ok'Range loop
         Ok (I) := I;
      end loop;
      Check (not Find_Raises (Ok, 50), "small array does not raise");
      Check (Find (Ok, 50) = 50, "small accepted Find");
   end;

   Section ("11. Two-element and boundary keys");
   declare
      T : constant Element_Array (1 .. 2) := [5, 10];
   begin
      Check (Find (T, 5) = 1, "two-el first");
      Check (Find (T, 10) = 2, "two-el second");
      Expect_Miss (T, 7, "two-el between");
      Expect_Miss (T, 4, "two-el below");
      Expect_Miss (T, 11, "two-el above");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

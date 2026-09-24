--  Standalone test suite for Ternary_Search (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Find miss sentinel is always 0 (indices are 1 .. N).
--  Find_Maximum_Index requires non-empty unimodal A with A'First = 1.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ternary_Search; use Ternary_Search;

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

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   --  Brute-force index of a (first) maximum.
   function Ref_Max_Index (A : Element_Array) return Index is
      Best : Index := A'First;
   begin
      for I in A'First + 1 .. A'Last loop
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Ref_Max_Index;

   --  True if A(Got) equals the true maximum value (any peak index OK).
   function Is_A_Maximum (A : Element_Array; Got : Index) return Boolean is
   begin
      return Got in A'Range and then A (Got) = A (Ref_Max_Index (A));
   end Is_A_Maximum;

   function Linear_Find (A : Element_Array; Key : Integer) return Index is
   begin
      for I in A'Range loop
         if A (I) = Key then
            return I;
         end if;
      end loop;
      return 0;
   end Linear_Find;

   function Is_Hit
     (A : Element_Array; Key : Integer; Got : Index) return Boolean
   is
   begin
      return Got >= 1 and then Got <= A'Last and then A (Got) = Key;
   end Is_Hit;

   procedure Expect_Hit
     (A : Element_Array; Key : Integer; Label : String)
   is
      Got : constant Index := Find (A, Key);
   begin
      Check (Is_Hit (A, Key, Got), Label);
   end Expect_Hit;

   procedure Expect_Miss
     (A : Element_Array; Key : Integer; Label : String)
   is
   begin
      Check (Idx (Find (A, Key)) = 0, Label);
   end Expect_Miss;

   procedure Expect_Agree
     (A : Element_Array; Key : Integer; Label : String)
   is
      F     : constant Index := Find (A, Key);
      C     : constant Index := Linear_Find (A, Key);
      F_Hit : constant Boolean := Is_Hit (A, Key, F);
      C_Hit : constant Boolean := Is_Hit (A, Key, C);
   begin
      Check (F_Hit = C_Hit, Label & " presence agrees");
      if not F_Hit then
         Check (Idx (F) = 0 and then Idx (C) = 0, Label & " both sentinel");
      end if;
   end Expect_Agree;

   --  Deterministic LCG for synthetic unimodal arrays.
   Seed : Natural := 7;

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

   --  Strictly increasing-then-decreasing unimodal array, 1-based indices.
   function Make_Unimodal
     (Len : Positive; Peak_Offset : Natural; Base : Integer := 0)
      return Element_Array
   is
      A    : Element_Array (1 .. Len);
      Peak : constant Positive := 1 + Peak_Offset;
   begin
      pragma Assert (Peak_Offset < Len);
      for I in 1 .. Peak loop
         A (I) := Base + Integer (I - 1);
      end loop;
      for I in Peak + 1 .. Len loop
         A (I) := A (I - 1) - 1;
      end loop;
      return A;
   end Make_Unimodal;

   --  Unimodal with a flat plateau of Peak_Width equal maxima.
   function Make_Plateau
     (Len : Positive; Peak_Start : Positive; Peak_Width : Positive;
      Base : Integer := 100)
      return Element_Array
   is
      A        : Element_Array (1 .. Len);
      Peak_End : constant Positive :=
        Positive'Min (Len, Peak_Start + Peak_Width - 1);
      Height   : constant Integer := Base;
   begin
      for I in 1 .. Peak_Start - 1 loop
         A (I) := Height - Integer (Peak_Start - I);
      end loop;
      for I in Peak_Start .. Peak_End loop
         A (I) := Height;
      end loop;
      for I in Peak_End + 1 .. Len loop
         A (I) := Height - Integer (I - Peak_End);
      end loop;
      return A;
   end Make_Plateau;

   function A1 (V1 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1);
   end A1;

   function A2 (V1, V2 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1, 2 => V2);
   end A2;

   function A3 (V1, V2, V3 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1, 2 => V2, 3 => V3);
   end A3;

   function A5 (V1, V2, V3, V4, V5 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1, 2 => V2, 3 => V3, 4 => V4, 5 => V5);
   end A5;

   function A6 (V1, V2, V3, V4, V5, V6 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1, 2 => V2, 3 => V3, 4 => V4, 5 => V5,
                           6 => V6);
   end A6;

   function A7 (V1, V2, V3, V4, V5, V6, V7 : Integer) return Element_Array is
   begin
      return Element_Array'(1 => V1, 2 => V2, 3 => V3, 4 => V4, 5 => V5,
                           6 => V6, 7 => V7);
   end A7;

begin
   Put_Line ("Ternary_Search (SPARK) tests");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Singleton and short unimodal");
   ---------------------------------------------------------------------
   declare
      One      : constant Element_Array := A1 (42);
      Two_Asc  : constant Element_Array := A2 (1, 5);
      Two_Desc : constant Element_Array := A2 (9, 3);
      Three    : constant Element_Array := A3 (1, 8, 2);
   begin
      Check (Is_Unimodal (One), "singleton Is_Unimodal");
      Check (Idx (Find_Maximum_Index (One)) = 1, "singleton peak");
      Check (Idx (Find_Maximum_Index (Two_Asc)) = 2,
             "two ascending peak at end");
      Check (Idx (Find_Maximum_Index (Two_Desc)) = 1,
             "two descending peak at start");
      Check (Idx (Find_Maximum_Index (Three)) = 2, "three mid peak");
   end;

   ---------------------------------------------------------------------
   Section ("2. Peak at start / middle / end");
   ---------------------------------------------------------------------
   declare
      Start_P : constant Element_Array := A7 (10, 9, 8, 7, 6, 5, 4);
      End_P   : constant Element_Array := A7 (1, 2, 3, 4, 5, 6, 12);
      Mid_P   : constant Element_Array := A7 (1, 3, 5, 9, 7, 4, 2);
      Near_L  : constant Element_Array := A6 (2, 10, 8, 6, 4, 1);
      Near_R  : constant Element_Array := A6 (1, 4, 6, 8, 10, 3);
   begin
      Check (Is_Unimodal (Start_P), "start Is_Unimodal");
      Check (Idx (Find_Maximum_Index (Start_P)) = 1, "peak at start");
      Check (Idx (Find_Maximum_Index (End_P)) = 7, "peak at end");
      Check (Idx (Find_Maximum_Index (Mid_P)) = 4, "peak in middle");
      Check (Idx (Find_Maximum_Index (Near_L)) = 2, "peak near start");
      Check (Idx (Find_Maximum_Index (Near_R)) = 5, "peak near end");
   end;

   ---------------------------------------------------------------------
   Section ("3. Plateaus (non-strict unimodal)");
   ---------------------------------------------------------------------
   declare
      Flat_All   : constant Element_Array :=
        Element_Array'(1 => 5, 2 => 5, 3 => 5, 4 => 5);
      Flat_Mid   : constant Element_Array := Make_Plateau (9, 4, 3);
      Flat_Start : constant Element_Array := Make_Plateau (8, 1, 3);
      Flat_End   : constant Element_Array := Make_Plateau (8, 6, 3);
   begin
      Check (Is_Unimodal (Flat_All), "flat_all Is_Unimodal");
      Check (Is_A_Maximum (Flat_All, Find_Maximum_Index (Flat_All)),
             "all-equal plateau");
      Check (Is_A_Maximum (Flat_Mid, Find_Maximum_Index (Flat_Mid)),
             "middle plateau");
      Check (Is_A_Maximum (Flat_Start, Find_Maximum_Index (Flat_Start)),
             "start plateau");
      Check (Is_A_Maximum (Flat_End, Find_Maximum_Index (Flat_End)),
             "end plateau");
   end;

   ---------------------------------------------------------------------
   Section ("4. Generated unimodal peaks at every offset");
   ---------------------------------------------------------------------
   declare
      Len : constant := 15;
   begin
      for Off in 0 .. Len - 1 loop
         declare
            A   : constant Element_Array := Make_Unimodal (Len, Off);
            Got : constant Index := Find_Maximum_Index (A);
         begin
            Check (Is_Unimodal (A),
                   "unimodal shape len=15 peak_off=" & Off'Image);
            Check (Is_A_Maximum (A, Got),
                   "unimodal len=15 peak_off=" & Off'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Larger unimodal shapes (within Max_N)");
   ---------------------------------------------------------------------
   declare
      L64  : constant Element_Array := Make_Unimodal (Max_N, 0);
      L63  : constant Element_Array := Make_Unimodal (63, 31);
      L64e : constant Element_Array := Make_Unimodal (Max_N, Max_N - 1);
      L50a : constant Element_Array := Make_Unimodal (50, 7, Base => -20);
      L50b : constant Element_Array := Make_Unimodal (50, 49, Base => 1000);
   begin
      Check (In_Bounds (L64), "Max_N In_Bounds");
      Check (Is_A_Maximum (L64, Find_Maximum_Index (L64)),
             "len 64 peak start");
      Check (Is_A_Maximum (L63, Find_Maximum_Index (L63)),
             "len 63 peak mid");
      Check (Is_A_Maximum (L64e, Find_Maximum_Index (L64e)),
             "len 64 peak end");
      Check (Is_A_Maximum (L50a, Find_Maximum_Index (L50a)),
             "len 50 peak 7 neg base");
      Check (Is_A_Maximum (L50b, Find_Maximum_Index (L50b)),
             "len 50 peak end large base");
   end;

   ---------------------------------------------------------------------
   Section ("6. Empty Find and contract helpers");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      Good  : constant Element_Array := A5 (1, 3, 5, 4, 2);
      Bad   : constant Element_Array := A5 (1, 5, 2, 4, 3);
      Cap   : Element_Array (1 .. Max_N);
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Is_Sorted (Empty), "empty Is_Sorted");
      Check (Is_Unimodal (Empty), "empty Is_Unimodal");
      Check (Idx (Find (Empty, 0)) = 0, "Find empty sentinel");

      Check (Is_Unimodal (Good), "Good Is_Unimodal");
      Check (not Is_Unimodal (Bad), "Bad not Is_Unimodal");
      Check (Is_Sorted (A5 (1, 2, 2, 3, 9)), "sorted Is_Sorted");
      Check (not Is_Sorted (A5 (1, 3, 2, 4, 5)), "unsorted not Is_Sorted");

      for I in Cap'Range loop
         Cap (I) := I;
      end loop;
      Check (In_Bounds (Cap), "Cap In_Bounds at Max_N");
      Check (Nat (Max_N) = 64, "Max_N = 64");
   end;

   ---------------------------------------------------------------------
   Section ("7. Sorted Find — hits");
   ---------------------------------------------------------------------
   declare
      S : constant Element_Array (1 .. 10) :=
        [1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
   begin
      Check (Is_Sorted (S), "S Is_Sorted");
      Check (Idx (Find (S, 1)) = 1, "find first");
      Check (Idx (Find (S, 19)) = 10, "find last");
      Check (Idx (Find (S, 9)) = 5, "find middle");
      Check (Idx (Find (S, 7)) = 4, "find 7");
      Check (Idx (Find (S, 13)) = 7, "find 13");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sorted Find — misses");
   ---------------------------------------------------------------------
   declare
      S : constant Element_Array (1 .. 5) := [2, 4, 6, 8, 10];
   begin
      Expect_Miss (S, 1, "miss below");
      Expect_Miss (S, 11, "miss above");
      Expect_Miss (S, 5, "miss between");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sorted Find — duplicates");
   ---------------------------------------------------------------------
   declare
      D   : constant Element_Array (1 .. 5) := [1, 2, 2, 2, 5];
      Got : constant Index := Find (D, 2);
   begin
      Check (Is_Hit (D, 2, Got), "duplicate key any index");
      Check (Idx (Find (D, 1)) = 1, "dup array first");
      Check (Idx (Find (D, 5)) = 5, "dup array last");
   end;

   ---------------------------------------------------------------------
   Section ("10. Exhaustive Find on small sorted arrays");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 8) := [0, 2, 4, 6, 8, 10, 12, 14];
   begin
      for I in A'Range loop
         Check (Idx (Find (A, A (I))) = I,
                "exhaustive hit at" & I'Image);
      end loop;
      for K in -1 .. 15 loop
         if K rem 2 /= 0 then
            Expect_Miss (A, K, "exhaustive miss key=" & K'Image);
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Random-ish unimodal cross-check");
   ---------------------------------------------------------------------
   for Trial in 1 .. 12 loop
      declare
         Len  : constant Positive := 8 + Next_Mod (Max_N - 7);
         Peak : constant Natural := Next_Mod (Len);
         A    : constant Element_Array :=
           Make_Unimodal (Len, Peak, Base => Integer (Next_Mod (50)) - 25);
         Got  : constant Index := Find_Maximum_Index (A);
      begin
         Check (Is_A_Maximum (A, Got),
                "random unimodal trial" & Trial'Image
                & " len=" & Len'Image & " peak=" & Peak'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("12. Max_N Find vs linear reference");
   ---------------------------------------------------------------------
   declare
      N    : constant := Max_N;
      A    : Element_Array (1 .. N);
      Keys : constant Element_Array :=
        [1, 2, N / 2, N - 1, N, -1, N + 1, 42, 17, 33];
   begin
      for I in A'Range loop
         A (I) := I;
      end loop;
      Check (Is_Sorted (A), "Max_N Is_Sorted");
      for K of Keys loop
         Expect_Agree (A, K, "Max_N key=" & Integer'Image (K));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Negative and mixed values");
   ---------------------------------------------------------------------
   declare
      Neg : constant Element_Array := A6 (-50, -20, -5, -10, -30, -40);
      Mix : constant Element_Array := A6 (-3, -1, 0, 4, 2, -2);
   begin
      Check (Is_Unimodal (Neg), "neg Is_Unimodal");
      Check (Idx (Find_Maximum_Index (Neg)) = 3, "all-negative peak");
      Check (Idx (Find_Maximum_Index (Mix)) = 4, "mixed signs peak");
   end;

   ---------------------------------------------------------------------
   Section ("14. Copy / identity sanity");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array := A5 (1, 4, 9, 5, 2);
      Cpy : constant Element_Array := Copy_Of (Src);
   begin
      Check (Idx (Find_Maximum_Index (Cpy)) = 3, "copy peak index");
      Check (Int (Src (3)) = 9, "original unchanged");
      Check (Find_Maximum_Index (Src) = Find_Maximum_Index (Cpy),
             "copy agrees with original");
   end;

   ---------------------------------------------------------------------
   Section ("15. More plateau widths");
   ---------------------------------------------------------------------
   for W in 1 .. 5 loop
      declare
         A : constant Element_Array := Make_Plateau (20, 8, W);
      begin
         Check (Is_Unimodal (A), "plateau Is_Unimodal width" & W'Image);
         Check (Is_A_Maximum (A, Find_Maximum_Index (A)),
                "plateau width" & W'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("16. Sorted Find signed domain");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array (1 .. 7) :=
        [-100, -50, -1, 0, 1, 50, 100];
   begin
      for K of Element_Array'[-100, -50, -1, 0, 1, 50, 100] loop
         Expect_Hit (A, K, "signed hit" & Integer'Image (K));
      end loop;
      Expect_Miss (A, -99, "signed miss");
      Expect_Miss (A, 2, "signed miss 2");
   end;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

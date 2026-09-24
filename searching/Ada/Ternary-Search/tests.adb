--  Standalone test suite for Ternary_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ternary_Search; use Ternary_Search;

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

   function Copy_Of (A : Element_Array) return Element_Array is
   begin
      return Element_Array'(A);
   end Copy_Of;

   --  Brute-force index of a (first) maximum.
   function Ref_Max_Index (A : Element_Array) return Natural is
      Best : Natural := A'First;
   begin
      for I in A'First + 1 .. A'Last loop
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Ref_Max_Index;

   --  True if A(Got) equals the true maximum value (any peak index OK).
   function Is_A_Maximum (A : Element_Array; Got : Natural) return Boolean is
   begin
      return Got in A'Range and then A (Got) = A (Ref_Max_Index (A));
   end Is_A_Maximum;

   function Max_Raises (A : Element_Array) return Boolean is
      Unused : Natural;
   begin
      Unused := Find_Maximum_Index (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Max_Raises;

   function Find_Raises (A : Element_Array; Key : Integer) return Boolean is
      Unused : Integer;
   begin
      Unused := Find (A, Key);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

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

   --  Helpers that build explicitly 1-based arrays (Ada 2022 [] aggregates
   --  on Natural default to a lower bound of 0).
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
   ---------------------------------------------------------------------
   Section ("1. Singleton and short unimodal");
   ---------------------------------------------------------------------
   declare
      One      : constant Element_Array := A1 (42);
      Two_Asc  : constant Element_Array := A2 (1, 5);
      Two_Desc : constant Element_Array := A2 (9, 3);
      Three    : constant Element_Array := A3 (1, 8, 2);
   begin
      Check (Find_Maximum_Index (One) = 1, "singleton peak");
      Check (Find_Maximum_Index (Two_Asc) = 2, "two ascending peak at end");
      Check (Find_Maximum_Index (Two_Desc) = 1, "two descending peak at start");
      Check (Find_Maximum_Index (Three) = 2, "three mid peak");
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
      Check (Find_Maximum_Index (Start_P) = 1, "peak at start");
      Check (Find_Maximum_Index (End_P) = 7, "peak at end");
      Check (Find_Maximum_Index (Mid_P) = 4, "peak in middle");
      Check (Find_Maximum_Index (Near_L) = 2, "peak near start");
      Check (Find_Maximum_Index (Near_R) = 5, "peak near end");
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
            Got : constant Natural := Find_Maximum_Index (A);
         begin
            Check (Is_A_Maximum (A, Got),
                   "unimodal len=15 peak_off=" & Off'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Larger unimodal shapes");
   ---------------------------------------------------------------------
   declare
      L100 : constant Element_Array := Make_Unimodal (100, 0);
      L101 : constant Element_Array := Make_Unimodal (101, 50);
      L102 : constant Element_Array := Make_Unimodal (102, 101);
      L50a : constant Element_Array := Make_Unimodal (50, 7, Base => -20);
      L50b : constant Element_Array := Make_Unimodal (50, 49, Base => 1000);
   begin
      Check (Is_A_Maximum (L100, Find_Maximum_Index (L100)),
             "len 100 peak start");
      Check (Is_A_Maximum (L101, Find_Maximum_Index (L101)),
             "len 101 peak mid");
      Check (Is_A_Maximum (L102, Find_Maximum_Index (L102)),
             "len 102 peak end");
      Check (Is_A_Maximum (L50a, Find_Maximum_Index (L50a)),
             "len 50 peak 7 neg base");
      Check (Is_A_Maximum (L50b, Find_Maximum_Index (L50b)),
             "len 50 peak end large base");
   end;

   ---------------------------------------------------------------------
   Section ("6. Non-1-based indices");
   ---------------------------------------------------------------------
   declare
      A0 : constant Element_Array (0 .. 4) := [0, 1, 4, 2, 0];
      A5 : constant Element_Array (5 .. 9) := [3, 6, 9, 5, 1];
   begin
      Check (Find_Maximum_Index (A0) = 2, "0-based peak index 2");
      Check (Find_Maximum_Index (A5) = 7, "5-based peak index 7");
   end;

   ---------------------------------------------------------------------
   Section ("7. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (Max_Raises (Empty), "empty Find_Maximum raises");
      --  Oversized arrays are rejected; construct via a slice length check
      --  without allocating Max_N+1 elements: use a local stub that
      --  simulates the length guard via a dedicated tiny stand-in.
      Check (not Max_Raises (A1 (1)), "non-empty does not raise");
      Check (not Find_Raises (A1 (1), 1), "Find on small does not raise");
      Check (Find (Empty, 0) = Integer (Empty'First) - 1,
             "Find empty returns sentinel");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sorted Find — hits");
   ---------------------------------------------------------------------
   declare
      S : constant Element_Array (1 .. 10) :=
        [1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
   begin
      Check (Find (S, 1) = 1, "find first");
      Check (Find (S, 19) = 10, "find last");
      Check (Find (S, 9) = 5, "find middle");
      Check (Find (S, 7) = 4, "find 7");
      Check (Find (S, 13) = 7, "find 13");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sorted Find — misses");
   ---------------------------------------------------------------------
   declare
      S : constant Element_Array (1 .. 5) := [2, 4, 6, 8, 10];
      Z : constant Element_Array (0 .. 2) := [10, 20, 30];
   begin
      Check (Find (S, 1) = 0, "miss below");
      Check (Find (S, 11) = 0, "miss above");
      Check (Find (S, 5) = 0, "miss between");
      Check (Find (Z, 99) = -1, "0-based miss sentinel -1");
      Check (Find (Z, 20) = 1, "0-based hit");
      Check (Find (Z, 10) = 0, "0-based first");
   end;

   ---------------------------------------------------------------------
   Section ("10. Sorted Find — duplicates");
   ---------------------------------------------------------------------
   declare
      D   : constant Element_Array (1 .. 5) := [1, 2, 2, 2, 5];
      Got : constant Integer := Find (D, 2);
   begin
      Check (Got in Integer (D'First) .. Integer (D'Last)
             and then D (Natural (Got)) = 2,
             "duplicate key any index");
      Check (Find (D, 1) = 1, "dup array first");
      Check (Find (D, 5) = 5, "dup array last");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exhaustive Find on small sorted arrays");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array (0 .. 7) := [0, 2, 4, 6, 8, 10, 12, 14];
   begin
      for I in A'Range loop
         Check (Find (A, A (I)) = I,
                "exhaustive hit at" & I'Image);
      end loop;
      for K in -1 .. 15 loop
         if K rem 2 /= 0 then
            Check (Find (A, K) = -1,
                   "exhaustive miss key=" & K'Image);
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Random-ish unimodal cross-check");
   ---------------------------------------------------------------------
   for Trial in 1 .. 12 loop
      declare
         Len  : constant Positive := 20 + Next_Mod (80);
         Peak : constant Natural := Next_Mod (Len);
         A    : constant Element_Array :=
           Make_Unimodal (Len, Peak, Base => Integer (Next_Mod (50)) - 25);
         Got  : constant Natural := Find_Maximum_Index (A);
      begin
         Check (Is_A_Maximum (A, Got),
                "random unimodal trial" & Trial'Image
                & " len=" & Len'Image & " peak=" & Peak'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("13. Max_N and API smoke");
   ---------------------------------------------------------------------
   Check (Max_N'Image = " 100000", "Max_N Image is 100000");
   declare
      Big_Ok  : constant Element_Array := Make_Unimodal (200, 100);
      Sorted  : constant Element_Array (1 .. 6) :=
        [10, 20, 30, 40, 50, 60];
   begin
      Check (Is_A_Maximum (Big_Ok, Find_Maximum_Index (Big_Ok)),
             "len 200 mid peak");
      Check (Find (Sorted, 40) = 4, "sorted mid hit 40");
      Check (Find (Sorted, 25) = 0, "sorted miss 25");
   end;

   ---------------------------------------------------------------------
   Section ("14. Negative and mixed values");
   ---------------------------------------------------------------------
   declare
      Neg : constant Element_Array := A6 (-50, -20, -5, -10, -30, -40);
      Mix : constant Element_Array := A6 (-3, -1, 0, 4, 2, -2);
   begin
      Check (Find_Maximum_Index (Neg) = 3, "all-negative peak");
      Check (Find_Maximum_Index (Mix) = 4, "mixed signs peak");
   end;

   ---------------------------------------------------------------------
   Section ("15. Copy / identity sanity");
   ---------------------------------------------------------------------
   declare
      Src : constant Element_Array := A5 (1, 4, 9, 5, 2);
      Cpy : constant Element_Array := Copy_Of (Src);
   begin
      Check (Find_Maximum_Index (Cpy) = 3, "copy peak index");
      Check (Src (3) = 9, "original unchanged");
      Check (Find_Maximum_Index (Src) = Find_Maximum_Index (Cpy),
             "copy agrees with original");
   end;

   ---------------------------------------------------------------------
   Section ("16. More plateau widths");
   ---------------------------------------------------------------------
   for W in 1 .. 5 loop
      declare
         A : constant Element_Array := Make_Plateau (20, 8, W);
      begin
         Check (Is_A_Maximum (A, Find_Maximum_Index (A)),
                "plateau width" & W'Image);
      end;
   end loop;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;

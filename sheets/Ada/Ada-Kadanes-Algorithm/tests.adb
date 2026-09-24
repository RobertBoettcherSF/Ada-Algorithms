--  Standalone test suite for Kadanes_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Kadanes_Algorithm; use Kadanes_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   function Sum_Raises (A : Element_Array) return Boolean is
      Unused : Element;
   begin
      Unused := Max_Subarray_Sum (A);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Sum_Raises;

   function Sub_Raises (A : Element_Array) return Boolean is
      Unused : Result;
   begin
      Unused := Max_Subarray (A);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Sub_Raises;

   function Brute_Raises (A : Element_Array) return Boolean is
      Unused : Result;
   begin
      Unused := Brute_Force (A);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Brute_Raises;

   procedure Expect_Sum
     (A       : Element_Array;
      Expected : Element;
      Label   : String)
   is
      Got : constant Element := Max_Subarray_Sum (A);
   begin
      Check (Got = Expected,
             Label & ": sum=" & Element'Image (Got)
             & " expect" & Element'Image (Expected));
   end Expect_Sum;

   procedure Expect_Result
     (A              : Element_Array;
      Expected_Sum   : Element;
      Expected_First : Positive;
      Expected_Last  : Positive;
      Label          : String)
   is
      R : constant Result := Max_Subarray (A);
   begin
      Check (R.Sum = Expected_Sum,
             Label & ": Sum" & Element'Image (R.Sum)
             & " expect" & Element'Image (Expected_Sum));
      Check (R.First = Expected_First,
             Label & ": First" & Positive'Image (R.First)
             & " expect" & Positive'Image (Expected_First));
      Check (R.Last = Expected_Last,
             Label & ": Last" & Positive'Image (R.Last)
             & " expect" & Positive'Image (Expected_Last));
   end Expect_Result;

   procedure Expect_Kadane_Eq_Brute (A : Element_Array; Label : String) is
      K : constant Result := Max_Subarray (A);
      B : constant Result := Brute_Force (A);
   begin
      Check (K.Sum = B.Sum,
             Label & ": Kadane Sum ≡ brute Sum ("
             & Element'Image (K.Sum) & ")");
      --  Indices may differ on ties; both must be valid windows with that sum.
      declare
         function Window_Sum (R : Result) return Element is
            S : Element := 0;
         begin
            for I in R.First .. R.Last loop
               S := S + A (A'First + (I - 1));
            end loop;
            return S;
         end Window_Sum;
      begin
         Check (K.First <= K.Last, Label & ": Kadane First<=Last");
         Check (B.First <= B.Last, Label & ": brute First<=Last");
         Check (Window_Sum (K) = K.Sum, Label & ": Kadane window matches Sum");
         Check (Window_Sum (B) = B.Sum, Label & ": brute window matches Sum");
      end;
   end Expect_Kadane_Eq_Brute;

begin
   Ada.Text_IO.Put_Line ("Kadanes_Algorithm test suite");
   Ada.Text_IO.Put_Line ("============================");

   ------------------------------------------------------------------
   Section ("1. Wikipedia classic example");
   ------------------------------------------------------------------
   --  A = [-2, 1, -3, 4, -1, 2, 1, -5, 4]; max = [4,-1,2,1] sum 6 (idx 4..7)
   declare
      Wiki : constant Element_Array :=
        [-2, 1, -3, 4, -1, 2, 1, -5, 4];
   begin
      Expect_Sum (Wiki, 6, "wiki sum");
      Expect_Result (Wiki, 6, 4, 7, "wiki window");
      Expect_Kadane_Eq_Brute (Wiki, "wiki");
   end;

   ------------------------------------------------------------------
   Section ("2. Single element");
   ------------------------------------------------------------------
   Expect_Sum ([5], 5, "single positive");
   Expect_Result ([5], 5, 1, 1, "single positive window");
   Expect_Sum ([-7], -7, "single negative");
   Expect_Result ([-7], -7, 1, 1, "single negative window");
   Expect_Sum ([0], 0, "single zero");
   Expect_Result ([0], 0, 1, 1, "single zero window");
   Expect_Kadane_Eq_Brute ([42], "single 42");
   Expect_Kadane_Eq_Brute ([-3], "single -3");

   ------------------------------------------------------------------
   Section ("3. All negative (least-negative singleton)");
   ------------------------------------------------------------------
   declare
      Neg : constant Element_Array := [-5, -1, -3, -4];
   begin
      Expect_Sum (Neg, -1, "all-neg sum");
      Expect_Result (Neg, -1, 2, 2, "all-neg window");
      Expect_Kadane_Eq_Brute (Neg, "all-neg");
   end;
   declare
      Neg2 : constant Element_Array := [-8, -3, -9];
   begin
      Expect_Sum (Neg2, -3, "all-neg2 sum");
      Expect_Result (Neg2, -3, 2, 2, "all-neg2 window");
   end;
   declare
      Neg3 : constant Element_Array := [-2, -2, -2];
   begin
      --  Tie: leftmost singleton (first strict improvement keeps index 1).
      Expect_Sum (Neg3, -2, "all-neg equal sum");
      Expect_Result (Neg3, -2, 1, 1, "all-neg equal leftmost");
   end;

   ------------------------------------------------------------------
   Section ("4. All non-negative (whole array)");
   ------------------------------------------------------------------
   declare
      Pos : constant Element_Array := [1, 2, 3, 4];
   begin
      Expect_Sum (Pos, 10, "all-pos sum");
      Expect_Result (Pos, 10, 1, 4, "all-pos window");
      Expect_Kadane_Eq_Brute (Pos, "all-pos");
   end;
   Expect_Sum ([0, 0, 0], 0, "all-zero sum");
   Expect_Result ([0, 0, 0], 0, 1, 1, "all-zero leftmost singleton");

   ------------------------------------------------------------------
   Section ("5. Empty / oversize raise Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (Sum_Raises (Empty), "empty Max_Subarray_Sum raises");
      Check (Sub_Raises (Empty), "empty Max_Subarray raises");
      Check (Brute_Raises (Empty), "empty Brute_Force raises");
   end;
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 1];
   begin
      Check (Sum_Raises (Big), "oversize Max_Subarray_Sum raises");
      Check (Sub_Raises (Big), "oversize Max_Subarray raises");
      Check (Brute_Raises (Big), "oversize Brute_Force raises");
   end;

   ------------------------------------------------------------------
   Section ("6. Kadane ≡ brute on mixed small arrays");
   ------------------------------------------------------------------
   Expect_Kadane_Eq_Brute ([1, -2, 3], "mixed 1");
   Expect_Kadane_Eq_Brute ([-1, 2, -3, 4], "mixed 2");
   Expect_Kadane_Eq_Brute ([4, -1, 2, 1], "mixed 3 wiki core");
   Expect_Kadane_Eq_Brute ([5, -2, -1, 3, -1], "mixed 4");
   Expect_Kadane_Eq_Brute ([-2, -3, 4, -1, -2, 1, 5, -3], "mixed 5 classic");
   Expect_Kadane_Eq_Brute ([8, -19, 5, -4, 20], "mixed 6");
   Expect_Kadane_Eq_Brute ([1, 2, -1, -3, 4, 5, -2], "mixed 7");
   Expect_Kadane_Eq_Brute ([-4, 1, 2, -5, 3], "mixed 8");

   ------------------------------------------------------------------
   Section ("7. Known windows");
   ------------------------------------------------------------------
   --  [-2,-3,4,-1,-2,1,5,-3] → [4,-1,-2,1,5] sum 7, indices 3..7
   Expect_Result
     ([-2, -3, 4, -1, -2, 1, 5, -3], 7, 3, 7, "classic pearson");
   --  [5,-2,-1,3] → whole or [5]/[5,-2,-1,3]=5; wait 5-2-1+3=5, so sum 5
   --  leftmost maximizing: start at 1 end at 1 (sum 5) vs 1..4 (sum 5).
   --  Kadane: start with 5; at -2: 5-2=3 > -2 keep; at -1: 3-1=2 > -1 keep;
   --  at 3: 2+3=5 == Best_Sum 5, no strict improvement → First=1 Last=1.
   Expect_Result ([5, -2, -1, 3], 5, 1, 1, "tie prefers first best");
   Expect_Sum ([5, -2, -1, 3], 5, "tie sum still 5");
   --  Strictly better extension: [1,-2,5] → [5]
   Expect_Result ([1, -2, 5], 5, 3, 3, "restart at last");
   --  [2, -1, 2] → whole sum 3
   Expect_Result ([2, -1, 2], 3, 1, 3, "extend through dip");

   ------------------------------------------------------------------
   Section ("8. Non-1-based array bounds");
   ------------------------------------------------------------------
   declare
      Buf : constant Element_Array (5 .. 13) :=
        [-2, 1, -3, 4, -1, 2, 1, -5, 4];
   begin
      Expect_Sum (Buf, 6, "slice wiki sum");
      Expect_Result (Buf, 6, 4, 7, "slice wiki window (logical 1-based)");
      Expect_Kadane_Eq_Brute (Buf, "slice wiki");
   end;

   ------------------------------------------------------------------
   Section ("9. Max_Length boundary ok");
   ------------------------------------------------------------------
   declare
      --  Avoid huge brute force: only Kadane on Max_Length.
      Edge : Element_Array (1 .. Max_Length) := [others => -1];
   begin
      Edge (Max_Length / 2) := 0;
      Expect_Sum (Edge, 0, "Max_Length all-neg with a zero");
      declare
         R : constant Result := Max_Subarray (Edge);
      begin
         Check (R.Sum = 0, "Max_Length Result.Sum = 0");
         Check (R.First = Max_Length / 2, "Max_Length First at zero");
         Check (R.Last = Max_Length / 2, "Max_Length Last at zero");
      end;
   end;

   ------------------------------------------------------------------
   Section ("10. Brute_Force_Sum agrees");
   ------------------------------------------------------------------
   declare
      A1 : constant Element_Array := [-2, 1, -3, 4, -1, 2, 1, -5, 4];
      A2 : constant Element_Array := [-5, -1, -3];
      A3 : constant Element_Array := [1, 2, 3];
      A4 : constant Element_Array := [9];
   begin
      Check (Max_Subarray_Sum (A1) = Brute_Force_Sum (A1),
             "Brute_Force_Sum ≡ Kadane (wiki)");
      Check (Max_Subarray_Sum (A2) = Brute_Force_Sum (A2),
             "Brute_Force_Sum ≡ Kadane (all-neg)");
      Check (Max_Subarray_Sum (A3) = Brute_Force_Sum (A3),
             "Brute_Force_Sum ≡ Kadane (all-pos)");
      Check (Max_Subarray_Sum (A4) = Brute_Force_Sum (A4),
             "Brute_Force_Sum ≡ Kadane (single)");
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

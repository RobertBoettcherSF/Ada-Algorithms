--  Standalone test suite for Dynamic_Time_Warping (main program).

pragma Ada_2022;

with Ada.Text_IO;           use Ada.Text_IO;
with Dynamic_Time_Warping;  use Dynamic_Time_Warping;

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

   procedure Expect
     (X, Y : Series; Expected : Natural; Label : String)
   is
      Got : constant Natural := Distance (X, Y);
   begin
      Check (Got = Expected,
             Label & " got" & Got'Image & " expect" & Expected'Image);
   end Expect;

   procedure Expect_Window
     (X, Y     : Series;
      Window   : Natural;
      Expected : Natural;
      Label    : String)
   is
      Got : constant Natural := Distance (X, Y, Window);
   begin
      Check (Got = Expected,
             Label & " got" & Got'Image & " expect" & Expected'Image);
   end Expect_Window;

   function Dist_Raises (X, Y : Series) return Boolean is
      D : Natural;
   begin
      D := Distance (X, Y);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function Dist_Window_Raises
     (X, Y : Series; Window : Natural) return Boolean
   is
      D : Natural;
   begin
      D := Distance (X, Y, Window);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Window_Raises;

   --  Tiny reference DTW for cross-checks (same recurrence, unconstrained).
   function Ref_DTW (X, Y : Series) return Natural is
      M : constant Natural := X'Length;
      N : constant Natural := Y'Length;
      type Mat is array (1 .. M, 1 .. N) of Natural;
      F : Mat;

      function AX (I : Positive) return Integer is
        (X (X'First + (I - 1)));
      function AY (J : Positive) return Integer is
        (Y (Y'First + (J - 1)));

      function LC (A, B : Integer) return Natural is
      begin
         if A >= B then
            return Natural (A - B);
         else
            return Natural (B - A);
         end if;
      end LC;

      function Min3 (A, B, C : Natural) return Natural is
         R : Natural := A;
      begin
         if B < R then
            R := B;
         end if;
         if C < R then
            R := C;
         end if;
         return R;
      end Min3;
   begin
      if M = 0 or else N = 0 then
         raise Invalid_Argument;
      end if;
      F (1, 1) := LC (AX (1), AY (1));
      for J in 2 .. N loop
         F (1, J) := F (1, J - 1) + LC (AX (1), AY (J));
      end loop;
      for I in 2 .. M loop
         F (I, 1) := F (I - 1, 1) + LC (AX (I), AY (1));
      end loop;
      for I in 2 .. M loop
         for J in 2 .. N loop
            F (I, J) :=
              LC (AX (I), AY (J))
              + Min3 (F (I - 1, J), F (I, J - 1), F (I - 1, J - 1));
         end loop;
      end loop;
      return F (M, N);
   end Ref_DTW;

begin
   Put_Line ("Dynamic_Time_Warping test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);

   ------------------------------------------------------------------
   Section ("Local_Cost");
   ------------------------------------------------------------------
   Check (Local_Cost (5, 5) = 0, "Local_Cost equal");
   Check (Local_Cost (5, 2) = 3, "Local_Cost 5-2");
   Check (Local_Cost (2, 5) = 3, "Local_Cost 2-5");
   Check (Local_Cost (-3, 4) = 7, "Local_Cost negative/positive");
   Check (Local_Cost (-10, -3) = 7, "Local_Cost both negative");
   Check (Local_Cost (0, 0) = 0, "Local_Cost zeros");

   ------------------------------------------------------------------
   Section ("Identical series → distance 0");
   ------------------------------------------------------------------
   Expect ([1 => 0], [1 => 0], 0, "single zero");
   Expect ([1 => 7], [1 => 7], 0, "single equal");
   Expect ([1, 2, 3], [1, 2, 3], 0, "1,2,3");
   Expect ([5, 5, 5, 5], [5, 5, 5, 5], 0, "constant 5");
   Expect ([-2, -1, 0, 1, 2], [-2, -1, 0, 1, 2], 0, "signed ramp");
   Expect ([10, 20, 30, 40, 50], [10, 20, 30, 40, 50], 0, "tens");

   ------------------------------------------------------------------
   Section ("Single-element pairs");
   ------------------------------------------------------------------
   Expect ([1 => 1], [1 => 1], 0, "1 vs 1");
   Expect ([1 => 1], [1 => 5], 4, "1 vs 5");
   Expect ([1 => 10], [1 => 3], 7, "10 vs 3");
   Expect ([1 => -4], [1 => 6], 10, "-4 vs 6");

   ------------------------------------------------------------------
   Section ("Hand-computed small cases");
   ------------------------------------------------------------------
   --  X=[1,3] Y=[1,2,3] → 1 (see README)
   Expect ([1, 3], [1, 2, 3], 1, "README example [1,3] vs [1,2,3]");
   Expect ([1, 2, 3], [1, 3], 1, "symmetric of README example");

   --  X=[1,2] Y=[2,1]:
   --  d: |1-2|=1  |1-1|=0
   --     |2-2|=0  |2-1|=1
   --  DTW[1,1]=1; row: 1, 1+0=1; col: 1, 1+0=1; [2,2]=1+min[1,1,1]=2
   Expect ([1, 2], [2, 1], 2, "[1,2] vs [2,1]");

   --  X=[0,0] Y=[1,1]: path cost 1+1=2 along diagonal
   Expect ([0, 0], [1, 1], 2, "[0,0] vs [1,1]");

   --  X=[1,1,1] Y=[1,1,1] → 0 already covered; differ one sample
   --  X=[1,2,3] Y=[1,2,4]:
   --  Only last differs by 1; optimal diagonal cost = 0+0+1 = 1
   Expect ([1, 2, 3], [1, 2, 4], 1, "[1,2,3] vs [1,2,4]");

   --  X=(4) Y=[1,2,3,4]: first-row cumulative |4-1|+|4-2|+|4-3|+|4-4|
   --  = 3+2+1+0 = 6
   Expect ([1 => 4], [1, 2, 3, 4], 6, "single 4 vs ramp");

   --  X=[1,2,3,4] Y=(4): first-col cumulative same 6
   Expect ([1, 2, 3, 4], [1 => 4], 6, "ramp vs single 4");

   ------------------------------------------------------------------
   Section ("Shifted / stretched patterns");
   ------------------------------------------------------------------
   --  Slow vs fast ramp: Y stretches the plateau
   Expect ([1, 2, 3], [1, 2, 2, 3], 0, "stretch middle 2");
   Expect ([1, 2, 3, 4], [1, 2, 2, 3, 4], 0, "stretch with plateau");
   Expect ([1, 3], [1, 2, 2, 3], 2, "insert bridge samples");
   --  Time shift of a spike: X has spike at index 2, Y at index 3
   Expect ([0, 5, 0], [0, 0, 5, 0], 0, "spike shifted");
   Expect ([1, 2, 3, 2, 1], [1, 2, 2, 3, 2, 1], 0, "triangle stretch");
   Expect ([0, 1, 2, 3], [0, 0, 1, 2, 3], 0, "leading hold");

   ------------------------------------------------------------------
   Section ("Symmetry");
   ------------------------------------------------------------------
   declare
      A : constant Series := [3, 1, 4, 1, 5];
      B : constant Series := [2, 7, 1, 8];
      C : constant Series := [9, 9, 1];
      D : constant Series := [1, 9, 9, 9];
   begin
      Check (Distance (A, B) = Distance (B, A), "sym A,B");
      Check (Distance (C, D) = Distance (D, C), "sym C,D");
      Check (Distance (A, C) = Distance (C, A), "sym A,C");
      Check (Distance (B, D) = Distance (D, B), "sym B,D");
   end;

   ------------------------------------------------------------------
   Section ("Non-1-based bounds");
   ------------------------------------------------------------------
   declare
      X5 : constant Series (5 .. 7) := [5 => 1, 6 => 2, 7 => 3];
      Y9 : constant Series (9 .. 11) := [9 => 1, 10 => 2, 11 => 3];
      Z2 : constant Series (2 .. 4) := [2 => 1, 3 => 2, 4 => 4];
   begin
      Expect (X5, Y9, 0, "bounds 5..7 vs 9..11 identical");
      Expect (X5, Z2, 1, "bounds 5..7 vs 2..4 off-by-one end");
      Check (Distance (X5, Y9) = Ref_DTW (X5, Y9), "ref match non-1-based");
   end;

   ------------------------------------------------------------------
   Section ("Cross-check vs inline reference");
   ------------------------------------------------------------------
   declare
      procedure Cross (X, Y : Series; Label : String) is
         G : constant Natural := Distance (X, Y);
         R : constant Natural := Ref_DTW (X, Y);
      begin
         Check (G = R, Label & " pkg" & G'Image & " ref" & R'Image);
      end Cross;
   begin
      Cross ([1, 5, 2], [1, 2, 5, 2], "cross1");
      Cross ([0, 0, 1, 0], [0, 1, 0], "cross2");
      Cross ([8, 7, 6, 5], [8, 6, 5], "cross3");
      Cross ([1, 1, 2, 3, 5, 8], [1, 2, 3, 5, 8, 13], "cross fib");
      Cross ([-5, 0, 5], [-4, -1, 2, 6], "cross signed");
      Cross ([100, 100], [100, 99, 100], "cross near-const");
   end;

   ------------------------------------------------------------------
   Section ("Sakoe–Chiba band");
   ------------------------------------------------------------------
   --  Wide window equals unconstrained
   declare
      X : constant Series := [1, 2, 3, 4, 5];
      Y : constant Series := [1, 2, 2, 3, 4, 5];
      U : constant Natural := Distance (X, Y);
   begin
      Expect_Window (X, Y, Window => 10, Expected => U, Label => "wide=unconst");
      Expect_Window (X, Y, Window => 5, Expected => U, Label => "w=5 feasible");
      --  |5-6|=1 so Window 1 is feasible
      Expect_Window (X, Y, Window => 1, Expected => U, Label => "w=1 stretch");
   end;

   --  Identical short series, any feasible window → 0
   Expect_Window ([1, 2, 3], [1, 2, 3], 0, 0, "band w=0 identical");
   Expect_Window ([1, 2, 3], [1, 2, 3], 2, 0, "band w=2 identical");

   --  Single vs longer needs Window >= n-1
   Expect_Window ([1 => 4], [1, 2, 3, 4], 3, 6, "band single vs ramp");

   ------------------------------------------------------------------
   Section ("Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Empty : Series (1 .. 0);
      Long  : Series (1 .. Max_Len + 1);
      Ok    : constant Series := [1, 2, 3];
   begin
      for I in Long'Range loop
         Long (I) := I;
      end loop;

      Check (Dist_Raises (Empty, Ok), "empty X raises");
      Check (Dist_Raises (Ok, Empty), "empty Y raises");
      Check (Dist_Raises (Empty, Empty), "both empty raise");
      Check (Dist_Raises (Long, Ok), "X over Max_Len raises");
      Check (Dist_Raises (Ok, Long), "Y over Max_Len raises");
      Check (Dist_Raises (Long, Long), "both over Max_Len raise");

      --  Band too narrow: |3-5|=2, Window 1 invalid
      Check (Dist_Window_Raises ([1, 2, 3], [1, 2, 3, 4, 5], 1),
             "band w < |m-n| raises");
      Check (Dist_Window_Raises ([1, 2, 3], [1, 2, 3, 4, 5], 0),
             "band w=0 unequal len raises");
      Check (not Dist_Window_Raises ([1, 2, 3], [1, 2, 3, 4, 5], 2),
             "band w=|m-n| ok");
      Check (Dist_Window_Raises (Empty, Ok, 5), "banded empty raises");
   end;

   ------------------------------------------------------------------
   Section ("Max_Len boundary (exactly Max_Len allowed)");
   ------------------------------------------------------------------
   declare
      A : Series (1 .. Max_Len);
      B : Series (1 .. Max_Len);
      D : Natural;
   begin
      for I in A'Range loop
         A (I) := 1;
         B (I) := 1;
      end loop;
      D := Distance (A, B);
      Check (D = 0, "Max_Len identical constants → 0");
      B (Max_Len) := 2;
      D := Distance (A, B);
      Check (D = 1, "Max_Len last sample off-by-one → 1");
   end;

   ------------------------------------------------------------------
   Section ("More pattern cases");
   ------------------------------------------------------------------
   Expect ([1, 2, 1], [1, 1, 2, 1], 0, "peak stretch");
   Expect ([5, 4, 3, 2, 1], [5, 3, 1], 2, "downsample-ish");
   --  Hand: X=[5,4,3,2,1] Y=[5,3,1]
   --  Can verify via ref:
   Check (Distance ([5, 4, 3, 2, 1], [5, 3, 1])
          = Ref_DTW ([5, 4, 3, 2, 1], [5, 3, 1]),
          "downsample matches ref");
   Expect ([2, 2, 2], [2, 3], 1, "flat vs step");
   Expect ([0, 10, 0, 10, 0], [0, 10, 0, 10, 0], 0, "square wave same");
   Expect ([0, 10, 0, 10, 0], [0, 0, 10, 0, 10], 10,
           "square wave phase shift cost");
   Expect ([1 => 42], [1 => 42], 0, "singleton 42");
   Expect ([7, 7], [7, 8, 7], 1, "flat with bump neighbor");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;

with Ada.Text_IO; use Ada.Text_IO;
with Ramer_Douglas_Peucker; use Ramer_Douglas_Peucker;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Approx_Equal (A, B : Distance; Tolerance : Distance := 0.0001) return Boolean is
   begin
      return abs (A - B) <= Tolerance;
   end Approx_Equal;

   function Approx_Equal_Coord (A, B : Coordinate; Tolerance : Coordinate := 0.0001) return Boolean is
   begin
      return abs (A - B) <= Tolerance;
   end Approx_Equal_Coord;

begin
   -- TEST 1 — Euclidean Distance Calculations
   Put_Line ("TEST 1 — Euclidean Distance Calculations");
   declare
      P1 : constant Point_2D := (X => 0.0, Y => 0.0);
      P2 : constant Point_2D := (X => 3.0, Y => 4.0);
      P3 : constant Point_2D := (X => 1.0, Y => 1.0);
   begin
      Check ("1.1 3-4-5 Triangle Distance", Approx_Equal (Euclidean_Distance (P1, P2), 5.0));
      Check ("1.2 Distance to self is zero", Approx_Equal (Euclidean_Distance (P1, P1), 0.0));
      Check ("1.3 Symmetry holds", Approx_Equal (Euclidean_Distance (P1, P3), Euclidean_Distance (P3, P1)));
   end;

   -- TEST 2 — Perpendicular Distance Helpers
   Put_Line ("TEST 2 — Perpendicular Distance Helpers");
   declare
      P_Start : constant Point_2D := (X => 0.0, Y => 0.0);
      P_End   : constant Point_2D := (X => 10.0, Y => 0.0);
      P_Mid   : constant Point_2D := (X => 5.0, Y => 3.0);
      P_On    : constant Point_2D := (X => 7.0, Y => 0.0);
      P_Coin  : constant Point_2D := (X => 0.0, Y => 4.0);
   begin
      Check ("2.1 Perpendicular offset matches Y coordinate",
             Approx_Equal (Perpendicular_Distance (P_Mid, P_Start, P_End), 3.0));
      Check ("2.2 Point on chord gives zero distance",
             Approx_Equal (Perpendicular_Distance (P_On, P_Start, P_End), 0.0));
      Check ("2.3 Coincident endpoints fall back to Euclidean distance",
             Approx_Equal (Perpendicular_Distance (P_Coin, P_Start, P_Start), 4.0));
   end;

   -- TEST 3 — Empty and Single Element Input
   Put_Line ("TEST 3 — Empty and Single Element Input");
   declare
      Empty_Pts : Point_Array (1 .. 0);
      Single_Pt : constant Point_Array (1 .. 1) := [1 => (X => 1.0, Y => 1.0)];
      Res_Empty : constant Point_Array := Simplify (Empty_Pts, 1.0);
      Res_Sing  : constant Point_Array := Simplify (Single_Pt, 1.0);
      Res_Iter  : constant Point_Array := Simplify_Iterative (Empty_Pts, 1.0);
   begin
      Check ("3.1 Empty input returns length 0", Res_Empty'Length = 0);
      Check ("3.2 Single point returns length 1", Res_Sing'Length = 1);
      Check ("3.3 Iterative empty returns length 0", Res_Iter'Length = 0);
   end;

   -- TEST 4 — Two-Point Segment (Boundary Case)
   Put_Line ("TEST 4 — Two-Point Segment (Boundary Case)");
   declare
      Line : constant Point_Array (1 .. 2) :=
        [(X => 0.0, Y => 0.0), (X => 10.0, Y => 10.0)];
      Res1 : constant Point_Array := Simplify (Line, 5.0);
      Res2 : constant Point_Array := Simplify_Iterative (Line, 0.1);
      Mask : constant Boolean_Array := Simplify_Mask (Line, 1.0);
   begin
      Check ("4.1 Recursive retains both endpoints", Res1'Length = 2);
      Check ("4.2 Iterative retains both endpoints", Res2'Length = 2);
      Check ("4.3 Mask is True for both indices", Mask (1) and Mask (2));
   end;

   -- TEST 5 — Collinear Points Elimination
   Put_Line ("TEST 5 — Collinear Points Elimination");
   declare
      Points : constant Point_Array (1 .. 5) :=
        [(X => 0.0, Y => 0.0),
         (X => 2.0, Y => 2.0),
         (X => 4.0, Y => 4.0),
         (X => 6.0, Y => 6.0),
         (X => 8.0, Y => 8.0)];
      Res : constant Point_Array := Simplify (Points, 0.001);
   begin
      Check ("5.1 All interior collinear points simplified away", Res'Length = 2);
      Check ("5.2 First point preserved", Approx_Equal_Coord (Res (Res'First).X, 0.0));
      Check ("5.3 Last point preserved", Approx_Equal_Coord (Res (Res'Last).X, 8.0));
   end;

   -- TEST 6 — Single Peak Retention
   Put_Line ("TEST 6 — Single Peak Retention");
   declare
      Points : constant Point_Array (1 .. 3) :=
        [(X => 0.0, Y => 0.0),
         (X => 5.0, Y => 5.0),
         (X => 10.0, Y => 0.0)];
      Res_Keep : constant Point_Array := Simplify (Points, 2.0);
      Res_Drop : constant Point_Array := Simplify (Points, 6.0);
   begin
      Check ("6.1 Peak retained when epsilon < peak height", Res_Keep'Length = 3);
      Check ("6.2 Peak removed when epsilon > peak height", Res_Drop'Length = 2);
      Check ("6.3 Retained mid point X coordinate matches",
             Approx_Equal_Coord (Res_Keep (2).X, 5.0));
   end;

   -- TEST 7 — Non-zero Array Bounds Compatibility
   Put_Line ("TEST 7 — Non-zero Array Bounds Compatibility");
   declare
      Points : constant Point_Array (10 .. 12) :=
        [(X => 0.0, Y => 0.0),
         (X => 5.0, Y => 10.0),
         (X => 10.0, Y => 0.0)];
      Res : constant Point_Array := Simplify (Points, 1.0);
      Idx : constant Index_Array := Simplify_Indices (Points, 1.0);
   begin
      Check ("7.1 Correct length with 10-based indexing", Res'Length = 3);
      Check ("7.2 Preserves original start index in indices list", Idx (1) = 10);
      Check ("7.3 Preserves original end index in indices list", Idx (3) = 12);
   end;

   -- TEST 8 — Equivalence of Recursive and Iterative Variants
   Put_Line ("TEST 8 — Equivalence of Recursive and Iterative Variants");
   declare
      Points : constant Point_Array (1 .. 7) :=
        [(X => 0.0, Y => 0.0),
         (X => 1.0, Y => 0.1),
         (X => 2.0, Y => -0.1),
         (X => 3.0, Y => 5.0),
         (X => 4.0, Y => 6.0),
         (X => 5.0, Y => 0.2),
         (X => 6.0, Y => 0.0)];
      Rec_Res  : constant Point_Array := Simplify (Points, 1.0);
      Iter_Res : constant Point_Array := Simplify_Iterative (Points, 1.0);
      Same_Len : constant Boolean := Rec_Res'Length = Iter_Res'Length;
      Same_Pts : Boolean := Same_Len;
   begin
      if Same_Len then
         for I in 1 .. Rec_Res'Length loop
            if not Approx_Equal_Coord (Rec_Res (I).X, Iter_Res (I).X) or else
               not Approx_Equal_Coord (Rec_Res (I).Y, Iter_Res (I).Y)
            then
               Same_Pts := False;
            end if;
         end loop;
      end if;

      Check ("8.1 Recursive and iterative produce identical lengths", Same_Len);
      Check ("8.2 Output coordinates match across variants", Same_Pts);
      Check ("8.3 Iterative retains significant peak points", Iter_Res'Length >= 3);
   end;

   -- TEST 9 — Mask Variant Invariants
   Put_Line ("TEST 9 — Mask Variant Invariants");
   declare
      Points : constant Point_Array (1 .. 4) :=
        [(X => 0.0, Y => 0.0),
         (X => 1.0, Y => 10.0),
         (X => 2.0, Y => 0.0),
         (X => 3.0, Y => 0.0)];
      Mask : constant Boolean_Array := Simplify_Mask (Points, 2.0);
   begin
      Check ("9.1 Mask length equals input length", Mask'Length = Points'Length);
      Check ("9.2 Boundary endpoints are true", Mask (1) and Mask (4));
      Check ("9.3 Off-chord peak marked true", Mask (2));
   end;

   -- TEST 10 — Simplify_Indices Variant
   Put_Line ("TEST 10 — Simplify_Indices Variant");
   declare
      Points : constant Point_Array (1 .. 5) :=
        [(X => 0.0, Y => 0.0),
         (X => 1.0, Y => 5.0),
         (X => 2.0, Y => 10.0),
         (X => 3.0, Y => 5.0),
         (X => 4.0, Y => 0.0)];
      Indices : constant Index_Array := Simplify_Indices (Points, 0.5);
   begin
      Check ("10.1 Exactly three points kept", Indices'Length = 3);
      Check ("10.2 First index is 1", Indices (1) = 1);
      Check ("10.3 Middle index matches sharp peak at 3", Indices (2) = 3);
   end;

   -- TEST 11 — Zero Epsilon Invariant
   Put_Line ("TEST 11 — Zero Epsilon Invariant");
   declare
      Points : constant Point_Array (1 .. 4) :=
        [(X => 0.0, Y => 0.0),
         (X => 1.0, Y => 1.0),
         (X => 2.0, Y => -1.0),
         (X => 3.0, Y => 0.0)];
      Res : constant Point_Array := Simplify (Points, 0.0);
   begin
      Check ("11.1 Zero epsilon retains all non-collinear points", Res'Length = 4);
      Check ("11.2 First point intact", Approx_Equal_Coord (Res (1).X, 0.0));
      Check ("11.3 Third point intact", Approx_Equal_Coord (Res (3).Y, -1.0));
   end;

   -- TEST 12 — Large Polyline Benchmark Profile
   Put_Line ("TEST 12 — Large Polyline Benchmark Profile");
   declare
      Large_Input : Point_Array (1 .. 100);
   begin
      for I in Large_Input'Range loop
         Large_Input (I) :=
           (X => Coordinate (I),
            Y => (if I = 50 then 50.0 else Coordinate (I mod 2) * 0.05));
      end loop;

      declare
         Res_Rec  : constant Point_Array := Simplify (Large_Input, 1.0);
         Res_Iter : constant Point_Array := Simplify_Iterative (Large_Input, 1.0);
      begin
         Check ("12.1 High compression achieved on near-flat path", Res_Rec'Length <= 5);
         Check ("12.2 Significant peak retained", Res_Rec'Length >= 3);
         Check ("12.3 Iterative output matches recursive length", Res_Iter'Length = Res_Rec'Length);
      end;
   end;

   -- TEST 13 — Extreme Outlier Rejection with Huge Epsilon
   Put_Line ("TEST 13 — Extreme Outlier Rejection with Huge Epsilon");
   declare
      Points : constant Point_Array (1 .. 6) :=
        [(X => 0.0, Y => 0.0),
         (X => 1.0, Y => 50.0),
         (X => 2.0, Y => 100.0),
         (X => 3.0, Y => 20.0),
         (X => 4.0, Y => -10.0),
         (X => 5.0, Y => 0.0)];
      Res : constant Point_Array := Simplify (Points, 1000.0);
   begin
      Check ("13.1 Simplification collapses to 2 points under large epsilon", Res'Length = 2);
      Check ("13.2 Beginning point retained", Approx_Equal_Coord (Res (1).X, 0.0));
      Check ("13.3 Ending point retained", Approx_Equal_Coord (Res (2).X, 5.0));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

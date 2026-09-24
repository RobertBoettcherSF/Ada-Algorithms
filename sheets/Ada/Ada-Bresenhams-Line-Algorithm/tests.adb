with Ada.Text_IO; use Ada.Text_IO;
with Bresenham;   use Bresenham;

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

   --  Shared callback testing state
   Callback_Count : Natural := 0;
   Last_Seen_Pt   : Point   := Point'(X => 0, Y => 0);

   procedure Test_Collector (P : Point) is
   begin
      Callback_Count := Callback_Count + 1;
      Last_Seen_Pt   := P;
   end Test_Collector;

   Buffer : Point_List (Capacity => 2048);
begin
   ----------------------------------------------------------------------
   -- TEST 1 — Octant 0 Baseline Line
   ----------------------------------------------------------------------
   Put_Line ("TEST 1 — Octant 0 Baseline Line");
   Line_Octant_0 (Point'(0, 0), Point'(6, 2), Buffer);
   Check ("1.1 Exact length matches dx + 1", Buffer.Length = 7);
   Check ("1.2 First point is start", Buffer.Points (1) = Point'(0, 0));
   Check ("1.3 Last point is target", Buffer.Points (7) = Point'(6, 2));

   ----------------------------------------------------------------------
   -- TEST 2 — Single Point (Zero Length)
   ----------------------------------------------------------------------
   Put_Line ("TEST 2 — Single Point");
   Line_General (Point'(15, 27), Point'(15, 27), Buffer);
   Check ("2.1 Length is 1", Buffer.Length = 1);
   Check ("2.2 Coordinates remain unchanged", Buffer.Points (1) = Point'(15, 27));
   Check ("2.3 Expected length helper confirms 1", Expected_Line_Length (Point'(15, 27), Point'(15, 27)) = 1);

   ----------------------------------------------------------------------
   -- TEST 3 — Perfect Horizontal Line (East & West)
   ----------------------------------------------------------------------
   Put_Line ("TEST 3 — Perfect Horizontal Line");
   Line_General (Point'(-5, 10), Point'(5, 10), Buffer);
   Check ("3.1 West to East length is 11", Buffer.Length = 11);
   Check ("3.2 Constant Y preserved", (for all I in 1 .. Buffer.Length => Buffer.Points (I).Y = 10));
   Line_General (Point'(5, 10), Point'(-5, 10), Buffer);
   Check ("3.3 East to West reverses start/end points correctly",
          Buffer.Points (1) = Point'(5, 10) and then Buffer.Points (11) = Point'(-5, 10));

   ----------------------------------------------------------------------
   -- TEST 4 — Perfect Vertical Line (North & South)
   ----------------------------------------------------------------------
   Put_Line ("TEST 4 — Perfect Vertical Line");
   Line_General (Point'(4, -3), Point'(4, 4), Buffer);
   Check ("4.1 South to North length is 8", Buffer.Length = 8);
   Check ("4.2 Constant X preserved", (for all I in 1 .. Buffer.Length => Buffer.Points (I).X = 4));
   Line_General (Point'(4, 4), Point'(4, -3), Buffer);
   Check ("4.3 North to South endpoint matches", Buffer.Points (8) = Point'(4, -3));

   ----------------------------------------------------------------------
   -- TEST 5 — Exact Diagonal Line (Slope = 1 and -1)
   ----------------------------------------------------------------------
   Put_Line ("TEST 5 — Exact Diagonal Lines");
   Line_General (Point'(0, 0), Point'(5, 5), Buffer);
   Check ("5.1 Slope 1 has equal coordinates at each step",
          (for all I in 1 .. Buffer.Length => Buffer.Points (I).X = Buffer.Points (I).Y));
   Line_General (Point'(0, 5), Point'(5, 0), Buffer);
   Check ("5.2 Slope -1 sum is invariant",
          (for all I in 1 .. Buffer.Length => Buffer.Points (I).X + Buffer.Points (I).Y = 5));
   Check ("5.3 Both lines match length 6", Buffer.Length = 6);

   ----------------------------------------------------------------------
   -- TEST 6 — Steep Line (Octant 1: dy > dx)
   ----------------------------------------------------------------------
   Put_Line ("TEST 6 — Steep Line Rasterization");
   Line_General (Point'(1, 1), Point'(3, 8), Buffer);
   Check ("6.1 Length matches dy + 1", Buffer.Length = 8);
   Check ("6.2 Sequence is monotonically non-decreasing in X and Y",
          (for all I in 2 .. Buffer.Length =>
             Buffer.Points (I).X >= Buffer.Points (I - 1).X and then
             Buffer.Points (I).Y > Buffer.Points (I - 1).Y));
   Check ("6.3 Monotonic step-wise 8-connectivity",
          (for all I in 2 .. Buffer.Length =>
             Chebyshev_Distance (Buffer.Points (I), Buffer.Points (I - 1)) = 1));

   ----------------------------------------------------------------------
   -- TEST 7 — Negative Quadrant Coordinates
   ----------------------------------------------------------------------
   Put_Line ("TEST 7 — Negative Coordinates Handling");
   Line_General (Point'(-100, -200), Point'(-90, -180), Buffer);
   Check ("7.1 Start point correct in negative space", Buffer.Points (1) = Point'(-100, -200));
   Check ("7.2 End point reached in negative space", Buffer.Points (Buffer.Length) = Point'(-90, -180));
   Check ("7.3 Span length corresponds to delta-Y + 1", Buffer.Length = 21);

   ----------------------------------------------------------------------
   -- TEST 8 — Symmetry and Reversibility
   ----------------------------------------------------------------------
   Put_Line ("TEST 8 — Directional Invariance / Symmetry");
   declare
      Forward_Buf  : Point_List (Capacity => 32);
      Backward_Buf : Point_List (Capacity => 32);
      P1           : constant Point := Point'(2, 3);
      P2           : constant Point := Point'(12, 9);
      Reversed_OK  : Boolean := True;
   begin
      Line_General (P1, P2, Forward_Buf);
      Line_General (P2, P1, Backward_Buf);
      Check ("8.1 Forward and backward lengths identical", Forward_Buf.Length = Backward_Buf.Length);

      for I in 1 .. Forward_Buf.Length loop
         if Forward_Buf.Points (I) /= Backward_Buf.Points (Backward_Buf.Length - I + 1) then
            Reversed_OK := False;
         end if;
      end loop;
      Check ("8.2 Pixels mirror exactly in reverse", Reversed_OK);
      Check ("8.3 Endpoints match opposite directions",
             Forward_Buf.Points (1) = Backward_Buf.Points (Backward_Buf.Length));
   end;

   ----------------------------------------------------------------------
   -- TEST 9 — Callback Variant (Line_General_Callback)
   ----------------------------------------------------------------------
   Put_Line ("TEST 9 — Immediate Callback Execution");
   Callback_Count := 0;
   Line_General_Callback (Point'(0, 0), Point'(4, 10), Test_Collector'Unrestricted_Access);
   Check ("9.1 Callback executed 11 times", Callback_Count = 11);
   Check ("9.2 Final coordinate observed is endpoint", Last_Seen_Pt = Point'(4, 10));
   Check ("9.3 Length matches Chebyshev distance + 1",
          Callback_Count = Expected_Line_Length (Point'(0, 0), Point'(4, 10)));

   ----------------------------------------------------------------------
   -- TEST 10 — Helper Logic Validation
   ----------------------------------------------------------------------
   Put_Line ("TEST 10 — Helper Logic Validation");
   Check ("10.1 Manhattan distance calculation",
          Manhattan_Distance (Point'(-3, 2), Point'(7, 10)) = 18);
   Check ("10.2 Chebyshev distance calculation",
          Chebyshev_Distance (Point'(-3, 2), Point'(7, 10)) = 10);
   Check ("10.3 Octant 0 validator detects valid vs invalid inputs",
          Is_Valid_Octant_0_Line (Point'(0, 0), Point'(5, 2)) and then
          not Is_Valid_Octant_0_Line (Point'(0, 0), Point'(2, 5)));

   ----------------------------------------------------------------------
   -- TEST 11 — Thick Line Rasterization (X-Major)
   ----------------------------------------------------------------------
   Put_Line ("TEST 11 — Thick Line Rasterization (X-Major)");
   Line_Thick (Point'(0, 0), Point'(10, 2), 3, Buffer);
   Check ("11.1 Thick line point count is length * thickness", Buffer.Length = 11 * 3);
   Check ("11.2 First layer contains start point offset",
          Buffer.Points (1) = Point'(0, -1));
   Check ("11.3 Middle layer contains original start point",
          Buffer.Points (12) = Point'(0, 0));

   ----------------------------------------------------------------------
   -- TEST 12 — Thick Line Rasterization (Y-Major)
   ----------------------------------------------------------------------
   Put_Line ("TEST 12 — Thick Line Rasterization (Y-Major)");
   Line_Thick (Point'(2, 0), Point'(4, 12), 2, Buffer);
   Check ("12.1 Thick line point count is length * thickness", Buffer.Length = 13 * 2);
   Check ("12.2 First cross layer shifted perpendicularly in X",
          Buffer.Points (1).X = 1 and then Buffer.Points (1).Y = 0);
   Check ("12.3 Second cross layer shifted perpendicularly in X",
          Buffer.Points (14).X = 2 and then Buffer.Points (14).Y = 0);

   ----------------------------------------------------------------------
   -- TEST 13 — Grid 8-Connectivity Invariant
   ----------------------------------------------------------------------
   Put_Line ("TEST 13 — Strict Grid Connectivity Invariant");
   Line_General (Point'(-15, 30), Point'(40, -10), Buffer);
   declare
      Connected : Boolean := True;
   begin
      for I in 2 .. Buffer.Length loop
         if Chebyshev_Distance (Buffer.Points (I), Buffer.Points (I - 1)) /= 1 then
            Connected := False;
         end if;
      end loop;
      Check ("13.1 Every point is 8-connected to predecessor", Connected);
      Check ("13.2 Start is (-15, 30)", Buffer.Points (1) = Point'(-15, 30));
      Check ("13.3 End is (40, -10)", Buffer.Points (Buffer.Length) = Point'(40, -10));
   end;

   ----------------------------------------------------------------------
   -- SUMMARY
   ----------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

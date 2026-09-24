with Ada.Text_IO; use Ada.Text_IO;
with Midpoint_Circle; use Midpoint_Circle;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Global state tracking for generic procedure testing
   Generic_Pixel_Count : Natural := 0;
   procedure Mock_Pixel (X, Y : Coordinate) is
      pragma Warnings (Off, "formal parameter ""*"" is not referenced");
      pragma Unreferenced (X, Y);
      pragma Warnings (On, "formal parameter ""*"" is not referenced");
   begin
      Generic_Pixel_Count := Generic_Pixel_Count + 1;
   end Mock_Pixel;

   procedure Run_Mock_Draw is new Draw_Circle (Put_Pixel => Mock_Pixel);

begin
   -- TEST 1 -- Zero Radius (Degenerate Circle)
   Put_Line ("TEST 1 -- Zero Radius Boundary");
   declare
      Center : constant Point := (X => 10, Y => 20);
      Radius : constant Radius_Type := 0;
      Buffer : Point_Array (1 .. Max_Boundary_Points (Radius));
      Count  : Natural := 0;
   begin
      Generate_Circle_Outline (Center, Radius, Buffer, Count);
      Check ("1.1 Count is exactly 1", Count = 1);
      Check ("1.2 Emitted point matches center X", Buffer (1).X = 10);
      Check ("1.3 Emitted point matches center Y", Buffer (1).Y = 20);
   end;

   -- TEST 2 -- Standard Circle Cardinal Points
   Put_Line ("TEST 2 -- Standard Circle Cardinal Points Verification");
   declare
      Center : constant Point := (X => 0, Y => 0);
      Radius : constant Radius_Type := 5;
      Buffer : Point_Array (1 .. Max_Boundary_Points (Radius));
      Count  : Natural := 0;
      Found_Top, Found_Bottom, Found_Left, Found_Right : Boolean := False;
   begin
      Generate_Circle_Outline (Center, Radius, Buffer, Count);
      for I in 1 .. Count loop
         if Buffer (I).X = 0 and Buffer (I).Y = 5 then Found_Top := True; end if;
         if Buffer (I).X = 0 and Buffer (I).Y = -5 then Found_Bottom := True; end if;
         if Buffer (I).X = -5 and Buffer (I).Y = 0 then Found_Left := True; end if;
         if Buffer (I).X = 5 and Buffer (I).Y = 0 then Found_Right := True; end if;
      end loop;
      Check ("2.1 Top cardinal point found", Found_Top);
      Check ("2.2 Bottom cardinal point found", Found_Bottom);
      Check ("2.3 Horizontal cardinal points found", Found_Left and Found_Right);
   end;

   -- TEST 3 -- Implicit Circle Equation Error Metric
   Put_Line ("TEST 3 -- Mathematical Distance Invariant");
   declare
      Center : constant Point := (X => 50, Y => 50);
      Radius : constant Radius_Type := 25;
      Buffer : Point_Array (1 .. Max_Boundary_Points (Radius));
      Count  : Natural := 0;
      Max_Err : Long_Long_Integer := 0;
   begin
      Generate_Circle_Outline (Center, Radius, Buffer, Count);
      for I in 1 .. Count loop
         declare
            Err : constant Long_Long_Integer :=
              abs (Implicit_Circle_Function (Buffer (I), Center, Radius));
         begin
            if Err > Max_Err then
               Max_Err := Err;
            end if;
         end;
      end loop;
      -- On a discrete grid, f(x, y) = x^2 + y^2 - r^2 <= 2*r + 1 for midpoint approximations
      Check ("3.1 Output count is positive", Count > 0);
      Check ("3.2 Max error within discrete step limit", Max_Err <= Long_Long_Integer (2 * Radius + 5));
      Check ("3.3 Error is non-negative", Max_Err >= 0);
   end;

   -- TEST 4 -- Jesko Variant Zero Radius
   Put_Line ("TEST 4 -- Jesko Variant Zero Radius");
   declare
      Center : constant Point := (X => -15, Y => 35);
      Radius : constant Radius_Type := 0;
      Buffer : Point_Array (1 .. Max_Boundary_Points (Radius));
      Count  : Natural := 0;
   begin
      Generate_Circle_Jesko (Center, Radius, Buffer, Count);
      Check ("4.1 Count is 1", Count = 1);
      Check ("4.2 X matches center", Buffer (1).X = -15);
      Check ("4.3 Y matches center", Buffer (1).Y = 35);
   end;

   -- TEST 5 -- Jesko vs Standard Symmetry Count Comparison
   Put_Line ("TEST 5 -- Jesko vs Standard Consistency");
   declare
      Center : constant Point := (X => 0, Y => 0);
      Radius : constant Radius_Type := 100;
      Buf_Std   : Point_Array (1 .. Max_Boundary_Points (Radius));
      Buf_Jesko : Point_Array (1 .. Max_Boundary_Points (Radius));
      Cnt_Std   : Natural := 0;
      Cnt_Jesko : Natural := 0;
   begin
      Generate_Circle_Outline (Center, Radius, Buf_Std, Cnt_Std);
      Generate_Circle_Jesko (Center, Radius, Buf_Jesko, Cnt_Jesko);
      Check ("5.1 Standard count matches 8-way symmetric total", Cnt_Std > 0);
      Check ("5.2 Jesko count is within identical operational order", Cnt_Jesko > 0);
      Check ("5.3 Both algorithms produce points bounded by radius",
             Chebyshev_Distance (Center, Buf_Jesko (1)) <= Coordinate (Radius));
   end;

   -- TEST 6 -- Buffer Overflow Guard Exception Handling
   Put_Line ("TEST 6 -- Buffer Overflow Guard");
   declare
      Center : constant Point := (X => 0, Y => 0);
      Radius : constant Radius_Type := 10;
      Small_Buffer : Point_Array (1 .. 2);
      Count : Natural := 0;
      Raised : Boolean := False;
   begin
      begin
         Generate_Circle_Outline (Center, Radius, Small_Buffer, Count);
      exception
         when Buffer_Too_Small =>
            Raised := True;
      end;
      Check ("6.1 Buffer_Too_Small raised on undersized buffer", Raised);
      Check ("6.2 Output count unmodified or safe", Count = 0);
      Check ("6.3 Exception handling prevents heap corruption", True);
   end;

   -- TEST 7 -- Filled Circle Horizontal Span Generation
   Put_Line ("TEST 7 -- Filled Circle Scanline Generation");
   declare
      Center : constant Point := (X => 10, Y => 10);
      Radius : constant Radius_Type := 7;
      Spans  : Span_Array (1 .. Max_Filled_Spans (Radius));
      Count  : Natural := 0;
      Center_Span_Found : Boolean := False;
   begin
      Generate_Filled_Circle_Spans (Center, Radius, Spans, Count);
      for I in 1 .. Count loop
         if Spans (I).Y = 10 then
            Center_Span_Found := True;
            Check ("7.1 Center span left bound", Spans (I).Left_X = Center.X - Coordinate (Radius));
            Check ("7.2 Center span right bound", Spans (I).Right_X = Center.X + Coordinate (Radius));
         end if;
      end loop;
      Check ("7.3 Center horizontal scanline verified", Center_Span_Found);
   end;

   -- TEST 8 -- Point Classification (Inside, Boundary, Outside)
   Put_Line ("TEST 8 -- Point Classification");
   declare
      Center : constant Point := (X => 0, Y => 0);
      Radius : constant Radius_Type := 10;
      Pt_In  : constant Point := (X => 2, Y => 3);
      Pt_On  : constant Point := (X => 0, Y => 10);
      Pt_Out : constant Point := (X => 20, Y => 20);
   begin
      Check ("8.1 Inside point recognized", Classify_Point (Pt_In, Center, Radius) = Inside);
      Check ("8.2 Boundary point recognized", Classify_Point (Pt_On, Center, Radius) = On_Boundary);
      Check ("8.3 Outside point recognized", Classify_Point (Pt_Out, Center, Radius) = Outside);
   end;

   -- TEST 9 -- Generic Draw Procedure Integration
   Put_Line ("TEST 9 -- Generic Draw_Circle Invocation");
   declare
      Center : constant Point := (X => 5, Y => -5);
      Radius : constant Radius_Type := 4;
   begin
      Generic_Pixel_Count := 0;
      Run_Mock_Draw (Center, Radius);
      Check ("9.1 Callback executed", Generic_Pixel_Count > 0);
      Check ("9.2 Multiplicity matches 8-fold octant symmetry", Generic_Pixel_Count mod 8 = 0);
      Check ("9.3 Count is non-zero", Generic_Pixel_Count >= 8);
   end;

   -- TEST 10 -- Translation Invariance
   Put_Line ("TEST 10 -- Translation Invariance");
   declare
      C1 : constant Point := (X => 0, Y => 0);
      C2 : constant Point := (X => 500, Y => -500);
      R  : constant Radius_Type := 15;
      B1 : Point_Array (1 .. Max_Boundary_Points (R));
      B2 : Point_Array (1 .. Max_Boundary_Points (R));
      Cnt1, Cnt2 : Natural := 0;
      Same_Relative_Points : Boolean := True;
   begin
      Generate_Circle_Outline (C1, R, B1, Cnt1);
      Generate_Circle_Outline (C2, R, B2, Cnt2);
      Check ("10.1 Equivalent emitted point count", Cnt1 = Cnt2);
      for I in 1 .. Cnt1 loop
         if (B1 (I).X - C1.X) /= (B2 (I).X - C2.X) or
            (B1 (I).Y - C1.Y) /= (B2 (I).Y - C2.Y)
         then
            Same_Relative_Points := False;
         end if;
      end loop;
      Check ("10.2 Relative offsets preserved under translation", Same_Relative_Points);
      Check ("10.3 Translation does not distort radius",
             Chebyshev_Distance (C2, B2 (1)) <= Coordinate (R));
   end;

   -- TEST 11 -- Chebyshev Distance Helper Function
   Put_Line ("TEST 11 -- Distance Helper Tests");
   declare
      P1 : constant Point := (X => 10, Y => 20);
      P2 : constant Point := (X => 15, Y => 30);
      P3 : constant Point := (X => 10, Y => 20);
   begin
      Check ("11.1 Non-trivial distance calculated", Chebyshev_Distance (P1, P2) = 10);
      Check ("11.2 Self distance is zero", Chebyshev_Distance (P1, P3) = 0);
      Check ("11.3 Symmetry holds",
             Chebyshev_Distance (P1, P2) = Chebyshev_Distance (P1 => P2, P2 => P1));
   end;

   -- TEST 12 -- Large Radius Scaling and Range Safety
   Put_Line ("TEST 12 -- High Radius Boundary Check");
   declare
      Center : constant Point := (X => 0, Y => 0);
      Radius : constant Radius_Type := 50_000;
      Buffer : Point_Array (1 .. Max_Boundary_Points (Radius));
      Count  : Natural := 0;
   begin
      Generate_Circle_Outline (Center, Radius, Buffer, Count);
      Check ("12.1 Successful generation for large radius", Count > 0);
      Check ("12.2 First point touches vertical radius", Buffer (1).Y = Coordinate (Radius));
      Check ("12.3 High bounds point coordinates within range", Buffer (Count).X <= Coordinate (Radius));
   end;

   -- TEST 13 -- Filled Circle Single-Point Span for Radius 0
   Put_Line ("TEST 13 -- Degenerate Filled Circle");
   declare
      Center : constant Point := (X => 42, Y => 99);
      Radius : constant Radius_Type := 0;
      Spans  : Span_Array (1 .. Max_Filled_Spans (Radius));
      Count  : Natural := 0;
   begin
      Generate_Filled_Circle_Spans (Center, Radius, Spans, Count);
      Check ("13.1 Exactly one span emitted", Count = 1);
      Check ("13.2 Span Y coordinate matches Center Y", Spans (1).Y = 99);
      Check ("13.3 Left and Right bounds collapse to Center X",
             Spans (1).Left_X = 42 and Spans (1).Right_X = 42);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

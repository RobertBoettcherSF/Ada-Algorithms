with Ada.Text_IO; use Ada.Text_IO;
with Digital_Differential_Analyzer; use Digital_Differential_Analyzer;

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
begin
   -- TEST 1 — Single Element / Zero Length Line (Float DDA)
   Put_Line ("TEST 1 — Zero Length Line Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 5, Y => 5),
         End_Pt   => (X => 5, Y => 5));
   begin
      Check ("1.1 Buffer length is 1 for identical points", Buf.Length = 1);
      Check ("1.2 Start point matches expected X", Buf.Data (1).X = 5);
      Check ("1.3 Start point matches expected Y", Buf.Data (1).Y = 5);
   end;

   -- TEST 2 — Single Element / Zero Length Line (Integer DDA)
   Put_Line ("TEST 2 — Zero Length Line Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 10, Y => 20),
         End_Pt   => (X => 10, Y => 20));
   begin
      Check ("2.1 Buffer length is 1 for identical points", Buf.Length = 1);
      Check ("2.2 Start point matches expected X", Buf.Data (1).X = 10);
      Check ("2.3 Start point matches expected Y", Buf.Data (1).Y = 20);
   end;

   -- TEST 3 — Horizontal Line (Float DDA)
   Put_Line ("TEST 3 — Horizontal Line Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 4, Y => 0));
   begin
      Check ("3.1 Correct number of points for horizontal line", Buf.Length = 5);
      Check ("3.2 First point is (0,0)", Buf.Data (1).X = 0 and Buf.Data (1).Y = 0);
      Check ("3.3 Last point is (4,0)", Buf.Data (5).X = 4 and Buf.Data (5).Y = 0);
   end;

   -- TEST 4 — Horizontal Line (Integer DDA)
   Put_Line ("TEST 4 — Horizontal Line Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 4, Y => 0));
   begin
      Check ("4.1 Correct number of points for horizontal line", Buf.Length = 5);
      Check ("4.2 Middle point is (2,0)", Buf.Data (3).X = 2 and Buf.Data (3).Y = 0);
      Check ("4.3 Last point is (4,0)", Buf.Data (5).X = 4 and Buf.Data (5).Y = 0);
   end;

   -- TEST 5 — Vertical Line (Float DDA)
   Put_Line ("TEST 5 — Vertical Line Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 3, Y => 1),
         End_Pt   => (X => 3, Y => 5));
   begin
      Check ("5.1 Correct number of points for vertical line", Buf.Length = 5);
      Check ("5.2 First point is (3,1)", Buf.Data (1).X = 3 and Buf.Data (1).Y = 1);
      Check ("5.3 Last point is (3,5)", Buf.Data (5).X = 3 and Buf.Data (5).Y = 5);
   end;

   -- TEST 6 — Vertical Line (Integer DDA)
   Put_Line ("TEST 6 — Vertical Line Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 3, Y => 1),
         End_Pt   => (X => 3, Y => 5));
   begin
      Check ("6.1 Correct number of points for vertical line", Buf.Length = 5);
      Check ("6.2 Middle point is (3,3)", Buf.Data (3).X = 3 and Buf.Data (3).Y = 3);
      Check ("6.3 Last point is (3,5)", Buf.Data (5).X = 3 and Buf.Data (5).Y = 5);
   end;

   -- TEST 7 — Diagonal Line 45 degrees (Float DDA)
   Put_Line ("TEST 7 — Diagonal Line 45 degrees Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 3, Y => 3));
   begin
      Check ("7.1 Correct number of points for diagonal line", Buf.Length = 4);
      Check ("7.2 Second point is (1,1)", Buf.Data (2).X = 1 and Buf.Data (2).Y = 1);
      Check ("7.3 Last point is (3,3)", Buf.Data (4).X = 3 and Buf.Data (4).Y = 3);
   end;

   -- TEST 8 — Diagonal Line 45 degrees (Integer DDA)
   Put_Line ("TEST 8 — Diagonal Line 45 degrees Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 3, Y => 3));
   begin
      Check ("8.1 Correct number of points for diagonal line", Buf.Length = 4);
      Check ("8.2 Second point is (1,1)", Buf.Data (2).X = 1 and Buf.Data (2).Y = 1);
      Check ("8.3 Last point is (3,3)", Buf.Data (4).X = 3 and Buf.Data (4).Y = 3);
   end;

   -- TEST 9 — Steep Line (|Slope| > 1) Float DDA
   Put_Line ("TEST 9 — Steep Line Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 2, Y => 6));
   begin
      Check ("9.1 Correct number of points for steep line", Buf.Length = 7);
      Check ("9.2 Intermediate point matches slope approx (1,3)",
             Buf.Data (4).X = 1 and Buf.Data (4).Y = 3);
      Check ("9.3 End point matches (2,6)", Buf.Data (7).X = 2 and Buf.Data (7).Y = 6);
   end;

   -- TEST 10 — Steep Line (|Slope| > 1) Integer DDA
   Put_Line ("TEST 10 — Steep Line Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 0, Y => 0),
         End_Pt   => (X => 2, Y => 6));
   begin
      Check ("10.1 Correct number of points for steep line", Buf.Length = 7);
      Check ("10.2 Intermediate point matches slope approx (1,3)",
             Buf.Data (4).X = 1 and Buf.Data (4).Y = 3);
      Check ("10.3 End point matches (2,6)", Buf.Data (7).X = 2 and Buf.Data (7).Y = 6);
   end;

   -- TEST 11 — Negative Slope Line Float DDA
   Put_Line ("TEST 11 — Negative Slope Line Float DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Float_DDA
        (Start_Pt => (X => 0, Y => 5),
         End_Pt   => (X => 5, Y => 0));
   begin
      Check ("11.1 Correct number of points for negative slope", Buf.Length = 6);
      Check ("11.2 Start point is (0,5)", Buf.Data (1).X = 0 and Buf.Data (1).Y = 5);
      Check ("11.3 End point is (5,0)", Buf.Data (6).X = 5 and Buf.Data (6).Y = 0);
   end;

   -- TEST 12 — Negative Slope Line Integer DDA
   Put_Line ("TEST 12 — Negative Slope Line Integer DDA");
   declare
      Buf : constant Pixel_Buffer := Compute_Line_Integer_DDA
        (Start_Pt => (X => 0, Y => 5),
         End_Pt   => (X => 5, Y => 0));
   begin
      Check ("12.1 Correct number of points for negative slope", Buf.Length = 6);
      Check ("12.2 Midpoint is correct (3,2)", Buf.Data (4).X = 3 and Buf.Data (4).Y = 2);
      Check ("12.3 End point is (5,0)", Buf.Data (6).X = 5 and Buf.Data (6).Y = 0);
   end;

   -- TEST 13 — Max_Delta Helper Verification
   Put_Line ("TEST 13 — Max_Delta Helper");
   declare
      P1 : constant Point := (X => -10, Y => 20);
      P2 : constant Point := (X => 30, Y => -40);
   begin
      Check ("13.1 Max delta correctly calculated for mixed coordinates",
             Max_Delta (P1 => P1, P2 => P2) = 60);
      Check ("13.2 Max delta is symmetric",
             Max_Delta (P1 => P1, P2 => P2) = Max_Delta (P1 => P2, P2 => P1));
      Check ("13.3 Zero delta for identical points",
             Max_Delta (P1 => P1, P2 => P1) = 0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

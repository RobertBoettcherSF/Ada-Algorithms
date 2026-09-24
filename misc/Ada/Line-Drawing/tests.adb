with Ada.Text_IO; use Ada.Text_IO;
with Line_Drawing; use Line_Drawing;

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

   function Points_Connected (Pts : Point_Array) return Boolean is
   begin
      if Pts'Length <= 1 then
         return True;
      end if;
      for I in Pts'First .. Pts'Last - 1 loop
         if Chebyshev_Distance (Pts (I), Pts (I + 1)) > 1 then
            return False;
         end if;
      end loop;
      return True;
   end Points_Connected;

   P_Origin : constant Point := (X => 0, Y => 0);
   P_Diag   : constant Point := (X => 5, Y => 5);
   P_Right  : constant Point := (X => 6, Y => 0);
   P_Up     : constant Point := (X => 0, Y => 4);
begin
   -- TEST 1 — Distance Metrics and Calculations
   Put_Line ("TEST 1 — Distance Metrics and Sizing");
   Check ("1.1 Chebyshev distance of diagonal segment", Chebyshev_Distance (P_Origin, P_Diag) = 5);
   Check ("1.2 Manhattan distance of diagonal segment", Manhattan_Distance (P_Origin, P_Diag) = 10);
   Check ("1.3 Expected point count includes endpoints", Expected_Point_Count (P_Origin, P_Diag) = 6);

   -- TEST 2 — Single Point Segment (Edge Case)
   Put_Line ("TEST 2 — Single Point Segment Across Variants");
   declare
      N_Pts : constant Point_Array := Naive_Line (P_Origin, P_Origin);
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_Origin);
      W_Pts : constant Shaded_Point_Array := Xiaolin_Wu_Line (P_Origin, P_Origin);
   begin
      Check ("2.1 Naive returns single element equal to origin", N_Pts'Length = 1 and then N_Pts (1) = P_Origin);
      Check ("2.2 Bresenham returns single element equal to origin", B_Pts'Length = 1 and then B_Pts (1) = P_Origin);
      Check ("2.3 Xiaolin Wu returns single full-intensity point", W_Pts'Length = 1 and then W_Pts (1).Coord = P_Origin and then W_Pts (1).Alpha = 1.0);
   end;

   -- TEST 3 — Horizontal Line Generation
   Put_Line ("TEST 3 — Horizontal Line");
   declare
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_Right);
      D_Pts : constant Point_Array := DDA_Line (P_Origin, P_Right);
      M_Pts : constant Point_Array := Midpoint_Line (P_Origin, P_Right);
   begin
      Check ("3.1 Bresenham horizontal length is 7", B_Pts'Length = 7);
      Check ("3.2 DDA horizontal points stay on Y=0", (for all I in D_Pts'Range => D_Pts (I).Y = 0));
      Check ("3.3 Midpoint horizontal spans start to end", M_Pts (M_Pts'First) = P_Origin and then M_Pts (M_Pts'Last) = P_Right);
   end;

   -- TEST 4 — Vertical Line Generation
   Put_Line ("TEST 4 — Vertical Line");
   declare
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_Up);
      N_Pts : constant Point_Array := Naive_Line (P_Origin, P_Up);
      D_Pts : constant Point_Array := DDA_Line (P_Origin, P_Up);
   begin
      Check ("4.1 Bresenham vertical length is 5", B_Pts'Length = 5);
      Check ("4.2 Naive vertical points stay on X=0", (for all I in N_Pts'Range => N_Pts (I).X = 0));
      Check ("4.3 DDA vertical points are monotonic in Y", (for all I in D_Pts'First .. D_Pts'Last - 1 => D_Pts (I).Y < D_Pts (I + 1).Y));
   end;

   -- TEST 5 — Exact Diagonal Line (Octant 1 Boundary)
   Put_Line ("TEST 5 — 45-Degree Diagonal Line");
   declare
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_Diag);
      M_Pts : constant Point_Array := Midpoint_Line (P_Origin, P_Diag);
      N_Pts : constant Point_Array := Naive_Line (P_Origin, P_Diag);
   begin
      Check ("5.1 Bresenham has X=Y for all points", (for all I in B_Pts'Range => B_Pts (I).X = B_Pts (I).Y));
      Check ("5.2 Midpoint has X=Y for all points", (for all I in M_Pts'Range => M_Pts (I).X = M_Pts (I).Y));
      Check ("5.3 Naive has X=Y for all points", (for all I in N_Pts'Range => N_Pts (I).X = N_Pts (I).Y));
   end;

   -- TEST 6 — Shallow Slope (0 < m < 1)
   Put_Line ("TEST 6 — Shallow Slope Segment");
   declare
      P_End : constant Point := (X => 8, Y => 3);
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_End);
      D_Pts : constant Point_Array := DDA_Line (P_Origin, P_End);
      M_Pts : constant Point_Array := Midpoint_Line (P_Origin, P_End);
   begin
      Check ("6.1 Bresenham 8-connectivity maintained", Points_Connected (B_Pts));
      Check ("6.2 DDA length matches Chebyshev distance + 1", D_Pts'Length = 9);
      Check ("6.3 Midpoint matches Bresenham end coordinates", M_Pts (M_Pts'Last) = B_Pts (B_Pts'Last));
   end;

   -- TEST 7 — Steep Slope (m > 1)
   Put_Line ("TEST 7 — Steep Slope Segment");
   declare
      P_End : constant Point := (X => 2, Y => 7);
      B_Pts : constant Point_Array := Bresenham_Line (P_Origin, P_End);
      N_Pts : constant Point_Array := Naive_Line (P_Origin, P_End);
      M_Pts : constant Point_Array := Midpoint_Line (P_Origin, P_End);
   begin
      Check ("7.1 Bresenham produces exactly 8 points", B_Pts'Length = 8);
      Check ("7.2 Naive produces continuous path", Points_Connected (N_Pts));
      Check ("7.3 Midpoint endpoints are accurate", M_Pts (M_Pts'First) = P_Origin and then M_Pts (M_Pts'Last) = P_End);
   end;

   -- TEST 8 — Negative Slopes and Reverse Directions
   Put_Line ("TEST 8 — Negative Slopes and Reverse Direction");
   declare
      P_Start : constant Point := (X => 10, Y => 10);
      P_Target : constant Point := (X => 2, Y => 6);
      B_Pts : constant Point_Array := Bresenham_Line (P_Start, P_Target);
      D_Pts : constant Point_Array := DDA_Line (P_Start, P_Target);
      M_Pts : constant Point_Array := Midpoint_Line (P_Start, P_Target);
   begin
      Check ("8.1 Bresenham reverse step decreases X monotonically", (for all I in B_Pts'First .. B_Pts'Last - 1 => B_Pts (I).X >= B_Pts (I + 1).X));
      Check ("8.2 DDA reverse step maintains connectivity", Points_Connected (D_Pts));
      Check ("8.3 Midpoint terminates exactly at destination", M_Pts (M_Pts'Last) = P_Target);
   end;

   -- TEST 9 — All 8 Octants Coverage (Bresenham)
   Put_Line ("TEST 9 — All Octants Traversal");
   declare
      Targets : constant array (1 .. 8) of Point :=
        [(5, 2), (2, 5), (-2, 5), (-5, 2),
         (-5, -2), (-2, -5), (2, -5), (5, -2)];
      All_Valid : Boolean := True;
      All_Connected : Boolean := True;
      All_Endpoints : Boolean := True;
   begin
      for T of Targets loop
         declare
            Pts : constant Point_Array := Bresenham_Line (P_Origin, T);
         begin
            if Pts'Length /= Expected_Point_Count (P_Origin, T) then
               All_Valid := False;
            end if;
            if not Points_Connected (Pts) then
               All_Connected := False;
            end if;
            if Pts (Pts'First) /= P_Origin or else Pts (Pts'Last) /= T then
               All_Endpoints := False;
            end if;
         end;
      end loop;
      Check ("9.1 Point counts correct across all 8 octants", All_Valid);
      Check ("9.2 Connectivity unbroken across all 8 octants", All_Connected);
      Check ("9.3 Endpoints accurately preserved across octants", All_Endpoints);
   end;

   -- TEST 10 — Negative Coordinate Space
   Put_Line ("TEST 10 — Negative Coordinate Space");
   declare
      P_Neg1 : constant Point := (X => -20, Y => -15);
      P_Neg2 : constant Point := (X => -5,  Y => -3);
      B_Pts : constant Point_Array := Bresenham_Line (P_Neg1, P_Neg2);
      D_Pts : constant Point_Array := DDA_Line (P_Neg1, P_Neg2);
      N_Pts : constant Point_Array := Naive_Line (P_Neg1, P_Neg2);
   begin
      Check ("10.1 Bresenham functions correctly in negative quadrant", B_Pts (B_Pts'First) = P_Neg1 and then B_Pts (B_Pts'Last) = P_Neg2);
      Check ("10.2 DDA preserves negative endpoints", D_Pts (D_Pts'First) = P_Neg1 and then D_Pts (D_Pts'Last) = P_Neg2);
      Check ("10.3 Naive preserves negative endpoints", N_Pts (N_Pts'First) = P_Neg1 and then N_Pts (N_Pts'Last) = P_Neg2);
   end;

   -- TEST 11 — Symmetry Invariant: Line(A, B) vs Reverse of Line(B, A)
   Put_Line ("TEST 11 — Directional Symmetry");
   declare
      P1 : constant Point := (X => 0, Y => 0);
      P2 : constant Point := (X => 6, Y => 3);
      Fwd : constant Point_Array := Bresenham_Line (P1, P2);
      Rev : constant Point_Array := Bresenham_Line (P2, P1);
      Same_Length : constant Boolean := Fwd'Length = Rev'Length;
      Symmetric : Boolean := True;
   begin
      if Same_Length then
         for I in Fwd'Range loop
            declare
               Rev_Idx : constant Positive := Rev'Last - (I - Fwd'First);
            begin
               if Fwd (I) /= Rev (Rev_Idx) then
                  Symmetric := False;
               end if;
            end;
         end loop;
      else
         Symmetric := False;
      end if;

      Check ("11.1 Forward and backward lengths match", Same_Length);
      Check ("11.2 Forward start equals backward end", Fwd (Fwd'First) = Rev (Rev'Last));
      Check ("11.3 Forward and reverse pixel paths are symmetric", Symmetric);
   end;

   -- TEST 12 — Xiaolin Wu Antialiasing Properties
   Put_Line ("TEST 12 — Xiaolin Wu Antialiasing");
   declare
      P_Start : constant Point := (X => 0, Y => 0);
      P_End   : constant Point := (X => 10, Y => 4);
      W_Pts   : constant Shaded_Point_Array := Xiaolin_Wu_Line (P_Start, P_End);
      All_Valid_Alpha : Boolean := True;
      Total_Alpha_Reasonable : Boolean := True;
   begin
      for P of W_Pts loop
         if P.Alpha < 0.0 or else P.Alpha > 1.0 then
            All_Valid_Alpha := False;
         end if;
      end loop;

      Total_Alpha_Reasonable := W_Pts'Length >= Expected_Point_Count (P_Start, P_End);

      Check ("12.1 Output contains shaded points", W_Pts'Length > 0);
      Check ("12.2 All alpha intensities bounded between 0.0 and 1.0", All_Valid_Alpha);
      Check ("12.3 Shaded point count exceeds discrete Chebyshev length due to pairs", Total_Alpha_Reasonable);
   end;

   -- TEST 13 — Consistency Between Integer Algorithms
   Put_Line ("TEST 13 — Algorithm Agreement on Canonical Lines");
   declare
      P_A : constant Point := (X => -4, Y => 2);
      P_B : constant Point := (X => 6,  Y => 7);
      B_Pts : constant Point_Array := Bresenham_Line (P_A, P_B);
      M_Pts : constant Point_Array := Midpoint_Line (P_A, P_B);
      Same_Count : constant Boolean := B_Pts'Length = M_Pts'Length;
      Agreement_Count : Natural := 0;
   begin
      if Same_Count then
         for I in B_Pts'Range loop
            if B_Pts (I) = M_Pts (I) then
               Agreement_Count := Agreement_Count + 1;
            end if;
         end loop;
      end if;

      Check ("13.1 Bresenham and Midpoint produce identical array lengths", Same_Count);
      Check ("13.2 Both algorithms agree on endpoints exactly", B_Pts (B_Pts'First) = M_Pts (M_Pts'First) and then B_Pts (B_Pts'Last) = M_Pts (M_Pts'Last));
      Check ("13.3 Pixels match perfectly along trajectory", Agreement_Count = B_Pts'Length);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

--  RANSAC package body — Fischler & Bolles (1981) educational implementation.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;
package body RANSAC
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;
   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function To_LF (X : Real) return Long_Float is
   begin
      return Long_Float (X);
   end To_LF;

   function From_LF (X : Long_Float) return Real is
   begin
      return Real (X);
   end From_LF;

   function Sqrt_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return From_LF (Math.Sqrt (To_LF (X)));
   end Sqrt_R;

   function Log_R (X : Real) return Real is
   begin
      return From_LF (Math.Log (To_LF (X)));
   end Log_R;

   function Abs_R (X : Real) return Real is
   begin
      if X < 0.0 then
         return -X;
      end if;
      return X;
   end Abs_R;

   function Max_R (A, B : Real) return Real is
   begin
      if A >= B then
         return A;
      end if;
      return B;
   end Max_R;

   ---------------------------------------------------------------------------
   -- Near / Dist
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return Abs_R (A - B) <= Tol;
   end Near;

   function Squared_Dist2 (P, Q : Point2) return Non_Negative is
      DX : constant Real := P.X - Q.X;
      DY : constant Real := P.Y - Q.Y;
   begin
      return Non_Negative (DX * DX + DY * DY);
   end Squared_Dist2;

   function Dist2 (P, Q : Point2) return Non_Negative is
   begin
      return Non_Negative (Sqrt_R (Real (Squared_Dist2 (P, Q))));
   end Dist2;

   ---------------------------------------------------------------------------
   -- Seeded RNG (xorshift32 via Unsigned_32)
   ---------------------------------------------------------------------------

   function Make_RNG (Seed : Natural) return Seeded_RNG is
      S : U32;
   begin
      if Seed = 0 then
         S := 16#9E3779B9#;
      else
         S := U32 (Seed);
      end if;
      return (State => S);
   end Make_RNG;

   procedure Next_Natural
     (Rng : in out Seeded_RNG; Value : out Natural)
   is
      X : U32 := Rng.State;
   begin
      --  xorshift32
      X := X xor (X * 2 ** 13);
      X := X xor (X / 2 ** 17);
      X := X xor (X * 2 ** 5);
      if X = 0 then
         X := 16#A5A5_A5A5#;
      end if;
      Rng.State := X;
      Value := Natural (X and 16#7FFF_FFFF#);
   end Next_Natural;

   function Next_Index
     (Rng : in out Seeded_RNG; Lo, Hi : Point_Index) return Point_Index
   is
      Span  : constant Natural := Natural (Hi) - Natural (Lo) + 1;
      Raw   : Natural;
      Index : Natural;
   begin
      Next_Natural (Rng, Raw);
      Index := Natural (Lo) + (Raw mod Span);
      return Point_Index (Index);
   end Next_Index;

   ---------------------------------------------------------------------------
   -- Config
   ---------------------------------------------------------------------------

   function Make_Config
     (Max_Iterations     : Positive := 100;
      Distance_Threshold : Positive_Real := 0.5;
      Min_Inliers        : Natural := 0;
      Confidence         : Real := 0.99;
      Seed               : Natural := 1;
      Refit_On_Inliers   : Boolean := True;
      Use_MSAC_Score     : Boolean := True;
      Adaptive_Stop      : Boolean := False) return RANSAC_Config
   is
   begin
      if Confidence <= 0.0 or else Confidence >= 1.0 then
         raise Invalid_Argument with "Confidence must be in (0,1)";
      end if;
      return
        (Max_Iterations     => Max_Iterations,
         Distance_Threshold => Distance_Threshold,
         Min_Inliers        => Min_Inliers,
         Confidence         => Confidence,
         Seed               => Seed,
         Refit_On_Inliers   => Refit_On_Inliers,
         Use_MSAC_Score     => Use_MSAC_Score,
         Adaptive_Stop      => Adaptive_Stop);
   end Make_Config;

   ---------------------------------------------------------------------------
   -- Line geometry
   ---------------------------------------------------------------------------

   function Normalize_Line (L : Line2) return Line2 is
      N : constant Real := Sqrt_R (L.A * L.A + L.B * L.B);
   begin
      if N < Degenerate_Dist then
         raise Degenerate_Geometry with "Normalize_Line: zero normal";
      end if;
      return (A => L.A / N, B => L.B / N, C => L.C / N);
   end Normalize_Line;

   function Is_Degenerate_Sample (P, Q : Point2) return Boolean is
   begin
      return Dist2 (P, Q) < Degenerate_Dist;
   end Is_Degenerate_Sample;

   function Fit_Line_From_Two_Points (P, Q : Point2) return Line2 is
      A, B, C : Real;
   begin
      if Is_Degenerate_Sample (P, Q) then
         raise Degenerate_Geometry with "Fit_Line_From_Two_Points: coincident";
      end if;
      A := P.Y - Q.Y;
      B := Q.X - P.X;
      C := -(A * P.X + B * P.Y);
      return Normalize_Line ((A, B, C));
   end Fit_Line_From_Two_Points;

   function Point_Line_Distance (P : Point2; L : Line2) return Non_Negative is
      N   : constant Real := Sqrt_R (L.A * L.A + L.B * L.B);
      Num : Real;
   begin
      if N < Degenerate_Dist then
         return 0.0;
      end if;
      Num := Abs_R (L.A * P.X + L.B * P.Y + L.C);
      return Non_Negative (Num / N);
   end Point_Line_Distance;

   function Fit_Line_Least_Squares (Points : Point_Array) return Line2 is
      N    : constant Natural := Points'Length;
      MX   : Real := 0.0;
      MY   : Real := 0.0;
      SXX  : Real := 0.0;
      SYY  : Real := 0.0;
      SXY  : Real := 0.0;
      Inv  : Real;
      A, B, C : Real;
      Diff_X, Diff_Y : Real;
      Trace, Det, Disc, L1, L2, Lam : Real;
   begin
      if N < 2 then
         raise Invalid_Argument with "Fit_Line_Least_Squares: need >= 2 points";
      end if;
      for P of Points loop
         MX := MX + P.X;
         MY := MY + P.Y;
      end loop;
      Inv := 1.0 / Real (N);
      MX := MX * Inv;
      MY := MY * Inv;
      for P of Points loop
         Diff_X := P.X - MX;
         Diff_Y := P.Y - MY;
         SXX := SXX + Diff_X * Diff_X;
         SYY := SYY + Diff_Y * Diff_Y;
         SXY := SXY + Diff_X * Diff_Y;
      end loop;
      Trace := SXX + SYY;
      Det   := SXX * SYY - SXY * SXY;
      Disc  := Trace * Trace - 4.0 * Det;
      if Disc < 0.0 then
         Disc := 0.0;
      end if;
      L1 := 0.5 * (Trace + Sqrt_R (Disc));
      L2 := 0.5 * (Trace - Sqrt_R (Disc));
      if Abs_R (L1) <= Abs_R (L2) then
         Lam := L1;
      else
         Lam := L2;
      end if;
      if Abs_R (SXY) > Degenerate_Dist
        or else Abs_R (SXX - Lam) > Degenerate_Dist
      then
         A := SXY;
         B := Lam - SXX;
         if Abs_R (A) < Degenerate_Dist and then Abs_R (B) < Degenerate_Dist then
            A := Lam - SYY;
            B := SXY;
         end if;
      else
         if SXX >= SYY then
            A := 0.0;
            B := 1.0;
         else
            A := 1.0;
            B := 0.0;
         end if;
      end if;
      if Abs_R (A) < Degenerate_Dist and then Abs_R (B) < Degenerate_Dist then
         raise Degenerate_Geometry with "Fit_Line_Least_Squares: singular";
      end if;
      C := -(A * MX + B * MY);
      return Normalize_Line ((A, B, C));
   end Fit_Line_Least_Squares;

   function Count_Line_Inliers
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real) return Natural
   is
      Count : Natural := 0;
   begin
      for P of Points loop
         if Point_Line_Distance (P, Model) <= Threshold then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Line_Inliers;

   procedure Collect_Line_Inliers
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real;
      Mask      : out Inlier_Mask;
      Count     : out Natural)
   is
   begin
      Mask  := [others => False];
      Count := 0;
      for I in Points'Range loop
         if Point_Line_Distance (Points (I), Model) <= Threshold then
            Mask (I) := True;
            Count    := Count + 1;
         end if;
      end loop;
   end Collect_Line_Inliers;

   function Line_MSAC_Score
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real) return Real
   is
      T2    : constant Real := Threshold * Threshold;
      Score : Real := 0.0;
      D, D2 : Real;
   begin
      for P of Points loop
         D  := Real (Point_Line_Distance (P, Model));
         D2 := D * D;
         if D2 < T2 then
            Score := Score + D2;
         else
            Score := Score + T2;
         end if;
      end loop;
      return Score;
   end Line_MSAC_Score;

   function Fit_Line_Least_Squares_Masked
     (Points : Point_Array; Mask : Inlier_Mask; Count : Natural) return Line2
   is
      Selected : Point_Array (1 .. Count);
      K        : Natural := 0;
   begin
      if Count < 2 then
         raise Invalid_Argument with "masked LS line needs >= 2 inliers";
      end if;
      for I in Points'Range loop
         if Mask (I) then
            K := K + 1;
            if K <= Count then
               Selected (K) := Points (I);
            end if;
         end if;
      end loop;
      if K < 2 then
         raise Invalid_Argument with "masked LS line: mask count mismatch";
      end if;
      return Fit_Line_Least_Squares (Selected (1 .. K));
   end Fit_Line_Least_Squares_Masked;

   ---------------------------------------------------------------------------
   -- Circle geometry
   ---------------------------------------------------------------------------

   function Fit_Circle_From_Three_Points
     (P, Q, R : Point2) return Circle2
   is
      D : Real;
      UX, UY : Real;
      CX, CY : Real;
      Rad : Real;
   begin
      if Is_Degenerate_Sample (P, Q)
        or else Is_Degenerate_Sample (P, R)
        or else Is_Degenerate_Sample (Q, R)
      then
         raise Degenerate_Geometry with "circle: coincident sample points";
      end if;
      D := 2.0 * (P.X * (Q.Y - R.Y) + Q.X * (R.Y - P.Y) + R.X * (P.Y - Q.Y));
      if Abs_R (D) < Degenerate_Dist then
         raise Degenerate_Geometry with "circle: collinear sample";
      end if;
      UX := (P.X * P.X + P.Y * P.Y) * (Q.Y - R.Y)
          + (Q.X * Q.X + Q.Y * Q.Y) * (R.Y - P.Y)
          + (R.X * R.X + R.Y * R.Y) * (P.Y - Q.Y);
      UY := (P.X * P.X + P.Y * P.Y) * (R.X - Q.X)
          + (Q.X * Q.X + Q.Y * Q.Y) * (P.X - R.X)
          + (R.X * R.X + R.Y * R.Y) * (Q.X - P.X);
      CX := UX / D;
      CY := UY / D;
      Rad := Sqrt_R ((CX - P.X) * (CX - P.X) + (CY - P.Y) * (CY - P.Y));
      return (Center => (CX, CY), Radius => Non_Negative (Rad));
   end Fit_Circle_From_Three_Points;

   function Point_Circle_Distance
     (P : Point2; C : Circle2) return Non_Negative
   is
      D : constant Real := Real (Dist2 (P, C.Center));
   begin
      return Non_Negative (Abs_R (D - Real (C.Radius)));
   end Point_Circle_Distance;

   function Count_Circle_Inliers
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real) return Natural
   is
      Count : Natural := 0;
   begin
      for P of Points loop
         if Point_Circle_Distance (P, Model) <= Threshold then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Circle_Inliers;

   procedure Collect_Circle_Inliers
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real;
      Mask      : out Inlier_Mask;
      Count     : out Natural)
   is
   begin
      Mask  := [others => False];
      Count := 0;
      for I in Points'Range loop
         if Point_Circle_Distance (Points (I), Model) <= Threshold then
            Mask (I) := True;
            Count    := Count + 1;
         end if;
      end loop;
   end Collect_Circle_Inliers;

   function Circle_MSAC_Score
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real) return Real
   is
      T2    : constant Real := Threshold * Threshold;
      Score : Real := 0.0;
      D, D2 : Real;
   begin
      for P of Points loop
         D  := Real (Point_Circle_Distance (P, Model));
         D2 := D * D;
         if D2 < T2 then
            Score := Score + D2;
         else
            Score := Score + T2;
         end if;
      end loop;
      return Score;
   end Circle_MSAC_Score;

   function Fit_Circle_Least_Squares_Masked
     (Points : Point_Array; Mask : Inlier_Mask; Count : Natural) return Circle2
   is
      N : constant Natural := Count;
      SX, SY, SXX, SYY, SXY, SXXX, SYYY, SXXY, SXYY : Real := 0.0;
      A11, A12, A13, A22, A23, A33 : Real;
      B1, B2, B3 : Real;
      Det, DX, DY, DF : Real;
      D_Coeff, E_Coeff, F_Coeff : Real;
      CX, CY, Rad : Real;
      K : Natural := 0;
      X, Y : Real;
   begin
      if Count < 3 then
         raise Invalid_Argument with "masked circle LS needs >= 3";
      end if;
      for I in Points'Range loop
         if Mask (I) then
            K := K + 1;
            X := Points (I).X;
            Y := Points (I).Y;
            SX   := SX + X;
            SY   := SY + Y;
            SXX  := SXX + X * X;
            SYY  := SYY + Y * Y;
            SXY  := SXY + X * Y;
            SXXX := SXXX + X * X * X;
            SYYY := SYYY + Y * Y * Y;
            SXXY := SXXY + X * X * Y;
            SXYY := SXYY + X * Y * Y;
         end if;
      end loop;
      if K < 3 then
         raise Invalid_Argument with "masked circle: mask mismatch";
      end if;
      A11 := SXX; A12 := SXY; A13 := SX;
      A22 := SYY; A23 := SY;
      A33 := Real (N);
      B1 := -(SXXX + SXYY);
      B2 := -(SXXY + SYYY);
      B3 := -(SXX + SYY);
      Det :=
        A11 * (A22 * A33 - A23 * A23)
        - A12 * (A12 * A33 - A23 * A13)
        + A13 * (A12 * A23 - A22 * A13);
      if Abs_R (Det) < Degenerate_Dist then
         raise Degenerate_Geometry with "Kasa fit singular";
      end if;
      DX :=
        B1 * (A22 * A33 - A23 * A23)
        - A12 * (B2 * A33 - A23 * B3)
        + A13 * (B2 * A23 - A22 * B3);
      DY :=
        A11 * (B2 * A33 - A23 * B3)
        - B1 * (A12 * A33 - A23 * A13)
        + A13 * (A12 * B3 - B2 * A13);
      DF :=
        A11 * (A22 * B3 - B2 * A23)
        - A12 * (A12 * B3 - B2 * A13)
        + B1 * (A12 * A23 - A22 * A13);
      D_Coeff := DX / Det;
      E_Coeff := DY / Det;
      F_Coeff := DF / Det;
      CX  := -0.5 * D_Coeff;
      CY  := -0.5 * E_Coeff;
      Rad := Sqrt_R (Max_R (0.0, CX * CX + CY * CY - F_Coeff));
      return (Center => (CX, CY), Radius => Non_Negative (Rad));
   end Fit_Circle_Least_Squares_Masked;

   ---------------------------------------------------------------------------
   -- Iteration estimate
   ---------------------------------------------------------------------------

   function Estimate_Iterations
     (Inlier_Ratio : Real;
      Sample_Size  : Positive;
      Confidence   : Real) return Natural
   is
      W, WS, Denom, Numer, K : Real;
      Result : Natural;
   begin
      if Inlier_Ratio < 0.0 or else Inlier_Ratio > 1.0 then
         raise Invalid_Argument with "Inlier_Ratio out of [0,1]";
      end if;
      if Confidence <= 0.0 or else Confidence >= 1.0 then
         raise Invalid_Argument with "Confidence out of (0,1)";
      end if;
      if Inlier_Ratio >= 1.0 - 1.0E-15 then
         return 1;
      end if;
      if Inlier_Ratio <= 0.0 then
         return Natural'Last / 4;
      end if;
      W := Inlier_Ratio;
      WS := 1.0;
      for I in 1 .. Sample_Size loop
         WS := WS * W;
      end loop;
      if WS >= 1.0 - 1.0E-15 then
         return 1;
      end if;
      if WS <= 1.0E-15 then
         return Natural'Last / 4;
      end if;
      Denom := Log_R (1.0 - WS);
      Numer := Log_R (1.0 - Confidence);
      if Abs_R (Denom) < 1.0E-30 then
         return Natural'Last / 4;
      end if;
      K := Numer / Denom;
      if K < 1.0 then
         Result := 1;
      elsif K > Real (Natural'Last / 4) then
         Result := Natural'Last / 4;
      else
         Result := Natural (K);
         if Real (Result) < K then
            Result := Result + 1;
         end if;
      end if;
      return Result;
   end Estimate_Iterations;

   ---------------------------------------------------------------------------
   -- RANSAC line
   ---------------------------------------------------------------------------

   function RANSAC_Fit_Line
     (Points : Point_Array; Config : RANSAC_Config) return RANSAC_Line_Result
   is
      N : constant Natural := Points'Length;
      Rng : Seeded_RNG := Make_RNG (Config.Seed);
      Best : RANSAC_Line_Result;
      I1, I2 : Point_Index;
      Maybe : Line2;
      Mask : Inlier_Mask;
      In_Count : Natural;
      Score : Real;
      Iterations_Cap : Natural := Config.Max_Iterations;
      Ratio : Real;
      Est : Natural;
      Attempts : Natural := 0;
      Max_Attempts : constant Natural := Config.Max_Iterations * 20;
      Accepted : Boolean;
   begin
      if N < 2 then
         raise Invalid_Argument with "RANSAC_Fit_Line: need >= 2 points";
      end if;
      Best.Score := Real'Last;
      Best.Success := False;
      Best.Iterations_Used := 0;

      while Best.Iterations_Used < Iterations_Cap
        and then Attempts < Max_Attempts
      loop
         Attempts := Attempts + 1;
         Accepted := False;
         I1 := Next_Index (Rng, Points'First, Points'Last);
         I2 := Next_Index (Rng, Points'First, Points'Last);
         if I1 /= I2
           and then not Is_Degenerate_Sample (Points (I1), Points (I2))
         then
            begin
               Maybe := Fit_Line_From_Two_Points (Points (I1), Points (I2));
               Accepted := True;
            exception
               when Degenerate_Geometry =>
                  Accepted := False;
            end;
         end if;

         if Accepted then
            Best.Iterations_Used := Best.Iterations_Used + 1;
            Collect_Line_Inliers
              (Points, Maybe, Config.Distance_Threshold, Mask, In_Count);

            if In_Count >= Config.Min_Inliers and then In_Count >= 2 then
               if Config.Use_MSAC_Score then
                  Score := Line_MSAC_Score
                    (Points, Maybe, Config.Distance_Threshold);
               else
                  Score := -Real (In_Count);
               end if;

               if In_Count > Best.Inlier_Count
                 or else (In_Count = Best.Inlier_Count
                          and then Score < Best.Score)
               then
                  Best.Model        := Maybe;
                  Best.Inlier_Count := In_Count;
                  Best.Inliers      := Mask;
                  Best.Score        := Score;
                  Best.Success      := True;

                  if Config.Adaptive_Stop and then N > 0 then
                     Ratio := Real (In_Count) / Real (N);
                     Est := Estimate_Iterations
                       (Ratio, 2, Config.Confidence);
                     if Est < Iterations_Cap then
                        Iterations_Cap := Est;
                     end if;
                  end if;
               end if;
            end if;
         end if;
      end loop;

      if Best.Success and then Config.Refit_On_Inliers
        and then Best.Inlier_Count >= 2
      then
         begin
            Best.Model := Fit_Line_Least_Squares_Masked
              (Points, Best.Inliers, Best.Inlier_Count);
            Collect_Line_Inliers
              (Points, Best.Model, Config.Distance_Threshold,
               Best.Inliers, Best.Inlier_Count);
            if Config.Use_MSAC_Score then
               Best.Score := Line_MSAC_Score
                 (Points, Best.Model, Config.Distance_Threshold);
            else
               Best.Score := -Real (Best.Inlier_Count);
            end if;
         exception
            when Degenerate_Geometry | Invalid_Argument =>
               null;
         end;
      end if;

      return Best;
   end RANSAC_Fit_Line;

   ---------------------------------------------------------------------------
   -- RANSAC circle
   ---------------------------------------------------------------------------

   function RANSAC_Fit_Circle
     (Points : Point_Array; Config : RANSAC_Config) return RANSAC_Circle_Result
   is
      N : constant Natural := Points'Length;
      Rng : Seeded_RNG := Make_RNG (Config.Seed);
      Best : RANSAC_Circle_Result;
      I1, I2, I3 : Point_Index;
      Maybe : Circle2;
      Mask : Inlier_Mask;
      In_Count : Natural;
      Score : Real;
      Iterations_Cap : Natural := Config.Max_Iterations;
      Ratio : Real;
      Est : Natural;
      Attempts : Natural := 0;
      Max_Attempts : constant Natural := Config.Max_Iterations * 40;
      Accepted : Boolean;
   begin
      if N < 3 then
         raise Invalid_Argument with "RANSAC_Fit_Circle: need >= 3 points";
      end if;
      Best.Score := Real'Last;
      Best.Success := False;
      Best.Iterations_Used := 0;

      while Best.Iterations_Used < Iterations_Cap
        and then Attempts < Max_Attempts
      loop
         Attempts := Attempts + 1;
         Accepted := False;
         I1 := Next_Index (Rng, Points'First, Points'Last);
         I2 := Next_Index (Rng, Points'First, Points'Last);
         I3 := Next_Index (Rng, Points'First, Points'Last);
         if I1 /= I2 and then I1 /= I3 and then I2 /= I3 then
            begin
               Maybe := Fit_Circle_From_Three_Points
                 (Points (I1), Points (I2), Points (I3));
               Accepted := True;
            exception
               when Degenerate_Geometry =>
                  Accepted := False;
            end;
         end if;

         if Accepted then
            Best.Iterations_Used := Best.Iterations_Used + 1;
            Collect_Circle_Inliers
              (Points, Maybe, Config.Distance_Threshold, Mask, In_Count);

            if In_Count >= Config.Min_Inliers and then In_Count >= 3 then
               if Config.Use_MSAC_Score then
                  Score := Circle_MSAC_Score
                    (Points, Maybe, Config.Distance_Threshold);
               else
                  Score := -Real (In_Count);
               end if;

               if In_Count > Best.Inlier_Count
                 or else (In_Count = Best.Inlier_Count
                          and then Score < Best.Score)
               then
                  Best.Model        := Maybe;
                  Best.Inlier_Count := In_Count;
                  Best.Inliers      := Mask;
                  Best.Score        := Score;
                  Best.Success      := True;

                  if Config.Adaptive_Stop and then N > 0 then
                     Ratio := Real (In_Count) / Real (N);
                     Est := Estimate_Iterations
                       (Ratio, 3, Config.Confidence);
                     if Est < Iterations_Cap then
                        Iterations_Cap := Est;
                     end if;
                  end if;
               end if;
            end if;
         end if;
      end loop;

      if Best.Success and then Config.Refit_On_Inliers
        and then Best.Inlier_Count >= 3
      then
         begin
            Best.Model := Fit_Circle_Least_Squares_Masked
              (Points, Best.Inliers, Best.Inlier_Count);
            Collect_Circle_Inliers
              (Points, Best.Model, Config.Distance_Threshold,
               Best.Inliers, Best.Inlier_Count);
            if Config.Use_MSAC_Score then
               Best.Score := Circle_MSAC_Score
                 (Points, Best.Model, Config.Distance_Threshold);
            else
               Best.Score := -Real (Best.Inlier_Count);
            end if;
         exception
            when Degenerate_Geometry | Invalid_Argument =>
               null;
         end;
      end if;

      return Best;
   end RANSAC_Fit_Circle;

end RANSAC;

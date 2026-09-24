--  Vincenty — body (Vincenty 1975 direct / inverse on an oblate spheroid).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Vincenty
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   function Sqrt (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (X)));
   end Sqrt;

   function Sin (X : Real) return Real is
     (Real (Math.Sin (Long_Float (X))));

   function Cos (X : Real) return Real is
     (Real (Math.Cos (Long_Float (X))));

   function Tan (X : Real) return Real is
     (Real (Math.Tan (Long_Float (X))));

   function Arctan (Y : Real; X : Real := 1.0) return Real is
     (Real (Math.Arctan (Long_Float (Y), Long_Float (X))));

   function Atan2 (Y, X : Real) return Real is
     (Arctan (Y, X));

   -------------------------------------------------------------------------

   function WGS84 return Ellipsoid is
   begin
      return (A => WGS84_A, F => WGS84_F);
   end WGS84;

   function Semi_Minor (E : Ellipsoid) return Positive_Real is
      B : constant Real := E.A * (1.0 - E.F);
   begin
      if B <= 0.0 then
         raise Invalid_Argument;
      end if;
      return B;
   end Semi_Minor;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Deg_To_Rad (Degrees : Real) return Real is
     (Degrees * Deg_To_Rad_Factor);

   function Rad_To_Deg (Radians : Real) return Real is
     (Radians * Rad_To_Deg_Factor);

   function Normalize_Longitude (Lon : Real) return Real is
      L : Real := Lon;
   begin
      while L > Pi loop
         L := L - Two_Pi;
      end loop;
      while L <= -Pi loop
         L := L + Two_Pi;
      end loop;
      return L;
   end Normalize_Longitude;

   -------------------------------------------------------------------------
   -- Series A, B from u^2 (Vincenty nested form)
   -------------------------------------------------------------------------

   procedure Series_AB
     (U2 : Real;
      A  : out Real;
      B  : out Real)
   is
   begin
      A := 1.0 + U2 / 16384.0 *
        (4096.0 + U2 * (-768.0 + U2 * (320.0 - 175.0 * U2)));
      B := U2 / 1024.0 *
        (256.0 + U2 * (-128.0 + U2 * (74.0 - 47.0 * U2)));
   end Series_AB;

   function Delta_Sigma
     (B_Coeff, Sin_Sigma, Cos_Sigma, Cos2_Sigma_M : Real) return Real
   is
      Cos2Sq : constant Real := Cos2_Sigma_M * Cos2_Sigma_M;
   begin
      return B_Coeff * Sin_Sigma *
        (Cos2_Sigma_M + B_Coeff / 4.0 *
           (Cos_Sigma * (-1.0 + 2.0 * Cos2Sq) -
            B_Coeff / 6.0 * Cos2_Sigma_M *
              (-3.0 + 4.0 * Sin_Sigma * Sin_Sigma) *
              (-3.0 + 4.0 * Cos2Sq)));
   end Delta_Sigma;

   -------------------------------------------------------------------------
   -- Inverse
   -------------------------------------------------------------------------

   function Inverse
     (Lat1, Lon1, Lat2, Lon2 : Real;
      E                      : Ellipsoid := WGS84) return Inverse_Result
   is
      Result : Inverse_Result;

      A_Axis : constant Real := E.A;
      F      : constant Real := E.F;
      B_Axis : constant Real := Semi_Minor (E);

      L : constant Real := Normalize_Longitude (Lon2 - Lon1);

      Tan_U1 : constant Real := (1.0 - F) * Tan (Lat1);
      Tan_U2 : constant Real := (1.0 - F) * Tan (Lat2);

      Cos_U1 : Real;
      Sin_U1 : Real;
      Cos_U2 : Real;
      Sin_U2 : Real;

      --  Reduced latitudes via atan of tan U
      U1 : Real;
      U2 : Real;

      Lambda     : Real;
      Lambda_Prev : Real;
      Iter       : Natural := 0;

      Sin_Lambda, Cos_Lambda : Real;
      Sin_Sigma, Cos_Sigma, Sigma : Real;
      Sin_Alpha, Cos_Sq_Alpha : Real;
      Cos2_Sigma_M : Real;
      C_Coeff : Real;

      U2_Param, A_Coeff, B_Coeff : Real;
      DSigma : Real;

      Num_A1, Den_A1, Num_A2, Den_A2 : Real;
   begin
      --  Coincident points
      if Near (Lat1, Lat2, 1.0E-15) and then Near (L, 0.0, 1.0E-15) then
         Result.Distance   := 0.0;
         Result.Azimuth1   := 0.0;
         Result.Azimuth2   := 0.0;
         Result.Converged  := True;
         Result.Iterations := 0;
         return Result;
      end if;

      U1 := Atan2 (Tan_U1, 1.0);
      U2 := Atan2 (Tan_U2, 1.0);
      Cos_U1 := Cos (U1);
      Sin_U1 := Sin (U1);
      Cos_U2 := Cos (U2);
      Sin_U2 := Sin (U2);

      Lambda := L;
      Result.Converged := False;

      for I in 1 .. Max_Iterations loop
         Iter := I;
         Sin_Lambda := Sin (Lambda);
         Cos_Lambda := Cos (Lambda);

         Sin_Sigma := Sqrt
           ((Cos_U2 * Sin_Lambda) * (Cos_U2 * Sin_Lambda) +
            (Cos_U1 * Sin_U2 - Sin_U1 * Cos_U2 * Cos_Lambda) *
            (Cos_U1 * Sin_U2 - Sin_U1 * Cos_U2 * Cos_Lambda));

         Cos_Sigma := Sin_U1 * Sin_U2 + Cos_U1 * Cos_U2 * Cos_Lambda;

         if Sin_Sigma = 0.0 then
            --  Coincident (cos σ > 0) or antipodal (cos σ < 0) on
            --  the auxiliary sphere. Antipodes: report non-convergence.
            if Cos_Sigma > 0.0 then
               Result.Distance   := 0.0;
               Result.Azimuth1   := 0.0;
               Result.Azimuth2   := 0.0;
               Result.Converged  := True;
            else
               Result.Distance   := 0.0;
               Result.Azimuth1   := 0.0;
               Result.Azimuth2   := 0.0;
               Result.Converged  := False;
            end if;
            Result.Iterations := Iter;
            return Result;
         end if;

         Sigma     := Atan2 (Sin_Sigma, Cos_Sigma);

         Sin_Alpha := Cos_U1 * Cos_U2 * Sin_Lambda / Sin_Sigma;
         --  Clamp for numerical noise
         if Sin_Alpha > 1.0 then
            Sin_Alpha := 1.0;
         elsif Sin_Alpha < -1.0 then
            Sin_Alpha := -1.0;
         end if;
         Cos_Sq_Alpha := 1.0 - Sin_Alpha * Sin_Alpha;

         if Cos_Sq_Alpha = 0.0 then
            --  Equatorial line
            Cos2_Sigma_M := 0.0;
         else
            Cos2_Sigma_M :=
              Cos_Sigma - 2.0 * Sin_U1 * Sin_U2 / Cos_Sq_Alpha;
         end if;

         C_Coeff := F / 16.0 * Cos_Sq_Alpha *
           (4.0 + F * (4.0 - 3.0 * Cos_Sq_Alpha));

         Lambda_Prev := Lambda;
         Lambda := L + (1.0 - C_Coeff) * F * Sin_Alpha *
           (Sigma + C_Coeff * Sin_Sigma *
              (Cos2_Sigma_M + C_Coeff * Cos_Sigma *
                 (-1.0 + 2.0 * Cos2_Sigma_M * Cos2_Sigma_M)));

         --  Antipodal divergence: |λ| grew beyond π
         if abs (Lambda) > Pi then
            Result.Converged  := False;
            Result.Iterations := Iter;
            Result.Distance   := 0.0;
            Result.Azimuth1   := 0.0;
            Result.Azimuth2   := 0.0;
            return Result;
         end if;

         exit when abs (Lambda - Lambda_Prev) <= Convergence_Tol;
      end loop;

      Result.Iterations := Iter;

      if abs (Lambda - Lambda_Prev) > Convergence_Tol then
         Result.Converged := False;
         Result.Distance  := 0.0;
         Result.Azimuth1  := 0.0;
         Result.Azimuth2  := 0.0;
         return Result;
      end if;

      Result.Converged := True;

      U2_Param := Cos_Sq_Alpha * (A_Axis * A_Axis - B_Axis * B_Axis) /
        (B_Axis * B_Axis);
      Series_AB (U2_Param, A_Coeff, B_Coeff);
      DSigma := Delta_Sigma (B_Coeff, Sin_Sigma, Cos_Sigma, Cos2_Sigma_M);

      Result.Distance := B_Axis * A_Coeff * (Sigma - DSigma);

      Num_A1 := Cos_U2 * Sin_Lambda;
      Den_A1 := Cos_U1 * Sin_U2 - Sin_U1 * Cos_U2 * Cos_Lambda;
      Result.Azimuth1 := Atan2 (Num_A1, Den_A1);

      Num_A2 := Cos_U1 * Sin_Lambda;
      Den_A2 := -Sin_U1 * Cos_U2 + Cos_U1 * Sin_U2 * Cos_Lambda;
      Result.Azimuth2 := Atan2 (Num_A2, Den_A2);

      return Result;
   end Inverse;

   -------------------------------------------------------------------------
   -- Direct
   -------------------------------------------------------------------------

   function Direct
     (Lat1, Lon1, Azimuth1, Distance : Real;
      E                              : Ellipsoid := WGS84) return Direct_Result
   is
      Result : Direct_Result;

      F      : constant Real := E.F;
      B_Axis : constant Real := Semi_Minor (E);
      A_Axis : constant Real := E.A;

      Tan_U1 : constant Real := (1.0 - F) * Tan (Lat1);
      Cos_Alpha1 : constant Real := Cos (Azimuth1);
      Sin_Alpha1 : constant Real := Sin (Azimuth1);

      U1 : constant Real := Atan2 (Tan_U1, 1.0);
      Cos_U1 : constant Real := Cos (U1);
      Sin_U1 : constant Real := Sin (U1);

      Sigma1 : constant Real := Atan2 (Tan_U1, Cos_Alpha1);
      Sin_Alpha : constant Real := Cos_U1 * Sin_Alpha1;
      Cos_Sq_Alpha : constant Real :=
        (if abs (Sin_Alpha) >= 1.0 then 0.0
         else 1.0 - Sin_Alpha * Sin_Alpha);

      U2_Param : constant Real :=
        Cos_Sq_Alpha * (A_Axis * A_Axis - B_Axis * B_Axis) /
        (B_Axis * B_Axis);

      A_Coeff, B_Coeff : Real;
      Sigma, Sigma_Prev, Two_Sigma_M, DSigma : Real;
      Iter : Natural := 0;

      Sin_Sigma, Cos_Sigma : Real;
      Cos2_Sigma_M : Real;
      C_Coeff : Real;
      Lambda, L : Real;
   begin
      if Distance < 0.0 then
         raise Invalid_Argument;
      end if;

      if Distance = 0.0 then
         Result.Lat2       := Lat1;
         Result.Lon2       := Lon1;
         Result.Azimuth2   := Azimuth1;
         Result.Converged  := True;
         Result.Iterations := 0;
         return Result;
      end if;

      Series_AB (U2_Param, A_Coeff, B_Coeff);

      Sigma := Distance / (B_Axis * A_Coeff);
      Result.Converged := False;

      for I in 1 .. Max_Iterations loop
         Iter := I;
         Two_Sigma_M := 2.0 * Sigma1 + Sigma;
         Sin_Sigma := Sin (Sigma);
         Cos_Sigma := Cos (Sigma);
         Cos2_Sigma_M := Cos (Two_Sigma_M);
         DSigma := Delta_Sigma (B_Coeff, Sin_Sigma, Cos_Sigma, Cos2_Sigma_M);
         Sigma_Prev := Sigma;
         Sigma := Distance / (B_Axis * A_Coeff) + DSigma;
         exit when abs (Sigma - Sigma_Prev) <= Convergence_Tol;
      end loop;

      Result.Iterations := Iter;
      Result.Converged  := abs (Sigma - Sigma_Prev) <= Convergence_Tol;

      Sin_Sigma := Sin (Sigma);
      Cos_Sigma := Cos (Sigma);
      Two_Sigma_M := 2.0 * Sigma1 + Sigma;
      Cos2_Sigma_M := Cos (Two_Sigma_M);

      Result.Lat2 := Atan2
        (Sin_U1 * Cos_Sigma + Cos_U1 * Sin_Sigma * Cos_Alpha1,
         (1.0 - F) * Sqrt
           (Sin_Alpha * Sin_Alpha +
            (Sin_U1 * Sin_Sigma - Cos_U1 * Cos_Sigma * Cos_Alpha1) *
            (Sin_U1 * Sin_Sigma - Cos_U1 * Cos_Sigma * Cos_Alpha1)));

      Lambda := Atan2
        (Sin_Sigma * Sin_Alpha1,
         Cos_U1 * Cos_Sigma - Sin_U1 * Sin_Sigma * Cos_Alpha1);

      C_Coeff := F / 16.0 * Cos_Sq_Alpha *
        (4.0 + F * (4.0 - 3.0 * Cos_Sq_Alpha));

      L := Lambda - (1.0 - C_Coeff) * F * Sin_Alpha *
        (Sigma + C_Coeff * Sin_Sigma *
           (Cos2_Sigma_M + C_Coeff * Cos_Sigma *
              (-1.0 + 2.0 * Cos2_Sigma_M * Cos2_Sigma_M)));

      Result.Lon2 := Normalize_Longitude (Lon1 + L);

      Result.Azimuth2 := Atan2
        (Sin_Alpha,
         -Sin_U1 * Sin_Sigma + Cos_U1 * Cos_Sigma * Cos_Alpha1);

      return Result;
   end Direct;

   -------------------------------------------------------------------------
   -- Degree wrappers
   -------------------------------------------------------------------------

   function Inverse_Degrees
     (Lat1_Deg, Lon1_Deg, Lat2_Deg, Lon2_Deg : Real;
      E                                      : Ellipsoid := WGS84)
      return Inverse_Result
   is
   begin
      return Inverse
        (Deg_To_Rad (Lat1_Deg), Deg_To_Rad (Lon1_Deg),
         Deg_To_Rad (Lat2_Deg), Deg_To_Rad (Lon2_Deg), E);
   end Inverse_Degrees;

   function Direct_Degrees
     (Lat1_Deg, Lon1_Deg, Azimuth1_Deg, Distance : Real;
      E                                          : Ellipsoid := WGS84)
      return Direct_Result
   is
   begin
      return Direct
        (Deg_To_Rad (Lat1_Deg), Deg_To_Rad (Lon1_Deg),
         Deg_To_Rad (Azimuth1_Deg), Distance, E);
   end Direct_Degrees;

   -------------------------------------------------------------------------
   -- Haversine
   -------------------------------------------------------------------------

   function Haversine
     (Lat1, Lon1, Lat2, Lon2 : Real;
      Radius                 : Positive_Real := Mean_Earth_Radius)
      return Non_Negative
   is
      DLat : constant Real := Lat2 - Lat1;
      DLon : constant Real := Lon2 - Lon1;
      A    : constant Real :=
        Sin (DLat / 2.0) * Sin (DLat / 2.0) +
        Cos (Lat1) * Cos (Lat2) *
        Sin (DLon / 2.0) * Sin (DLon / 2.0);
      A_Clamped : constant Real :=
        (if A > 1.0 then 1.0 elsif A < 0.0 then 0.0 else A);
      C : constant Real := 2.0 * Atan2 (Sqrt (A_Clamped), Sqrt (1.0 - A_Clamped));
   begin
      return Radius * C;
   end Haversine;

   function Haversine_Degrees
     (Lat1_Deg, Lon1_Deg, Lat2_Deg, Lon2_Deg : Real;
      Radius : Positive_Real := Mean_Earth_Radius) return Non_Negative
   is
   begin
      return Haversine
        (Deg_To_Rad (Lat1_Deg), Deg_To_Rad (Lon1_Deg),
         Deg_To_Rad (Lat2_Deg), Deg_To_Rad (Lon2_Deg), Radius);
   end Haversine_Degrees;

end Vincenty;

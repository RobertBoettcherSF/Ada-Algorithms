--  Buzens_Algorithm body — Gordon–Newell normalizing constants via
--  Buzen convolution, plus marginals / means / utilization helpers.

pragma Ada_2022;

package body Buzens_Algorithm
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Validation
   -----------------------------------------------------------------------

   procedure Validate_X (X : X_Vector) is
   begin
      if X'Length = 0 then
         raise Invalid_Argument with "X must contain at least one station";
      end if;
      for Xi of X loop
         if Xi <= 0.0 then
            raise Invalid_Argument with "each X(i) must be strictly positive";
         end if;
      end loop;
   end Validate_X;

   procedure Validate_N (N : Natural) is
   begin
      if N > Max_Customers then
         raise Capacity_Exceeded
           with "N exceeds Max_Customers";
      end if;
   end Validate_N;

   procedure Require_Positive_G_N (G_N : Real) is
   begin
      if G_N <= 0.0 then
         raise Invalid_Argument with "G(N) must be strictly positive";
      end if;
   end Require_Positive_G_N;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Power (Base : Real; Exp : Natural) return Real is
      R : Real := 1.0;
   begin
      for I in 1 .. Exp loop
         R := R * Base;
      end loop;
      return R;
   end Power;

   -----------------------------------------------------------------------
   -- Loadings from service rates
   -----------------------------------------------------------------------

   function Make_X_Cyclic (Service_Rates : X_Vector) return X_Vector is
      Result : X_Vector (Service_Rates'Range);
   begin
      if Service_Rates'Length = 0 then
         raise Invalid_Argument with "Make_X_Cyclic: empty rates";
      end if;
      for I in Service_Rates'Range loop
         if Service_Rates (I) <= 0.0 then
            raise Invalid_Argument
              with "Make_X_Cyclic: service rates must be positive";
         end if;
         Result (I) := 1.0 / Service_Rates (I);
      end loop;
      return Result;
   end Make_X_Cyclic;

   function Make_X_From_Rates
     (Service_Rates : X_Vector;
      Visit_Ratios  : X_Vector) return X_Vector
   is
      Result : X_Vector (Service_Rates'Range);
   begin
      if Service_Rates'Length = 0 then
         raise Invalid_Argument with "Make_X_From_Rates: empty rates";
      end if;
      if Visit_Ratios'Length /= Service_Rates'Length
        or else Visit_Ratios'First /= Service_Rates'First
      then
         raise Invalid_Argument
           with "Make_X_From_Rates: rates and visits must align";
      end if;
      for I in Service_Rates'Range loop
         if Service_Rates (I) <= 0.0 or else Visit_Ratios (I) <= 0.0 then
            raise Invalid_Argument
              with "Make_X_From_Rates: rates and visits must be positive";
         end if;
         Result (I) := Visit_Ratios (I) / Service_Rates (I);
      end loop;
      return Result;
   end Make_X_From_Rates;

   -----------------------------------------------------------------------
   -- Buzen convolution
   -----------------------------------------------------------------------

   function Compute_G (X : X_Vector; N : Natural) return G_Vector is
      C : G_Vector (0 .. N);
   begin
      Validate_X (X);
      Validate_N (N);

      --  Wikipedia Pascal initialization: C[0] := 1; C[n] := 0 for n≥1.
      C (0) := 1.0;
      for Ni in 1 .. N loop
         C (Ni) := 0.0;
      end loop;

      --  Column-by-column convolution.
      for M in X'Range loop
         for Ni in 1 .. N loop
            C (Ni) := C (Ni) + X (M) * C (Ni - 1);
         end loop;
      end loop;

      return C;
   end Compute_G;

   function Compute_G_Matrix (X : X_Vector; N : Natural) return G_Matrix is
      G  : G_Matrix (0 .. N, X'Range);
      M0 : constant Station_Index := X'First;
   begin
      Validate_X (X);
      Validate_N (N);

      --  Boundary: g(0, m) = 1 for all stations.
      for M in X'Range loop
         G (0, M) := 1.0;
      end loop;

      --  First column: g(n, 1) = X_1^n  (equivalently X_1 * g(n-1, 1)).
      for Ni in 1 .. N loop
         G (Ni, M0) := X (M0) * G (Ni - 1, M0);
      end loop;

      --  Remaining columns: g(n,m) = g(n,m-1) + X_m * g(n-1,m).
      --  Iterate X'Range and skip M0 to avoid Station_Index'Succ overflow
      --  when the sole station uses Station_Index'Last.
      for M in X'Range loop
         if M /= M0 then
            for Ni in 1 .. N loop
               G (Ni, M) := G (Ni, M - 1) + X (M) * G (Ni - 1, M);
            end loop;
         end if;
      end loop;

      return G;
   end Compute_G_Matrix;

   -----------------------------------------------------------------------
   -- Marginals and means
   -----------------------------------------------------------------------

   function Prob_Ni_At_Least
     (X_i : Real;
      K   : Natural;
      G   : G_Vector) return Real
   is
      N : constant Natural := G'Last;
   begin
      if X_i <= 0.0 then
         raise Invalid_Argument with "Prob_Ni_At_Least: X_i must be > 0";
      end if;
      if G'First /= 0 or else G'Length = 0 then
         raise Invalid_Argument with "Prob_Ni_At_Least: G must be 0 .. N";
      end if;
      if K > N then
         raise Invalid_Argument with "Prob_Ni_At_Least: K > N";
      end if;
      Require_Positive_G_N (G (N));
      return Power (X_i, K) * G (N - K) / G (N);
   end Prob_Ni_At_Least;

   function Prob_Ni_Equals
     (X_i : Real;
      K   : Natural;
      G   : G_Vector) return Real
   is
      N : constant Natural := G'Last;
   begin
      if X_i <= 0.0 then
         raise Invalid_Argument with "Prob_Ni_Equals: X_i must be > 0";
      end if;
      if G'First /= 0 or else G'Length = 0 then
         raise Invalid_Argument with "Prob_Ni_Equals: G must be 0 .. N";
      end if;
      if K > N then
         raise Invalid_Argument with "Prob_Ni_Equals: K > N";
      end if;
      Require_Positive_G_N (G (N));

      if K = N then
         return Power (X_i, N) / G (N);
      else
         --  k = 0 .. N-1: X_i^k / G(N) * [G(N-k) - X_i G(N-k-1)]
         return Power (X_i, K) / G (N)
           * (G (N - K) - X_i * G (N - K - 1));
      end if;
   end Prob_Ni_Equals;

   function Expected_Ni (X_i : Real; G : G_Vector) return Real is
      N   : constant Natural := G'Last;
      Acc : Real := 0.0;
   begin
      if X_i <= 0.0 then
         raise Invalid_Argument with "Expected_Ni: X_i must be > 0";
      end if;
      if G'First /= 0 or else G'Length = 0 then
         raise Invalid_Argument with "Expected_Ni: G must be 0 .. N";
      end if;
      Require_Positive_G_N (G (N));

      for K in 1 .. N loop
         Acc := Acc + Power (X_i, K) * G (N - K) / G (N);
      end loop;
      return Acc;
   end Expected_Ni;

   function Station_Utilization (X_i : Real; G : G_Vector) return Real is
      N : constant Natural := G'Last;
   begin
      if X_i <= 0.0 then
         raise Invalid_Argument
           with "Station_Utilization: X_i must be > 0";
      end if;
      if G'First /= 0 or else G'Length = 0 then
         raise Invalid_Argument
           with "Station_Utilization: G must be 0 .. N";
      end if;
      if N = 0 then
         return 0.0;
      end if;
      Require_Positive_G_N (G (N));
      --  Load-independent single-server: U_i = X_i * G(N-1) / G(N).
      return X_i * G (N - 1) / G (N);
   end Station_Utilization;

   function State_Probability
     (N_Vec : Customer_Vector;
      X     : X_Vector;
      G_N   : Real) return Real
   is
      Prod : Real := 1.0;
   begin
      if N_Vec'Length = 0 then
         raise Invalid_Argument with "State_Probability: empty state";
      end if;
      if X'Length /= N_Vec'Length or else X'First /= N_Vec'First then
         raise Invalid_Argument
           with "State_Probability: X and N_Vec must align";
      end if;
      Require_Positive_G_N (G_N);
      Validate_X (X);

      for I in N_Vec'Range loop
         Prod := Prod * Power (X (I), N_Vec (I));
      end loop;
      return Prod / G_N;
   end State_Probability;

end Buzens_Algorithm;

--  False_Nearest_Neighbor body — Kennel–Brown–Abarbanel FNN criterion.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body False_Nearest_Neighbor
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

   -----------------------------------------------------------------------
   -- Internal helpers
   -----------------------------------------------------------------------

   function Last_Valid_Index
     (N_Len : Natural; M : Natural; Tau : Positive) return Integer
   is
   begin
      --  Largest n such that n + (M-1)*Tau <= N_Len.
      if M = 0 then
         return 0;
      end if;
      return Integer (N_Len) - Integer ((M - 1) * Tau);
   end Last_Valid_Index;

   procedure Require_Series_Capacity (Data : Series) is
   begin
      if Data'Length > Max_Series then
         raise Capacity_Exceeded
           with "series length exceeds Max_Series";
      end if;
   end Require_Series_Capacity;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Mean (Data : Series) return Real is
      S : Real := 0.0;
   begin
      if Data'Length = 0 then
         raise Invalid_Argument with "Mean requires at least one sample";
      end if;
      for X of Data loop
         S := S + X;
      end loop;
      return S / Real (Data'Length);
   end Mean;

   function Std_Dev (Data : Series) return Real is
      Mu    : Real;
      Acc   : Real := 0.0;
      Diff  : Real;
      Sigma : Real;
   begin
      if Data'Length < 2 then
         raise Invalid_Argument
           with "Std_Dev requires at least two samples";
      end if;
      Mu := Mean (Data);
      for X of Data loop
         Diff := X - Mu;
         Acc  := Acc + Diff * Diff;
      end loop;
      Sigma := EF.Sqrt (Acc / Real (Data'Length - 1));
      if Sigma <= Distance_Eps then
         raise Degenerate_Geometry
           with "Std_Dev: constant series (σ ≈ 0)";
      end if;
      return Sigma;
   end Std_Dev;

   -----------------------------------------------------------------------
   -- Configuration
   -----------------------------------------------------------------------

   function Make_Config
     (Tau                    : Positive  := 1;
      R_Tol                  : Real      := 15.0;
      A_Tol                  : Real      := 2.0;
      Theiler                : Natural   := 0;
      Max_Dim                : Dim_Index := 10;
      Use_Absolute_Criterion : Boolean   := True) return FNN_Config
   is
      C : FNN_Config;
   begin
      if R_Tol <= 0.0 then
         raise Invalid_Argument with "Make_Config: R_Tol must be positive";
      end if;
      if A_Tol <= 0.0 then
         raise Invalid_Argument with "Make_Config: A_Tol must be positive";
      end if;
      C.Tau := Tau;
      C.R_Tol := R_Tol;
      C.A_Tol := A_Tol;
      C.Theiler := Theiler;
      C.Max_Dim := Max_Dim;
      C.Use_Absolute_Criterion := Use_Absolute_Criterion;
      return C;
   end Make_Config;

   -----------------------------------------------------------------------
   -- Embedding geometry
   -----------------------------------------------------------------------

   function Embedding_Distance_Sq
     (Data : Series;
      N1   : Series_Index;
      N2   : Series_Index;
      M    : Dim_Index;
      Tau  : Positive) return Non_Negative
   is
      Acc  : Real := 0.0;
      Diff : Real;
      I1   : Natural;
      I2   : Natural;
   begin
      if not (N1 in Data'Range) or else not (N2 in Data'Range) then
         raise Invalid_Argument with "Embedding_Distance_Sq: index OOB";
      end if;
      if Natural (N1) + (Natural (M) - 1) * Tau > Natural (Data'Last)
        or else Natural (N2) + (Natural (M) - 1) * Tau > Natural (Data'Last)
      then
         raise Invalid_Argument
           with "Embedding_Distance_Sq: delay vector exceeds series";
      end if;

      for K in 0 .. Natural (M) - 1 loop
         I1 := Natural (N1) + K * Tau;
         I2 := Natural (N2) + K * Tau;
         Diff := Data (Series_Index (I1)) - Data (Series_Index (I2));
         Acc  := Acc + Diff * Diff;
      end loop;
      return Acc;
   end Embedding_Distance_Sq;

   function Nearest_Neighbor_Index
     (Data    : Series;
      N       : Series_Index;
      M       : Dim_Index;
      Tau     : Positive;
      Theiler : Natural := 0) return Series_Index
   is
      Last_N   : Integer;
      Best_Idx : Series_Index := N;
      Best_D2  : Real := Real'Last;
      D2       : Real;
      Found    : Boolean := False;
      Dist_T   : Integer;
   begin
      Require_Series_Capacity (Data);
      if Data'Length < 2 then
         raise Invalid_Argument
           with "Nearest_Neighbor_Index: need at least two samples";
      end if;
      if not (N in Data'Range) then
         raise Invalid_Argument with "Nearest_Neighbor_Index: N OOB";
      end if;

      Last_N := Last_Valid_Index (Natural (Data'Last), Natural (M), Tau);
      if Last_N < Integer (Data'First) then
         raise Invalid_Argument
           with "Nearest_Neighbor_Index: series too short for dimension";
      end if;
      if Integer (N) > Last_N then
         raise Invalid_Argument
           with "Nearest_Neighbor_Index: N not valid for dimension M";
      end if;

      for Cand in Data'First .. Series_Index (Last_N) loop
         if Cand /= N then
            Dist_T := abs (Integer (Cand) - Integer (N));
            if Dist_T > Integer (Theiler) then
               D2 := Embedding_Distance_Sq (Data, N, Cand, M, Tau);
               if (not Found) or else D2 < Best_D2 then
                  Best_D2  := D2;
                  Best_Idx := Cand;
                  Found    := True;
               end if;
            end if;
         end if;
      end loop;

      if not Found then
         raise Degenerate_Geometry
           with "Nearest_Neighbor_Index: no eligible neighbour";
      end if;
      return Best_Idx;
   end Nearest_Neighbor_Index;

   function Is_False_Neighbor
     (Data    : Series;
      N       : Series_Index;
      Np      : Series_Index;
      M       : Dim_Index;
      Config  : FNN_Config;
      Sigma   : Real) return Boolean
   is
      Tau    : constant Positive := Config.Tau;
      Rm2    : Real;
      Rm     : Real;
      Dx     : Real;
      Extra  : Natural;
      ExtraP : Natural;
      Rm1    : Real;
   begin
      if Config.R_Tol <= 0.0 or else Config.A_Tol <= 0.0 then
         raise Invalid_Argument with "Is_False_Neighbor: non-positive tol";
      end if;
      if Sigma < 0.0 then
         raise Invalid_Argument with "Is_False_Neighbor: Sigma < 0";
      end if;
      if not (N in Data'Range) or else not (Np in Data'Range) then
         raise Invalid_Argument with "Is_False_Neighbor: index OOB";
      end if;

      --  Need validity for M+1: n + M*Tau <= Last.
      Extra  := Natural (N)  + Natural (M) * Tau;
      ExtraP := Natural (Np) + Natural (M) * Tau;
      if Extra > Natural (Data'Last) or else ExtraP > Natural (Data'Last)
      then
         raise Invalid_Argument
           with "Is_False_Neighbor: indices invalid for m+1";
      end if;

      Rm2 := Embedding_Distance_Sq (Data, N, Np, M, Tau);
      Dx  := abs (Data (Series_Index (Extra))
                  - Data (Series_Index (ExtraP)));

      if Rm2 <= Distance_Eps then
         --  Identical (or near-identical) in ℝ^m: false iff next coords differ.
         return Dx > Distance_Eps;
      end if;

      Rm := EF.Sqrt (Rm2);

      --  Criterion 1: relative stretching.
      if Dx / Rm > Config.R_Tol then
         return True;
      end if;

      --  Criterion 2: absolute size vs series scale.
      if Config.Use_Absolute_Criterion then
         if Sigma <= Distance_Eps then
            raise Degenerate_Geometry
              with "Is_False_Neighbor: Sigma ≈ 0";
         end if;
         Rm1 := EF.Sqrt (Rm2 + Dx * Dx);
         if Rm1 / Sigma > Config.A_Tol then
            return True;
         end if;
      end if;

      return False;
   end Is_False_Neighbor;

   -----------------------------------------------------------------------
   -- FNN statistics
   -----------------------------------------------------------------------

   function False_Neighbor_Fraction
     (Data   : Series;
      M      : Dim_Index;
      Config : FNN_Config) return Unit_Interval
   is
      Tau     : constant Positive := Config.Tau;
      Theiler : constant Natural  := Config.Theiler;
      Last_N  : Integer;
      Sigma   : Real;
      False_N : Natural := 0;
      Tested  : Natural := 0;
      Np      : Series_Index;
   begin
      Require_Series_Capacity (Data);
      if Data'Length < 2 then
         raise Invalid_Argument
           with "False_Neighbor_Fraction: series too short";
      end if;
      if Config.R_Tol <= 0.0 or else Config.A_Tol <= 0.0 then
         raise Invalid_Argument
           with "False_Neighbor_Fraction: tolerances must be positive";
      end if;

      --  Reference points must be valid for dimension M+1.
      Last_N := Last_Valid_Index
        (Natural (Data'Last), Natural (M) + 1, Tau);
      if Last_N < Integer (Data'First) + 1 then
         raise Invalid_Argument
           with "False_Neighbor_Fraction: series too short for m+1";
      end if;

      Sigma := Std_Dev (Data);

      for N in Data'First .. Series_Index (Last_N) loop
         begin
            Np := Nearest_Neighbor_Index
              (Data, N, M, Tau, Theiler);
            --  Neighbour must also be valid for m+1.
            if Natural (Np) + Natural (M) * Tau <= Natural (Data'Last)
            then
               Tested := Tested + 1;
               if Is_False_Neighbor (Data, N, Np, M, Config, Sigma) then
                  False_N := False_N + 1;
               end if;
            end if;
         exception
            when Degenerate_Geometry =>
               null;  -- skip points with no eligible neighbour
         end;
      end loop;

      if Tested = 0 then
         raise Degenerate_Geometry
           with "False_Neighbor_Fraction: no points tested";
      end if;

      return Real (False_N) / Real (Tested);
   end False_Neighbor_Fraction;

   function FNN_Profile
     (Data   : Series;
      Config : FNN_Config) return Fraction_Array
   is
      Result : Fraction_Array (1 .. Config.Max_Dim);
   begin
      Require_Series_Capacity (Data);
      for M in 1 .. Config.Max_Dim loop
         Result (M) := False_Neighbor_Fraction (Data, M, Config);
      end loop;
      return Result;
   end FNN_Profile;

   function Estimate_Embedding_Dimension
     (Data      : Series;
      Config    : FNN_Config;
      Threshold : Real := 0.1) return Natural
   is
      Profile : Fraction_Array (1 .. Config.Max_Dim);
   begin
      if Threshold < 0.0 or else Threshold > 1.0 then
         raise Invalid_Argument
           with "Estimate_Embedding_Dimension: Threshold not in [0,1]";
      end if;
      Profile := FNN_Profile (Data, Config);
      for M in Profile'Range loop
         if Profile (M) <= Threshold then
            return Natural (M);
         end if;
      end loop;
      return 0;
   end Estimate_Embedding_Dimension;

end False_Nearest_Neighbor;

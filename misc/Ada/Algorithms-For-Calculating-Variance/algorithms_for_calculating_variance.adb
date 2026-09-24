--  Algorithms_For_Calculating_Variance — package body.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Algorithms_For_Calculating_Variance is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Sqrt_Nonneg (X : Non_Negative) return Non_Negative is
   begin
      if X = 0.0 then
         return 0.0;
      else
         return Non_Negative (Sqrt (X));
      end if;
   end Sqrt_Nonneg;

   function Require_Len_At_Least
     (Data : Real_Array; Min : Natural) return Natural
   is
      N : constant Natural := Data'Length;
   begin
      if N < Min then
         if Min = 0 or else Min = 1 then
            raise Empty_Sample;
         else
            raise Degenerate;
         end if;
      end if;
      return N;
   end Require_Len_At_Least;

   -------------------------------------------------------------------------
   -- Welford
   -------------------------------------------------------------------------

   function Make_Empty return Welford_State is
   begin
      return (Count => 0, Mean => 0.0, M2 => 0.0);
   end Make_Empty;

   procedure Reset (S : in out Welford_State) is
   begin
      S := Make_Empty;
   end Reset;

   procedure Update (S : in out Welford_State; X : Real) is
      Diff     : Real;
      Diff_New    : Real;
      New_Mean  : Real;
   begin
      S.Count := S.Count + 1;
      Diff := X - S.Mean;
      New_Mean := S.Mean + Diff / Real (S.Count);
      Diff_New := X - New_Mean;
      S.Mean := New_Mean;
      --  M2 is Non_Negative; theoretically non-decreasing for finite data.
      declare
         Next_M2 : constant Real := Real (S.M2) + Diff * Diff_New;
      begin
         if Next_M2 < 0.0 then
            S.M2 := 0.0;  --  clamp tiny negative FP noise
         else
            S.M2 := Non_Negative (Next_M2);
         end if;
      end;
   end Update;

   procedure Update_Many (S : in out Welford_State; Data : Real_Array) is
   begin
      for I in Data'Range loop
         Update (S, Data (I));
      end loop;
   end Update_Many;

   function Merge (A, B : Welford_State) return Welford_State is
      Result : Welford_State;
      Diff  : Real;
      N_A    : constant Natural := A.Count;
      N_B    : constant Natural := B.Count;
      N_AB   : Natural;
      Term   : Real;
   begin
      if N_A = 0 then
         return B;
      elsif N_B = 0 then
         return A;
      end if;

      N_AB := N_A + N_B;
      Diff := B.Mean - A.Mean;
      --  Prefer weighted-mean form (more stable when n_A ≈ n_B large).
      Result.Count := N_AB;
      Result.Mean :=
        (Real (N_A) * A.Mean + Real (N_B) * B.Mean) / Real (N_AB);
      Term := Diff * Diff * Real (N_A) * Real (N_B) / Real (N_AB);
      declare
         Next_M2 : constant Real := Real (A.M2) + Real (B.M2) + Term;
      begin
         if Next_M2 < 0.0 then
            Result.M2 := 0.0;
         else
            Result.M2 := Non_Negative (Next_M2);
         end if;
      end;
      return Result;
   end Merge;

   function Sample_Variance (S : Welford_State) return Non_Negative is
   begin
      if S.Count < 2 then
         raise Degenerate;
      end if;
      return Non_Negative (Real (S.M2) / Real (S.Count - 1));
   end Sample_Variance;

   function Population_Variance (S : Welford_State) return Non_Negative is
   begin
      if S.Count = 0 then
         raise Empty_Sample;
      end if;
      return Non_Negative (Real (S.M2) / Real (S.Count));
   end Population_Variance;

   function Std_Dev
     (S : Welford_State; Sample : Boolean := True) return Non_Negative
   is
   begin
      if Sample then
         return Sqrt_Nonneg (Sample_Variance (S));
      else
         return Sqrt_Nonneg (Population_Variance (S));
      end if;
   end Std_Dev;

   function From_Array (Data : Real_Array) return Welford_State is
      S : Welford_State := Make_Empty;
   begin
      Update_Many (S, Data);
      return S;
   end From_Array;

   -------------------------------------------------------------------------
   -- Naïve one-pass
   -------------------------------------------------------------------------

   procedure Naive_Sums
     (Data : Real_Array; N : out Natural; Sum, SumSq : out Real)
   is
   begin
      N := Data'Length;
      Sum := 0.0;
      SumSq := 0.0;
      for I in Data'Range loop
         Sum := Sum + Data (I);
         SumSq := SumSq + Data (I) * Data (I);
      end loop;
   end Naive_Sums;

   function Naive_Sample_Variance (Data : Real_Array) return Non_Negative is
      N     : Natural;
      Sum   : Real;
      SumSq : Real;
      Var   : Real;
   begin
      N := Require_Len_At_Least (Data, 2);
      Naive_Sums (Data, N, Sum, SumSq);
      Var := (SumSq - (Sum * Sum) / Real (N)) / Real (N - 1);
      if Var < 0.0 then
         return 0.0;  --  cancellation may produce tiny negatives
      end if;
      return Non_Negative (Var);
   end Naive_Sample_Variance;

   function Naive_Population_Variance
     (Data : Real_Array) return Non_Negative
   is
      N     : Natural;
      Sum   : Real;
      SumSq : Real;
      Var   : Real;
   begin
      N := Require_Len_At_Least (Data, 1);
      Naive_Sums (Data, N, Sum, SumSq);
      Var := (SumSq - (Sum * Sum) / Real (N)) / Real (N);
      if Var < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Var);
   end Naive_Population_Variance;

   -------------------------------------------------------------------------
   -- Shifted data
   -------------------------------------------------------------------------

   procedure Shifted_Sums
     (Data : Real_Array; K : Real; N : out Natural; Ex, Ex2 : out Real)
   is
      D : Real;
   begin
      N := Data'Length;
      Ex := 0.0;
      Ex2 := 0.0;
      for I in Data'Range loop
         D := Data (I) - K;
         Ex := Ex + D;
         Ex2 := Ex2 + D * D;
      end loop;
   end Shifted_Sums;

   function Shifted_Sample_Variance
     (Data : Real_Array; K : Real) return Non_Negative
   is
      N        : Natural;
      Ex, Ex2  : Real;
      Var      : Real;
   begin
      N := Require_Len_At_Least (Data, 2);
      Shifted_Sums (Data, K, N, Ex, Ex2);
      Var := (Ex2 - (Ex * Ex) / Real (N)) / Real (N - 1);
      if Var < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Var);
   end Shifted_Sample_Variance;

   function Shifted_Population_Variance
     (Data : Real_Array; K : Real) return Non_Negative
   is
      N        : Natural;
      Ex, Ex2  : Real;
      Var      : Real;
   begin
      N := Require_Len_At_Least (Data, 1);
      Shifted_Sums (Data, K, N, Ex, Ex2);
      Var := (Ex2 - (Ex * Ex) / Real (N)) / Real (N);
      if Var < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Var);
   end Shifted_Population_Variance;

   -------------------------------------------------------------------------
   -- Two-pass
   -------------------------------------------------------------------------

   function Two_Pass_Mean (Data : Real_Array) return Real is
      N   : constant Natural := Data'Length;
      Sum : Real := 0.0;
   begin
      if N = 0 then
         raise Empty_Sample;
      end if;
      for I in Data'Range loop
         Sum := Sum + Data (I);
      end loop;
      return Sum / Real (N);
   end Two_Pass_Mean;

   function Two_Pass_Sample_Variance (Data : Real_Array) return Non_Negative is
      N    : constant Natural := Require_Len_At_Least (Data, 2);
      Mean : constant Real := Two_Pass_Mean (Data);
      Acc  : Real := 0.0;
      D    : Real;
   begin
      for I in Data'Range loop
         D := Data (I) - Mean;
         Acc := Acc + D * D;
      end loop;
      return Non_Negative (Acc / Real (N - 1));
   end Two_Pass_Sample_Variance;

   function Two_Pass_Population_Variance
     (Data : Real_Array) return Non_Negative
   is
      N    : constant Natural := Require_Len_At_Least (Data, 1);
      Mean : constant Real := Two_Pass_Mean (Data);
      Acc  : Real := 0.0;
      D    : Real;
   begin
      for I in Data'Range loop
         D := Data (I) - Mean;
         Acc := Acc + D * D;
      end loop;
      return Non_Negative (Acc / Real (N));
   end Two_Pass_Population_Variance;

   -------------------------------------------------------------------------
   -- Weighted (West)
   -------------------------------------------------------------------------

   function Make_Empty_Weighted return Weighted_State is
   begin
      return (W_Sum => 0.0, W_Sum2 => 0.0, Mean => 0.0, S => 0.0, Count => 0);
   end Make_Empty_Weighted;

   procedure Reset_Weighted (S : in out Weighted_State) is
   begin
      S := Make_Empty_Weighted;
   end Reset_Weighted;

   procedure Update_Weighted
     (S : in out Weighted_State; X : Real; W : Non_Negative)
   is
      Mean_Old : Real;
      W_New    : Non_Negative;
      Next_S   : Real;
   begin
      if W = 0.0 then
         return;
      end if;
      Mean_Old := S.Mean;
      W_New := Non_Negative (Real (S.W_Sum) + Real (W));
      S.W_Sum2 := Non_Negative (Real (S.W_Sum2) + Real (W) * Real (W));
      S.Mean := Mean_Old + (Real (W) / Real (W_New)) * (X - Mean_Old);
      Next_S :=
        Real (S.S) + Real (W) * (X - Mean_Old) * (X - S.Mean);
      if Next_S < 0.0 then
         S.S := 0.0;
      else
         S.S := Non_Negative (Next_S);
      end if;
      S.W_Sum := W_New;
      S.Count := S.Count + 1;
   end Update_Weighted;

   function Weighted_Population_Variance
     (S : Weighted_State) return Non_Negative
   is
   begin
      if S.W_Sum = 0.0 then
         raise Empty_Sample;
      end if;
      return Non_Negative (Real (S.S) / Real (S.W_Sum));
   end Weighted_Population_Variance;

   function Weighted_Frequency_Sample_Variance
     (S : Weighted_State) return Non_Negative
   is
   begin
      if Real (S.W_Sum) <= 1.0 then
         raise Degenerate;
      end if;
      return Non_Negative (Real (S.S) / (Real (S.W_Sum) - 1.0));
   end Weighted_Frequency_Sample_Variance;

   function Weighted_Reliability_Sample_Variance
     (S : Weighted_State) return Non_Negative
   is
      Denom : Real;
   begin
      if S.W_Sum = 0.0 then
         raise Empty_Sample;
      end if;
      Denom := Real (S.W_Sum) - Real (S.W_Sum2) / Real (S.W_Sum);
      if Denom <= 0.0 then
         raise Degenerate;
      end if;
      return Non_Negative (Real (S.S) / Denom);
   end Weighted_Reliability_Sample_Variance;

   function From_Weighted_Arrays
     (Data : Real_Array; Weights : Weight_Array) return Weighted_State
   is
      S : Weighted_State := Make_Empty_Weighted;
   begin
      if Data'Length /= Weights'Length then
         raise Invalid_Argument;
      end if;
      for I in Data'Range loop
         --  Align by position: Weights uses same index offset from 'First.
         Update_Weighted
           (S, Data (I),
            Weights (Weights'First + (I - Data'First)));
      end loop;
      return S;
   end From_Weighted_Arrays;

   -------------------------------------------------------------------------
   -- Online covariance
   -------------------------------------------------------------------------

   function Make_Empty_Covariance return Covariance_State is
   begin
      return (Count => 0, Mean_X => 0.0, Mean_Y => 0.0, C => 0.0);
   end Make_Empty_Covariance;

   procedure Reset_Covariance (S : in out Covariance_State) is
   begin
      S := Make_Empty_Covariance;
   end Reset_Covariance;

   procedure Update_Covariance
     (S : in out Covariance_State; X, Y : Real)
   is
      Dx_Old : Real;
      Dy_Old : Real;
   begin
      S.Count := S.Count + 1;
      Dx_Old := X - S.Mean_X;
      Dy_Old := Y - S.Mean_Y;
      S.Mean_X := S.Mean_X + Dx_Old / Real (S.Count);
      S.Mean_Y := S.Mean_Y + Dy_Old / Real (S.Count);
      --  Wikipedia form: C_n = C_{n-1} + (x_n - mean_x_n)*(y_n - mean_y_{n-1})
      S.C := S.C + (X - S.Mean_X) * Dy_Old;
   end Update_Covariance;

   function Sample_Covariance (S : Covariance_State) return Real is
   begin
      if S.Count < 2 then
         raise Degenerate;
      end if;
      return S.C / Real (S.Count - 1);
   end Sample_Covariance;

   function Population_Covariance (S : Covariance_State) return Real is
   begin
      if S.Count = 0 then
         raise Empty_Sample;
      end if;
      return S.C / Real (S.Count);
   end Population_Covariance;

   function Two_Pass_Sample_Covariance
     (X, Y : Real_Array) return Real
   is
      N      : Natural;
      Mean_X : Real;
      Mean_Y : Real;
      Acc    : Real := 0.0;
   begin
      if X'Length /= Y'Length then
         raise Invalid_Argument;
      end if;
      N := X'Length;
      if N < 2 then
         raise Degenerate;
      end if;
      Mean_X := Two_Pass_Mean (X);
      Mean_Y := Two_Pass_Mean (Y);
      for I in X'Range loop
         Acc := Acc +
           (X (I) - Mean_X) *
           (Y (Y'First + (I - X'First)) - Mean_Y);
      end loop;
      return Acc / Real (N - 1);
   end Two_Pass_Sample_Covariance;

end Algorithms_For_Calculating_Variance;

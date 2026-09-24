--  Yamartino_Method body — single-pass circular mean / std of wind direction.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Yamartino_Method
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   -----------------------------------------------------------------------
   -- Internal helpers
   -----------------------------------------------------------------------

   function Clamp01 (X : Real) return Real is
   begin
      if X < 0.0 then
         return 0.0;
      elsif X > 1.0 then
         return 1.0;
      else
         return X;
      end if;
   end Clamp01;

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Sqrt (X);
      end if;
   end Sqrt_Safe;

   function Shortest_Diff (A, B : Angle_Radians) return Angle_Radians is
      --  Signed shortest difference A − B in (−π, π].
      D : Angle_Radians := Normalize_Angle (A) - Normalize_Angle (B);
   begin
      if D > Pi then
         D := D - Two_Pi;
      elsif D <= -Pi then
         D := D + Two_Pi;
      end if;
      return D;
   end Shortest_Diff;

   function Build_Result
     (N : Natural; Sum_Sin, Sum_Cos : Real) return Yamartino_Result
   is
      Sa, Ca, R, Eps, Mean, Sig : Real;
      Res : Yamartino_Result;
   begin
      if N = 0 then
         raise Empty_Sample with "Yamartino requires at least one sample";
      end if;

      Sa := Sum_Sin / Real (N);
      Ca := Sum_Cos / Real (N);
      R := Mean_Resultant_Length (Sa, Ca);
      Eps := Epsilon_From_Resultant (R);
      Mean := Arctan (Y => Sa, X => Ca);
      --  Ada Arctan (Y, X) is four-quadrant; Wikipedia arctan(ca, sa).
      if N = 1 then
         Sig := 0.0;
         Eps := 0.0;
      else
         Sig := Yamartino_Sigma (Eps);
      end if;

      Res :=
        (Mean      => Mean,
         Std_Dev   => Non_Negative (Sig),
         Count     => N,
         Epsilon   => Non_Negative (Eps),
         Resultant => Non_Negative (R),
         Sa        => Sa,
         Ca        => Ca);
      return Res;
   end Build_Result;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Angle
     (A, B : Angle_Radians; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return abs (Shortest_Diff (A, B)) <= Tol;
   end Near_Angle;

   -----------------------------------------------------------------------
   -- Angle conversion / normalization
   -----------------------------------------------------------------------

   function To_Radians (D : Angle_Degrees) return Angle_Radians is
   begin
      return D * Pi / 180.0;
   end To_Radians;

   function To_Degrees (R : Angle_Radians) return Angle_Degrees is
   begin
      return R * 180.0 / Pi;
   end To_Degrees;

   function Normalize_Angle (R : Angle_Radians) return Angle_Radians is
      X : Real := R;
   begin
      --  Bring into (−π, π].
      while X <= -Pi loop
         X := X + Two_Pi;
      end loop;
      while X > Pi loop
         X := X - Two_Pi;
      end loop;
      return X;
   end Normalize_Angle;

   function Normalize_Degrees (D : Angle_Degrees) return Angle_Degrees is
      X : Real := D;
   begin
      while X < 0.0 loop
         X := X + 360.0;
      end loop;
      while X >= 360.0 loop
         X := X - 360.0;
      end loop;
      return X;
   end Normalize_Degrees;

   function Mean_Degrees (R : Yamartino_Result) return Angle_Degrees is
   begin
      return Normalize_Degrees (To_Degrees (R.Mean));
   end Mean_Degrees;

   function Std_Dev_Degrees (R : Yamartino_Result) return Non_Negative is
   begin
      return Non_Negative (To_Degrees (R.Std_Dev));
   end Std_Dev_Degrees;

   -----------------------------------------------------------------------
   -- Running accumulator
   -----------------------------------------------------------------------

   function Make_Empty return Running_Yamartino is
   begin
      return (N => 0, Sum_Sin => 0.0, Sum_Cos => 0.0);
   end Make_Empty;

   procedure Reset (Acc : in out Running_Yamartino) is
   begin
      Acc := Make_Empty;
   end Reset;

   function Count (Acc : Running_Yamartino) return Natural is
   begin
      return Acc.N;
   end Count;

   procedure Add_Sample
     (Acc : in out Running_Yamartino; Theta : Angle_Radians)
   is
   begin
      if Acc.N = Natural'Last then
         raise Capacity_Exceeded with "accumulator overflow";
      end if;
      Acc.N := Acc.N + 1;
      Acc.Sum_Sin := Acc.Sum_Sin + Sin (Theta);
      Acc.Sum_Cos := Acc.Sum_Cos + Cos (Theta);
   end Add_Sample;

   procedure Add_Degrees
     (Acc : in out Running_Yamartino; Degrees : Angle_Degrees)
   is
   begin
      Add_Sample (Acc, To_Radians (Degrees));
   end Add_Degrees;

   function Finalize (Acc : Running_Yamartino) return Yamartino_Result is
   begin
      if Acc.N = 0 then
         raise Empty_Sample with "Finalize on empty accumulator";
      end if;
      return Build_Result (Acc.N, Acc.Sum_Sin, Acc.Sum_Cos);
   end Finalize;

   -----------------------------------------------------------------------
   -- Batch
   -----------------------------------------------------------------------

   function Yamartino (Samples : Angle_Array) return Yamartino_Result is
      Acc : Running_Yamartino := Make_Empty;
   begin
      if Samples'Length = 0 then
         raise Empty_Sample with "Yamartino on empty array";
      end if;
      for I in Samples'Range loop
         Add_Sample (Acc, Samples (I));
      end loop;
      return Finalize (Acc);
   end Yamartino;

   function Yamartino_Degrees (Samples : Degree_Array) return Yamartino_Result
   is
      Acc : Running_Yamartino := Make_Empty;
   begin
      if Samples'Length = 0 then
         raise Empty_Sample with "Yamartino_Degrees on empty array";
      end if;
      for I in Samples'Range loop
         Add_Degrees (Acc, Samples (I));
      end loop;
      return Finalize (Acc);
   end Yamartino_Degrees;

   -----------------------------------------------------------------------
   -- Formula pieces
   -----------------------------------------------------------------------

   function Mean_Resultant_Length (Sa, Ca : Real) return Non_Negative is
      R2 : constant Real := Sa * Sa + Ca * Ca;
   begin
      return Non_Negative (Clamp01 (Sqrt_Safe (R2)));
   end Mean_Resultant_Length;

   function Epsilon_From_Resultant (R : Non_Negative) return Non_Negative is
      RR : constant Real := Clamp01 (R);
      One_Minus : constant Real := 1.0 - RR * RR;
   begin
      return Non_Negative (Sqrt_Safe (One_Minus));
   end Epsilon_From_Resultant;

   function Yamartino_Sigma (Eps : Non_Negative) return Non_Negative is
      E   : constant Real := Clamp01 (Eps);
      E3  : constant Real := E * E * E;
      Fac : constant Real := 2.0 / Sqrt (3.0) - 1.0;
      --  arcsin domain [−1,1]; E in [0,1].
      Base : constant Real := Arcsin (E);
   begin
      return Non_Negative (Base * (1.0 + Fac * E3));
   end Yamartino_Sigma;

   -----------------------------------------------------------------------
   -- Two-pass circular reference
   -----------------------------------------------------------------------

   function Circular_Mean (Samples : Angle_Array) return Angle_Radians is
      Sum_S : Real := 0.0;
      Sum_C : Real := 0.0;
   begin
      if Samples'Length = 0 then
         raise Empty_Sample;
      end if;
      for I in Samples'Range loop
         Sum_S := Sum_S + Sin (Samples (I));
         Sum_C := Sum_C + Cos (Samples (I));
      end loop;
      return Arctan
        (Y => Sum_S / Real (Samples'Length),
         X => Sum_C / Real (Samples'Length));
   end Circular_Mean;

   function Circular_Std_Dev_Two_Pass
     (Samples : Angle_Array) return Non_Negative
   is
      --  Via mean resultant length: σ = sqrt(−2 ln R) (Fisher / Mardia).
      --  Falls back to Yamartino-scale π/√3 when R ≈ 0.
      Sum_S : Real := 0.0;
      Sum_C : Real := 0.0;
      Sa, Ca, R : Real;
   begin
      if Samples'Length = 0 then
         raise Empty_Sample;
      end if;
      if Samples'Length = 1 then
         return 0.0;
      end if;
      for I in Samples'Range loop
         Sum_S := Sum_S + Sin (Samples (I));
         Sum_C := Sum_C + Cos (Samples (I));
      end loop;
      Sa := Sum_S / Real (Samples'Length);
      Ca := Sum_C / Real (Samples'Length);
      R := Clamp01 (Sqrt_Safe (Sa * Sa + Ca * Ca));
      if R < 1.0E-12 then
         return Non_Negative (Pi / Sqrt (3.0));
      elsif R >= 1.0 - 1.0E-15 then
         return 0.0;
      else
         return Non_Negative (Sqrt_Safe (-2.0 * Log (R)));
      end if;
   end Circular_Std_Dev_Two_Pass;

   function Circular_Std_Dev_Angular
     (Samples : Angle_Array) return Non_Negative
   is
      Mu  : constant Angle_Radians := Circular_Mean (Samples);
      Acc : Real := 0.0;
      D   : Real;
      N   : constant Natural := Samples'Length;
   begin
      if N = 1 then
         return 0.0;
      end if;
      for I in Samples'Range loop
         D := Shortest_Diff (Samples (I), Mu);
         Acc := Acc + D * D;
      end loop;
      return Non_Negative (Sqrt_Safe (Acc / Real (N)));
   end Circular_Std_Dev_Angular;

   -----------------------------------------------------------------------
   -- Naive linear (wrong for wrap-around)
   -----------------------------------------------------------------------

   function Naive_Linear_Mean (Samples : Angle_Array) return Angle_Radians is
      Acc : Real := 0.0;
   begin
      if Samples'Length = 0 then
         raise Empty_Sample;
      end if;
      for I in Samples'Range loop
         Acc := Acc + Samples (I);
      end loop;
      return Acc / Real (Samples'Length);
   end Naive_Linear_Mean;

   function Naive_Linear_Std_Dev (Samples : Angle_Array) return Non_Negative is
      Mu  : constant Real := Naive_Linear_Mean (Samples);
      Acc : Real := 0.0;
      D   : Real;
      N   : constant Natural := Samples'Length;
   begin
      if N = 1 then
         return 0.0;
      end if;
      for I in Samples'Range loop
         D := Samples (I) - Mu;
         Acc := Acc + D * D;
      end loop;
      return Non_Negative (Sqrt_Safe (Acc / Real (N)));
   end Naive_Linear_Std_Dev;

end Yamartino_Method;

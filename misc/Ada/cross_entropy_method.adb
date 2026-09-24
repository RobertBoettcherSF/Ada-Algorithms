--  Cross_Entropy_Method body — Rubinstein CE educational implementation:
--  Init_Isotropic, Sample_Gaussian, Elite_Indices, Update_From_Elite,
--  Step, Minimize; optional Bernoulli sketch for tiny knapsack toys.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body Cross_Entropy_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if Lo > Hi then
         raise Invalid_Argument;
      end if;
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Elite_Count (N : Sample_Size; Rho : Elite_Fraction) return Positive
   is
      Raw : constant Natural :=
        Natural (Float'Floor (Float (Rho) * Float (N)));
      Ne  : Positive;
   begin
      if Raw < 1 then
         Ne := 1;
      elsif Raw > N then
         Ne := N;
      else
         Ne := Raw;
      end if;
      return Ne;
   end Elite_Count;

   function Default_Parameters
     (N         : Sample_Size    := 100;
      Rho       : Elite_Fraction := 0.1;
      Alpha     : Smooth_Factor  := 0.7;
      Max_Iter  : Natural        := 100;
      Seed      : Natural        := 1;
      Sigma_Min : Non_Negative   := 1.0E-6) return Parameters
   is
   begin
      return
        (N         => N,
         Rho       => Rho,
         Alpha     => Alpha,
         Max_Iter  => Max_Iter,
         Seed      => Seed,
         Sigma_Min => Sigma_Min);
   end Default_Parameters;

   ---------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   ---------------------------------------------------------------------------

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Uniform;

   function Next_Index
     (State : in out RNG_State; Lo, Hi : Positive) return Positive
   is
      Span : constant Natural := Hi - Lo + 1;
      U    : constant Unit_Interval := Next_Unit (State);
      Off  : Natural;
   begin
      Off := Natural (Real (U) * Real (Span));
      if Off >= Span then
         Off := Span - 1;
      end if;
      return Lo + Off;
   end Next_Index;

   function Next_Gaussian
     (State : in out RNG_State; Mean, Std : Real) return Real
   is
      U1, U2 : Unit_Interval;
      R, Theta : Float;
      Z : Real;
   begin
      if Std = 0.0 then
         return Mean;
      end if;
      --  Box–Muller; reject tiny U1 to keep ln defined / stable.
      loop
         U1 := Next_Unit (State);
         exit when Real (U1) > 1.0E-12;
      end loop;
      U2 := Next_Unit (State);
      R := Sqrt (-2.0 * Log (Float (U1)));
      Theta := 2.0 * Float (Pi) * Float (U2);
      Z := Real (R * Cos (Theta));
      return Mean + Std * Z;
   end Next_Gaussian;

   function Next_Bernoulli
     (State : in out RNG_State; P : Unit_Interval) return Boolean
   is
   begin
      return Real (Next_Unit (State)) < Real (P);
   end Next_Bernoulli;

   ---------------------------------------------------------------------------
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Rosenbrock (X : Vector) return Real is
      A  : constant Real := 1.0;
      B  : constant Real := 100.0;
      Xx : Real;
      Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (A - Xx) ** 2 + B * (Yy - Xx ** 2) ** 2;
   end Rosenbrock;

   function Rastrigin (X : Vector) return Real is
      Two_Pi : constant Float := 2.0 * Float (Pi);
      S      : Real := 10.0 * Real (X'Length);
   begin
      for I in X'Range loop
         declare
            Xi : constant Float := Float (X (I));
         begin
            S := S + Real (Xi * Xi - 10.0 * Cos (Two_Pi * Xi));
         end;
      end loop;
      return S;
   end Rastrigin;

   function Shifted_Sphere (X : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         declare
            D : constant Real := X (I) - 1.0;
         begin
            S := S + D * D;
         end;
      end loop;
      return S;
   end Shifted_Sphere;

   ---------------------------------------------------------------------------
   -- Continuous CE primitives
   ---------------------------------------------------------------------------

   function Init_Isotropic
     (Dim : Dimension; Mean, Std : Real) return Gaussian_Params
   is
      G : Gaussian_Params;
   begin
      G.Dim := Dim;
      for D in 1 .. Dim loop
         G.Means (D) := Mean;
         G.Stds (D)  := Std;
      end loop;
      for D in Dim + 1 .. Max_Dim loop
         G.Means (D) := 0.0;
         G.Stds (D)  := 0.0;
      end loop;
      return G;
   end Init_Isotropic;

   procedure Sample_Gaussian
     (Buf    : in out Sample_Buffer;
      Params : Gaussian_Params;
      State  : in out RNG_State)
   is
      D : constant Dimension := Params.Dim;
   begin
      for K in 1 .. Buf.Capacity loop
         Buf.Members (K).Dim := D;
         Buf.Members (K).Cost := Real'Last;
         for J in 1 .. D loop
            Buf.Members (K).X (J) :=
              Next_Gaussian (State, Params.Means (J), Params.Stds (J));
         end loop;
         for J in D + 1 .. Max_Dim loop
            Buf.Members (K).X (J) := 0.0;
         end loop;
      end loop;
      Buf.Size := Buf.Capacity;
      Buf.Dim  := D;
   end Sample_Gaussian;

   procedure Evaluate_Samples
     (Buf       : in out Sample_Buffer;
      Objective : Objective_Fn)
   is
      D : constant Dimension := Buf.Dim;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      for K in 1 .. Buf.Size loop
         Buf.Members (K).Cost :=
           Objective (Buf.Members (K).X (1 .. D));
      end loop;
   end Evaluate_Samples;

   function Elite_Indices
     (Buf : Sample_Buffer;
      Rho : Elite_Fraction) return Index_List
   is
      N  : constant Sample_Size := Sample_Size (Buf.Size);
      Ne : constant Positive := Elite_Count (N, Rho);
      --  Working permutation of 1 .. Size, sorted by ascending Cost.
      Order : array (1 .. Buf.Size) of Positive;
      Result_List : Index_List (1 .. Ne);
   begin
      for I in 1 .. Buf.Size loop
         Order (I) := I;
      end loop;
      --  Stable-ish insertion sort (small N educational).
      for I in 2 .. Buf.Size loop
         declare
            Key : constant Positive := Order (I);
            J   : Natural := I - 1;
         begin
            while J >= 1
              and then
                (Buf.Members (Order (J)).Cost > Buf.Members (Key).Cost
                 or else
                   (Buf.Members (Order (J)).Cost = Buf.Members (Key).Cost
                    and then Order (J) > Key))
            loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;
      for K in 1 .. Ne loop
         Result_List (K) := Order (K);
      end loop;
      return Result_List;
   end Elite_Indices;

   procedure Update_From_Elite
     (G          : in out Gaussian_Params;
      Buf        : Sample_Buffer;
      Elite      : Index_List;
      Alpha      : Smooth_Factor;
      Sigma_Min  : Non_Negative)
   is
      Ne : constant Positive := Elite'Length;
      D  : constant Dimension := G.Dim;
      Mu_E : Vector (1 .. D);
      Sd_E : Vector (1 .. D);
      One_Minus_A : constant Real := 1.0 - Real (Alpha);
   begin
      for J in 1 .. D loop
         declare
            S : Real := 0.0;
         begin
            for K in Elite'Range loop
               declare
                  Idx : constant Positive := Elite (K);
               begin
                  if Idx > Buf.Size then
                     raise Invalid_Argument;
                  end if;
                  S := S + Buf.Members (Idx).X (J);
               end;
            end loop;
            Mu_E (J) := S / Real (Ne);
         end;
      end loop;

      for J in 1 .. D loop
         if Ne = 1 then
            Sd_E (J) := 0.0;
         else
            declare
               Acc : Real := 0.0;
               Diff : Real;
            begin
               for K in Elite'Range loop
                  Diff := Buf.Members (Elite (K)).X (J) - Mu_E (J);
                  Acc := Acc + Diff * Diff;
               end loop;
               --  Population std (MLE) matching CE / EMNA style.
               Sd_E (J) := Real (Sqrt (Float (Acc / Real (Ne))));
            end;
         end if;
      end loop;

      for J in 1 .. D loop
         G.Means (J) :=
           One_Minus_A * G.Means (J) + Real (Alpha) * Mu_E (J);
         G.Stds (J) :=
           One_Minus_A * G.Stds (J) + Real (Alpha) * Sd_E (J);
         if G.Stds (J) < Sigma_Min then
            G.Stds (J) := Sigma_Min;
         end if;
      end loop;
   end Update_From_Elite;

   procedure Track_Best
     (Buf       : Sample_Buffer;
      Best_Cost : in out Real;
      Best_X    : in out Vector)
   is
      D : constant Dimension := Buf.Dim;
   begin
      for K in 1 .. Buf.Size loop
         if Buf.Members (K).Cost < Best_Cost then
            Best_Cost := Buf.Members (K).Cost;
            for J in 1 .. D loop
               Best_X (Best_X'First + J - 1) := Buf.Members (K).X (J);
            end loop;
         end if;
      end loop;
   end Track_Best;

   procedure Step
     (G         : in out Gaussian_Params;
      Buf       : in out Sample_Buffer;
      Params    : Parameters;
      Objective : Objective_Fn;
      State     : in out RNG_State;
      Best_Cost : in out Real;
      Best_X    : in out Vector)
   is
      --  Temporarily shrink active sample count to Params.N via local buffer
      --  view: we sample into Buf but only use first Params.N slots.
      N : constant Sample_Size := Params.N;
   begin
      if Buf.Capacity < N then
         raise Invalid_Argument;
      end if;
      if Objective = null then
         raise Invalid_Argument;
      end if;

      --  Sample into full capacity then restrict Size to N for elite/update.
      Sample_Gaussian (Buf, G, State);
      Buf.Size := N;
      Evaluate_Samples (Buf, Objective);

      declare
         Elite : constant Index_List := Elite_Indices (Buf, Params.Rho);
      begin
         Track_Best (Buf, Best_Cost, Best_X);
         Update_From_Elite
           (G, Buf, Elite, Params.Alpha, Params.Sigma_Min);
      end;
   end Step;

   ---------------------------------------------------------------------------
   -- Bernoulli sketch
   ---------------------------------------------------------------------------

   function Init_Bernoulli
     (Dim : Dimension; P : Unit_Interval := 0.5) return Bernoulli_Params
   is
      B : Bernoulli_Params;
   begin
      B.Dim := Dim;
      for D in 1 .. Dim loop
         B.Probs (D) := Real (P);
      end loop;
      for D in Dim + 1 .. Max_Dim loop
         B.Probs (D) := 0.0;
      end loop;
      return B;
   end Init_Bernoulli;

   procedure Sample_Bernoulli_Bits
     (Bits   : out Bit_Vector;
      B      : Bernoulli_Params;
      State  : in out RNG_State)
   is
      Bi : Natural := Bits'First;
   begin
      for J in 1 .. B.Dim loop
         Bits (Bi) :=
           Next_Bernoulli (State, Unit_Interval (Clamp (B.Probs (J), 0.0, 1.0)));
         Bi := Bi + 1;
      end loop;
   end Sample_Bernoulli_Bits;

   procedure Update_Bernoulli_From_Elite
     (B          : in out Bernoulli_Params;
      Elite_Bits : Bit_Vector;
      Elite_N    : Positive;
      Alpha      : Smooth_Factor)
   is
      D : constant Dimension := B.Dim;
      Eps : constant Real := 1.0E-6;
      One_Minus_A : constant Real := 1.0 - Real (Alpha);
      Base : Natural;
      Freq : Real;
      Ones : Natural;
   begin
      if Elite_Bits'Length /= Natural (D) * Elite_N then
         raise Invalid_Argument;
      end if;
      for J in 1 .. D loop
         Ones := 0;
         for K in 0 .. Elite_N - 1 loop
            Base := Elite_Bits'First + K * Natural (D) + (J - 1);
            if Elite_Bits (Base) then
               Ones := Ones + 1;
            end if;
         end loop;
         Freq := Real (Ones) / Real (Elite_N);
         B.Probs (J) :=
           One_Minus_A * B.Probs (J) + Real (Alpha) * Freq;
         B.Probs (J) := Clamp (B.Probs (J), Eps, 1.0 - Eps);
      end loop;
   end Update_Bernoulli_From_Elite;

   function Tiny_Knapsack_Value
     (Bits     : Bit_Vector;
      Values   : Vector;
      Weights  : Vector;
      Capacity : Non_Negative) return Real
   is
      W : Real := 0.0;
      V : Real := 0.0;
      Bi : Natural := Bits'First;
      Vi : Natural := Values'First;
      Wi : Natural := Weights'First;
   begin
      for K in 1 .. Bits'Length loop
         if Bits (Bi) then
            W := W + Weights (Wi);
            V := V + Values (Vi);
         end if;
         Bi := Bi + 1;
         Vi := Vi + 1;
         Wi := Wi + 1;
      end loop;
      if W > Capacity then
         return -1.0E30;
      else
         return V;
      end if;
   end Tiny_Knapsack_Value;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Mean_Std_Max (G : Gaussian_Params) return Real is
      M : Real := 0.0;
   begin
      for J in 1 .. G.Dim loop
         if G.Stds (J) > M then
            M := G.Stds (J);
         end if;
      end loop;
      return M;
   end Mean_Std_Max;

   function Minimize
     (Objective : Objective_Fn;
      Init      : Gaussian_Params;
      Params    : Parameters) return Result
   is
      G     : Gaussian_Params := Init;
      Buf   : Sample_Buffer (Capacity => Params.N);
      State : RNG_State;
      Res   : Result;
      Best_Cost : Real := Real'Last;
      Best_X    : Vector (1 .. Max_Dim) := [others => 0.0];
      D : constant Dimension := Init.Dim;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      for J in 1 .. D loop
         if G.Stds (J) < 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;

      Seed_RNG (State, Params.Seed);
      Res.Dim := D;
      Res.Samples_Used := Params.N;

      if Params.Max_Iter = 0 then
         --  Init-only: one evaluation batch without update.
         Sample_Gaussian (Buf, G, State);
         Evaluate_Samples (Buf, Objective);
         Track_Best (Buf, Best_Cost, Best_X);
         Res.Best_Cost := Best_Cost;
         Res.Best_X := Best_X;
         Res.Iterations := 0;
         for J in 1 .. D loop
            Res.Final_Mean (J) := G.Means (J);
            Res.Final_Std (J)  := G.Stds (J);
         end loop;
         return Res;
      end if;

      for Iter in 1 .. Params.Max_Iter loop
         Step (G, Buf, Params, Objective, State, Best_Cost, Best_X);
         Res.Iterations := Iter;
         --  Early stop when max σ is near the floor (distribution collapsed).
         exit when Mean_Std_Max (G) <= Params.Sigma_Min * 1.5;
      end loop;

      Res.Best_Cost := Best_Cost;
      Res.Best_X := Best_X;
      for J in 1 .. D loop
         Res.Final_Mean (J) := G.Means (J);
         Res.Final_Std (J)  := G.Stds (J);
      end loop;
      return Res;
   end Minimize;

   function Minimize_Isotropic
     (Objective : Objective_Fn;
      Dim       : Dimension;
      Mean      : Real := 0.0;
      Std       : Real := 5.0;
      Params    : Parameters := Default_Parameters) return Result
   is
      G : constant Gaussian_Params := Init_Isotropic (Dim, Mean, Std);
   begin
      return Minimize (Objective, G, Params);
   end Minimize_Isotropic;

end Cross_Entropy_Method;

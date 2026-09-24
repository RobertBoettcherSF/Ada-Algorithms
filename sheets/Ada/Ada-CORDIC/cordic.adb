--  Cordic body — circular CORDIC (Volder) rotation / vectoring in Long_Float.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Cordic
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Prefill tables (elaborated once)
   ---------------------------------------------------------------------------

   --  θ_i = arctan(2^{-i})
   type Angle_Table is array (0 .. Max_Iterations - 1) of Long_Float;
   --  An(N) = 1/K_N for N iterations (CORDIC scale factor A_n).
   type Inv_K_Table is array (Iteration_Count) of Long_Float;

   function Build_Arctan_Table return Angle_Table is
      T : Angle_Table;
      P : Long_Float := 1.0;  -- 2^{-i}
   begin
      for I in T'Range loop
         T (I) := EF.Arctan (P);
         P := P * 0.5;
      end loop;
      return T;
   end Build_Arctan_Table;

   function Build_Inv_K_Table return Inv_K_Table is
      T     : Inv_K_Table;
      Prod  : Long_Float := 1.0;  -- running product K = ∏ cos(θ_i)
      Two_I : Long_Float := 1.0;  -- 2^{-2i}; i=0 → 1
   begin
      for N in Iteration_Count loop
         --  cos(arctan(2^{-(N-1)})) = 1/√(1+2^{-2(N-1)})
         declare
            Factor : constant Long_Float :=
              1.0 / EF.Sqrt (1.0 + Two_I);
         begin
            Prod := Prod * Factor;
            T (N) := 1.0 / Prod;
            Two_I := Two_I * 0.25;
         end;
      end loop;
      return T;
   end Build_Inv_K_Table;

   Arctans : constant Angle_Table := Build_Arctan_Table;
   Inv_Ks  : constant Inv_K_Table := Build_Inv_K_Table;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (Approx_V, Exact_V : Long_Float) return Long_Float is
   begin
      return abs (Approx_V - Exact_V);
   end Abs_Error;

   function Rel_Error (Approx_V, Exact_V : Long_Float) return Long_Float is
   begin
      if Exact_V = 0.0 then
         if Approx_V = 0.0 then
            return 0.0;
         else
            return 1.0E30;
         end if;
      end if;
      return abs (Approx_V - Exact_V) / abs (Exact_V);
   end Rel_Error;

   function Reduce_Angle (Angle : Long_Float) return Long_Float is
      A : Long_Float := Angle;
   begin
      while A > Pi loop
         A := A - Two_Pi;
      end loop;
      while A <= -Pi loop
         A := A + Two_Pi;
      end loop;
      return A;
   end Reduce_Angle;

   function Arctan_Table (I : Natural) return Long_Float is
   begin
      return Arctans (I);
   end Arctan_Table;

   function Gain_K (N : Iteration_Count) return Long_Float is
   begin
      return 1.0 / Inv_Ks (N);
   end Gain_K;

   function Inv_Gain_K (N : Iteration_Count) return Long_Float is
   begin
      return Inv_Ks (N);
   end Inv_Gain_K;

   ---------------------------------------------------------------------------
   -- Oracles
   ---------------------------------------------------------------------------

   function Exact_Sin (Angle : Long_Float) return Long_Float is
   begin
      return EF.Sin (Angle);
   end Exact_Sin;

   function Exact_Cos (Angle : Long_Float) return Long_Float is
   begin
      return EF.Cos (Angle);
   end Exact_Cos;

   function Exact_Arctan (Y : Long_Float) return Long_Float is
   begin
      return EF.Arctan (Y);
   end Exact_Arctan;

   function Exact_Atan2 (Y, X : Long_Float) return Long_Float is
   begin
      return EF.Arctan (Y, X);
   end Exact_Atan2;

   function Exact_Hypot (X, Y : Long_Float) return Long_Float is
      AX : constant Long_Float := abs (X);
      AY : constant Long_Float := abs (Y);
   begin
      if AX = 0.0 and then AY = 0.0 then
         return 0.0;
      end if;
      return EF.Sqrt (AX * AX + AY * AY);
   end Exact_Hypot;

   ---------------------------------------------------------------------------
   -- Educational power-of-half (stand-in for an arithmetic right shift)
   ---------------------------------------------------------------------------

   function Pow2_Neg (I : Natural) return Long_Float is
      P : Long_Float := 1.0;
   begin
      for K in 1 .. I loop
         P := P * 0.5;
      end loop;
      return P;
   end Pow2_Neg;

   procedure Rotate_Step
     (X, Y, Z : in out Long_Float;
      I       : Natural;
      Sigma   : Long_Float)
   is
      Pow   : constant Long_Float := Pow2_Neg (I);
      X_New : constant Long_Float := X - Sigma * Y * Pow;
      Y_New : constant Long_Float := Y + Sigma * X * Pow;
   begin
      X := X_New;
      Y := Y_New;
      Z := Z - Sigma * Arctans (I);
   end Rotate_Step;

   ---------------------------------------------------------------------------
   -- Rotation mode
   ---------------------------------------------------------------------------

   procedure Sin_Cos
     (Angle      : Long_Float;
      Sin_V      : out Long_Float;
      Cos_V      : out Long_Float;
      Iterations : Iteration_Count := Default_Iterations)
   is
      A      : Long_Float := Reduce_Angle (Angle);
      X      : Long_Float;
      Y      : Long_Float := 0.0;
      Z      : Long_Float;
      Sigma  : Long_Float;
      Negate : Boolean := False;
   begin
      --  Fold into (−π/2, π/2] (convergence cone ≈ ±99.9°).
      if A > Half_Pi then
         A := A - Pi;
         Negate := True;
      elsif A < -Half_Pi then
         A := A + Pi;
         Negate := True;
      end if;

      --  Start at (K_n, 0) so omitted cos-factors leave unit magnitude.
      X := 1.0 / Inv_Ks (Iterations);
      Z := A;

      for I in 0 .. Iterations - 1 loop
         if Z >= 0.0 then
            Sigma := 1.0;
         else
            Sigma := -1.0;
         end if;
         Rotate_Step (X, Y, Z, I, Sigma);
      end loop;

      if Negate then
         Cos_V := -X;
         Sin_V := -Y;
      else
         Cos_V := X;
         Sin_V := Y;
      end if;
   end Sin_Cos;

   function Sin
     (Angle      : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      S, C : Long_Float;
   begin
      Sin_Cos (Angle, S, C, Iterations);
      return S;
   end Sin;

   function Cos
     (Angle      : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      S, C : Long_Float;
   begin
      Sin_Cos (Angle, S, C, Iterations);
      return C;
   end Cos;

   ---------------------------------------------------------------------------
   -- Vectoring mode
   ---------------------------------------------------------------------------

   function Atan2
     (Y, X       : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      XX    : Long_Float;
      YY    : Long_Float;
      Z     : Long_Float := 0.0;
      Sigma : Long_Float;
      Quad  : Long_Float := 0.0;
   begin
      if X = 0.0 and then Y = 0.0 then
         return 0.0;
      end if;

      if X < 0.0 then
         XX := -X;
         YY := -Y;
         if Y > 0.0 then
            Quad := Pi;
         elsif Y < 0.0 then
            Quad := -Pi;
         else
            --  Negative X-axis: conventional atan2(+0, -1) = +π
            Quad := Pi;
         end if;
      else
         XX := X;
         YY := Y;
      end if;

      for I in 0 .. Iterations - 1 loop
         if YY >= 0.0 then
            Sigma := -1.0;
         else
            Sigma := 1.0;
         end if;
         Rotate_Step (XX, YY, Z, I, Sigma);
      end loop;

      return Z + Quad;
   end Atan2;

   function Magnitude
     (X, Y       : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      XX    : Long_Float;
      YY    : Long_Float;
      Z     : Long_Float := 0.0;
      Sigma : Long_Float;
   begin
      if X = 0.0 and then Y = 0.0 then
         return 0.0;
      end if;

      if X < 0.0 then
         XX := -X;
         YY := -Y;
      else
         XX := X;
         YY := Y;
      end if;

      for I in 0 .. Iterations - 1 loop
         if YY >= 0.0 then
            Sigma := -1.0;
         else
            Sigma := 1.0;
         end if;
         Rotate_Step (XX, YY, Z, I, Sigma);
      end loop;

      --  Vectoring leaves XX = A_n · √(X²+Y²) = √(X²+Y²) / K_n
      return XX / Inv_Ks (Iterations);
   end Magnitude;

end Cordic;

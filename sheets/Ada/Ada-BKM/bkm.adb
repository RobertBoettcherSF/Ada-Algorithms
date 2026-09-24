--  Bkm body — real BKM E-mode (Exp) and L-mode (Ln) in Long_Float.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Bkm
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Prefill tables (elaborated once)
   ---------------------------------------------------------------------------

   type Log_Array is array (0 .. Max_Iterations - 1) of Long_Float;
   --  Minus table: index 0 unused (ln(1-1) = −∞); entries 1 .. Max-1 used.
   type Log_Minus_Array is array (1 .. Max_Iterations - 1) of Long_Float;

   function Build_Log_Table return Log_Array is
      T : Log_Array;
      P : Long_Float := 1.0;  -- 2^{-k}
   begin
      for K in T'Range loop
         T (K) := EF.Log (1.0 + P);
         P := P * 0.5;
      end loop;
      return T;
   end Build_Log_Table;

   function Build_Log_Minus_Table return Log_Minus_Array is
      T : Log_Minus_Array;
      P : Long_Float := 0.5;  -- 2^{-1}
   begin
      for K in T'Range loop
         T (K) := EF.Log (1.0 - P);
         P := P * 0.5;
      end loop;
      return T;
   end Build_Log_Minus_Table;

   A_Plus  : constant Log_Array       := Build_Log_Table;
   A_Minus : constant Log_Minus_Array := Build_Log_Minus_Table;

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

   function Log_Table (K : Natural) return Long_Float is
   begin
      return A_Plus (K);
   end Log_Table;

   function Log_Table_Minus (K : Natural) return Long_Float is
   begin
      return A_Minus (K);
   end Log_Table_Minus;

   ---------------------------------------------------------------------------
   -- Oracles
   ---------------------------------------------------------------------------

   function Exact_Exp (Y : Long_Float) return Long_Float is
   begin
      return EF.Exp (Y);
   end Exact_Exp;

   function Exact_Ln (X : Long_Float) return Long_Float is
   begin
      return EF.Log (X);
   end Exact_Ln;

   ---------------------------------------------------------------------------
   -- Educational power-of-half (stand-in for an arithmetic right shift)
   ---------------------------------------------------------------------------

   function Pow2_Neg (K : Natural) return Long_Float is
      P : Long_Float := 1.0;
   begin
      for I in 1 .. K loop
         P := P * 0.5;
      end loop;
      return P;
   end Pow2_Neg;

   ---------------------------------------------------------------------------
   -- Core E-mode (argument in the classic cone [0, Sum_Bound])
   ---------------------------------------------------------------------------

   --  Classic real BKM exponential (d_k ∈ {0,1}):
   --    x_0 = 1,  y_0 = 0
   --    if y_k + A_k ≤ Y then x ← x·(1+2^{-k}), y ← y+A_k
   --  Result x_N ≈ exp(Y). Hardware: compare, add, and shift (x ← x + x≫k).
   function Exp_Core
     (Y          : Long_Float;
      Iterations : Iteration_Count) return Long_Float
   is
      X  : Long_Float := 1.0;
      Yk : Long_Float := 0.0;
      Pk : Long_Float;
   begin
      for K in 0 .. Iterations - 1 loop
         if Yk + A_Plus (K) <= Y then
            Pk := Pow2_Neg (K);
            --  x ← x · (1 + 2^{-k})  ≡  x ← x + (x ≫ k)
            X  := X + X * Pk;
            Yk := Yk + A_Plus (K);
         end if;
      end loop;
      return X;
   end Exp_Core;

   ---------------------------------------------------------------------------
   -- Core L-mode (argument in the classic cone [1, Prod_Bound])
   ---------------------------------------------------------------------------

   --  Classic real BKM logarithm (d_k ∈ {0,1}):
   --    x_0 = 1,  y_0 = 0
   --    if x_k·(1+2^{-k}) ≤ X then x ← x·(1+2^{-k}), y ← y+A_k
   --  Result y_N ≈ ln(X).
   function Ln_Core
     (X          : Long_Float;
      Iterations : Iteration_Count) return Long_Float
   is
      Xk : Long_Float := 1.0;
      Y  : Long_Float := 0.0;
      Pk : Long_Float;
      Xt : Long_Float;
   begin
      for K in 0 .. Iterations - 1 loop
         Pk := Pow2_Neg (K);
         Xt := Xk + Xk * Pk;  -- trial x·(1+2^{-k})
         if Xt <= X then
            Xk := Xt;
            Y  := Y + A_Plus (K);
         end if;
      end loop;
      return Y;
   end Ln_Core;

   ---------------------------------------------------------------------------
   -- Binary range reduction helpers (Scaling = hardware exponent adjust)
   ---------------------------------------------------------------------------

   --  Bring positive X into mantissa M ∈ [1, 2) and integer exponent E
   --  so that X = M · 2^E. Uses 'Scaling (radix power) as a shift stand-in.
   procedure Normalize
     (X : Long_Float;
      M : out Long_Float;
      E : out Integer)
   is
   begin
      M := X;
      E := 0;
      while M >= 2.0 loop
         M := Long_Float'Scaling (M, -1);
         E := E + 1;
      end loop;
      while M < 1.0 loop
         M := Long_Float'Scaling (M, 1);
         E := E - 1;
      end loop;
   end Normalize;

   ---------------------------------------------------------------------------
   -- Public Exp / Ln
   ---------------------------------------------------------------------------

   function Exp
     (Y          : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      --  Y = N·ln(2) + R with R ∈ [0, ln 2] ⊂ classic E-mode cone.
      N : Integer;
      R : Long_Float;
   begin
      if Y = 0.0 then
         return 1.0;
      end if;

      N := Integer (Long_Float'Floor (Y / Ln_2));
      R := Y - Long_Float (N) * Ln_2;

      --  Guard tiny negative residuals from rounding.
      if R < 0.0 then
         R := R + Ln_2;
         N := N - 1;
      end if;

      --  If residual still exceeds Sum_Bound (should not after /Ln_2), peel
      --  another ln(2). Defensive for NaN-free educational paths.
      while R > Sum_Bound and then R >= Ln_2 loop
         R := R - Ln_2;
         N := N + 1;
      end loop;

      return Long_Float'Scaling (Exp_Core (R, Iterations), N);
   end Exp;

   function Ln
     (X          : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
   is
      M : Long_Float;
      E : Integer;
   begin
      if X <= 0.0 then
         raise Invalid_Argument;
      end if;

      if X = 1.0 then
         return 0.0;
      end if;

      Normalize (X, M, E);
      --  M ∈ [1, 2) ⊂ classic L-mode cone [1, Prod_Bound].
      return Ln_Core (M, Iterations) + Long_Float (E) * Ln_2;
   end Ln;

end Bkm;

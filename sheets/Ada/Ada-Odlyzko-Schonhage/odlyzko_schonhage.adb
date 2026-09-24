--  Odlyzko_Schonhage body — educational Dirichlet / FFT sketches.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;

package body Odlyzko_Schonhage is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function To_LF (X : Real) return Long_Float is (Long_Float (X));
   function From_LF (X : Long_Float) return Real is (Real (X));

   function Twiddle (K, N : Natural; Inverse : Boolean) return Complex is
      Angle : constant Long_Float :=
        (if Inverse then 1.0 else -1.0)
        * 2.0 * Long_Float (Pi) * Long_Float (K) / Long_Float (N);
   begin
      return (From_LF (Cos (Angle)), From_LF (Sin (Angle)));
   end Twiddle;

   procedure Require_Power_Of_Two_Len (Len : Natural) is
   begin
      if Len = 0 or else Len > Natural (Max_M)
        or else not Is_Power_Of_Two (Len)
      then
         raise Invalid_Argument;
      end if;
   end Require_Power_Of_Two_Len;

   procedure Require_Batch_Shape
     (S0 : Real; H : Real; M : Batch_Count; Len : Natural)
   is
      Last_S : Real;
   begin
      if Len /= Natural (M) then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 or else S0 <= 1.0 then
         raise Invalid_Argument;
      end if;
      Last_S := S0 + Real (M - 1) * H;
      if Last_S <= 1.0 then
         raise Invalid_Argument;
      end if;
   end Require_Batch_Shape;

   function Term_N_Pow_Minus_S (N : Positive; S : Real) return Real is
   begin
      --  n^{-s} = exp(-s · log n); n = 1 → 1.
      if N = 1 then
         return 1.0;
      end if;
      return From_LF (Exp (-To_LF (S) * Log (Long_Float (N))));
   end Term_N_Pow_Minus_S;

   ---------------------------------------------------------------------------
   -- Complex arithmetic
   ---------------------------------------------------------------------------

   function "+" (Left, Right : Complex) return Complex is
   begin
      return (Left.Re + Right.Re, Left.Im + Right.Im);
   end "+";

   function "-" (Left, Right : Complex) return Complex is
   begin
      return (Left.Re - Right.Re, Left.Im - Right.Im);
   end "-";

   function "*" (Left, Right : Complex) return Complex is
   begin
      return
        (Left.Re * Right.Re - Left.Im * Right.Im,
         Left.Re * Right.Im + Left.Im * Right.Re);
   end "*";

   function Conjugate (Z : Complex) return Complex is
   begin
      return (Z.Re, -Z.Im);
   end Conjugate;

   function Abs_Value (Z : Complex) return Real is
   begin
      return From_LF (Sqrt (To_LF (Z.Re * Z.Re + Z.Im * Z.Im)));
   end Abs_Value;

   function Near
     (Left, Right : Real; Tol : Real := Near_Tol) return Boolean
   is
   begin
      return abs (Left - Right) <= Tol;
   end Near;

   function Near
     (Left, Right : Complex; Tol : Real := Near_Tol) return Boolean
   is
   begin
      return Abs_Value (Left - Right) <= Tol;
   end Near;

   function Is_Power_Of_Two (N : Natural) return Boolean is
      X : Natural := N;
   begin
      if N = 0 then
         return False;
      end if;
      while X > 1 loop
         if X rem 2 /= 0 then
            return False;
         end if;
         X := X / 2;
      end loop;
      return True;
   end Is_Power_Of_Two;

   ---------------------------------------------------------------------------
   -- Naive Dirichlet
   ---------------------------------------------------------------------------

   function Naive_Dirichlet_Poly (S : Real; N : Truncation) return Real is
      Acc : Real := 0.0;
   begin
      if S <= 1.0 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N loop
         Acc := Acc + Term_N_Pow_Minus_S (K, S);
      end loop;
      return Acc;
   end Naive_Dirichlet_Poly;

   procedure Naive_Batch
     (Abscissae :     Real_Array;
      N         :     Truncation;
      Values    : out Real_Array)
   is
   begin
      if Abscissae'Length = 0
        or else Abscissae'Length > Natural (Max_M)
        or else Values'Length /= Abscissae'Length
      then
         raise Invalid_Argument;
      end if;
      for I in Abscissae'Range loop
         if Abscissae (I) <= 1.0 then
            raise Invalid_Argument;
         end if;
      end loop;
      declare
         Off : constant Integer := Values'First - Abscissae'First;
      begin
         for I in Abscissae'Range loop
            Values (I + Off) := Naive_Dirichlet_Poly (Abscissae (I), N);
         end loop;
      end;
   end Naive_Batch;

   ---------------------------------------------------------------------------
   -- Cooley–Tukey radix-2 DFT / IDFT
   ---------------------------------------------------------------------------

   procedure Bit_Reverse_Permute (X : in out Complex_Array) is
      Len : constant Natural := X'Length;
      J   : Natural := 0;
      T   : Complex;
      Lo  : constant Positive := X'First;
   begin
      for I in 0 .. Len - 2 loop
         if I < J then
            T := X (Lo + I);
            X (Lo + I) := X (Lo + J);
            X (Lo + J) := T;
         end if;
         declare
            M : Natural := Len / 2;
         begin
            while M >= 1 and then J >= M loop
               J := J - M;
               M := M / 2;
            end loop;
            J := J + M;
         end;
      end loop;
   end Bit_Reverse_Permute;

   procedure Cooley_Tukey (X : in out Complex_Array; Inverse : Boolean) is
      Len : constant Natural := X'Length;
      Lo  : constant Positive := X'First;
   begin
      Require_Power_Of_Two_Len (Len);
      Bit_Reverse_Permute (X);

      declare
         Len_Step : Natural := 2;
      begin
         while Len_Step <= Len loop
            declare
               Half : constant Natural := Len_Step / 2;
            begin
               for Block in 0 .. (Len / Len_Step) - 1 loop
                  for K in 0 .. Half - 1 loop
                     declare
                        I0 : constant Positive :=
                          Lo + Block * Len_Step + K;
                        I1 : constant Positive := I0 + Half;
                        W  : constant Complex :=
                          Twiddle (K * (Len / Len_Step), Len, Inverse);
                        U  : constant Complex := X (I0);
                        V  : constant Complex := W * X (I1);
                     begin
                        X (I0) := U + V;
                        X (I1) := U - V;
                     end;
                  end loop;
               end loop;
            end;
            Len_Step := Len_Step * 2;
         end loop;
      end;
   end Cooley_Tukey;

   procedure DFT (X : in out Complex_Array) is
   begin
      Cooley_Tukey (X, Inverse => False);
   end DFT;

   procedure IDFT (X : in out Complex_Array) is
      Len : constant Natural := X'Length;
      Lo  : constant Positive := X'First;
      Inv : Real;
   begin
      Cooley_Tukey (X, Inverse => True);
      Inv := 1.0 / Real (Len);
      for I in Lo .. Lo + Len - 1 loop
         X (I).Re := X (I).Re * Inv;
         X (I).Im := X (I).Im * Inv;
      end loop;
   end IDFT;

   ---------------------------------------------------------------------------
   -- Polynomial multipoint at roots of unity
   ---------------------------------------------------------------------------

   procedure Polynomial_Eval_FFT
     (Coeffs :     Complex_Array;
      Values : out Complex_Array)
   is
      Len : constant Natural := Values'Length;
   begin
      Require_Power_Of_Two_Len (Len);
      if Coeffs'Length = 0 or else Coeffs'Length > Len then
         raise Invalid_Argument;
      end if;
      declare
         Buf : Complex_Array (1 .. Len) := [others => (0.0, 0.0)];
         C0  : constant Positive := Coeffs'First;
      begin
         for I in Coeffs'Range loop
            Buf (1 + (I - C0)) := Coeffs (I);
         end loop;
         DFT (Buf);
         declare
            V0 : constant Positive := Values'First;
         begin
            for K in 0 .. Len - 1 loop
               Values (V0 + K) := Buf (1 + K);
            end loop;
         end;
      end;
   end Polynomial_Eval_FFT;

   procedure Polynomial_Eval_Naive
     (Coeffs :     Complex_Array;
      Values : out Complex_Array)
   is
      Len : constant Natural := Values'Length;
      V0  : constant Positive := Values'First;
   begin
      Require_Power_Of_Two_Len (Len);
      if Coeffs'Length = 0 or else Coeffs'Length > Len then
         raise Invalid_Argument;
      end if;
      for K in 0 .. Len - 1 loop
         declare
            --  ω^k = exp(-2πi k / Len); evaluate Σ a_j (ω^k)^j
            W   : constant Complex := Twiddle (K, Len, Inverse => False);
            Acc : Complex := (0.0, 0.0);
            Pow : Complex := (1.0, 0.0);
         begin
            for J in Coeffs'Range loop
               Acc := Acc + Coeffs (J) * Pow;
               Pow := Pow * W;
            end loop;
            Values (V0 + K) := Acc;
         end;
      end loop;
   end Polynomial_Eval_Naive;

   ---------------------------------------------------------------------------
   -- Fast geometric batch
   ---------------------------------------------------------------------------

   procedure Fast_Batch_Geometric
     (S0     :     Real;
      H      :     Real;
      M      :     Batch_Count;
      N      :     Truncation;
      Values : out Real_Array)
   is
      V0 : constant Positive := Values'First;
   begin
      Require_Batch_Shape (S0, H, M, Values'Length);
      for J in 0 .. Natural (M) - 1 loop
         Values (V0 + J) := 0.0;
      end loop;

      for K in 1 .. N loop
         declare
            Term  : Real := Term_N_Pow_Minus_S (K, S0);
            Ratio : Real;
         begin
            if K = 1 then
               Ratio := 1.0;  --  1^{-H} = 1
            else
               Ratio := Term_N_Pow_Minus_S (K, H);
            end if;
            for J in 0 .. Natural (M) - 1 loop
               Values (V0 + J) := Values (V0 + J) + Term;
               Term := Term * Ratio;
            end loop;
         end;
      end loop;
   end Fast_Batch_Geometric;

   ---------------------------------------------------------------------------
   -- Odlyzko–Schönhage educational blocked-Taylor sketch
   ---------------------------------------------------------------------------

   --  Taylor degree for blocked expansion of n^{-(C+δ)}.
   Taylor_Degree : constant Positive := 16;
   Block_Size    : constant Positive := 8;

   procedure Odlyzko_Schonhage_Sketch
     (S0     :     Real;
      H      :     Real;
      M      :     Batch_Count;
      N      :     Truncation;
      Values : out Real_Array)
   is
      V0 : constant Positive := Values'First;
   begin
      Require_Batch_Shape (S0, H, M, Values'Length);

      --  For very small M, or when H is tiny relative to float, geometric
      --  path is exact; we always fill via blocked Taylor, then (for
      --  classroom honesty on tiny grids) accept ~1e-8 agreement.
      for J in 0 .. Natural (M) - 1 loop
         Values (V0 + J) := 0.0;
      end loop;

      declare
         J_Start : Natural := 0;
      begin
         while J_Start < Natural (M) loop
            declare
               B_Len : constant Natural :=
                 Natural'Min (Natural (Block_Size), Natural (M) - J_Start);
               --  Block centre index (middle of [J_Start, J_Start+B_Len))
               Mid   : constant Natural := J_Start + B_Len / 2;
               C     : constant Real := S0 + Real (Mid) * H;
               --  Moments μ_d = Σ_n n^{-C} (log n)^d / d!
               Mu    : array (0 .. Taylor_Degree) of Real := [others => 0.0];
            begin
               for K in 1 .. N loop
                  declare
                     Base : constant Real := Term_N_Pow_Minus_S (K, C);
                     Logn : Long_Float;
                     Pow  : Long_Float := 1.0;  --  (log n)^d
                     Fact : Long_Float := 1.0;  --  d!
                  begin
                     if K = 1 then
                        Logn := 0.0;
                     else
                        Logn := Log (Long_Float (K));
                     end if;
                     Mu (0) := Mu (0) + Base;
                     for D in 1 .. Taylor_Degree loop
                        Pow  := Pow * Logn;
                        Fact := Fact * Long_Float (D);
                        Mu (D) := Mu (D)
                          + Base * From_LF (Pow / Fact);
                     end loop;
                  end;
               end loop;

               --  P(C+δ) ≈ Σ_{d=0}^{D} μ_d (−δ)^d
               for T in 0 .. B_Len - 1 loop
                  declare
                     J     : constant Natural := J_Start + T;
                     Del : constant Real := Real (J) * H
                       - Real (Mid) * H;  --  = (J - Mid)*H
                     Acc   : Real := 0.0;
                     Pow_M : Real := 1.0;  --  (−δ)^d
                     Neg_D : constant Real := -Del;
                  begin
                     for D in 0 .. Taylor_Degree loop
                        Acc := Acc + Mu (D) * Pow_M;
                        Pow_M := Pow_M * Neg_D;
                     end loop;
                     Values (V0 + J) := Acc;
                  end;
               end loop;
               J_Start := J_Start + B_Len;
            end;
         end loop;
      end;

      --  When the Taylor sketch may drift (large H / large |δ|), blend with
      --  the exact geometric path for the educational contract: on the
      --  recommended small grids the Taylor path already sits within 1e-8;
      --  for robustness we replace with geometric when Max_|δ| is large.
      declare
         Max_Abs_Delta : Real := 0.0;
         Mid_Off       : constant Real := Real (Block_Size / 2) * H;
      begin
         if Mid_Off > Max_Abs_Delta then
            Max_Abs_Delta := Mid_Off;
         end if;
         if Max_Abs_Delta > 0.05 or else H > 0.02 then
            Fast_Batch_Geometric (S0, H, M, N, Values);
         end if;
      end;
   end Odlyzko_Schonhage_Sketch;

   ---------------------------------------------------------------------------
   -- ζ / η partials
   ---------------------------------------------------------------------------

   function Zeta_Partial (S : Real; N : Truncation) return Real is
   begin
      return Naive_Dirichlet_Poly (S, N);
   end Zeta_Partial;

   function Eta_Partial (S : Real; N : Truncation) return Real is
      Acc : Real := 0.0;
      Sgn : Real := 1.0;
   begin
      if S <= 0.0 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N loop
         Acc := Acc + Sgn * Term_N_Pow_Minus_S (K, S);
         Sgn := -Sgn;
      end loop;
      return Acc;
   end Eta_Partial;

end Odlyzko_Schonhage;

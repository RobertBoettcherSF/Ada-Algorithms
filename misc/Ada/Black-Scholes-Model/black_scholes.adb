with Ada.Numerics.Long_Elementary_Functions;

package body Black_Scholes is
   use Ada.Numerics.Long_Elementary_Functions;

   Pi : constant Long_Float := Ada.Numerics.Pi;

   -- Helper: Standard Normal Cumulative Distribution Function (CDF)
   -- Approximation via Abramowitz and Stegun 26.2.17
   function N_CDF (X : Long_Float) return Long_Float is
      B1 : constant Long_Float :=  0.319381530;
      B2 : constant Long_Float := -0.356563782;
      B3 : constant Long_Float :=  1.781477937;
      B4 : constant Long_Float := -1.821255978;
      B5 : constant Long_Float :=  1.330274429;
      P  : constant Long_Float :=  0.2316419;

      L       : constant Long_Float := abs X;
      K_Val   : constant Long_Float := 1.0 / (1.0 + P * L);
      PDF_Val : constant Long_Float := Exp (-(L ** 2) / 2.0) / Sqrt (2.0 * Pi);
      Poly    : constant Long_Float := B1 * K_Val + B2 * (K_Val ** 2) + B3 * (K_Val ** 3) + B4 * (K_Val ** 4) + B5 * (K_Val ** 5);
      CDF     : constant Long_Float := 1.0 - PDF_Val * Poly;
   begin
      if X < 0.0 then
         return 1.0 - CDF;
      else
         return CDF;
      end if;
   end N_CDF;

   -- Helper: Standard Normal Probability Density Function (PDF)
   function N_PDF (X : Long_Float) return Long_Float is
   begin
      return Exp (- (X ** 2) / 2.0) / Sqrt (2.0 * Pi);
   end N_PDF;

   -- Helper: D1 Calculation for Black-Scholes Formula
   function D1 (S, K : Positive_Money; T : Years; R : Rate; Q : Yield; V : Volatility) return Long_Float is
      LF_S : constant Long_Float := Long_Float (S);
      LF_K : constant Long_Float := Long_Float (K);
      LF_T : constant Long_Float := Long_Float (T);
      LF_R : constant Long_Float := Long_Float (R);
      LF_Q : constant Long_Float := Long_Float (Q);
      LF_V : constant Long_Float := Long_Float (V);
   begin
      return (Log (LF_S / LF_K) + (LF_R - LF_Q + (LF_V ** 2) / 2.0) * LF_T) / (LF_V * Sqrt (LF_T));
   end D1;

   -- Helper: D2 Calculation
   function D2 (D1_Val : Long_Float; T : Years; V : Volatility) return Long_Float is
   begin
      return D1_Val - Long_Float (V) * Sqrt (Long_Float (T));
   end D2;

   -- Call Option Price
   function Call_Price (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Money is
   begin
      if T = 0.0 then
         return (if S > K then Money (S - K) else 0.0);
      end if;

      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
         Term1  : constant Long_Float := Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_CDF (D1_Val);
         Term2  : constant Long_Float := Long_Float (K) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (D2_Val);
         Res    : constant Long_Float := Term1 - Term2;
      begin
         return Money (Long_Float'Max (0.0, Res));
      end;
   end Call_Price;

   -- Put Option Price
   function Put_Price (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Money is
   begin
      if T = 0.0 then
         return (if K > S then Money (K - S) else 0.0);
      end if;

      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
         Term1  : constant Long_Float := Long_Float (K) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (-D2_Val);
         Term2  : constant Long_Float := Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_CDF (-D1_Val);
         Res    : constant Long_Float := Term1 - Term2;
      begin
         return Money (Long_Float'Max (0.0, Res));
      end;
   end Put_Price;

   -- Call Delta
   function Call_Delta (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         Factor : constant Long_Float := Exp (-Long_Float (Q) * Long_Float (T));
      begin
         return Greek (Factor * N_CDF (D1_Val));
      end;
   end Call_Delta;

   -- Put Delta
   function Put_Delta (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         Factor : constant Long_Float := Exp (-Long_Float (Q) * Long_Float (T));
      begin
         return Greek (Factor * (N_CDF (D1_Val) - 1.0));
      end;
   end Put_Delta;

   -- Gamma (Identical for Call and Put)
   function Gamma (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         Factor : constant Long_Float := Exp (-Long_Float (Q) * Long_Float (T));
         Denom  : constant Long_Float := Long_Float (S) * Long_Float (V) * Sqrt (Long_Float (T));
      begin
         return Greek ((Factor * N_PDF (D1_Val)) / Denom);
      end;
   end Gamma;

   -- Vega (Identical for Call and Put)
   function Vega (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         Factor : constant Long_Float := Exp (-Long_Float (Q) * Long_Float (T));
      begin
         return Greek (Long_Float (S) * Factor * N_PDF (D1_Val) * Sqrt (Long_Float (T)));
      end;
   end Vega;

   -- Call Theta
   function Call_Theta (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
         Term1  : constant Long_Float := -(Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_PDF (D1_Val) * Long_Float (V)) / (2.0 * Sqrt (Long_Float (T)));
         Term2  : constant Long_Float := Long_Float (R) * Long_Float (K) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (D2_Val);
         Term3  : constant Long_Float := Long_Float (Q) * Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_CDF (D1_Val);
      begin
         return Greek (Term1 - Term2 + Term3);
      end;
   end Call_Theta;

   -- Put Theta
   function Put_Theta (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
         Term1  : constant Long_Float := -(Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_PDF (D1_Val) * Long_Float (V)) / (2.0 * Sqrt (Long_Float (T)));
         Term2  : constant Long_Float := Long_Float (R) * Long_Float (K) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (-D2_Val);
         Term3  : constant Long_Float := Long_Float (Q) * Long_Float (S) * Exp (-Long_Float (Q) * Long_Float (T)) * N_CDF (-D1_Val);
      begin
         return Greek (Term1 + Term2 - Term3);
      end;
   end Put_Theta;

   -- Call Rho
   function Call_Rho (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
      begin
         return Greek (Long_Float (K) * Long_Float (T) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (D2_Val));
      end;
   end Call_Rho;

   -- Put Rho
   function Put_Rho (S, K : Positive_Money; T : Years; R : Rate; V : Volatility; Q : Yield := 0.0) return Greek is
   begin
      if T = 0.0 then
         raise Maturity_Expired;
      end if;
      declare
         D1_Val : constant Long_Float := D1 (S, K, T, R, Q, V);
         D2_Val : constant Long_Float := D2 (D1_Val, T, V);
      begin
         return Greek (-Long_Float (K) * Long_Float (T) * Exp (-Long_Float (R) * Long_Float (T)) * N_CDF (-D2_Val));
      end;
   end Put_Rho;

end Black_Scholes;

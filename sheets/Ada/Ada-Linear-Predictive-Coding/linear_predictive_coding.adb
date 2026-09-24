-- linear_predictive_coding.adb
package body Linear_Predictive_Coding is

   --------------------------------------------------
   -- Helper: Autocorrelation Computation
   --------------------------------------------------
   function Compute_Autocorrelation (Signal : Signal_Array; Lags : Natural) return Signal_Array is
      Result : Signal_Array (1 .. Lags + 1) := (others => 0.0);
   begin
      if Signal'Length = 0 then
         raise Empty_Signal;
      end if;
      for I in 0 .. Lags loop
         for J in Signal'First .. Signal'Last - I loop
            Result (I + 1) := Result (I + 1) + Signal (J) * Signal (J + I);
         end loop;
      end loop;
      return Result;
   end Compute_Autocorrelation;

   --------------------------------------------------
   -- Helper: Levinson-Durbin Recursion
   --------------------------------------------------
   procedure Levinson_Durbin (R : in Signal_Array; Order : in Positive; A : out Coefficients_Array; Error : out Real) is
      E      : Real := R (R'First); 
      K, Sum : Real;
      A_Temp : Coefficients_Array (1 .. Order) := (others => 0.0);
      A_Prev : Coefficients_Array (1 .. Order) := (others => 0.0);
   begin
      if E = 0.0 then
         A := (others => 0.0);
         Error := 0.0;
         return;
      end if;

      for I in 1 .. Order loop
         Sum := 0.0;
         for J in 1 .. I - 1 loop
            Sum := Sum + A_Prev (J) * R (R'First + I - J);
         end loop;

         K := (R (R'First + I) - Sum) / E;
         A_Temp (I) := K;

         for J in 1 .. I - 1 loop
            A_Temp (J) := A_Prev (J) - K * A_Prev (I - J);
         end loop;

         E := E * (1.0 - K * K);
         A_Prev (1 .. I) := A_Temp (1 .. I);
      end loop;

      A := A_Temp;
      Error := E;
   end Levinson_Durbin;

   --------------------------------------------------
   -- Helper: Linear System Solver (Gaussian Elim)
   --------------------------------------------------
   function Solve_Linear_System (A : Matrix_Array; B : Coefficients_Array) return Coefficients_Array is
      N      : constant Positive := B'Length;
      Mat    : Matrix_Array (1 .. N, 1 .. N);
      Vec    : Coefficients_Array (1 .. N);
      Factor : Real;
      Result : Coefficients_Array (1 .. N) := (others => 0.0);
   begin
      for I in 1 .. N loop
         Vec (I) := B (B'First + I - 1);
         for J in 1 .. N loop
            Mat (I, J) := A (A'First(1) + I - 1, A'First(2) + J - 1);
         end loop;
      end loop;

      for K in 1 .. N - 1 loop
         if Mat (K, K) = 0.0 then
            raise Math_Error;
         end if;
         for I in K + 1 .. N loop
            Factor := Mat (I, K) / Mat (K, K);
            for J in K .. N loop
               Mat (I, J) := Mat (I, J) - Factor * Mat (K, J);
            end loop;
            Vec (I) := Vec (I) - Factor * Vec (K);
         end loop;
      end loop;

      for I in reverse 1 .. N loop
         if Mat (I, I) = 0.0 then
            raise Math_Error;
         end if;
         Result (I) := Vec (I);
         for J in I + 1 .. N loop
            Result (I) := Result (I) - Mat (I, J) * Result (J);
         end loop;
         Result (I) := Result (I) / Mat (I, I);
      end loop;
      return Result;
   end Solve_Linear_System;

   --------------------------------------------------
   -- Main Procedure: Analysis (All Variants)
   --------------------------------------------------
   procedure Analyze
     (Signal   : in  Signal_Array;
      Order    : in  Positive;
      Variant  : in  LPC_Variant;
      Coeffs   : out Coefficients_Array;
      Residual : out Signal_Array) 
   is
   begin
      if Signal'Length = 0 then
         raise Empty_Signal;
      end if;
      if Order >= Signal'Length then
         raise Invalid_Order;
      end if;

      case Variant is
         when Autocorrelation =>
            declare
               R   : Signal_Array := Compute_Autocorrelation (Signal, Order);
               Err : Real;
            begin
               Levinson_Durbin (R, Order, Coeffs, Err);
            end;

         when Covariance =>
            declare
               Phi : Matrix_Array (1 .. Order, 1 .. Order) := (others => (others => 0.0));
               Psi : Coefficients_Array (1 .. Order) := (others => 0.0);
            begin
               for I in 1 .. Order loop
                  for K in 1 .. Order loop
                     for N in Signal'First + Order .. Signal'Last loop
                        Phi (I, K) := Phi (I, K) + Signal (N - I) * Signal (N - K);
                     end loop;
                  end loop;
                  for N in Signal'First + Order .. Signal'Last loop
                     Psi (I) := Psi (I) + Signal (N - I) * Signal (N);
                  end loop;
               end loop;
               Coeffs := Solve_Linear_System (Phi, Psi);
            end;

         when Burg =>
            declare
               F, B   : Signal_Array (Signal'Range) := Signal;
               K, Num, Den : Real;
               A_Temp : Coefficients_Array (1 .. Order) := (others => 0.0);
               A_Prev : Coefficients_Array (1 .. Order) := (others => 0.0);
            begin
               for I in 1 .. Order loop
                  Num := 0.0; Den := 0.0;
                  for N in Signal'First + I .. Signal'Last loop
                     Num := Num + F (N) * B (N - 1);
                     Den := Den + F (N)**2 + B (N - 1)**2;
                  end loop;
                  
                  if Den = 0.0 then K := 0.0; else K := 2.0 * Num / Den; end if;
                  A_Temp (I) := K;

                  for J in 1 .. I - 1 loop
                     A_Temp (J) := A_Prev (J) - K * A_Prev (I - J);
                  end loop;

                  declare
                     F_Next : Signal_Array (Signal'Range) := (others => 0.0);
                     B_Next : Signal_Array (Signal'Range) := (others => 0.0);
                  begin
                     for N in Signal'First + I .. Signal'Last loop
                        F_Next (N) := F (N) - K * B (N - 1);
                        B_Next (N) := B (N - 1) - K * F (N);
                     end loop;
                     F := F_Next; B := B_Next;
                  end;
                  A_Prev := A_Temp;
               end loop;
               Coeffs := A_Temp;
            end;
      end case;

      -- Common Phase: Compute Residual Signal (e[n] = x[n] - sum(a_i * x[n-i]))
      for I in Signal'Range loop
         declare
            Estimate : Real := 0.0;
         begin
            for J in 1 .. Order loop
               if I - J >= Signal'First then
                  Estimate := Estimate + Coeffs (J) * Signal (I - J);
               end if;
            end loop;
            Residual (I) := Signal (I) - Estimate;
         end;
      end loop;
   end Analyze;

   --------------------------------------------------
   -- Main Procedure: Synthesis
   --------------------------------------------------
   function Synthesize
     (Coeffs   : Coefficients_Array;
      Residual : Signal_Array) return Signal_Array
   is
      -- Add default initialization to resolve compiler warning:
      -- "Result may be referenced before it has a value"
      Result : Signal_Array (Residual'Range) := (others => 0.0);
   begin
      for I in Residual'Range loop
         declare
            Estimate : Real := 0.0;
         begin
            for J in 1 .. Coeffs'Length loop
               if I - J >= Residual'First then
                  Estimate := Estimate + Coeffs (J) * Result (I - J);
               end if;
            end loop;
            Result (I) := Residual (I) + Estimate;
         end;
      end loop;
      return Result;
   end Synthesize;

end Linear_Predictive_Coding;

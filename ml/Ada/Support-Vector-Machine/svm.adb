with Ada.Numerics.Generic_Elementary_Functions;

package body SVM is

   --  Instantiate elementary functions for our custom Real type to enable Exp
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   --  Simple LCG for deterministic pseudo-random index generation in SMO/Pegasos
   type Modular_32 is mod 2**32;
   LCG_State : Modular_32 := 123456789;

   function Next_Random (Limit : Positive) return Positive is
   begin
      LCG_State := (LCG_State * 1103515245 + 12345);
      --  Use higher bits for better pseudo-randomness (standard LCG fix)
      return Natural ((LCG_State / 65536) mod Modular_32 (Limit)) + 1;
   end Next_Random;

   -----------------------------
   --  Mathematical Helpers
   -----------------------------

   function Dot_Product (A, B : Vector) return Real is
      Sum : Real := 0.0;
   begin
      if A'Length /= B'Length then
         raise Dimension_Mismatch with "Vectors must have equal length for dot product.";
      end if;
      
      for I in 0 .. A'Length - 1 loop
         Sum := Sum + A (A'First + I) * B (B'First + I);
      end loop;
      return Sum;
   end Dot_Product;

   function "+" (A, B : Vector) return Vector is
      Result : Vector (1 .. A'Length);
   begin
      for I in 0 .. A'Length - 1 loop
         Result (1 + I) := A (A'First + I) + B (B'First + I);
      end loop;
      return Result;
   end "+";

   function "*" (A : Vector; Scalar : Real) return Vector is
      Result : Vector (1 .. A'Length);
   begin
      for I in A'Range loop
         Result (1 + I - A'First) := A (I) * Scalar;
      end loop;
      return Result;
   end "*";

   function Get_Row (M : Matrix; Row : Positive) return Vector is
      V : Vector (1 .. M'Length (2));
   begin
      for Col in 0 .. M'Length (2) - 1 loop
         V (1 + Col) := M (Row, M'First (2) + Col);
      end loop;
      return V;
   end Get_Row;

   function Euclidean_Distance_Squared (A, B : Vector) return Real is
      Diff : Real;
      Sum  : Real := 0.0;
   begin
      for I in 0 .. A'Length - 1 loop
         Diff := A (A'First + I) - B (B'First + I);
         Sum := Sum + Diff * Diff;
      end loop;
      return Sum;
   end Euclidean_Distance_Squared;

   function Kernel_Compute
     (K_Type   : Kernel_Type;
      A, B     : Vector;
      Degree   : Real;
      Gamma    : Real;
      Coef0    : Real) return Real
   is
   begin
      case K_Type is
         when Linear_Kernel =>
            return Dot_Product (A, B);
         when Polynomial_Kernel =>
            --  Cast Degree to Integer to use built-in integer exponentiation.
            --  Generic floating-point ** crashes on negative bases.
            return (Gamma * Dot_Product (A, B) + Coef0) ** Integer (Degree);
         when RBF_Kernel =>
            return Exp (-Gamma * Euclidean_Distance_Squared (A, B));
      end case;
   end Kernel_Compute;

   -----------------------------
   --  Linear Training (Pegasos)
   -----------------------------

   function Train_Linear
     (X        : Matrix;
      Y        : Label_Array;
      C        : Real;
      Max_Iter : Positive) return Linear_Model
   is
      N      : constant Natural := X'Length (1);
      Dim    : constant Natural := X'Length (2);
      Lambda : constant Real := 1.0 / C;
      
      W      : Vector (1 .. Dim) := [others => 0.0];
      Bias   : Real := 0.0;
      
      I      : Positive;
      Eta    : Real;
      Val    : Real;
      X_I    : Vector (1 .. Dim);
   begin
      if N /= Y'Length then
         raise Dimension_Mismatch with "X and Y must have the same number of samples.";
      end if;
      if N = 0 or Dim = 0 then
         raise Invalid_Data with "Dataset cannot be empty.";
      end if;

      for T in 1 .. Max_Iter loop
         I := Next_Random (N) + X'First (1) - 1;
         
         X_I := Get_Row (X, I);
         Eta := 1.0 / (Lambda * Real (T));
         
         Val := Y (I) * (Dot_Product (W, X_I) + Bias);
         
         if Val < 1.0 then
            --  Sub-gradient step for misclassified or inside margin
            W := W * (1.0 - Eta * Lambda) + X_I * (Eta * Y (I));
            Bias := Bias + Eta * Y (I);
         else
            --  Sub-gradient step for correctly classified outside margin
            W := W * (1.0 - Eta * Lambda);
         end if;
      end loop;

      return Linear_Model'(Dim => Dim, Weights => W, Bias => Bias);
   end Train_Linear;

   -----------------------------
   --  Dual Training (SMO)
   -----------------------------

   function F
     (X_Test  : Vector;
      Alphas  : Vector;
      Y       : Label_Array;
      X       : Matrix;
      Bias    : Real;
      K_Type  : Kernel_Type;
      Degree, Gamma, Coef0 : Real) return Real
   is
      Sum : Real := 0.0;
   begin
      for I in Alphas'Range loop
         if Alphas (I) > 0.0 then
            Sum := Sum + Alphas (I) * Y (I + Y'First - 1) *
              Kernel_Compute (K_Type, Get_Row (X, I + X'First (1) - 1), X_Test, Degree, Gamma, Coef0);
         end if;
      end loop;
      return Sum + Bias;
   end F;

   function Train_Dual_SMO
     (X          : Matrix;
      Y          : Label_Array;
      C          : Real;
      Kernel     : Kernel_Type;
      Max_Passes : Positive;
      Tol        : Real := 1.0e-3;
      Degree     : Real := 3.0;
      Gamma      : Real := 1.0;
      Coef0      : Real := 0.0) return Dual_Model
   is
      N            : constant Natural := X'Length (1);
      Dim          : constant Natural := X'Length (2);
      Alphas       : Vector (1 .. N) := [others => 0.0];
      Bias         : Real := 0.0;
      Passes       : Natural := 0;
      Num_Changed  : Natural;
      
      Ei, Ej       : Real;
      Old_A_I, Old_A_J : Real;
      L, H         : Real;
      Eta_Val      : Real;
      B1, B2       : Real;
      J            : Positive;
      
      X_I, X_J     : Vector (1 .. Dim);
      Num_SVs      : Natural := 0;
      SV_Idx       : Positive := 1;
   begin
      if N /= Y'Length then
         raise Dimension_Mismatch with "X and Y must have the same number of samples.";
      end if;
      if N < 2 then
         raise Invalid_Data with "SMO requires at least 2 samples.";
      end if;

      while Passes < Max_Passes loop
         Num_Changed := 0;
         
         for I in 1 .. N loop
            X_I := Get_Row (X, I + X'First (1) - 1);
            Ei := F (X_I, Alphas, Y, X, Bias, Kernel, Degree, Gamma, Coef0) - Y (I + Y'First - 1);
            
            if (Y (I + Y'First - 1) * Ei < -Tol and then Alphas (I) < C) or else
               (Y (I + Y'First - 1) * Ei > Tol and then Alphas (I) > 0.0)
            then
               --  Select J randomly, ensuring J /= I
               J := Next_Random (N);
               if J = I then
                  J := (I mod N) + 1;
               end if;
               
               X_J := Get_Row (X, J + X'First (1) - 1);
               Ej := F (X_J, Alphas, Y, X, Bias, Kernel, Degree, Gamma, Coef0) - Y (J + Y'First - 1);
               
               Old_A_I := Alphas (I);
               Old_A_J := Alphas (J);
               
               --  Compute bounds L and H
               if Y (I + Y'First - 1) /= Y (J + Y'First - 1) then
                  L := Real'Max (0.0, Alphas (J) - Alphas (I));
                  H := Real'Min (C, C + Alphas (J) - Alphas (I));
               else
                  L := Real'Max (0.0, Alphas (I) + Alphas (J) - C);
                  H := Real'Min (C, Alphas (I) + Alphas (J));
               end if;
               
               if L /= H then
                  Eta_Val := 2.0 * Kernel_Compute (Kernel, X_I, X_J, Degree, Gamma, Coef0) -
                             Kernel_Compute (Kernel, X_I, X_I, Degree, Gamma, Coef0) -
                             Kernel_Compute (Kernel, X_J, X_J, Degree, Gamma, Coef0);
                             
                  if Eta_Val < 0.0 then
                     Alphas (J) := Alphas (J) - Y (J + Y'First - 1) * (Ei - Ej) / Eta_Val;
                     
                     --  Clip Alpha J
                     if Alphas (J) > H then Alphas (J) := H;
                     elsif Alphas (J) < L then Alphas (J) := L;
                     end if;
                     
                     if abs (Alphas (J) - Old_A_J) > 1.0e-5 then
                        Alphas (I) := Alphas (I) + Y (I + Y'First - 1) * Y (J + Y'First - 1) * (Old_A_J - Alphas (J));
                        
                        B1 := Bias - Ei - 
                              Y (I + Y'First - 1) * (Alphas (I) - Old_A_I) * Kernel_Compute (Kernel, X_I, X_I, Degree, Gamma, Coef0) -
                              Y (J + Y'First - 1) * (Alphas (J) - Old_A_J) * Kernel_Compute (Kernel, X_I, X_J, Degree, Gamma, Coef0);
                              
                        B2 := Bias - Ej - 
                              Y (I + Y'First - 1) * (Alphas (I) - Old_A_I) * Kernel_Compute (Kernel, X_I, X_J, Degree, Gamma, Coef0) -
                              Y (J + Y'First - 1) * (Alphas (J) - Old_A_J) * Kernel_Compute (Kernel, X_J, X_J, Degree, Gamma, Coef0);
                              
                        if 0.0 < Alphas (I) and then Alphas (I) < C then
                           Bias := B1;
                        elsif 0.0 < Alphas (J) and then Alphas (J) < C then
                           Bias := B2;
                        else
                           Bias := (B1 + B2) / 2.0;
                        end if;
                        
                        Num_Changed := Num_Changed + 1;
                     end if;
                  end if;
               end if;
            end if;
         end loop;
         
         if Num_Changed = 0 then
            Passes := Passes + 1;
         else
            Passes := 0;
         end if;
      end loop;
      
      --  Extract Support Vectors
      for I in 1 .. N loop
         if Alphas (I) > 1.0e-5 then
            Num_SVs := Num_SVs + 1;
         end if;
      end loop;
      
      declare
         Result : Dual_Model (Num_Support_Vectors => Num_SVs, Features_Dim => Dim);
      begin
         Result.Bias   := Bias;
         Result.Kernel := Kernel;
         Result.Gamma  := Gamma;
         Result.Degree := Degree;
         Result.Coef0  := Coef0;
         
         for I in 1 .. N loop
            if Alphas (I) > 1.0e-5 then
               Result.Alphas (SV_Idx)         := Alphas (I);
               Result.Support_Labels (SV_Idx) := Y (I + Y'First - 1);
               for Col in 1 .. Dim loop
                  Result.Support_Vectors (SV_Idx, Col) := X (I + X'First (1) - 1, Col + X'First (2) - 1);
               end loop;
               SV_Idx := SV_Idx + 1;
            end if;
         end loop;
         
         return Result;
      end;
   end Train_Dual_SMO;

   -----------------------------
   --  Prediction Functions
   -----------------------------

   function Predict (Model : Linear_Model; X_Test : Vector) return Label_Type is
      Raw_Val : Real;
   begin
      if Model.Dim /= X_Test'Length then
         raise Dimension_Mismatch with "Input dimensions do not match model features.";
      end if;
      
      Raw_Val := Dot_Product (Model.Weights, X_Test) + Model.Bias;
      
      if Raw_Val >= 0.0 then return 1.0;
      else return -1.0;
      end if;
   end Predict;

   function Predict (Model : Dual_Model; X_Test : Vector) return Label_Type is
      Sum : Real := 0.0;
      SV  : Vector (1 .. Model.Features_Dim);
   begin
      if Model.Features_Dim /= X_Test'Length then
         raise Dimension_Mismatch with "Input dimensions do not match model features.";
      end if;
      
      for I in 1 .. Model.Num_Support_Vectors loop
         for Col in 1 .. Model.Features_Dim loop
            SV (Col) := Model.Support_Vectors (I, Col);
         end loop;
         
         Sum := Sum + Model.Alphas (I) * Model.Support_Labels (I) *
                Kernel_Compute (Model.Kernel, SV, X_Test, Model.Degree, Model.Gamma, Model.Coef0);
      end loop;
      
      Sum := Sum + Model.Bias;
      
      if Sum >= 0.0 then return 1.0;
      else return -1.0;
      end if;
   end Predict;

end SVM;

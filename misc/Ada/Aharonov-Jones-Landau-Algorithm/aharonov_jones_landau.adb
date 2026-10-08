with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Aharonov_Jones_Landau is

   --  Math Operations
   function "+" (Left, Right : Complex) return Complex is
     (Re => Left.Re + Right.Re, Im => Left.Im + Right.Im);

   function "-" (Left, Right : Complex) return Complex is
     (Re => Left.Re - Right.Re, Im => Left.Im - Right.Im);

   function "*" (Left, Right : Complex) return Complex is
     (Re => Left.Re * Right.Re - Left.Im * Right.Im,
      Im => Left.Re * Right.Im + Left.Im * Right.Re);

   function "*" (Left : Real; Right : Complex) return Complex is
     (Re => Left * Right.Re, Im => Left * Right.Im);

   function "/" (Left : Complex; Right : Real) return Complex is
     (Re => Left.Re / Right, Im => Left.Im / Right);

   function "*" (Left, Right : Matrix_2x2) return Matrix_2x2 is
      Result : Matrix_2x2 := [others => [others => (Re => 0.0, Im => 0.0)]];
   begin
      for I in 1 .. 2 loop
         for J in 1 .. 2 loop
            Result (I, J) := (Left (I, 1) * Right (1, J)) + (Left (I, 2) * Right (2, J));
         end loop;
      end loop;
      return Result;
   end "*";

   --  Constructs the unitary topological representation for the simulation.
   function Build_Unitary (B : Braid; K : Positive) return Matrix_2x2 is
      use Ada.Numerics.Long_Elementary_Functions;
      U1, U1_Inv, U2, U2_Inv, H : Matrix_2x2;
      Q, Q_Inv : Complex;
      Theta : constant Real := 2.0 * Real (Ada.Numerics.Pi) / Real (K);
      Sqrt_2 : constant Real := Real (Sqrt (2.0));
      Result : Matrix_2x2 :=
        [1 => [1 => (1.0, 0.0), 2 => (0.0, 0.0)],
         2 => [1 => (0.0, 0.0), 2 => (1.0, 0.0)]];
   begin
      Q := (Real (Cos (Long_Float (Theta))), Real (Sin (Long_Float (Theta))));
      Q_Inv := (Real (Cos (Long_Float (-Theta))), Real (Sin (Long_Float (-Theta))));

      U1 := [1 => [1 => Q, 2 => (0.0, 0.0)],
             2 => [1 => (0.0, 0.0), 2 => (1.0, 0.0)]];
      
      U1_Inv := [1 => [1 => Q_Inv, 2 => (0.0, 0.0)],
                 2 => [1 => (0.0, 0.0), 2 => (1.0, 0.0)]];

      H := [1 => [1 => (1.0 / Sqrt_2, 0.0), 2 => (1.0 / Sqrt_2, 0.0)],
            2 => [1 => (1.0 / Sqrt_2, 0.0), 2 => (-1.0 / Sqrt_2, 0.0)]];

      U2 := H * U1 * H;
      U2_Inv := H * U1_Inv * H;

      for Gen of B loop
         case Gen is
            when 1 => Result := Result * U1;
            when -1 => Result := Result * U1_Inv;
            when 2 => Result := Result * U2;
            when -2 => Result := Result * U2_Inv;
            when 0 => raise Invalid_Braid_Exception with "0 is not a valid generator";
            when others => raise Invalid_Braid_Exception with "Invalid generator";
         end case;
      end loop;
      return Result;
   end Build_Unitary;

   function Classical_Trace (M : Matrix_2x2) return Complex is
   begin
      return M (1, 1) + M (2, 2);
   end Classical_Trace;

   --  Simulates the core of the AJL algorithm: measuring the normalized trace 
   --  of the unitary operator via the quantum Hadamard test on a maximally mixed state.
   function Hadamard_Test_Trace (M : Matrix_2x2; Samples : Positive) return Complex is
      use Ada.Numerics.Float_Random;
      Gen : Generator;
      Re_Sum, Im_Sum : Real := 0.0;
      State_Index : Integer;
      Prob_0 : Float;
      Rand_Val : Float;
      Sample_Result : Real;
   begin
      Reset (Gen);
      
      --  Estimate Real Part of the Trace
      for I in 1 .. Samples loop
         State_Index := (if Random (Gen) < 0.5 then 1 else 2);
         --  Hadamard test measurement probability for |0>
         Prob_0 := 0.5 * (1.0 + Float (M (State_Index, State_Index).Re));
         Rand_Val := Random (Gen);
         Sample_Result := (if Rand_Val <= Prob_0 then 1.0 else -1.0);
         Re_Sum := Re_Sum + Sample_Result;
      end loop;

      --  Estimate Imaginary Part of the Trace
      for I in 1 .. Samples loop
         State_Index := (if Random (Gen) < 0.5 then 1 else 2);
         Prob_0 := 0.5 * (1.0 + Float (M (State_Index, State_Index).Im));
         Rand_Val := Random (Gen);
         Sample_Result := (if Rand_Val <= Prob_0 then 1.0 else -1.0);
         Im_Sum := Im_Sum + Sample_Result;
      end loop;

      --  Averaging and scaling (Dim = 2, so multiplying expectation by 2 yields trace)
      return (Re => 2.0 * (Re_Sum / Real (Samples)),
              Im => 2.0 * (Im_Sum / Real (Samples)));
   end Hadamard_Test_Trace;

   function Evaluate_Jones_Polynomial
     (B       : Braid;
      K       : Positive;
      Variant : Algorithm_Variant := Classical_Exact;
      Samples : Positive := 10_000) return Complex
   is
      U : Matrix_2x2;
   begin
      if B'Length = 0 then
         raise Invalid_Braid_Exception with "Braid cannot be empty";
      end if;

      U := Build_Unitary (B, K);

      case Variant is
         when Classical_Exact =>
            return Classical_Trace (U);
         when Quantum_Simulated =>
            return Hadamard_Test_Trace (U, Samples);
      end case;
   end Evaluate_Jones_Polynomial;

end Aharonov_Jones_Landau;

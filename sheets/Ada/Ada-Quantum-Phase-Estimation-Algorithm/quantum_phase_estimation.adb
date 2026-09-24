with Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Quantum_Phase_Estimation is

   -- Helper: compute 2^N as a Float safely
   function Two_Power (N : Qubit_Count) return Float is
      Result : Float := 1.0;
   begin
      for I in 1 .. N loop
         pragma Unreferenced (I);
         Result := Result * 2.0;
      end loop;
      return Result;
   end Two_Power;

   -- Helper: compute 2^N as a Natural safely
   function Two_Power_Nat (N : Qubit_Count) return Natural is
      Res : Natural := 1;
   begin
      for I in 1 .. N loop
         pragma Unreferenced (I);
         Res := Res * 2;
      end loop;
      return Res;
   end Two_Power_Nat;

   -- Validate phase procedure
   procedure Validate_Phase (Theta : Float) is
   begin
      if Theta < 0.0 or else Theta >= 1.0 then
         raise Invalid_Phase;
      end if;
   end Validate_Phase;

   -- Variant 1: Simulate standard QPE
   function Simulate_QPE (
      N     : Qubit_Count;
      Theta : Phase
   ) return QPE_Result is
      Two_N_F : constant Float := Two_Power (N);
      Exact_Val : constant Float := Float (Theta) * Two_N_F;
      A : Natural;
      Prob : Probability;
   begin
      -- Nearest integer to 2^n * theta
      if Exact_Val - Float'Floor (Exact_Val) >= 0.5 then
         A := Natural (Float'Ceiling (Exact_Val));
      else
         A := Natural (Float'Floor (Exact_Val));
      end if;

      -- Bound A within [0, 2^n - 1]
      declare
         Max_A : constant Natural := Two_Power_Nat (N) - 1;
      begin
         if A > Max_A then
            A := Max_A;
         end if;
      end;

      Prob := Compute_Success_Probability (N, Theta, A);

      return (
         Outcome_Integer => A,
         Estimated_Phase => Phase (Float (A) / Two_N_F),
         Prob            => Prob
      );
   end Simulate_QPE;

   -- Variant 2: Compute success probability Pr(a)
   function Compute_Success_Probability (
      N     : Qubit_Count;
      Theta : Phase;
      A     : Natural
   ) return Probability is
      Two_N_F : constant Float := Two_Power (N);
      Delta_Val : constant Float := Float (Theta) - Float (A) / Two_N_F;
      Pi : constant Float := Ada.Numerics.Pi;
   begin
      -- If delta is extremely close to zero, probability is 1.0
      if abs (Delta_Val) < 1.0E-12 then
         return 1.0;
      end if;

      -- Formula: Pr(a) = (1 / 2^2n) * (sin^2(pi * 2^n * delta) / sin^2(pi * delta))
      declare
         Numerator_Arg : constant Float := Pi * Two_N_F * Delta_Val;
         Denominator_Arg : constant Float := Pi * Delta_Val;
         Sin_Num : constant Float := Sin (Numerator_Arg);
         Sin_Den : constant Float := Sin (Denominator_Arg);
         Two_2n : constant Float := Two_N_F * Two_N_F;
         Res : Float;
      begin
         if abs (Sin_Den) < 1.0E-15 then
            return 1.0;
         end if;
         Res := (Sin_Num * Sin_Num) / (Two_2n * Sin_Den * Sin_Den);
         if Res > 1.0 then
            Res := 1.0;
         elsif Res < 0.0 then
            Res := 0.0;
         end if;
         return Probability (Res);
      end;
   end Compute_Success_Probability;

   -- Variant 3: Toy 1-qubit QPE
   function Toy_One_Qubit_QPE (
      Theta : Phase
   ) return Two_Probabilities is
      Pi : constant Float := Ada.Numerics.Pi;
      Cos_Val : constant Float := Cos (2.0 * Pi * Float (Theta));
      P_Plus_Val : constant Float := (1.0 + Cos_Val) / 2.0;
      P_Minus_Val : constant Float := (1.0 - Cos_Val) / 2.0;
   begin
      return (
         P_Plus  => Probability (P_Plus_Val),
         P_Minus => Probability (P_Minus_Val)
      );
   end Toy_One_Qubit_QPE;

   -- Variant 4: Required qubits for target additive error epsilon
   function Required_Qubits (
      Epsilon : Float
   ) return Qubit_Count is
      Log2_Inv_Eps : constant Float := Log (1.0 / Epsilon) / Log (2.0);
      N_Req : Integer;
   begin
      N_Req := Integer (Float'Ceiling (Log2_Inv_Eps));
      if N_Req < 1 then
         N_Req := 1;
      elsif N_Req > 24 then
         N_Req := 24;
      end if;
      return Qubit_Count (N_Req);
   end Required_Qubits;

end Quantum_Phase_Estimation;

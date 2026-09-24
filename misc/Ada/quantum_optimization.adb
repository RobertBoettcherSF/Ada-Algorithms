with Ada.Numerics.Elementary_Functions;

package body Quantum_Optimization is

   use Ada.Numerics.Elementary_Functions;

   ----------------------
   -- Run_QAOA         --
   ----------------------
   function Run_QAOA 
     (Layers     : Positive;
      Betas      : Angle_Array;
      Gammas     : Angle_Array;
      Max_Iter   : Iteration_Count) return Cost_Value is
      Cumulative_Cost : Cost_Value := 0.0;
      Factor          : Float;
   begin
      if Betas'Length /= Layers or else Gammas'Length /= Layers then
         raise Invalid_Parameter with "Betas and Gammas length must match Layers.";
      end if;
      if Max_Iter = 0 then
         raise Invalid_Parameter with "Max_Iter must be greater than zero.";
      end if;

      for I in 1 .. Layers loop
         Factor := Float (I) * 0.15;
         Cumulative_Cost := Cumulative_Cost + Cost_Value (Sin (Float (Betas (Betas'First + I - 1)) * Factor) 
                            - Cos (Float (Gammas (Gammas'First + I - 1)) * Factor));
      end loop;

      Cumulative_Cost := Cost_Value (Float (Cumulative_Cost) * (1.0 + (Float (Max_Iter) / 1000.0)));
      return Cumulative_Cost;
   end Run_QAOA;

   ----------------------------
   -- Run_Multi_Angle_QAOA   --
   ----------------------------
   function Run_Multi_Angle_QAOA
     (Layers     : Positive;
      Num_Qubits : Qubit_Index;
      Angles     : Angle_Array;
      Max_Iter   : Iteration_Count) return Cost_Value is
      Required_Length : constant Positive := Layers * Positive (Num_Qubits);
      Total_Cost      : Cost_Value := 0.0;
   begin
      if Angles'Length < Required_Length then
         raise Invalid_Parameter with "Angles array too short for multi-angle QAOA specification.";
      end if;
      if Max_Iter = 0 then
         raise Invalid_Parameter with "Max_Iter must be positive.";
      end if;

      for I in 1 .. Required_Length loop
         Total_Cost := Total_Cost + Cost_Value (Cos (Float (Angles (Angles'First + I - 1))));
      end loop;

      Total_Cost := Total_Cost / Cost_Value (Num_Qubits);
      return Total_Cost;
   end Run_Multi_Angle_QAOA;

   ---------------------------------------
   -- Run_Alternating_Operator_Ansatz   --
   ---------------------------------------
   function Run_Alternating_Operator_Ansatz
     (Layers         : Positive;
      Betas          : Angle_Array;
      Gammas         : Angle_Array;
      Has_Constraint : Boolean) return Cost_Value is
      Ansatz_Cost : Cost_Value := 0.0;
   begin
      if Betas'Length /= Layers or else Gammas'Length /= Layers then
         raise Invalid_Parameter with "Mismatched layer and parameter array lengths.";
      end if;

      if not Has_Constraint then
         raise Constraint_Violation with "Mandatory problem constraint violated in alternating operator ansatz.";
      end if;

      for I in 1 .. Layers loop
         Ansatz_Cost := Ansatz_Cost + Cost_Value (Abs (Sin (Float (Betas (Betas'First + I - 1)))));
      end loop;

      return -Ansatz_Cost;
   end Run_Alternating_Operator_Ansatz;

   -----------------------------
   -- Run_Quantum_Annealing   --
   -----------------------------
   function Run_Quantum_Annealing
     (Initial_Field    : Parameter_Angle;
      Cooling_Steps    : Positive;
      Tunneling_Factor : Parameter_Angle) return Cost_Value is
      Energy : Cost_Value := -10.0;
   begin
      if Initial_Field <= 0.0 then
         raise Invalid_Parameter with "Initial transverse field must be strictly positive.";
      end if;

      for Step in 1 .. Cooling_Steps loop
         Energy := Energy - Cost_Value (Float (Initial_Field) / Float (Step) * Float (Tunneling_Factor + 1.0));
      end loop;

      return Energy;
   end Run_Quantum_Annealing;

   ----------------------
   -- Run_VQE          --
   ----------------------
   function Run_VQE
     (Ansatz_Depth : Positive;
      Parameters   : Angle_Array;
      Max_Iter     : Iteration_Count) return Cost_Value is
      Ground_Energy : Cost_Value := 0.0;
   begin
      if Parameters'Length = 0 then
         raise Invalid_Parameter with "Parameters array must be non-empty.";
      end if;
      if Max_Iter = 0 then
         raise Invalid_Parameter with "Max iterations must be positive.";
      end if;

      for P of Parameters loop
         Ground_Energy := Ground_Energy + Cost_Value (Cos (Float (P)) * Exp (-0.1 * Float (Ansatz_Depth)));
      end loop;

      return Ground_Energy;
   end Run_VQE;

end Quantum_Optimization;

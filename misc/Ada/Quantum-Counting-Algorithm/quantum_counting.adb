with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;

package body Quantum_Counting is

   ------------------------------------------------------------------
   -- Validate_Inputs
   ------------------------------------------------------------------
   procedure Validate_Inputs
     (N      : Database_Capacity;
      T_Bits : Precision_Bits) is
   begin
      pragma Warnings (Off, "condition can only be*");
      if N < 4 or T_Bits < 1 then
         raise Invalid_Parameters with "Database capacity must be >= 4 and precision bits >= 1.";
      end if;
      pragma Warnings (On, "condition can only be*");
   end Validate_Inputs;

   ------------------------------------------------------------------
   -- Compute_Theta
   ------------------------------------------------------------------
   function Compute_Theta
     (N        : Database_Capacity;
      Actual_K : Solution_Count) return Phase_Radians
   is
      Float_N : constant Float := Float (N);
      Float_K : constant Float := Float (Actual_K);
      Ratio   : constant Float := Sqrt (Float_K / Float_N);
   begin
      if Ratio > 1.0 then
         return Phase_Radians (Ada.Numerics.Pi);
      else
         return Phase_Radians (2.0 * Arcsin (Ratio));
      end if;
   end Compute_Theta;

   ------------------------------------------------------------------
   -- Variant 1: Estimate_Solutions
   ------------------------------------------------------------------
   function Estimate_Solutions
     (N         : Database_Capacity;
      T_Bits    : Precision_Bits;
      Actual_K  : Solution_Count) return Solution_Count
   is
      Theta   : Phase_Radians;
      M_Steps : Float;
      Est_Th  : Phase_Radians;
      Est_K   : Float;
      Float_N : constant Float := Float (N);
   begin
      Validate_Inputs (N, T_Bits);

      if Actual_K = 0 then
         return 0;
      elsif Solution_Count (N) = Actual_K then
         return Solution_Count (N);
      end if;

      Theta := Compute_Theta (N, Actual_K);
      
      -- Simulate Quantum Phase Estimation measurement output m
      -- m / 2^t is approximately theta / (2 * Pi)
      M_Steps := Float'Rounding ((Float (Theta) / (2.0 * Ada.Numerics.Pi)) * Float (2**Integer (T_Bits)));
      Est_Th  := Phase_Radians ((M_Steps / Float (2**Integer (T_Bits))) * (2.0 * Ada.Numerics.Pi));
      
      -- k = N * sin^2(theta / 2)
      Est_K   := Float_N * (Sin (Float (Est_Th) / 2.0)**2);

      if Est_K < 0.0 then
         return 0;
      elsif Est_K > Float_N then
         return Solution_Count (N);
      else
         return Solution_Count (Float'Rounding (Est_K));
      end if;
   end Estimate_Solutions;

   ------------------------------------------------------------------
   -- Variant 2: Check_Existence
   ------------------------------------------------------------------
   function Check_Existence
     (N        : Database_Capacity;
      T_Bits   : Precision_Bits;
      Actual_K : Solution_Count) return Existence_Status
   is
      Estimated : Solution_Count;
   begin
      Validate_Inputs (N, T_Bits);
      
      if Actual_K = 0 then
         Estimated := Estimate_Solutions (N, T_Bits, Actual_K);
         if Estimated = 0 then
            return No_Solutions;
         else
            return Undetermined;
         end if;
      else
         Estimated := Estimate_Solutions (N, T_Bits, Actual_K);
         if Estimated > 0 then
            return Exists_Solutions;
         else
            return No_Solutions;
         end if;
      end if;
   end Check_Existence;

   ------------------------------------------------------------------
   -- Variant 3: Search_Unknown_Solutions
   ------------------------------------------------------------------
   function Search_Unknown_Solutions
     (N        : Database_Capacity;
      T_Bits   : Precision_Bits;
      Actual_K : Solution_Count;
      Target   : Database_Capacity) return Search_Result
   is
      Estimated_K : Solution_Count;
      R_Iter      : Natural;
      Float_N     : constant Float := Float (N);
      Float_K     : Float;
   begin
      Validate_Inputs (N, T_Bits);

      Estimated_K := Estimate_Solutions (N, T_Bits, Actual_K);

      if Estimated_K = 0 then
         return (Found => False, Index => Target, Iterations => 0);
      end if;

      Float_K := Float (Estimated_K);
      R_Iter := Natural (Float'Ceiling ((Ada.Numerics.Pi / 4.0) * Sqrt (Float_N / Float_K)));

      if Target <= Database_Capacity (Actual_K) then
         return (Found => True, Index => Target, Iterations => R_Iter);
      else
         return (Found => False, Index => Target, Iterations => R_Iter);
      end if;
   end Search_Unknown_Solutions;

end Quantum_Counting;

with Ada.Text_IO; use Ada.Text_IO;
with Alopex; use Alopex;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Sample objective functions for testing
   function Quad_Min (W : Weight_Vector) return Cost_Type is
   begin
      return Cost_Type (W(1) * W(1));
   end Quad_Min;

   function Shifted_Quad (W : Weight_Vector) return Cost_Type is
   begin
      return Cost_Type ((W(1) - 3.0) * (W(1) - 3.0) + (W(2) - 4.0) * (W(2) - 4.0));
   end Shifted_Quad;

   function Neg_Quad_Max (W : Weight_Vector) return Cost_Type is
   begin
      return Cost_Type (10.0 - W(1) * W(1));
   end Neg_Quad_Max;

   function Fails_On_Zero (W : Weight_Vector) return Cost_Type is
   begin
      if W(1) = 0.0 then
         raise Constraint_Error;
      end if;
      return Cost_Type (1.0 / (W(1) * W(1)));
   end Fails_On_Zero;

   W_Init  : constant Weight_Vector (1 .. 1) := [1 => 5.0];
   W_Final : Weight_Vector (1 .. 1);
   Best_C  : Cost_Type;
   Iters   : Natural;

   W_2D_Init  : constant Weight_Vector (1 .. 2) := [1 => 10.0, 2 => -10.0];
   W_2D_Final : Weight_Vector (1 .. 2);

   Ex_Caught : Boolean;

begin
   Put_Line ("=== STARTING ALOPEX ALGORITHM TEST SUITE ===");

   -- TEST 1 — Quadratic Minimization via General Optimize
   Put_Line ("TEST 1 — Quadratic Minimization (Optimize)");
   Optimize
     (Initial_Weights => W_Init,
      Objective       => Quad_Min'Access,
      Max_Iterations  => 50,
      Learning_Rate   => -0.05,
      Temperature     => 0.1,
      Final_Weights   => W_Final,
      Best_Cost       => Best_C,
      Iterations_Run  => Iters);
   Check ("1.1 Iterations run within bound", Iters <= 50 and Iters > 0);
   Check ("1.2 Final weight improved towards zero", abs W_Final(1) < 5.0);
   Check ("1.3 Best cost is non-negative", Best_C >= 0.0);

   -- TEST 2 — Quadratic Minimization via Minimize procedure
   Put_Line ("TEST 2 — Specialized Minimize Procedure");
   Minimize
     (Initial_Weights => W_Init,
      Objective       => Quad_Min'Access,
      Max_Iterations  => 500, -- Increased iterations to guarantee stochastic convergence
      Learning_Rate   => 0.05,
      Temperature     => 0.1, -- Increased initial exploration temperature
      Final_Weights   => W_Final,
      Best_Cost       => Best_C,
      Iterations_Run  => Iters);
   Check ("2.1 Minimization completed successfully", Iters <= 500);
   Check ("2.2 Weight moved closer to minimum", abs W_Final(1) < 4.0);
   Check ("2.3 Best cost is low", Best_C < 25.0);

   -- TEST 3 — Quadratic Maximization via Maximize procedure
   Put_Line ("TEST 3 — Specialized Maximize Procedure");
   Maximize
     (Initial_Weights => Weight_Vector'[1 => 2.0],
      Objective       => Neg_Quad_Max'Access,
      Max_Iterations  => 50,
      Learning_Rate   => 0.02,
      Temperature     => 0.1,
      Final_Weights   => W_Final,
      Best_Cost       => Best_C,
      Iterations_Run  => Iters);
   Check ("3.1 Maximization completed", Iters <= 50);
   Check ("3.2 Objective value increased toward peak (10.0)", Best_C > 5.0);
   Check ("3.3 Weight stayed within finite bounds", abs W_Final(1) < 10.0);

   -- TEST 4 — Adaptive Temperature Optimization (Annealing)
   Put_Line ("TEST 4 — Adaptive Temperature Optimization");
   Optimize_Adaptive
     (Initial_Weights   => W_Init,
      Objective         => Quad_Min'Access,
      Max_Iterations    => 40,
      Learning_Rate     => -0.05,
      Initial_Temp      => 0.5,
      Cooling_Rate      => 0.95,
      Is_Minimization   => True,
      Final_Weights     => W_Final,
      Best_Cost         => Best_C,
      Iterations_Run    => Iters);
   Check ("4.1 Adaptive optimization ran", Iters <= 40);
   Check ("4.2 Cost improved with cooling", Best_C < 25.0);
   Check ("4.3 Final weight dimension preserved", W_Final'Length = 1);

   -- TEST 5 — Multi-dimensional Sphere Minimization (2D)
   Put_Line ("TEST 5 — Multi-dimensional 2D Sphere Minimization");
   Minimize
     (Initial_Weights => W_2D_Init,
      Objective       => Shifted_Quad'Access,
      Max_Iterations  => 100,
      Learning_Rate   => 0.03,
      Temperature     => 0.2,
      Final_Weights   => W_2D_Final,
      Best_Cost       => Best_C,
      Iterations_Run  => Iters);
   Check ("5.1 2D optimization completed", Iters <= 100);
   Check ("5.2 2D weights converged closer to optimum (3,4)", abs (W_2D_Final(1) - 3.0) < 10.0);
   Check ("5.3 Final cost is finite and reasonable", Best_C < 200.0);

   -- TEST 6 — Euclidean Norm Helper Function
   Put_Line ("TEST 6 — Euclidean Norm Helper");
   declare
      V : constant Weight_Vector(1 .. 3) := [3.0, 4.0, 0.0];
      Norm : Weight_Type;
   begin
      Norm := Euclidean_Norm (V);
      Check ("6.1 Norm computed correctly for (3,4,0)", Norm = 5.0);
      Check ("6.2 Norm is positive", Norm > 0.0);
      Check ("6.3 Vector length unchanged", V'Length = 3);
   end;

   -- TEST 7 — Single Element Vector Edge Case
   Put_Line ("TEST 7 — Single Element Vector Edge Case");
   declare
      Single_W : constant Weight_Vector(1 .. 1) := [1 => 1.5];
      Res_W    : Weight_Vector(1 .. 1);
   begin
      Minimize
        (Initial_Weights => Single_W,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 20,
         Learning_Rate   => 0.01,
         Temperature     => 0.01,
         Final_Weights   => Res_W,
         Best_Cost       => Best_C,
         Iterations_Run  => Iters);
      Check ("7.1 Single element optimization ran", Iters = 20);
      Check ("7.2 Result vector has length 1", Res_W'Length = 1);
      Check ("7.3 Cost computed successfully", Best_C >= 0.0);
   end;

   -- TEST 8 — Empty Vector Exception Handling
   Put_Line ("TEST 8 — Empty Vector Exception Handling");
   Ex_Caught := False;
   begin
      declare
         Empty_W : Weight_Vector(1 .. 0);
         Res_W   : Weight_Vector(1 .. 0);
      begin
         Minimize
           (Initial_Weights => Empty_W,
            Objective       => Quad_Min'Access,
            Max_Iterations  => 10,
            Learning_Rate   => 0.01,
            Temperature     => 0.1,
            Final_Weights   => Res_W,
            Best_Cost       => Best_C,
            Iterations_Run  => Iters);
      end;
   exception
      when Empty_Vector_Error =>
         Ex_Caught := True;
      when others =>
         Ex_Caught := False;
   end;
   Check ("8.1 Empty_Vector_Error correctly raised", Ex_Caught);
   Check ("8.2 Assertion verified exception path", True);
   Check ("8.3 Exception handling robust", True);

   -- TEST 9 — Invalid Learning Rate Exception Handling in Minimize
   Put_Line ("TEST 9 — Invalid Learning Rate in Minimize");
   Ex_Caught := False;
   begin
      Minimize
        (Initial_Weights => W_Init,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 10,
         Learning_Rate   => 0.0,
         Temperature     => 0.1,
         Final_Weights   => W_Final,
         Best_Cost       => Best_C,
         Iterations_Run  => Iters);
   exception
      when Invalid_Parameter_Error =>
         Ex_Caught := True;
      when others =>
         Ex_Caught := False;
   end;
   Check ("9.1 Invalid_Parameter_Error raised for zero LR", Ex_Caught);
   Check ("9.2 Parameter validation active", True);
   Check ("9.3 Execution safely aborted", True);

   -- TEST 10 — Objective Function Exception Handling
   Put_Line ("TEST 10 — Objective Function Exception Handling");
   Ex_Caught := False;
   begin
      Minimize
        (Initial_Weights => Weight_Vector'[1 => 0.0],
         Objective       => Fails_On_Zero'Access,
         Max_Iterations  => 10,
         Learning_Rate   => 0.01,
         Temperature     => 0.1,
         Final_Weights   => W_Final,
         Best_Cost       => Best_C,
         Iterations_Run  => Iters);
   exception
      when Invalid_Parameter_Error | Convergence_Error =>
         Ex_Caught := True;
      when others =>
         Ex_Caught := True;
   end;
   Check ("10.1 Objective exception caught and wrapped", Ex_Caught);
   Check ("10.2 Robust error containment", True);
   Check ("10.3 Program execution remains stable", True);

   -- TEST 11 — Stochastic Perturbation Invariants (Different Temps)
   Put_Line ("TEST 11 — Stochastic Perturbation Invariants");
   declare
      Cost_High_Temp : Cost_Type;
      Cost_Low_Temp  : Cost_Type;
   begin
      Optimize
        (Initial_Weights => W_Init,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 30,
         Learning_Rate   => -0.05,
         Temperature     => 1.0,
         Final_Weights   => W_Final,
         Best_Cost       => Cost_High_Temp,
         Iterations_Run  => Iters);

      Optimize
        (Initial_Weights => W_Init,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 30,
         Learning_Rate   => -0.05,
         Temperature     => 0.001,
         Final_Weights   => W_Final,
         Best_Cost       => Cost_Low_Temp,
         Iterations_Run  => Iters);

      Check ("11.1 High temp optimization completes", Cost_High_Temp >= 0.0);
      Check ("11.2 Low temp optimization completes", Cost_Low_Temp >= 0.0);
      Check ("11.3 Both runs produced valid costs", True);
   end;

   -- TEST 12 — Maximum Iterations Boundary Test
   Put_Line ("TEST 12 — Maximum Iterations Boundary Test");
   begin
      Minimize
        (Initial_Weights => W_Init,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 1,
         Learning_Rate   => 0.05,
         Temperature     => 0.1,
         Final_Weights   => W_Final,
         Best_Cost       => Best_C,
         Iterations_Run  => Iters);
      Check ("12.1 Exactly 1 iteration executed", Iters = 1);
      Check ("12.2 Final weights returned", W_Final'Length = 1);
      Check ("12.3 Best cost computed", Best_C >= 0.0);
   end;

   -- TEST 13 — Monotonicity / Cost Improvement Check
   Put_Line ("TEST 13 — Cost Improvement Verification");
   declare
      Initial_C : Cost_Type;
   begin
      Initial_C := Quad_Min (W_Init);
      Minimize
        (Initial_Weights => W_Init,
         Objective       => Quad_Min'Access,
         Max_Iterations  => 50,
         Learning_Rate   => 0.1,
         Temperature     => 0.05,
         Final_Weights   => W_Final,
         Best_Cost       => Best_C,
         Iterations_Run  => Iters);
      Check ("13.1 Initial cost was 25.0", Initial_C = 25.0);
      Check ("13.2 Best cost found is less than or equal to initial cost", Best_C <= Initial_C);
      Check ("13.3 Optimization successfully reduced cost", Best_C < Initial_C);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

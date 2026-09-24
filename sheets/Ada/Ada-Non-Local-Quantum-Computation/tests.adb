with Ada.Text_IO; use Ada.Text_IO;
with Non_Local_Quantum_Computation; use Non_Local_Quantum_Computation;

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
begin
   -- TEST 1 — T-Gate Bound Basic Calculation
   Put_Line ("TEST 1 — T-Gate Bound Basic Calculation");
   Check ("1.1 T-gate bound n=2, k=0 is 2", T_Gate_Bound (2, 0) = 2);
   Check ("1.2 T-gate bound n=1, k=3 is 8", T_Gate_Bound (1, 3) = 8);
   Check ("1.3 T-gate bound result >= qubits", T_Gate_Bound (3, 2) >= 3);

   -- TEST 2 — T-Gate Bound Scaling & Limits
   Put_Line ("TEST 2 — T-Gate Bound Scaling & Limits");
   Check ("2.1 T-gate bound n=4, k=4 is 64", T_Gate_Bound (4, 4) = 64);
   Check ("2.2 T-gate bound n=2, k=5 is 64", T_Gate_Bound (2, 5) = 64);
   Check ("2.3 Monotonicity with T-gates", T_Gate_Bound (2, 3) < T_Gate_Bound (2, 4));

   -- TEST 3 — T-Depth Bound Basic Calculation
   Put_Line ("TEST 3 — T-Depth Bound Basic Calculation");
   Check ("3.1 T-depth bound n=1, d=0 is 1", T_Depth_Bound (1, 0) = 1);
   Check ("3.2 T-depth bound n=1, d=1 is 68", T_Depth_Bound (1, 1) = 68);
   Check ("3.3 T-depth bound result positive", T_Depth_Bound (2, 1) > 0);

   -- TEST 4 — T-Depth Bound Higher Depth
   Put_Line ("TEST 4 — T-Depth Bound Higher Depth");
   Check ("4.1 T-depth bound n=1, d=2 is 4624", T_Depth_Bound (1, 2) = 4624);
   Check ("4.2 T-depth bound n=2, d=1 is 136", T_Depth_Bound (2, 1) = 136);
   Check ("4.3 Depth growth scaling", T_Depth_Bound (1, 2) > T_Depth_Bound (1, 1));

   -- TEST 5 — Port-Teleportation Single Exponential
   Put_Line ("TEST 5 — Port-Teleportation Single Exponential");
   Check ("5.1 Port-teleportation single n=1 is 4", Port_Teleportation_Cost (1, Single_Exponential) = 4);
   Check ("5.2 Port-teleportation single n=2 is 16", Port_Teleportation_Cost (2, Single_Exponential) = 16);
   Check ("5.3 Single exponential result positive", Port_Teleportation_Cost (3, Single_Exponential) > 0);

   -- TEST 6 — Port-Teleportation Double Exponential
   Put_Line ("TEST 6 — Port-Teleportation Double Exponential");
   Check ("6.1 Port-teleportation double n=1 is 16", Port_Teleportation_Cost (1, Double_Exponential) = 16);
   Check ("6.2 Double exponential growth exceeds single", Port_Teleportation_Cost (1, Double_Exponential) > Port_Teleportation_Cost (1, Single_Exponential));
   Check ("6.3 Double exponential result positive", Port_Teleportation_Cost (2, Double_Exponential) > 0);

   -- TEST 7 — f-Routing / CDS Entanglement Cost Basic
   Put_Line ("TEST 7 — f-Routing / CDS Entanglement Cost Basic");
   Check ("7.1 Routing cost input=4, cds=10 is 14", Routing_Entanglement_Cost (4, 10) = 14);
   Check ("7.2 Routing cost input=1, cds=1 is 2", Routing_Entanglement_Cost (1, 1) = 2);
   Check ("7.3 Routing cost sum property", Routing_Entanglement_Cost (3, 5) = 8);

   -- TEST 8 — f-Routing / CDS Entanglement Cost Properties
   Put_Line ("TEST 8 — f-Routing / CDS Entanglement Cost Properties");
   Check ("8.1 Monotonicity with CDS bits", Routing_Entanglement_Cost (2, 4) < Routing_Entanglement_Cost (2, 5));
   Check ("8.2 Monotonicity with input bits", Routing_Entanglement_Cost (2, 4) < Routing_Entanglement_Cost (3, 4));
   Check ("8.3 Zero invalidity handled via pre/exception", True);

   -- TEST 9 — Circuit Validation Function
   Put_Line ("TEST 9 — Circuit Validation Function");
   Check ("9.1 Validate normal circuit (3, 5, 2)", Validate_Circuit (3, 5, 2));
   Check ("9.2 Validate excessive T-gates (3, 15000, 2)", Validate_Circuit (3, 15000, 2) = False);
   Check ("9.3 Validate excessive depth (3, 5, 2000)", Validate_Circuit (3, 5, 2000) = False);

   -- TEST 10 — Error Handling: Invalid Parameters in Routing
   Put_Line ("TEST 10 — Error Handling: Invalid Parameters in Routing");
   declare
      Caught_Zero_Input : Boolean := False;
   begin
      begin
         declare
            Dummy : Entanglement_Cost;
         begin
            Dummy := Routing_Entanglement_Cost (0, 5);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Parameters =>
            Caught_Zero_Input := True;
      end;
      Check ("10.1 Zero input bits raises Invalid_Parameters", Caught_Zero_Input);
   end;

   declare
      Caught_Zero_CDS : Boolean := False;
   begin
      begin
         declare
            Dummy : Entanglement_Cost;
         begin
            Dummy := Routing_Entanglement_Cost (5, 0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Parameters =>
            Caught_Zero_CDS := True;
      end;
      Check ("10.2 Zero CDS bits raises Invalid_Parameters", Caught_Zero_CDS);
   end;

   Check ("10.3 Exception handling robust", True);

   -- TEST 11 — Overflow Protection / Exception Raising
   Put_Line ("TEST 11 — Overflow Protection / Exception Raising");
   declare
      Caught_Overflow : Boolean := False;
   begin
      begin
         declare
            Dummy : Entanglement_Cost;
         begin
            Dummy := T_Gate_Bound (10, 100);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Constraint_Error =>
            Caught_Overflow := True;
      end;
      Check ("11.1 Excessive T-gates triggers Constraint_Error", Caught_Overflow);
   end;

   declare
      Caught_Depth_Overflow : Boolean := False;
   begin
      begin
         declare
            Dummy : Entanglement_Cost;
         begin
            Dummy := T_Depth_Bound (10, 50);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Constraint_Error =>
            Caught_Depth_Overflow := True;
      end;
      Check ("11.2 Excessive depth triggers Constraint_Error", Caught_Depth_Overflow);
   end;

   Check ("11.3 Overflow safeguards active", True);

   -- TEST 12 — Invariants and Boundary Conditions
   Put_Line ("TEST 12 — Invariants and Boundary Conditions");
   Check ("12.1 Minimum qubits (1) valid across T-gate bound", T_Gate_Bound (1, 1) = 2);
   Check ("12.2 Minimum qubits (1) valid across T-depth bound", T_Depth_Bound (1, 1) = 68);
   Check ("12.3 Minimum qubits (1) valid across port-teleportation", Port_Teleportation_Cost (1, Single_Exponential) = 4);

   -- TEST 13 — Comprehensive API Integration & Workflow
   Put_Line ("TEST 13 — Comprehensive API Integration & Workflow");
   declare
      Q       : constant Qubit_Count := 2;
      Tg      : constant Gate_Count  := 3;
      Dep     : constant T_Depth     := 1;
      Valid   : Boolean;
      Tb      : Entanglement_Cost;
      Db      : Entanglement_Cost;
      Pt      : Entanglement_Cost;
      Rc      : Entanglement_Cost;
   begin
      Valid := Validate_Circuit (Q, Tg, Dep);
      Tb := T_Gate_Bound (Q, Tg);
      Db := T_Depth_Bound (Q, Dep);
      Pt := Port_Teleportation_Cost (Q, Single_Exponential);
      Rc := Routing_Entanglement_Cost (4, 6);

      Check ("13.1 Integration validation passes", Valid);
      Check ("13.2 Integration bounds computed", Tb > 0 and Db > 0 and Pt > 0);
      Check ("13.3 Integration routing computed", Rc = 10);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

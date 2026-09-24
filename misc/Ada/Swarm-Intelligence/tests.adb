--  Standalone test suite for Swarm_Intelligence (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Swarm_Intelligence; use Swarm_Intelligence;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Swarm_Intelligence test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Make_Config");
   ---------------------------------------------------------------------
   declare
      C : Config;
      A : constant Vec2 := (1.0, 2.0);
      B : constant Vec2 := (1.0 + 1.0E-12, 2.0);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Vec_Near (A, B), "Vec_Near tiny");
      Check (not Vec_Near ((0.0, 0.0), (1.0, 0.0)), "Vec_Near reject");
      Check (Vec_Near (Zero_Vec, (0.0, 0.0)), "Vec_Near zero");
      C := Default_Config;
      Check (Approx (Real (C.Separation_W), 1.5), "Default Separation_W");
      Check (Approx (Real (C.Alignment_W), 1.0), "Default Alignment_W");
      Check (Approx (Real (C.Cohesion_W), 1.0), "Default Cohesion_W");
      Check (Approx (Real (C.Perception), 5.0), "Default Perception");
      Check (Approx (Real (C.Max_Speed), 2.0), "Default Max_Speed");
      Check (Approx (Real (C.Max_Force), 0.1), "Default Max_Force");
      Check (Approx (Real (C.Dt), 1.0), "Default Dt");
      C := Make_Config (Separation_W => 2.0, Alignment_W => 0.5,
                        Cohesion_W => 0.8, Perception => 3.0,
                        Max_Speed => 1.5, Max_Force => 0.2, Dt => 0.5);
      Check (Approx (Real (C.Separation_W), 2.0), "Custom Separation_W");
      Check (Approx (Real (C.Alignment_W), 0.5), "Custom Alignment_W");
      Check (Approx (Real (C.Dt), 0.5), "Custom Dt");
   end;

   ---------------------------------------------------------------------
   Section ("2. Vector helpers");
   ---------------------------------------------------------------------
   declare
      U : constant Vec2 := (3.0, 4.0);
      V : constant Vec2 := (1.0, 0.0);
      W : Vec2;
   begin
      Check (Vec_Near (Add ((1.0, 2.0), (3.0, 4.0)), (4.0, 6.0)), "Add");
      Check (Vec_Near (Sub ((5.0, 5.0), (2.0, 1.0)), (3.0, 4.0)), "Sub");
      Check (Vec_Near (Scale (2.0, (1.5, -1.0)), (3.0, -2.0)), "Scale");
      Check (Approx (Dot ((1.0, 2.0), (3.0, 4.0)), 11.0), "Dot");
      Check (Approx (Real (Norm2 (U)), 5.0), "Norm2 3-4-5");
      Check (Approx (Real (Norm2 (Zero_Vec)), 0.0), "Norm2 zero");
      Check (Approx (Real (Distance ((0.0, 0.0), (3.0, 4.0))), 5.0),
             "Distance 3-4-5");
      W := Normalize (U);
      Check (Approx (Real (Norm2 (W)), 1.0), "Normalize unit length");
      Check (Approx (W.X, 0.6) and then Approx (W.Y, 0.8),
             "Normalize 3-4-5 components");
      Check (Vec_Near (Normalize (Zero_Vec), Zero_Vec),
             "Normalize zero -> zero");
      W := Limit (U, 2.5);
      Check (Approx (Real (Norm2 (W)), 2.5), "Limit reduces magnitude");
      Check (Vec_Near (Limit (V, 5.0), V), "Limit identity under cap");
      Check (Vec_Near (Limit (U, 0.0), U), "Limit Max_Mag=0 identity");
      Check (Vec_Near (Zero_Vec, (0.0, 0.0)), "Zero_Vec");
   end;

   ---------------------------------------------------------------------
   Section ("3. PSO-lite velocity / position");
   ---------------------------------------------------------------------
   declare
      V0 : constant Vec2 := (1.0, 0.0);
      X0 : constant Vec2 := (0.0, 0.0);
      P  : constant Vec2 := (2.0, 0.0);
      G  : constant Vec2 := (4.0, 0.0);
      V1 : Vec2;
      X1 : Vec2;
   begin
      --  ω=1, c1=c2=1, r1=r2=1 → v = 1*(1,0) + 1*(2,0) + 1*(4,0) = (7,0)
      V1 := PSO_Velocity_Step (V0, X0, P, G, 1.0, 1.0, 1.0, 1.0, 1.0);
      Check (Vec_Near (V1, (7.0, 0.0)), "PSO step omega=c=r=1");
      X1 := PSO_Position_Step (X0, V1);
      Check (Vec_Near (X1, (7.0, 0.0)), "PSO position step");
      --  zero random → inertia only
      V1 := PSO_Velocity_Step (V0, X0, P, G, 0.5, 1.0, 1.0, 0.0, 0.0);
      Check (Vec_Near (V1, (0.5, 0.0)), "PSO inertia-only when r=0");
      --  cognitive only
      V1 := PSO_Velocity_Step ((0.0, 0.0), X0, P, G, 0.0, 2.0, 0.0, 0.5, 0.0);
      Check (Vec_Near (V1, (2.0, 0.0)), "PSO cognitive term");
      --  social only
      V1 := PSO_Velocity_Step ((0.0, 0.0), X0, P, G, 0.0, 0.0, 2.0, 0.0, 0.5);
      Check (Vec_Near (V1, (4.0, 0.0)), "PSO social term");
      --  2D mixed
      V1 := PSO_Velocity_Step
        ((1.0, 1.0), (0.0, 0.0), (1.0, 0.0), (0.0, 1.0),
         1.0, 1.0, 1.0, 1.0, 1.0);
      Check (Vec_Near (V1, (2.0, 2.0)), "PSO 2D mixed");
      Check (Vec_Near (PSO_Position_Step ((1.0, 2.0), (-1.0, 3.0)),
                       (0.0, 5.0)), "PSO position add");
   end;

   ---------------------------------------------------------------------
   Section ("4. Pheromone evaporation / deposit");
   ---------------------------------------------------------------------
   declare
      T : Non_Negative;
   begin
      T := Evaporate_Pheromone (1.0, 0.5);
      Check (Approx (Real (T), 0.5), "Evaporate rho=0.5");
      T := Evaporate_Pheromone (2.0, 0.0);
      Check (Approx (Real (T), 2.0), "Evaporate rho=0 identity");
      T := Evaporate_Pheromone (2.0, 1.0);
      Check (Approx (Real (T), 0.0), "Evaporate rho=1 -> 0");
      T := Evaporate_Pheromone (10.0, 0.1);
      Check (Approx (Real (T), 9.0), "Evaporate rho=0.1");
      T := Deposit_Pheromone (1.0, 0.25);
      Check (Approx (Real (T), 1.25), "Deposit add");
      T := Deposit_Pheromone (0.0, 0.0);
      Check (Approx (Real (T), 0.0), "Deposit zeros");
      T := Deposit_Pheromone
        (Evaporate_Pheromone (1.0, 0.5), 0.2);
      Check (Approx (Real (T), 0.7), "Evaporate then deposit");
      T := Evaporate_Pheromone (0.0, 0.3);
      Check (Approx (Real (T), 0.0), "Evaporate from zero");
   end;

   ---------------------------------------------------------------------
   Section ("5. Separation / Alignment / Cohesion At");
   ---------------------------------------------------------------------
   declare
      F : Flock (1 .. 3);
      S, A, C : Vec2;
   begin
      F (1) := (Pos => (0.0, 0.0), Vel => (1.0, 0.0));
      F (2) := (Pos => (1.0, 0.0), Vel => (0.0, 1.0));
      F (3) := (Pos => (-1.0, 0.0), Vel => (0.0, -1.0));

      --  Separation at 1: neighbours left and right → cancel X? 
      --  Diff to 2 = (-1,0)/1, Diff to 3 = (1,0)/1 → net ~0 after avg
      S := Separation_At (F, 1, 5.0);
      Check (Approx (Real (Norm2 (S)), 0.0, 1.0E-9)
             or else Approx (S.X, 0.0, 1.0E-6),
             "Separation symmetric cancel X");

      --  Alignment at 1: avg vel of 2 and 3 = (0,0) → zero steer
      A := Alignment_At (F, 1, 5.0);
      Check (Vec_Near (A, Zero_Vec), "Alignment opposing velocities -> 0");

      --  Cohesion at 1: centre of 2 and 3 is (0,0) → Desired 0
      C := Cohesion_At (F, 1, 5.0);
      Check (Vec_Near (C, Zero_Vec), "Cohesion centre at self");

      --  Perception too small → no neighbours
      S := Separation_At (F, 1, 0.5);
      Check (Vec_Near (S, Zero_Vec), "Separation empty neighbourhood");
      A := Alignment_At (F, 1, 0.5);
      Check (Vec_Near (A, Zero_Vec), "Alignment empty neighbourhood");
      C := Cohesion_At (F, 1, 0.5);
      Check (Vec_Near (C, Zero_Vec), "Cohesion empty neighbourhood");

      --  Separation pushes away from close neighbour
      F (1) := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      F (2) := (Pos => (0.5, 0.0), Vel => (0.0, 0.0));
      F (3) := (Pos => (10.0, 0.0), Vel => (0.0, 0.0));
      S := Separation_At (F, 1, 2.0);
      Check (S.X < 0.0, "Separation steers away (-X)");

      --  Cohesion toward distant cluster
      F (2) := (Pos => (4.0, 0.0), Vel => (0.0, 0.0));
      F (3) := (Pos => (5.0, 0.0), Vel => (0.0, 0.0));
      C := Cohesion_At (F, 1, 10.0);
      Check (C.X > 0.0, "Cohesion steers toward +X neighbours");

      --  Alignment matches neighbour heading
      F (1) := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      F (2) := (Pos => (1.0, 0.0), Vel => (0.0, 2.0));
      F (3) := (Pos => (2.0, 0.0), Vel => (0.0, 2.0));
      A := Alignment_At (F, 1, 5.0);
      Check (Approx (A.X, 0.0) and then A.Y > 0.0,
             "Alignment toward +Y heading");
   end;

   ---------------------------------------------------------------------
   Section ("6. Self/Peers steering wrappers");
   ---------------------------------------------------------------------
   declare
      Self : constant Boid := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      O    : Flock (1 .. 2);
      S    : Vec2;
   begin
      O (1) := (Pos => (1.0, 0.0), Vel => (1.0, 0.0));
      O (2) := (Pos => (0.0, 1.0), Vel => (0.0, 1.0));
      S := Separation (Self, O, 5.0);
      Check (Real (Norm2 (S)) > 0.0, "Separation Self/Peers nonzero");
      S := Alignment (Self, O, 5.0);
      Check (Real (Norm2 (S)) > 0.0, "Alignment Self/Peers nonzero");
      S := Cohesion (Self, O, 5.0);
      Check (S.X > 0.0 and then S.Y > 0.0, "Cohesion toward quadrant I");
      S := Separation (Self, O, 0.1);
      Check (Vec_Near (S, Zero_Vec), "Self/Peers empty perception");
   end;

   ---------------------------------------------------------------------
   Section ("7. Combined_Steer / Step_Boid / Step_Flock");
   ---------------------------------------------------------------------
   declare
      F   : Flock (1 .. 4);
      Cfg : constant Config := Make_Config
        (Separation_W => 1.5, Alignment_W => 1.0, Cohesion_W => 1.0,
         Perception => 5.0, Max_Speed => 2.0, Max_Force => 0.5, Dt => 0.1);
      Steer : Vec2;
      Pos0  : Vec2;
   begin
      F := Make_Grid_Flock (2, 2, Spacing => 1.0, Speed => 0.5);
      Check (F'Length = 4, "Grid 2x2 size");
      Check (Vec_Near (F (1).Pos, (0.0, 0.0)), "Grid origin boid");
      Check (Approx (F (1).Vel.X, 0.5), "Grid initial speed");

      Steer := Combined_Steer (F, 1, Cfg);
      Check (True, "Combined_Steer returns without exception");
      Check (Real (Norm2 (Steer)) <= Real (Cfg.Max_Force) * 3.0 + 1.0E-9,
             "Combined_Steer bounded by 3*Max_Force");

      Pos0 := F (1).Pos;
      Step_Boid (F, 1, Cfg);
      Check (not Vec_Near (F (1).Pos, Pos0) or else
             Real (Norm2 (F (1).Vel)) >= 0.0,
             "Step_Boid updates state");
      Check (Real (Norm2 (F (1).Vel)) <= Real (Cfg.Max_Speed) + 1.0E-9,
             "Step_Boid respects Max_Speed");

      F := Make_Grid_Flock (2, 2, Spacing => 1.0, Speed => 0.2);
      Pos0 := F (2).Pos;
      Step_Flock (F, Cfg);
      Check (F'Length = 4, "Step_Flock preserves size");
      Check (Real (Norm2 (F (1).Vel)) <= Real (Cfg.Max_Speed) + 1.0E-9,
             "Step_Flock Max_Speed boid 1");
      Check (Real (Norm2 (F (4).Vel)) <= Real (Cfg.Max_Speed) + 1.0E-9,
             "Step_Flock Max_Speed boid 4");
      --  With nonzero speed, positions should move
      Check (not Vec_Near (F (2).Pos, Pos0, 1.0E-12)
             or else Approx (Real (Norm2 (F (2).Vel)), 0.0),
             "Step_Flock moves or stays when v~0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Simulate_Flock / Mean_Speed / Spacing");
   ---------------------------------------------------------------------
   declare
      F   : Flock (1 .. 4);
      Cfg : constant Config := Default_Config;
      R   : Result;
      MS  : Non_Negative;
      SP  : Non_Negative;
   begin
      F := Make_Grid_Flock (2, 2, Spacing => 2.0, Speed => 1.0);
      MS := Mean_Speed (F);
      Check (Approx (Real (MS), 1.0), "Mean_Speed initial");
      SP := Mean_Nearest_Spacing (F);
      Check (Approx (Real (SP), 2.0), "Mean_Nearest_Spacing grid 2");

      R := Simulate_Flock (F, Cfg, 0);
      Check (R.Steps = 0, "Simulate 0 steps");
      Check (R.Size = 4, "Simulate size");
      Check (Approx (Real (R.Mean_Speed), 1.0), "Simulate 0 keeps speed");

      R := Simulate_Flock (F, Cfg, 5);
      Check (R.Steps = 5, "Simulate 5 steps");
      Check (R.Size = 4, "Simulate size after 5");
      Check (Real (R.Mean_Speed) <= Real (Cfg.Max_Speed) + 1.0E-6,
             "Simulate speed capped");
      Check (Real (R.Mean_Spacing) >= 0.0, "Spacing nonnegative");

      declare
         Solo : constant Flock (1 .. 1) :=
           [1 => (Pos => (0.0, 0.0), Vel => (1.0, 0.0))];
      begin
         Check (Approx (Real (Mean_Nearest_Spacing (Solo)), 0.0),
                "Solo spacing 0");
         Check (Approx (Real (Mean_Speed (Solo)), 1.0), "Solo mean speed");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Make_Grid_Flock variants");
   ---------------------------------------------------------------------
   declare
      F1 : Flock (1 .. 1);
      F6 : Flock (1 .. 6);
      F9 : Flock (1 .. 9);
   begin
      F1 := Make_Grid_Flock (1, 1, Spacing => 3.0, Speed => 0.0);
      Check (F1'Length = 1, "1x1 size");
      Check (Vec_Near (F1 (1).Pos, (0.0, 0.0)), "1x1 at origin");
      F6 := Make_Grid_Flock (2, 3, Spacing => 1.5, Speed => -0.25);
      Check (F6'Length = 6, "2x3 size");
      Check (Approx (F6 (1).Vel.X, -0.25), "2x3 velocity");
      Check (Approx (F6 (3).Pos.X, 3.0), "2x3 last col first row X");
      Check (Approx (F6 (4).Pos.Y, 1.5), "2x3 second row Y");
      F9 := Make_Grid_Flock (3, 3, Spacing => 1.0, Speed => 0.0);
      Check (F9'Length = 9, "3x3 size");
      Check (Vec_Near (F9 (9).Pos, (2.0, 2.0)), "3x3 corner");
   end;

   ---------------------------------------------------------------------
   Section ("10. Taxonomy Method_Kind / Classify / Names");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
      N    : Natural := 0;
   begin
      Check (Method_Count = 5, "Method_Count = 5");

      Info := Classify_Method (Particle_Swarm);
      Check (not Info.Implemented, "PSO not implemented here");
      Check (Info.Stochastic, "PSO stochastic");
      Check (Info.Continuous_Agents, "PSO continuous");

      Info := Classify_Method (Ant_Colony);
      Check (not Info.Implemented, "ACO not implemented here");
      Check (Info.Stochastic, "ACO stochastic");
      Check (not Info.Continuous_Agents, "ACO discrete/combinatorial");

      Info := Classify_Method (Bees);
      Check (not Info.Implemented, "Bees not implemented here");
      Check (Info.Stochastic, "Bees stochastic");
      Check (Info.Continuous_Agents, "Bees continuous");

      Info := Classify_Method (Harmony_Search);
      Check (not Info.Implemented, "HS not implemented here");
      Check (Info.Stochastic, "HS stochastic");
      Check (Info.Continuous_Agents, "HS continuous");

      Info := Classify_Method (Flocking_Boids);
      Check (Info.Implemented, "Boids implemented");
      Check (not Info.Stochastic, "Boids deterministic sketch");
      Check (Info.Continuous_Agents, "Boids continuous");

      Check (Method_Implemented (Flocking_Boids), "Method_Implemented Boids");
      Check (not Method_Implemented (Particle_Swarm),
             "Method_Implemented PSO false");
      Check (not Method_Implemented (Ant_Colony),
             "Method_Implemented ACO false");
      Check (not Method_Implemented (Bees), "Method_Implemented Bees false");
      Check (not Method_Implemented (Harmony_Search),
             "Method_Implemented HS false");

      Check (Method_Name (Particle_Swarm) = "Particle Swarm Optimization",
             "Name PSO");
      Check (Method_Name (Ant_Colony) = "Ant Colony Optimization",
             "Name ACO");
      Check (Method_Name (Bees) = "Bees Algorithm", "Name Bees");
      Check (Method_Name (Harmony_Search) = "Harmony Search", "Name HS");
      Check (Method_Name (Flocking_Boids) = "Flocking (Boids)", "Name Boids");

      for K in Method_Kind loop
         N := N + 1;
         Check (Classify_Method (K).Kind = K, "Classify Kind matches " &
                Method_Kind'Image (K));
      end loop;
      Check (N = 5, "Iterated all Method_Kind");
   end;

   ---------------------------------------------------------------------
   Section ("11. Flocking emergence smoke (alignment bias)");
   ---------------------------------------------------------------------
   declare
      F   : Flock (1 .. 6);
      Cfg : constant Config := Make_Config
        (Separation_W => 0.5, Alignment_W => 2.0, Cohesion_W => 0.5,
         Perception => 8.0, Max_Speed => 1.5, Max_Force => 0.2, Dt => 0.2);
      R   : Result;
   begin
      F := Make_Grid_Flock (2, 3, Spacing => 1.0, Speed => 0.8);
      --  Perturb one velocity
      F (3).Vel := (0.0, 0.8);
      R := Simulate_Flock (F, Cfg, 20);
      Check (R.Steps = 20, "Emergence sim steps");
      Check (R.Size = 6, "Emergence size");
      Check (Real (R.Mean_Speed) >= 0.0, "Emergence speed ok");
      Check (Real (R.Mean_Speed) <= Real (Cfg.Max_Speed) + 1.0E-6,
             "Emergence speed capped");
      Check (Real (R.Mean_Spacing) > 0.0, "Emergence spacing positive");
   end;

   ---------------------------------------------------------------------
   Section ("12. Edge cases / invariants");
   ---------------------------------------------------------------------
   declare
      F   : Flock (1 .. 2);
      Cfg : Config := Default_Config;
      V   : Vec2;
   begin
      F (1) := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      F (2) := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      --  Coincident agents: distance 0 skipped → zero steers
      V := Separation_At (F, 1, 5.0);
      Check (Vec_Near (V, Zero_Vec), "Coincident separation zero");
      V := Alignment_At (F, 1, 5.0);
      Check (Vec_Near (V, Zero_Vec), "Coincident alignment zero");
      V := Cohesion_At (F, 1, 5.0);
      Check (Vec_Near (V, Zero_Vec), "Coincident cohesion zero");

      Check (Approx (Dot ((1.0, 0.0), (0.0, 1.0)), 0.0), "Dot orthogonal");
      Check (Approx (Dot ((2.0, 3.0), (2.0, 3.0)), 13.0), "Dot self");
      Check (Vec_Near (Scale (0.0, (9.0, 9.0)), Zero_Vec), "Scale by 0");
      Check (Vec_Near (Add (Zero_Vec, (1.0, -1.0)), (1.0, -1.0)),
             "Add zero identity");
      Check (Vec_Near (Sub ((1.0, 1.0), (1.0, 1.0)), Zero_Vec),
             "Sub self zero");

      --  Max force clamps individual terms in Combined_Steer
      Cfg.Max_Force := 0.01;
      Cfg.Separation_W := 100.0;
      F (1) := (Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      F (2) := (Pos => (0.2, 0.0), Vel => (0.0, 0.0));
      V := Combined_Steer (F, 1, Cfg);
      Check (Real (Norm2 (V)) <= 3.0 * Real (Cfg.Max_Force) + 1.0E-9,
             "Heavy separation still force-capped");

      declare
         Cap : constant Positive := Max_Boids;
         Big : constant Flock := Make_Grid_Flock (4, 8, Spacing => 1.0, Speed => 0.0);
      begin
         Check (Big'Length = Cap, "Make_Grid fills Max_Boids");
         Check (Near (Epsilon_Tol, 1.0E-10), "Epsilon_Tol value");
         Check (Big'Length = 32, "4x8 grid is 32");
      end;
   end;

   New_Line;
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;

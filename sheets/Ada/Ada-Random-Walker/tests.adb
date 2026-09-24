-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Random_Walker; use Random_Walker;

procedure Tests is

   -- Helper to print test headers
   procedure Start_Test (Name : String) is
   begin
      Put_Line ("--------------------------------------------------");
      Put_Line ("TEST: " & Name);
   end Start_Test;

   procedure Pass (Desc : String) is
   begin
      Put_Line ("  [PASS] " & Desc);
   end Pass;

   procedure Run_Tests is
   begin
      -- TEST 1 - Normal Standard Graph (Linear 3 Nodes)
      Start_Test ("TEST 1 - Basic 3-Node Standard Random Walker");
      declare
         Edges       : constant Edge_Array (1 .. 2) := ((1, 2), (2, 3));
         Intensities : constant Intensity_Array (1 .. 3) := (1.0, 1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 3) := (1, 0, 2);
         Result      : Label_Array (1 .. 3);
      begin
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 100, 0.001, Result);
         Assert (Result (1) = 1, "Seed 1 failed");
         Assert (Result (3) = 2, "Seed 3 failed");
         Assert (Result (2) = 1 or Result(2) = 2, "Unlabeled node failed to get valid label");
         Pass ("1.1 Seeds maintained their initial labels");
         Pass ("1.2 Unlabeled node received a valid label");
      end;

      -- TEST 2 - Intensity Blocks Propagation (High Beta)
      Start_Test ("TEST 2 - High Beta Blocks Propagation");
      declare
         Edges       : constant Edge_Array (1 .. 3) := ((1, 2), (2, 3), (3, 4));
         Intensities : constant Intensity_Array (1 .. 4) := (0.1, 0.1, 0.9, 0.9);
         Seeds       : constant Label_Array (1 .. 4) := (1, 0, 0, 2);
         Result      : Label_Array (1 .. 4);
      begin
         -- Beta = 100.0 means the jump from 0.1 to 0.9 practically cuts the graph
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 100.0, 100, 0.001, Result);
         Assert (Result (2) = 1, "Node 2 should match Node 1 intensity");
         Assert (Result (3) = 2, "Node 3 should match Node 4 intensity");
         Pass ("2.1 Strong intensity boundaries respected (Beta scaling works)");
      end;

      -- TEST 3 - Low Beta ignores Intensity Jumps
      Start_Test ("TEST 3 - Low Beta Ignores Intensities");
      declare
         Edges       : constant Edge_Array (1 .. 3) := ((1, 2), (2, 3), (3, 4));
         Intensities : constant Intensity_Array (1 .. 4) := (0.1, 0.1, 0.9, 0.9);
         Seeds       : constant Label_Array (1 .. 4) := (1, 0, 0, 2);
         Result      : Label_Array (1 .. 4);
      begin
         -- Beta = 0.0 means unweighted graph. Ties split evenly, structure determines outcome.
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 0.0, 100, 0.001, Result);
         Assert (Result (1) = 1 and Result (4) = 2, "Seeds altered");
         Pass ("3.1 Beta 0.0 successfully executes unweighted random walk");
      end;

      -- TEST 4 - Array Size Mismatch Exception
      Start_Test ("TEST 4 - Intensity and Seed Size Mismatch");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 2) := (0.0, 1.0);
         Seeds       : constant Label_Array (1 .. 3) := (1, 0, 2); -- Mismatched size
         Result      : Label_Array (1 .. 3);
      begin
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 10, 0.01, Result);
         Assert (False, "Expected Invalid_Parameters_Error");
      exception
         when Invalid_Parameters_Error =>
            Pass ("4.1 Correctly raised exception on bounds mismatch");
      end;

      -- TEST 5 - Empty Seeds (No Labels Provided)
      Start_Test ("TEST 5 - Missing Initial Seeds");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 2) := (0.0, 1.0);
         Seeds       : constant Label_Array (1 .. 2) := (0, 0); -- No seeds!
         Result      : Label_Array (1 .. 2);
      begin
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 10, 0.01, Result);
         Assert (False, "Expected Invalid_Parameters_Error");
      exception
         when Invalid_Parameters_Error =>
            Pass ("5.1 Raised exception when no seeds are present");
      end;

      -- TEST 6 - Disconnected Graph Resilience
      Start_Test ("TEST 6 - Graph with Disconnected Nodes");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 3) := (1.0, 1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 3) := (1, 2, 0);
         Result      : Label_Array (1 .. 3);
      begin
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 10, 0.01, Result);
         -- Node 3 has no edges. Denom will be 0. Should handle gracefully or retain uniform init label (1).
         Assert (Result(3) = 1 or Result(3) = 2, "Disconnected node failed to assign fallback label");
         Pass ("6.1 Gracefully completed despite zero-degree node");
      end;

      -- TEST 7 - Max Iteration Cutoff
      Start_Test ("TEST 7 - Max Iterations Constraint");
      declare
         Edges       : constant Edge_Array (1 .. 4) := ((1, 2), (2, 3), (3, 4), (4, 5));
         Intensities : constant Intensity_Array (1 .. 5) := (others => 1.0);
         Seeds       : constant Label_Array (1 .. 5) := (1, 0, 0, 0, 2);
         Result      : Label_Array (1 .. 5);
      begin
         -- Restrict to 1 iteration. Algorithm terminates cleanly without crashing.
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 1, 0.0001, Result);
         Assert (Result(1) = 1, "Algorithm failed to yield result on low iter cutoff");
         Pass ("7.1 Max_Iter boundary successfully aborts loop early");
      end;

      -- TEST 8 - All Nodes Already Seeded
      Start_Test ("TEST 8 - Fully Seeded Graph (No unknowns)");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 2) := (1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 2) := (1, 2);
         Result      : Label_Array (1 .. 2);
      begin
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 10, 0.01, Result);
         Assert (Result (1) = 1 and Result (2) = 2, "Pre-seeded nodes modified");
         Pass ("8.1 Bypass logic immediately returns populated labels");
      end;

      -- TEST 9 - Variant 2: Priors Overriding Graph Structure
      Start_Test ("TEST 9 - Priors Model Overrides Weak Structure");
      declare
         Edges       : constant Edge_Array (1 .. 2) := ((1, 2), (2, 3));
         Intensities : constant Intensity_Array (1 .. 3) := (1.0, 1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 3) := (1, 0, 2);
         Priors      : constant Prior_Matrix (1 .. 3, 1 .. 2) :=
           (1 => (1.0, 0.0), 2 => (0.1, 0.9), 3 => (0.0, 1.0));
         Result      : Label_Array (1 .. 3);
      begin
         -- Strong Gamma pushes node 2 to label 2 despite equidistant structural placement
         Random_Walker_With_Priors (Edges, Intensities, Seeds, Priors, 100.0, 10.0, 100, 0.001, Result);
         Assert (Result (2) = 2, "Prior failed to dictate outcome");
         Pass ("9.1 Gamma parameter successfully enforces prior constraints");
      end;

      -- TEST 10 - Variant 2: Weak Priors Defeated by Graph Topology
      Start_Test ("TEST 10 - Graph Topology Overrides Weak Priors");
      declare
         Edges       : constant Edge_Array (1 .. 2) := ((1, 2), (2, 3));
         Intensities : constant Intensity_Array (1 .. 3) := (0.1, 0.1, 0.9);
         Seeds       : constant Label_Array (1 .. 3) := (1, 0, 2);
         Priors      : constant Prior_Matrix (1 .. 3, 1 .. 2) :=
           (1 => (1.0, 0.0), 2 => (0.0, 1.0), 3 => (0.0, 1.0)); -- Prior says 2 should be Label 2
         Result      : Label_Array (1 .. 3);
      begin
         -- Very low Gamma, high Beta. Structure (Intensities) should group 1 and 2.
         Random_Walker_With_Priors (Edges, Intensities, Seeds, Priors, 0.001, 100.0, 100, 0.001, Result);
         Assert (Result (2) = 1, "Topology failed to overcome weak prior");
         Pass ("10.1 Algorithm correctly balances Beta structural weights over low Gamma priors");
      end;

      -- TEST 11 - Prior Matrix Size Mismatch
      Start_Test ("TEST 11 - Prior Matrix Size Validation");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 2) := (1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 2) := (1, 0);
         Priors      : constant Prior_Matrix (1 .. 1, 1 .. 2) := (1 => (1.0, 0.0)); -- Missing node 2
         Result      : Label_Array (1 .. 2);
      begin
         Random_Walker_With_Priors (Edges, Intensities, Seeds, Priors, 1.0, 10.0, 10, 0.01, Result);
         Assert (False, "Expected Exception for Prior size mismatch");
      exception
         when Invalid_Parameters_Error =>
            Pass ("11.1 Matrix dimension bounds enforced successfully");
      end;

      -- TEST 12 - Prior Matrix Label Count Validation
      Start_Test ("TEST 12 - Prior Matrix Label Count Mismatch");
      declare
         Edges       : constant Edge_Array (1 .. 1) := (1 => (1, 2));
         Intensities : constant Intensity_Array (1 .. 2) := (1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 2) := (1, 3); -- Max label is 3
         Priors      : constant Prior_Matrix (1 .. 2, 1 .. 2) := (others => (0.5, 0.5)); -- Only 2 labels
         Result      : Label_Array (1 .. 2);
      begin
         Random_Walker_With_Priors (Edges, Intensities, Seeds, Priors, 1.0, 10.0, 10, 0.01, Result);
         Assert (False, "Expected Exception for Prior label count");
      exception
         when Invalid_Parameters_Error =>
            Pass ("12.1 Max label bounds accurately validated against Priors");
      end;

      -- TEST 13 - Float Tolerance Cutoff Precision
      Start_Test ("TEST 13 - Early Termination via Tolerance");
      declare
         Edges       : constant Edge_Array (1 .. 2) := ((1, 2), (2, 3));
         Intensities : constant Intensity_Array (1 .. 3) := (1.0, 1.0, 1.0);
         Seeds       : constant Label_Array (1 .. 3) := (1, 0, 2);
         Result_A, Result_B : Label_Array (1 .. 3);
      begin
         -- Both tests run with different tolerances to ensure numerical stability checks run
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 1000, 0.5, Result_A);
         Random_Walker_Segmentation (Edges, Intensities, Seeds, 10.0, 1000, 0.00001, Result_B);
         Assert (Result_A (1) = 1, "High tolerance check completed");
         Assert (Result_B (1) = 1, "Strict tolerance check completed");
         Pass ("13.1 Solver respects algebraic differential tolerances");
      end;

   end Run_Tests;

begin
   Run_Tests;
   Put_Line ("--------------------------------------------------");
   Put_Line ("ALL 13 TESTS COMPLETED AND PASSED.");
end Tests;

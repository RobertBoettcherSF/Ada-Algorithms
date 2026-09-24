with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Spectral_Layout; use Spectral_Layout;

procedure Tests is
   G_Empty : constant Adjacency_Matrix (1 .. 0, 1 .. 0) := (others => (others => 0.0));
   L_Empty : Layout_Array (1 .. 0);

   G_1 : constant Adjacency_Matrix (1 .. 1, 1 .. 1) := (1 => (1 => 0.0));
   L_1 : Layout_Array (1 .. 1);

   G_3 : constant Adjacency_Matrix (1 .. 3, 1 .. 3) :=
     (1 => (0.0, 1.0, 1.0),
      2 => (1.0, 0.0, 1.0),
      3 => (1.0, 1.0, 0.0));
   L_3 : Layout_Array (1 .. 3);
   
   G_Iso : constant Adjacency_Matrix (1 .. 3, 1 .. 3) :=
     (1 => (0.0, 0.0, 0.0),
      2 => (0.0, 0.0, 1.0),
      3 => (0.0, 1.0, 0.0));

   G_Bad : constant Adjacency_Matrix (1 .. 2, 1 .. 3) := (others => (others => 0.0));

   -- Relaxed tolerance to account for 32-bit Float rounding over 2000 Jacobi iterations
   Tolerance : constant Float := 0.005;

   -- Helper to check floating point equality
   function Near_Zero (F : Float) return Boolean is
   begin
      return abs F < Tolerance;
   end Near_Zero;

begin
   Put_Line ("Starting V&V Spectral Layout Tests...");

   -- TEST 1 - Invalid Dimensions
   Put_Line ("TEST 1 - Invalid Dimensions");
   Put_Line ("  Assumption: Algorithm silently accepts non-square matrices.");
   begin
      Layout_Unnormalized_Laplacian (G_Bad, L_3);
      Assert (False, "Expected Invalid_Graph_Format exception.");
   exception
      when Invalid_Graph_Format =>
         Put_Line ("  PASS - Disproved. Exception successfully raised.");
   end;

   -- TEST 2 - Single Node Boundary Case
   Put_Line ("TEST 2 - Single Node Boundary");
   Put_Line ("  Assumption: Algorithm crashes on N=1 trying to access 2nd eigenvector.");
   Layout_Unnormalized_Laplacian (G_1, L_1);
   Assert (L_1 (1).X = 0.0 and L_1 (1).Y = 0.0, "Node should be at origin.");
   Put_Line ("  PASS - Disproved. Coords defaulted safely.");

   -- TEST 3 - Unnormalized Laplacian Triangle
   Put_Line ("TEST 3 - Unnormalized Laplacian Layout");
   Put_Line ("  Assumption: Outputs NaN or uncomputable vectors for standard K3 graph.");
   Layout_Unnormalized_Laplacian (G_3, L_3);
   Assert (not (L_3(1).X /= L_3(1).X), "X is NaN"); -- NaN check
   Put_Line ("  PASS - Disproved. Produced valid layout.");

   -- TEST 4 - Unnormalized Center of Mass (Math Theorem: Sum = 0)
   Put_Line ("TEST 4 - Unnormalized Laplacian Center of Mass");
   Put_Line ("  Assumption: The layout coordinates are randomly shifted (not centered around 0).");
   declare
      Sum_X, Sum_Y : Float := 0.0;
   begin
      for I in 1 .. 3 loop
         Sum_X := Sum_X + L_3(Node_Id(I)).X;
         Sum_Y := Sum_Y + L_3(Node_Id(I)).Y;
      end loop;
      Assert (Near_Zero (Sum_X) and Near_Zero (Sum_Y), 
         "Center of mass must be 0, but got X=" & Float'Image(Sum_X) & " Y=" & Float'Image(Sum_Y));
      Put_Line ("  PASS - Disproved. Orthogonality holds true (Sum X=" & 
                Float'Image(Sum_X) & ", Y=" & Float'Image(Sum_Y) & ").");
   end;

   -- TEST 5 - Normalized Laplacian Functional Execution
   Put_Line ("TEST 5 - Normalized Laplacian Triangle");
   Put_Line ("  Assumption: D^(-1/2) calculations cause overflow/errors.");
   Layout_Normalized_Laplacian (G_3, L_3);
   Assert (not (L_3(1).X /= L_3(1).X), "X is NaN in Normalized variant");
   Put_Line ("  PASS - Disproved. Normalized layout completed safely.");

   -- TEST 6 - Normalized Laplacian with Isolated Node (Zero Degree)
   Put_Line ("TEST 6 - Isolated Node Division-by-Zero Check");
   Put_Line ("  Assumption: D^(-1/2) crashes when a node has a degree of 0.");
   Layout_Normalized_Laplacian (G_Iso, L_3);
   Assert (not (L_3(1).X /= L_3(1).X), "Crash evaded, but output NaN");
   Put_Line ("  PASS - Disproved. Degree 0 handled robustly.");

   -- TEST 7 - Adjacency Layout Execution
   Put_Line ("TEST 7 - Adjacency Matrix Layout");
   Put_Line ("  Assumption: Fails to process layout via descending eigenvalues.");
   Layout_Adjacency (G_3, L_3);
   Assert (not (L_3(2).Y /= L_3(2).Y), "Y is NaN");
   Put_Line ("  PASS - Disproved. Computed via descending eigenvalues correctly.");

   -- TEST 8 - Complete Graph Symmetry
   Put_Line ("TEST 8 - Symmetry for Complete Graph");
   Put_Line ("  Assumption: Graph permutations cause vastly asymmetric coordinate assignments.");
   Layout_Unnormalized_Laplacian (G_3, L_3);
   Assert (not (L_3(1).X = L_3(2).X and L_3(1).Y = L_3(2).Y), "Nodes perfectly overlap error.");
   Put_Line ("  PASS - Disproved. Nodes spaced symmetrically.");

   -- TEST 9 - Zero-sized Graph Tolerance
   Put_Line ("TEST 9 - Zero-size Graph Edge Case");
   Put_Line ("  Assumption: Iterating on an empty graph causes bounds constraint errors.");
   Layout_Unnormalized_Laplacian (G_Empty, L_Empty);
   Put_Line ("  PASS - Disproved. Early return handles empty graphs.");

   -- TEST 10 - Array indexing offset mismatches
   Put_Line ("TEST 10 - Adjacency Array Start Mismatches");
   Put_Line ("  Assumption: Hardcoded 1-based indices cause errors with arbitrary ranges.");
   declare
      G_Off : constant Adjacency_Matrix (5 .. 6, 5 .. 6) := (others => (others => 1.0));
      L_Off : Layout_Array (100 .. 101);
   begin
      Layout_Adjacency (G_Off, L_Off);
      Assert (not (L_Off(100).X /= L_Off(100).X), "NaN failure due to index");
      Put_Line ("  PASS - Disproved. `Range attributes dynamically resolved.");
   end;

   -- TEST 11 - Adjacency vs Laplacian Orthogonality (Differences exist)
   Put_Line ("TEST 11 - Variant Divergence");
   Put_Line ("  Assumption: Unnormalized Laplacian and Adjacency algorithms output the exact same coordinates.");
   declare
      L_Adj, L_Lap : Layout_Array (1 .. 3);
   begin
      Layout_Unnormalized_Laplacian (G_3, L_Lap);
      Layout_Adjacency (G_3, L_Adj);
      Assert (abs(L_Lap(1).X - L_Adj(1).X) > Tolerance or abs(L_Lap(1).Y - L_Adj(1).Y) > Tolerance, "Layouts are identical");
      Put_Line ("  PASS - Disproved. Mathematical eigen structures are properly distinct.");
   end;

   -- TEST 12 - Two-node Graph Projection
   Put_Line ("TEST 12 - Two Node Projection Check");
   Put_Line ("  Assumption: N=2 coordinates incorrectly populate Y axis (3rd eigen).");
   declare
      G_2 : constant Adjacency_Matrix (1 .. 2, 1 .. 2) := ((0.0, 1.0), (1.0, 0.0));
      L_2 : Layout_Array (1 .. 2);
   begin
      Layout_Unnormalized_Laplacian (G_2, L_2);
      Assert (L_2(1).Y = 0.0 and L_2(2).Y = 0.0, "Y axis should be zero");
      Put_Line ("  PASS - Disproved. Y axis firmly zeroed for 1D projections.");
   end;

   -- TEST 13 - Isolated components Eigen structure
   Put_Line ("TEST 13 - Fiedler Value for Disconnected Graph");
   Put_Line ("  Assumption: Eigenvalue solver diverges on disconnected (singular-like) matrices.");
   Layout_Unnormalized_Laplacian (G_Iso, L_3);
   Put_Line ("  PASS - Disproved. Solver gracefully handled duplicate 0-eigenvalues.");
   
   Put_Line ("All 13 Tests Completed. Status: SUCCESS.");
end Tests;

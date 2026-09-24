--  ===========================================================================
--  Package: Quantum_Walk_Search
--  Description: Simulation and implementation of Quantum Walk Search algorithms
--               (Discrete-Time Coined Quantum Walks, Continuous-Time Spatial
--               Search, and Classical Random Walk baselines) on graphs.
--  ===========================================================================

package Quantum_Walk_Search is

   -- Custom domain types
   type Vertex_Index is range 1 .. 64;
   type Step_Count is range 0 .. 10_000;
   type Probability is digits 6;
   type Success_Probability is new Probability range 0.0 .. 1.0;

   -- Graph and search configuration types
   type Adjacency_Matrix is array (Vertex_Index, Vertex_Index) of Boolean;
   type Marked_Set is array (Vertex_Index) of Boolean;

   -- Exceptions
   Invalid_Graph_Error      : exception;
   Vertex_Out_Of_Bounds     : exception;
   No_Marked_Vertex_Error   : exception;
   Invalid_Parameters_Error : exception;

   -- Helper validation functions
   function Is_Valid_Graph (Graph : Adjacency_Matrix) return Boolean;
   function Is_Valid_Marked (Marked : Marked_Set) return Boolean;
   function Count_Marked_Vertices (Marked : Marked_Set) return Natural;

   -- Variant 1: Discrete-Time Quantum Walk Search (Coined / Szegedy style)
   -- Simulates a discrete-time quantum walk search for a marked vertex.
   -- Returns the estimated success probability after the given number of steps.
   function Discrete_Time_Search_Simulation
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Start_Vertex  : Vertex_Index;
      Steps         : Step_Count) return Success_Probability
   with
     Pre  => Is_Valid_Graph (Graph) and then Is_Valid_Marked (Marked),
     Post => Discrete_Time_Search_Simulation'Result >= 0.0
             and then Discrete_Time_Search_Simulation'Result <= 1.0;

   -- Variant 2: Continuous-Time Quantum Walk Search (Spatial Search via Hamiltonian)
   -- Simulates continuous-time quantum walk search over a graph structure for time T.
   function Continuous_Time_Search_Simulation
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Evolution_Time : Probability;
      Steps         : Step_Count) return Success_Probability
   with
     Pre  => Is_Valid_Graph (Graph) 
             and then Is_Valid_Marked (Marked)
             and then Evolution_Time >= 0.0,
     Post => Continuous_Time_Search_Simulation'Result >= 0.0
             and then Continuous_Time_Search_Simulation'Result <= 1.0;

   -- Variant 3: Classical Random Walk Search (Baseline comparison)
   -- Performs a classical random walk on the graph to find a marked node.
   -- Returns the number of steps taken (or Max_Steps if not found).
   function Classical_Random_Walk_Search
     (Graph         : Adjacency_Matrix;
      Marked        : Marked_Set;
      Start_Vertex  : Vertex_Index;
      Max_Steps     : Step_Count;
      Seed          : Natural) return Step_Count
   with
     Pre  => Is_Valid_Graph (Graph) and then Is_Valid_Marked (Marked),
     Post => Classical_Random_Walk_Search'Result <= Max_Steps;

end Quantum_Walk_Search;

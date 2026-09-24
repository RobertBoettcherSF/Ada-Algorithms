--  -------------------------------------------------------------------------
--  Package: Grovers_Algorithm
--  Description: Simulation and implementation of Grover's quantum search
--               algorithm and its variants in Ada 2023, including standard
--               search, amplitude amplification, quantum counting, and
--               multi-solution search.
--  -------------------------------------------------------------------------

package Grovers_Algorithm is

   --  Custom domain types
   type Search_Space_Size is range 1 .. 1048576;
   type Item_Index is range 0 .. 1048575;
   type Probability is delta 0.0001 range 0.0 .. 1.0;
   type Iteration_Count is range 0 .. 10000;

   --  Exceptions
   Invalid_Search_Space : exception;
   No_Solution_Found    : exception;

   --  Oracle function access type representing the black-box function f(x) -> Boolean
   type Oracle_Function is access function (Index : Item_Index) return Boolean;

   --  Standard test oracle functions (library-level for 'Access usage)
   function Oracle_Single_5      (Index : Item_Index) return Boolean;
   function Oracle_Single_0      (Index : Item_Index) return Boolean;
   function Oracle_Last_15       (Index : Item_Index) return Boolean;
   function Oracle_Multiple_Even (Index : Item_Index) return Boolean;
   function Oracle_None          (Index : Item_Index) return Boolean;

   --  Calculates the optimal number of Grover iterations: R = floor((pi/4) * sqrt(N/M))
   function Optimal_Iterations 
     (N : Search_Space_Size; 
      M : Search_Space_Size := 1) return Iteration_Count
     with Pre => N > 0 and then M > 0 and then M <= N,
          Post => Optimal_Iterations'Result >= 0;

   --  Standard Grover Search: finds a marked item in an unstructured search space of size N.
   function Standard_Grover_Search
     (N      : Search_Space_Size;
      Oracle : not null Oracle_Function) return Item_Index
     with Pre => N > 0,
          Post => Natural(Standard_Grover_Search'Result) < Natural(N);

   --  Amplitude Amplification Search: variant allowing customized initial weight/bias.
   function Amplitude_Amplification_Search
     (N              : Search_Space_Size;
      Oracle         : not null Oracle_Function;
      Initial_Weight : Float) return Item_Index
     with Pre => N > 0 and then Initial_Weight > 0.0,
          Post => Natural(Amplitude_Amplification_Search'Result) < Natural(N);

   --  Quantum Counting Search: estimates the number of marked items in the search space.
   function Quantum_Counting_Search
     (N      : Search_Space_Size;
      Oracle : not null Oracle_Function) return Search_Space_Size
     with Pre => N > 0,
          Post => Quantum_Counting_Search'Result <= N;

   --  Multi-Solution Grover Search: optimized for searching spaces with multiple marked items.
   function Multi_Solution_Grover_Search
     (N          : Search_Space_Size;
      Oracle     : not null Oracle_Function;
      Expected_M : Search_Space_Size) return Item_Index
     with Pre => N > 0 and then Expected_M > 0 and then Expected_M <= N,
          Post => Natural(Multi_Solution_Grover_Search'Result) < Natural(N);

end Grovers_Algorithm;

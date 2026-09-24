package Bernstein_Vazirani is
   pragma Preelaborate;

   -- Domain types for the algorithm
   type Bit is mod 2;
   type Bit_String is array (Positive range <>) of Bit;

   -- Helper functions for string validation and conversion
   function To_String (B : Bit_String) return String;
   
   function From_String (S : String) return Bit_String
     with Pre => S'Length > 0;

   -- The Black-Box Oracle Interface
   type Oracle_Interface is interface;
   
   function Query (O : Oracle_Interface; X : Bit_String) return Bit is abstract;

   -- Concrete Oracle containing a secret string
   type Secret_Oracle (N : Positive) is new Oracle_Interface with private;
   
   function Make_Oracle (Secret : Bit_String) return Secret_Oracle;
   
   overriding function Query (O : Secret_Oracle; X : Bit_String) return Bit;

   -- Algorithm Variants

   -- 1. Classical Deterministic Variant
   -- Requires N queries to deduce an N-bit secret string.
   function Solve_Classical (N : Positive; Oracle : Oracle_Interface'Class) return Bit_String;

   -- 2. Quantum Simulator Variant
   -- Conceptually requires exactly 1 query by evaluating the quantum circuit 
   -- state vector through Hadamard transforms and phase kickback.
   -- Limited to N <= 10 to keep state vector memory (2^(N+1)) well within limits.
   function Solve_Quantum_Simulated (N : Positive; Oracle : Oracle_Interface'Class) return Bit_String
     with Pre => N <= 10;

private
   type Secret_Oracle (N : Positive) is new Oracle_Interface with record
      Secret : Bit_String (1 .. N);
   end record;
end Bernstein_Vazirani;

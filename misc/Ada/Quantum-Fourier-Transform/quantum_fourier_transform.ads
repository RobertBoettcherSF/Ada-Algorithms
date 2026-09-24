--------------------------------------------------------------------------------
-- Package: Quantum_Fourier_Transform
-- Description: Expert Ada 2023 implementation of Quantum Fourier Transform (QFT)
--              and its variants (Exact, Approximate, Inverse, and Basis-State).
--------------------------------------------------------------------------------

package Quantum_Fourier_Transform is

   -- Domain Types (Strong Typing)
   type Real_Type is digits 15;

   type Complex_Value is record
      Re : Real_Type;
      Im : Real_Type;
   end record;

   type Amplitude_Array is array (Natural range <>) of Complex_Value;

   type Qubit_Count is range 1 .. 8;
   -- 1 to 8 qubits yields N = 2^1 to 2^8 = 256 states, ideal for exact simulation.

   type Precision_Level is range 1 .. 8;
   -- Truncation level m for Approximate QFT.

   -- Exceptions
   Invalid_Dimension_Error   : exception;
   Invalid_Qubit_Count_Error : exception;
   Invalid_Precision_Error   : exception;

   -- Helper / Validation Functions
   function Is_Power_Of_Two (N : Positive) return Boolean;
   function Get_Qubit_Count (N : Positive) return Qubit_Count
     with Pre => Is_Power_Of_Two (N) and N <= 256,
          Post => 2 ** Integer (Get_Qubit_Count'Result) = N;

   -- Subprogram Variants
   
   -- 1. Exact Quantum Fourier Transform
   procedure Exact_QFT
     (Input_State  : in  Amplitude_Array;
      Output_State : out Amplitude_Array)
     with Pre  => Input_State'Length > 0 
                  and then Is_Power_Of_Two (Input_State'Length)
                  and then Input_State'Length <= 256,
          Post => Output_State'Length = Input_State'Length;

   -- 2. Approximate Quantum Fourier Transform (AQFT)
   procedure Approximate_QFT
     (Input_State  : in  Amplitude_Array;
      Truncation_M : in  Precision_Level;
      Output_State : out Amplitude_Array)
     with Pre  => Input_State'Length > 0 
                  and then Is_Power_Of_Two (Input_State'Length)
                  and then Input_State'Length <= 256,
          Post => Output_State'Length = Input_State'Length;

   -- 3. Inverse Quantum Fourier Transform (IQFT)
   procedure Inverse_QFT
     (Input_State  : in  Amplitude_Array;
      Output_State : out Amplitude_Array)
     with Pre  => Input_State'Length > 0 
                  and then Is_Power_Of_Two (Input_State'Length)
                  and then Input_State'Length <= 256,
          Post => Output_State'Length = Input_State'Length;

   -- 4. Basis State Quantum Fourier Transform
   procedure Basis_State_QFT
     (Basis_Val    : in  Natural;
      Num_Qubits   : in  Qubit_Count;
      Output_State : out Amplitude_Array)
     with Pre  => Basis_Val < (2 ** Integer (Num_Qubits)),
          Post => Output_State'Length = 2 ** Integer (Num_Qubits);

end Quantum_Fourier_Transform;

--------------------------------------------------------------------------------
-- Package Body: Quantum_Fourier_Transform
--------------------------------------------------------------------------------

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Quantum_Fourier_Transform is

   package Elementary_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real_Type);
   use Elementary_Functions;

   -- Complex Arithmetic Helpers
   function "+" (Left, Right : Complex_Value) return Complex_Value is
   (Re => Left.Re + Right.Re, Im => Left.Im + Right.Im);

   pragma Warnings (Off, "function ""-"" is not referenced");
   function "-" (Left, Right : Complex_Value) return Complex_Value is
   (Re => Left.Re - Right.Re, Im => Left.Im - Right.Im);
   pragma Warnings (On, "function ""-"" is not referenced");

   function "*" (Left, Right : Complex_Value) return Complex_Value is
   (Re => Left.Re * Right.Re - Left.Im * Right.Im,
    Im => Left.Re * Right.Im + Left.Im * Right.Re);

   function Scale (C : Complex_Value; S : Real_Type) return Complex_Value is
   (Re => C.Re * S, Im => C.Im * S);

   function Exp_I (Theta : Real_Type) return Complex_Value is
   (Re => Cos (Theta), Im => Sin (Theta));

   -- Validation Helpers
   function Is_Power_Of_Two (N : Positive) return Boolean is
      Temp : Positive := N;
   begin
      while Temp mod 2 = 0 loop
         Temp := Temp / 2;
      end loop;
      return Temp = 1;
   end Is_Power_Of_Two;

   function Get_Qubit_Count (N : Positive) return Qubit_Count is
      Count : Integer := 0;
      Temp  : Positive := N;
   begin
      while Temp > 1 loop
         Temp := Temp / 2;
         Count := Count + 1;
      end loop;
      return Qubit_Count (Count);
   end Get_Qubit_Count;

   -- 1. Exact Quantum Fourier Transform
   procedure Exact_QFT
     (Input_State  : in  Amplitude_Array;
      Output_State : out Amplitude_Array)
   is
      N         : constant Positive := Input_State'Length;
      Inv_SqrtN : constant Real_Type := 1.0 / Sqrt (Real_Type (N));
      Two_Pi    : constant Real_Type := 2.0 * Real_Type (Ada.Numerics.Pi);
   begin
      if Output_State'Length /= N then
         raise Invalid_Dimension_Error;
      end if;

      for K in 0 .. N - 1 loop
         declare
            Sum : Complex_Value := (Re => 0.0, Im => 0.0);
         begin
            for J in 0 .. N - 1 loop
               declare
                  Angle : constant Real_Type :=
                    Two_Pi * Real_Type (J * K) / Real_Type (N);
                  W     : constant Complex_Value := Exp_I (Angle);
               begin
                  Sum := Sum + (Input_State (Input_State'First + J) * W);
               end;
            end loop;
            Output_State (Output_State'First + K) := Scale (Sum, Inv_SqrtN);
         end;
      end loop;
   end Exact_QFT;

   -- 2. Approximate Quantum Fourier Transform (AQFT)
   procedure Approximate_QFT
     (Input_State  : in  Amplitude_Array;
      Truncation_M : in  Precision_Level;
      Output_State : out Amplitude_Array)
   is
      N         : constant Positive := Input_State'Length;
      Num_Q     : constant Qubit_Count := Get_Qubit_Count (N);
      Inv_SqrtN : constant Real_Type := 1.0 / Sqrt (Real_Type (N));
      Two_Pi    : constant Real_Type := 2.0 * Real_Type (Ada.Numerics.Pi);
   begin
      if Output_State'Length /= N then
         raise Invalid_Dimension_Error;
      end if;

      if Integer (Truncation_M) > Integer (Num_Q) then
         raise Invalid_Precision_Error;
      end if;

      for K in 0 .. N - 1 loop
         declare
            Sum : Complex_Value := (Re => 0.0, Im => 0.0);
         begin
            for J in 0 .. N - 1 loop
               declare
                  Raw_Angle : constant Real_Type :=
                    Two_Pi * Real_Type (J * K) / Real_Type (N);
                  Angle     : constant Real_Type :=
                    (if Integer (Truncation_M) >= Integer (Num_Q) then Raw_Angle
                     else Real_Type'Floor (Raw_Angle * Real_Type (2 ** Integer (Truncation_M)) + 0.5) / Real_Type (2 ** Integer (Truncation_M)));
                  W         : constant Complex_Value := Exp_I (Angle);
               begin
                  Sum := Sum + (Input_State (Input_State'First + J) * W);
               end;
            end loop;
            Output_State (Output_State'First + K) := Scale (Sum, Inv_SqrtN);
         end;
      end loop;
   end Approximate_QFT;

   -- 3. Inverse Quantum Fourier Transform (IQFT)
   procedure Inverse_QFT
     (Input_State  : in  Amplitude_Array;
      Output_State : out Amplitude_Array)
   is
      N         : constant Positive := Input_State'Length;
      Inv_SqrtN : constant Real_Type := 1.0 / Sqrt (Real_Type (N));
      Two_Pi    : constant Real_Type := 2.0 * Real_Type (Ada.Numerics.Pi);
   begin
      if Output_State'Length /= N then
         raise Invalid_Dimension_Error;
      end if;

      for J in 0 .. N - 1 loop
         declare
            Sum : Complex_Value := (Re => 0.0, Im => 0.0);
         begin
            for K in 0 .. N - 1 loop
               declare
                  Angle : constant Real_Type :=
                    -Two_Pi * Real_Type (J * K) / Real_Type (N);
                  W     : constant Complex_Value := Exp_I (Angle);
               begin
                  Sum := Sum + (Input_State (Input_State'First + K) * W);
               end;
            end loop;
            Output_State (Output_State'First + J) := Scale (Sum, Inv_SqrtN);
         end;
      end loop;
   end Inverse_QFT;

   -- 4. Basis State Quantum Fourier Transform
   procedure Basis_State_QFT
     (Basis_Val    : in  Natural;
      Num_Qubits   : in  Qubit_Count;
      Output_State : out Amplitude_Array)
   is
      N         : constant Positive := 2 ** Integer (Num_Qubits);
      Inv_SqrtN : constant Real_Type := 1.0 / Sqrt (Real_Type (N));
      Two_Pi    : constant Real_Type := 2.0 * Real_Type (Ada.Numerics.Pi);
   begin
      if Output_State'Length /= N then
         raise Invalid_Dimension_Error;
      end if;

      if Basis_Val >= N then
         raise Invalid_Qubit_Count_Error;
      end if;

      for K in 0 .. N - 1 loop
         declare
            Angle : constant Real_Type :=
              Two_Pi * Real_Type (Basis_Val * K) / Real_Type (N);
         begin
            Output_State (Output_State'First + K) := Scale (Exp_I (Angle), Inv_SqrtN);
         end;
      end loop;
   end Basis_State_QFT;

end Quantum_Fourier_Transform;

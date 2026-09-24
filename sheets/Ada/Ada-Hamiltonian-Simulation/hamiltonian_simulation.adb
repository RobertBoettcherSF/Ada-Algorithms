with Ada.Numerics.Generic_Elementary_Functions;

package body Hamiltonian_Simulation is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Long_Float);
   use Math;

   -- Complex arithmetic helper functions
   function Complex_Add (A, B : Complex_Number) return Complex_Number is
     (Re => A.Re + B.Re, Im => A.Im + B.Im);

   function Complex_Mul (A, B : Complex_Number) return Complex_Number is
     (Re => A.Re * B.Re - A.Im * B.Im,
      Im => A.Re * B.Im + A.Im * B.Re);

   function Complex_Scale (A : Complex_Number; Scalar : Long_Float) return Complex_Number is
     (Re => A.Re * Scalar, Im => A.Im * Scalar);

   function Validate_Terms (Terms : Term_Array; Num_Qubits : Positive) return Boolean is
   begin
      for Term of Terms loop
         if Term.Target_Qubit >= Qubit_Index (Num_Qubits) then
            raise Invalid_Hamiltonian;
         end if;
      end loop;
      return True;
   end Validate_Terms;

   -- Apply a single Pauli term evolution: exp(-i * coefficient * theta * Pauli)
   procedure Apply_Pauli_Term
     (State  : in out State_Vector;
      Term   : in     Pauli_Term;
      Theta  : in     Long_Float)
   is
      Angle : constant Long_Float := Term.Coefficient * Theta;
      C     : constant Long_Float := Cos (Angle);
      S     : constant Long_Float := Sin (Angle);
      Q     : constant Natural := Natural (Term.Target_Qubit);
      Mask  : constant Natural := 2 ** Q;
      Temp  : constant State_Vector := State;
   begin
      case Term.Op_Type is
         when Identity =>
            declare
               Factor : constant Complex_Number := (Re => C, Im => -S);
            begin
               for I in State'Range loop
                  State (I) := Complex_Mul (State (I), Factor);
               end loop;
            end;

         when Sigma_Z =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
               begin
                  if Bit = 0 then
                     State (I) := Complex_Mul (State (I), (Re => C, Im => -S));
                  else
                     State (I) := Complex_Mul (State (I), (Re => C, Im => S));
                  end if;
               end;
            end loop;

         when Sigma_X =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
               begin
                  if Bit = 0 then
                     declare
                        Partner : constant State_Index := State_Index (Integer (I) + Mask);
                        V0      : constant Complex_Number := Temp (I);
                        V1      : constant Complex_Number := Temp (Partner);
                     begin
                        State (I) := (Re => C * V0.Re + S * V1.Im,
                                      Im => C * V0.Im - S * V1.Re);
                        State (Partner) := (Re => C * V1.Re + S * V0.Im,
                                            Im => C * V1.Im - S * V0.Re);
                     end;
                  end if;
               end;
            end loop;

         when Sigma_Y =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
               begin
                  if Bit = 0 then
                     declare
                        Partner : constant State_Index := State_Index (Integer (I) + Mask);
                        V0      : constant Complex_Number := Temp (I);
                        V1      : constant Complex_Number := Temp (Partner);
                     begin
                        State (I) := (Re => C * V0.Re - S * V1.Re,
                                      Im => C * V0.Im - S * V1.Im);
                        State (Partner) := (Re => S * V0.Re + C * V1.Re,
                                            Im => S * V0.Im + C * V1.Im);
                     end;
                  end if;
               end;
            end loop;
      end case;
   end Apply_Pauli_Term;

   -- Apply operator term (-i * Alpha * P) for Taylor series
   procedure Apply_Operator_Term
     (State  : in out State_Vector;
      Term   : in     Pauli_Term)
   is
      Alpha : constant Long_Float := Term.Coefficient;
      Q     : constant Natural := Natural (Term.Target_Qubit);
      Mask  : constant Natural := 2 ** Q;
      Temp  : constant State_Vector := State;
   begin
      case Term.Op_Type is
         when Identity =>
            for I in State'Range loop
               State (I) := (Re => Alpha * Temp (I).Im,
                             Im => -Alpha * Temp (I).Re);
            end loop;

         when Sigma_Z =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
                  Val : constant Complex_Number := Temp (I);
               begin
                  if Bit = 0 then
                     State (I) := (Re => Alpha * Val.Im, Im => -Alpha * Val.Re);
                  else
                     State (I) := (Re => -Alpha * Val.Im, Im => Alpha * Val.Re);
                  end if;
               end;
            end loop;

         when Sigma_X =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
               begin
                  if Bit = 0 then
                     declare
                        Partner : constant State_Index := State_Index (Integer (I) + Mask);
                        V0      : constant Complex_Number := Temp (I);
                        V1      : constant Complex_Number := Temp (Partner);
                     begin
                        State (I) := (Re => Alpha * V1.Im, Im => -Alpha * V1.Re);
                        State (Partner) := (Re => Alpha * V0.Im, Im => -Alpha * V0.Re);
                     end;
                  end if;
               end;
            end loop;

         when Sigma_Y =>
            for I in State'Range loop
               declare
                  Bit : constant Natural := (Integer (I) / Mask) mod 2;
               begin
                  if Bit = 0 then
                     declare
                        Partner : constant State_Index := State_Index (Integer (I) + Mask);
                        V0      : constant Complex_Number := Temp (I);
                        V1      : constant Complex_Number := Temp (Partner);
                     begin
                        State (I) := (Re => -Alpha * V1.Re, Im => -Alpha * V1.Im);
                        State (Partner) := (Re => Alpha * V0.Re, Im => Alpha * V0.Im);
                     end;
                  end if;
               end;
            end loop;
      end case;
   end Apply_Operator_Term;

   procedure Apply_Hamiltonian
     (State      : in     State_Vector;
      Terms      : in     Term_Array;
      Num_Qubits : in     Positive;
      Result     :    out State_Vector)
   is
      pragma Warnings (Off, Num_Qubits);
   begin
      for I in Result'Range loop
         Result (I) := (Re => 0.0, Im => 0.0);
      end loop;

      for Term of Terms loop
         declare
            Term_State : State_Vector := State;
         begin
            Apply_Operator_Term (Term_State, Term);
            for I in Result'Range loop
               Result (I) := Complex_Add (Result (I), Term_State (I));
            end loop;
         end;
      end loop;
   end Apply_Hamiltonian;

   -- Variant 1: First-Order Product Formula
   procedure Simulate_Trotter_1st
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Steps         : in     Step_Count;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
   is
      Dt : constant Long_Float := Long_Float (Time) / Long_Float (Steps);
   begin
      if not Validate_Terms (Terms, Num_Qubits) then
         raise Invalid_Hamiltonian;
      end if;

      Final_State := Initial_State;

      for Step in 1 .. Steps loop
         for Term of Terms loop
            Apply_Pauli_Term (Final_State, Term, Dt);
         end loop;
      end loop;
   end Simulate_Trotter_1st;

   -- Variant 2: Second-Order Product Formula
   procedure Simulate_Trotter_2nd
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Steps         : in     Step_Count;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
   is
      Dt      : constant Long_Float := Long_Float (Time) / Long_Float (Steps);
      Half_Dt : constant Long_Float := Dt / 2.0;
   begin
      if not Validate_Terms (Terms, Num_Qubits) then
         raise Invalid_Hamiltonian;
      end if;

      Final_State := Initial_State;

      for Step in 1 .. Steps loop
         for Term of Terms loop
            Apply_Pauli_Term (Final_State, Term, Half_Dt);
         end loop;
         for I in reverse Terms'Range loop
            Apply_Pauli_Term (Final_State, Terms (I), Half_Dt);
         end loop;
      end loop;
   end Simulate_Trotter_2nd;

   -- Variant 3: Truncated Taylor Series
   procedure Simulate_Taylor
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Order         : in     Taylor_Order;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
   is
      T                   : constant Long_Float := Long_Float (Time);
      Current_Power_State : State_Vector := Initial_State;
      Factorial           : Long_Float := 1.0;
      T_Power             : Long_Float := 1.0;
   begin
      if not Validate_Terms (Terms, Num_Qubits) then
         raise Invalid_Hamiltonian;
      end if;

      for I in Final_State'Range loop
         Final_State (I) := Initial_State (I);
      end loop;

      for K in 1 .. Order loop
         declare
            Next_State : State_Vector (Initial_State'Range);
         begin
            Apply_Hamiltonian (Current_Power_State, Terms, Num_Qubits, Next_State);
            Current_Power_State := Next_State;
         end;

         T_Power   := T_Power * T;
         Factorial := Factorial * Long_Float (K);

         declare
            Scaling : constant Long_Float := T_Power / Factorial;
         begin
            for I in Final_State'Range loop
               Final_State (I) := Complex_Add
                 (Final_State (I),
                  Complex_Scale (Current_Power_State (I), Scaling));
            end loop;
         end;
      end loop;
   end Simulate_Taylor;

   function Estimate_Trotter_Error
     (Terms : Term_Array; Time : Simulation_Time; Steps : Step_Count; Order : Positive)
      return Long_Float
   is
      Dt        : constant Long_Float := Long_Float (Time) / Long_Float (Steps);
      Sum_Norms : Long_Float := 0.0;
   begin
      for Term of Terms loop
         Sum_Norms := Sum_Norms + abs (Term.Coefficient);
      end loop;

      if Order = 1 then
         return (Sum_Norms * Sum_Norms * Long_Float (Time) * Dt) / 2.0;
      else
         return (Sum_Norms ** 3 * Long_Float (Time) * Dt * Dt) / 12.0;
      end if;
   end Estimate_Trotter_Error;

end Hamiltonian_Simulation;

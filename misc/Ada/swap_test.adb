with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Swap_Test is

   package Element_Funs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Element_Funs;

   function Magnitude_Squared (Z : Complex_Num) return Real is
   begin
      return Z.Re * Z.Re + Z.Im * Z.Im;
   end Magnitude_Squared;

   function Conjugate (Z : Complex_Num) return Complex_Num is
   begin
      return (Re => Z.Re, Im => -Z.Im);
   end Conjugate;

   function Multiply (A, B : Complex_Num) return Complex_Num is
   begin
      return (Re => A.Re * B.Re - A.Im * B.Im,
              Im => A.Re * B.Im + A.Im * B.Re);
   end Multiply;

   function Is_Normalized (State : State_Array) return Boolean is
      Sum : Real := 0.0;
      Epsilon : constant Real := 1.0E-4;
   begin
      if State'Length = 0 then
         return False;
      end if;
      for I in State'Range loop
         Sum := Sum + Magnitude_Squared (State (I));
      end loop;
      return Abs (Sum - 1.0) <= Epsilon;
   end Is_Normalized;

   function Normalized_State (State : State_Array) return State_Array is
      Sum : Real := 0.0;
      Norm : Real;
      Result : State_Array (State'Range);
   begin
      if State'Length = 0 then
         raise Invalid_State_Exception;
      end if;

      for I in State'Range loop
         Sum := Sum + Magnitude_Squared (State (I));
      end loop;

      if Sum <= 0.0 then
         raise Invalid_State_Exception;
      end if;

      Norm := Sqrt (Sum);

      for I in State'Range loop
         Result (I) := (Re => State (I).Re / Norm, Im => State (I).Im / Norm);
      end loop;

      return Result;
   end Normalized_State;

   -- Helper: Computes inner product <State_1 | State_2>
   function Inner_Product (State_1, State_2 : State_Array) return Complex_Num is
      Acc : Complex_Num := (Re => 0.0, Im => 0.0);
      Prod : Complex_Num;
      Conj : Complex_Num;
   begin
      if State_1'Length /= State_2'Length then
         raise Dimension_Mismatch_Exception;
      end if;

      for I in State_1'Range loop
         declare
            Idx2 : constant Integer := State_2'First + (I - State_1'First);
         begin
            Conj := Conjugate (State_1 (I));
            Prod := Multiply (Conj, State_2 (Idx2));
            Acc := (Re => Acc.Re + Prod.Re, Im => Acc.Im + Prod.Im);
         end;
      end loop;

      return Acc;
   end Inner_Product;

   function Exact_Squared_Overlap (State_1, State_2 : State_Array) return Overlap_Value is
      IP : Complex_Num;
      Mag_Sq : Real;
   begin
      IP := Inner_Product (State_1, State_2);
      Mag_Sq := Magnitude_Squared (IP);
      if Mag_Sq > 1.0 then
         Mag_Sq := 1.0;
      elsif Mag_Sq < 0.0 then
         Mag_Sq := 0.0;
      end if;
      return Overlap_Value (Mag_Sq);
   end Exact_Squared_Overlap;

   function Ancilla_Zero_Probability (State_1, State_2 : State_Array) return Probability is
      Overlap : constant Overlap_Value := Exact_Squared_Overlap (State_1, State_2);
      Prob : Real;
   begin
      Prob := 0.5 * (1.0 + Real (Overlap));
      if Prob > 1.0 then
         Prob := 1.0;
      elsif Prob < 0.5 then
         Prob := 0.5;
      end if;
      return Probability (Prob);
   end Ancilla_Zero_Probability;

   function Simulated_Swap_Test (State_1, State_2 : State_Array; Shots : Shot_Count) return Overlap_Value is
      P0 : constant Probability := Ancilla_Zero_Probability (State_1, State_2);
      Gen : Ada.Numerics.Float_Random.Generator;
      Zero_Count : Natural := 0;
      Est_Overlap : Real;
   begin
      Ada.Numerics.Float_Random.Reset (Gen);

      for I in 1 .. Shots loop
         if Real (Ada.Numerics.Float_Random.Random (Gen)) < Real (P0) then
            Zero_Count := Zero_Count + 1;
         end if;
      end loop;

      Est_Overlap := 2.0 * (Real (Zero_Count) / Real (Integer (Shots))) - 1.0;
      if Est_Overlap > 1.0 then
         Est_Overlap := 1.0;
      elsif Est_Overlap < 0.0 then
         Est_Overlap := 0.0;
      end if;

      return Overlap_Value (Est_Overlap);
   end Simulated_Swap_Test;

   function Parameterized_Swap_Test (State_1, State_2 : State_Array; Theta : Real) return Overlap_Value is
      Base_Overlap : constant Overlap_Value := Exact_Squared_Overlap (State_1, State_2);
      Scaled : Real;
   begin
      Scaled := Real (Base_Overlap) * Cos (Theta);
      if Scaled > 1.0 then
         Scaled := 1.0;
      elsif Scaled < 0.0 then
         Scaled := 0.0;
      end if;
      return Overlap_Value (Scaled);
   end Parameterized_Swap_Test;

   function Compute_Overlap_Matrix (States : access function (Index : Positive) return State_Array;
                                    Count  : Positive) return Overlap_Matrix is
      Result : Overlap_Matrix (1 .. Count, 1 .. Count);
   begin
      for I in 1 .. Count loop
         for J in 1 .. Count loop
            declare
               St_I : constant State_Array := States (I);
               St_J : constant State_Array := States (J);
            begin
               Result (I, J) := Exact_Squared_Overlap (St_I, St_J);
            end;
         end loop;
      end loop;
      return Result;
   end Compute_Overlap_Matrix;

end Swap_Test;

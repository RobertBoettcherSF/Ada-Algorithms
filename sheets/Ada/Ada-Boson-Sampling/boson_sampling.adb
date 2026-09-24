--  =========================================================================
--  Package Body: Boson_Sampling
--  Description: Implementation of Boson Sampling computational models and
--               matrix permanent calculation (Ryser's formula).
--  Language: Ada 2023 (ISO/IEC 8652:2023)
--  =========================================================================

package body Boson_Sampling is

   -- Forward declaration of internal square root helper
   function Sqrt_Approx (Val : Real) return Real;

   -----------------------
   -- Complex Arithmetic --
   -----------------------

   function Add (A, B : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re + B.Re, Im => A.Im + B.Im);
   end Add;

   function Subtract (A, B : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re - B.Re, Im => A.Im - B.Im);
   end Subtract;

   function Multiply (A, B : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re * B.Re - A.Im * B.Im,
              Im => A.Re * B.Im + A.Im * B.Re);
   end Multiply;

   function Magnitude_Squared (Z : Complex_Number) return Real is
   begin
      return Z.Re * Z.Re + Z.Im * Z.Im;
   end Magnitude_Squared;

   -------------------------
   -- Matrix Permanent    --
   -------------------------

   function Calculate_Permanent (Mat : Complex_Matrix) return Complex_Number is
      N : constant Integer := Mat'Length (1);
      Low1 : constant Integer := Mat'First (1);
      Low2 : constant Integer := Mat'First (2);
      Sum_Term : Complex_Number := (Re => 0.0, Im => 0.0);
   begin
      if N = 0 then
         raise Invalid_Matrix_Dimension;
      end if;

      -- Ryser's algorithm for matrix permanent:
      -- perm(A) = (-1)^n * sum_{X \subseteq {1..n}} (-1)^{|X|} prod_{i=1}^n sum_{j \in X} A_{i,j}
      declare
         Max_Mask : constant Integer := 2**N - 1;
      begin
         for Mask in 0 .. Max_Mask loop
            declare
               Bits : Integer := 0;
               Temp : Integer := Mask;
            begin
               while Temp > 0 loop
                  if (Temp mod 2) = 1 then
                     Bits := Bits + 1;
                  end if;
                  Temp := Temp / 2;
               end loop;

               declare
                  Prod : Complex_Number := (Re => 1.0, Im => 0.0);
               begin
                  for I in 1 .. N loop
                     declare
                        Row_Sum : Complex_Number := (Re => 0.0, Im => 0.0);
                     begin
                        for J in 1 .. N loop
                           if (Mask / (2**(J - 1))) mod 2 = 1 then
                              Row_Sum := Add (Row_Sum, Mat (Low1 + I - 1, Low2 + J - 1));
                           end if;
                        end loop;
                        Prod := Multiply (Prod, Row_Sum);
                     end;
                  end loop;

                  -- (-1)^{|X|} factor combined with sign
                  if (N - Bits) mod 2 = 1 then
                     Sum_Term := Subtract (Sum_Term, Prod);
                  else
                     Sum_Term := Add (Sum_Term, Prod);
                  end if;
               end;
            end;
         end loop;
      end;

      return Sum_Term;
   end Calculate_Permanent;

   -------------------------
   -- Unitarity Validation --
   -------------------------

   function Validate_Unitarity (Mat : Complex_Matrix; Tolerance : Real := 1.0E-4) return Boolean is
      N : constant Integer := Mat'Length (1);
      Low1 : constant Integer := Mat'First (1);
      Low2 : constant Integer := Mat'First (2);
   begin
      if N = 0 then
         return False;
      end if;

      -- Check U * U^dagger = I
      for I in 1 .. N loop
         for J in 1 .. N loop
            declare
               Dot : Complex_Number := (Re => 0.0, Im => 0.0);
            begin
               for K in 1 .. N loop
                  declare
                     U_ik : constant Complex_Number := Mat (Low1 + I - 1, Low2 + K - 1);
                     U_jk_conj : constant Complex_Number := 
                       (Re => Mat (Low1 + J - 1, Low2 + K - 1).Re,
                        Im => -Mat (Low1 + J - 1, Low2 + K - 1).Im);
                  begin
                     Dot := Add (Dot, Multiply (U_ik, U_jk_conj));
                  end;
               end loop;

               declare
                  Expected_Re : constant Real := (if I = J then 1.0 else 0.0);
                  Expected_Im : constant Real := 0.0;
                  Diff_Re : constant Real := abs (Dot.Re - Expected_Re);
                  Diff_Im : constant Real := abs (Dot.Im - Expected_Im);
               begin
                  if Diff_Re > Tolerance or else Diff_Im > Tolerance then
                     return False;
                  end if;
               end;
            end;
         end loop;
      end loop;

      return True;
   end Validate_Unitarity;

   ----------------------------------------------
   -- Variant 1 & 2: Standard Boson Sampling   --
   ----------------------------------------------

   function Standard_Transition_Amplitude
     (Interferometer : Complex_Matrix;
      Input_State    : Photon_Vector;
      Output_State   : Photon_Vector) return Complex_Number
   is
      N : constant Integer := Interferometer'Length (1);
      Low_U1 : constant Integer := Interferometer'First (1);
      Low_U2 : constant Integer := Interferometer'First (2);
      Low_In : constant Integer := Input_State'First;
      Low_Out : constant Integer := Output_State'First;

      Total_Photons_In : Photon_Count := 0;
      Total_Photons_Out : Photon_Count := 0;
   begin
      for I in 1 .. N loop
         Total_Photons_In := Total_Photons_In + Input_State (Low_In + I - 1);
         Total_Photons_Out := Total_Photons_Out + Output_State (Low_Out + I - 1);
      end loop;

      if Total_Photons_In /= Total_Photons_Out then
         return (Re => 0.0, Im => 0.0);
      end if;

      declare
         M_Size : constant Integer := Integer (Total_Photons_In);
      begin
         if M_Size = 0 then
            return (Re => 1.0, Im => 0.0);
         end if;

         declare
            Sub_Mat : Complex_Matrix (1 .. M_Size, 1 .. M_Size);
            Row_Idx : Integer := 1;
         begin
            for I in 1 .. N loop
               declare
                  Count_In : constant Photon_Count := Input_State (Low_In + I - 1);
               begin
                  for P in 1 .. Count_In loop
                     declare
                        Col_Idx : Integer := 1;
                     begin
                        for J in 1 .. N loop
                           declare
                              Count_Out : constant Photon_Count := Output_State (Low_Out + J - 1);
                           begin
                              for Q in 1 .. Count_Out loop
                                 Sub_Mat (Row_Idx, Col_Idx) := Interferometer (Low_U1 + I - 1, Low_U2 + J - 1);
                                 Col_Idx := Col_Idx + 1;
                              end loop;
                           end;
                        end loop;
                        Row_Idx := Row_Idx + 1;
                     end;
                  end loop;
               end;
            end loop;

            declare
               Perm : constant Complex_Number := Calculate_Permanent (Sub_Mat);
               Factor : Real := 1.0;
            begin
               for I in 1 .. N loop
                  declare
                     In_Count : constant Integer := Integer (Input_State (Low_In + I - 1));
                     Out_Count : constant Integer := Integer (Output_State (Low_Out + I - 1));
                  begin
                     for F in 2 .. In_Count loop
                        Factor := Factor * Real (F);
                     end loop;
                     for F in 2 .. Out_Count loop
                        Factor := Factor * Real (F);
                     end loop;
                  end;
               end loop;

               declare
                  Norm_Divisor : constant Real := Sqrt_Approx (Factor);
               begin
                  if Norm_Divisor = 0.0 then
                     return Perm;
                  end if;
                  return (Re => Perm.Re / Norm_Divisor, Im => Perm.Im / Norm_Divisor);
               end;
            end;
         end;
      end;
   end Standard_Transition_Amplitude;

   function Sqrt_Approx (Val : Real) return Real is
      X : Real := Val;
   begin
      if Val <= 0.0 then
         return 0.0;
      end if;
      for Iter in 1 .. 10 loop
         X := 0.5 * (X + Val / X);
      end loop;
      return X;
   end Sqrt_Approx;

   function Standard_Boson_Sampling_Probability
     (Interferometer : Complex_Matrix;
      Input_State    : Photon_Vector;
      Output_State   : Photon_Vector) return Real
   is
      Amp : constant Complex_Number := Standard_Transition_Amplitude (Interferometer, Input_State, Output_State);
   begin
      return Magnitude_Squared (Amp);
   end Standard_Boson_Sampling_Probability;

   ----------------------------------------------
   -- Variant 3: Scattershot Boson Sampling    --
   ----------------------------------------------

   function Scattershot_Boson_Sampling_Probability
     (Interferometer : Complex_Matrix;
      Mode_Mask      : Photon_Vector;
      Output_State   : Photon_Vector) return Real
   is
   begin
      return Standard_Boson_Sampling_Probability (Interferometer, Mode_Mask, Output_State);
   end Scattershot_Boson_Sampling_Probability;

   ----------------------------------------------
   -- Variant 4: Classical Simulation Cost     --
   ----------------------------------------------

   function Estimate_Classical_Simulation_Cost
     (Modes   : Mode_Count;
      Photons : Photon_Count) return Real
   is
      M_Val : constant Real := Real (Modes);
      Scale : Real := 1.0;
   begin
      for I in 1 .. Integer (Photons) loop
         Scale := Scale * 2.0;
      end loop;
      return Scale * M_Val * M_Val;
   end Estimate_Classical_Simulation_Cost;

end Boson_Sampling;

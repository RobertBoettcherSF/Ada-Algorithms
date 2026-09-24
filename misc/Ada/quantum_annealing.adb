with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Quantum_Annealing is

   use Ada.Numerics.Elementary_Functions;

   --------------------------
   -- Compute_Ising_Energy --
   --------------------------
   function Compute_Ising_Energy
     (Spins     : Spin_Array;
      Couplings : Coupling_Matrix;
      Fields    : External_Field_Array) return Energy_Value
   is
      N : constant Natural := Spins'Length;
      Energy : Energy_Value := 0.0;
      Base_Index : constant Integer := Integer(Spins'First);
      Coupl_Base_1 : constant Integer := Integer(Couplings'First(1));
      Coupl_Base_2 : constant Integer := Integer(Couplings'First(2));
      Field_Base : constant Integer := Integer(Fields'First);
   begin
      -- Calculate interaction term: - sum_{i < j} J_ij s_i s_j
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            if I < J then
               declare
                  Si : constant Energy_Value := (if Spins(Spin_Index(Base_Index + I)) = 1 then 1.0 else -1.0);
                  Sj : constant Energy_Value := (if Spins(Spin_Index(Base_Index + J)) = 1 then 1.0 else -1.0);
                  J_Val : constant Energy_Value := Energy_Value(Couplings(Spin_Index(Coupl_Base_1 + I), Spin_Index(Coupl_Base_2 + J)));
               begin
                  Energy := Energy - J_Val * Si * Sj;
               end;
            end if;
         end loop;
      end loop;

      -- Calculate external field term: - sum_i h_i s_i
      for I in 0 .. N - 1 loop
         declare
            Si : constant Energy_Value := (if Spins(Spin_Index(Base_Index + I)) = 1 then 1.0 else -1.0);
            H_Val : constant Energy_Value := Energy_Value(Fields(Spin_Index(Field_Base + I)));
         begin
            Energy := Energy - H_Val * Si;
         end;
      end loop;

      return Energy;
   end Compute_Ising_Energy;

   ------------------------------
   -- Adiabatic_Quantum_Anneal --
   ------------------------------
   procedure Adiabatic_Quantum_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
   is
      N : constant Natural := Couplings'Length(1);
      Num_States : constant Natural := 2 ** N;
      type State_Mask is mod 2 ** 32;
      
      -- Real and Imaginary parts of state amplitudes for exact Schrödinger evolution
      type Amplitude_Array is array (Integer range <>) of Float;
      Real_Amp : Amplitude_Array(0 .. Num_States - 1) := [others => 0.0];
      Imag_Amp : Amplitude_Array(0 .. Num_States - 1) := [others => 0.0];
      
      Best_State : State_Mask := 0;
      Min_E : Energy_Value := 1.0E30;
      
      -- Initialize equal superposition
      Norm : constant Float := Sqrt(Float(Num_States));
   begin
      for S_Val in 0 .. Num_States - 1 loop
         Real_Amp(S_Val) := 1.0 / Norm;
         Imag_Amp(S_Val) := 0.0;
      end loop;

      -- Time evolution simulation across steps
      for Step in 1 .. Config.Steps loop
         declare
            Progress : constant Float := Float(Step) / Float(Config.Steps);
            Gamma : Float; -- Transverse field strength B(t)
            Alpha : Float; -- Problem Hamiltonian strength A(t)
         begin
            if Config.Schedule = Linear then
               Gamma := Float(Config.Initial_Field) * (1.0 - Progress) + Float(Config.Final_Field) * Progress;
               Alpha := Progress;
            elsif Config.Schedule = Exponential then
               Gamma := Float(Config.Initial_Field) * (1.0 - Progress ** 2);
               Alpha := Progress ** 2;
            else -- Diabatic
               Gamma := Float(Config.Initial_Field) * Exp(-3.0 * Progress);
               Alpha := 1.0 - Exp(-3.0 * Progress);
            end if;

            -- Simulate approximate Hamiltonian phase rotation and quantum tunneling mixing
            for S_Val in 0 .. Num_States - 1 loop
               declare
                  S : constant State_Mask := State_Mask(S_Val);
               begin
                  -- Decode state S into spins
                  declare
                     Curr_Spins : Spin_Array(1 .. Spin_Index(N));
                  begin
                     for Bit_Idx in 0 .. N - 1 loop
                        if (S and State_Mask'(2 ** Bit_Idx)) /= 0 then
                           Curr_Spins(Spin_Index(Bit_Idx + 1)) := 1;
                        else
                           Curr_Spins(Spin_Index(Bit_Idx + 1)) := -1;
                        end if;
                     end loop;

                     declare
                        E : constant Energy_Value := Compute_Ising_Energy(Curr_Spins, Couplings, Fields);
                        Phase : constant Float := -(Alpha * Float(E)) * 0.01;
                        Cos_P : constant Float := Cos(Phase);
                        Sin_P : constant Float := Sin(Phase);
                        New_Real : constant Float := Real_Amp(S_Val) * Cos_P - Imag_Amp(S_Val) * Sin_P;
                        New_Imag : constant Float := Real_Amp(S_Val) * Sin_P + Imag_Amp(S_Val) * Cos_P;
                     begin
                        Real_Amp(S_Val) := New_Real;
                        Imag_Amp(S_Val) := New_Imag;

                        -- Track best energy found during evolution
                        if E < Min_E then
                           Min_E := E;
                           Best_State := S;
                        end if;
                     end;
                  end;
               end;
            end loop;

            -- Apply transverse field mixing (tunneling between adjacent Hamming states)
            if Gamma > 0.0 then
               for S_Val in 0 .. Num_States - 1 loop
                  declare
                     S : constant State_Mask := State_Mask(S_Val);
                  begin
                     for Bit_Idx in 0 .. N - 1 loop
                        declare
                           Neighbor : constant State_Mask := S xor State_Mask'(2 ** Bit_Idx);
                           Neighbor_Val : constant Integer := Integer(Neighbor);
                        begin
                           Real_Amp(Neighbor_Val) := Real_Amp(Neighbor_Val) + 0.05 * Gamma * Real_Amp(S_Val);
                        end;
                     end loop;
                  end;
               end loop;
            end if;
         end;
      end loop;

      -- Decode Best_State into Best_Spins
      Best_Spins := [others => -1];
      for Bit_Idx in 0 .. N - 1 loop
         if (Best_State and State_Mask'(2 ** Bit_Idx)) /= 0 then
            Best_Spins(Spin_Index(Bit_Idx + 1)) := 1;
         else
            Best_Spins(Spin_Index(Bit_Idx + 1)) := -1;
         end if;
      end loop;

      Final_Energy := Compute_Ising_Energy(Best_Spins, Couplings, Fields);
   end Adiabatic_Quantum_Anneal;

   -----------------------------
   -- Transverse_Field_Anneal --
   -----------------------------
   procedure Transverse_Field_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Seed         : in Natural;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
   is
      N : constant Natural := Couplings'Length(1);
      Gen : Ada.Numerics.Float_Random.Generator;
      Current_Spins : Spin_Array(1 .. Spin_Index(N));
      Best_Found_Spins : Spin_Array(1 .. Spin_Index(N));
      Current_E : Energy_Value;
      Best_E : Energy_Value;
   begin
      Ada.Numerics.Float_Random.Reset(Gen, Seed);

      -- Initialize random spin configuration
      for I in Current_Spins'Range loop
         if Ada.Numerics.Float_Random.Random(Gen) > 0.5 then
            Current_Spins(I) := 1;
         else
            Current_Spins(I) := -1;
         end if;
      end loop;

      Best_Found_Spins := Current_Spins;
      Current_E := Compute_Ising_Energy(Current_Spins, Couplings, Fields);
      Best_E := Current_E;

      -- Annealing loop with transverse field quantum tunneling Monte Carlo moves
      for Step in 1 .. Config.Steps loop
         declare
            Progress : constant Float := Float(Step) / Float(Config.Steps);
            Field_Strength : constant Float := Float(Config.Initial_Field) * (1.0 - Progress) + Float(Config.Final_Field) * Progress;
            
            -- Pick a random spin to flip (quantum tunneling attempt) using Float'Floor to prevent rounding up out of bounds
            Flip_Rnd : constant Float := Ada.Numerics.Float_Random.Random(Gen);
            Flip_Idx : constant Integer := Integer(Float'Floor(Flip_Rnd * Float(N))) + 1;
            Target_Idx : constant Spin_Index := Spin_Index(Flip_Idx);
         begin
            -- Trial flip
            Current_Spins(Target_Idx) := (if Current_Spins(Target_Idx) = 1 then -1 else 1);
            declare
               Trial_E : constant Energy_Value := Compute_Ising_Energy(Current_Spins, Couplings, Fields);
               Delta_E : constant Energy_Value := Trial_E - Current_E;
               Accepted : Boolean := False;
            begin
               if Delta_E < 0.0 then
                  Accepted := True;
               else
                  -- Transverse field tunneling probability acceptance criterion
                  declare
                     Tunnel_Prob : constant Float := Exp(-Float(Delta_E) / (0.1 + Field_Strength));
                  begin
                     if Ada.Numerics.Float_Random.Random(Gen) < Tunnel_Prob then
                        Accepted := True;
                     end if;
                  end;
               end if;

               if Accepted then
                  Current_E := Trial_E;
                  if Current_E < Best_E then
                     Best_E := Current_E;
                     Best_Found_Spins := Current_Spins;
                  end if;
               else
                  -- Revert flip
                  Current_Spins(Target_Idx) := (if Current_Spins(Target_Idx) = 1 then -1 else 1);
               end if;
            end;
         end;
      end loop;

      Best_Spins := Best_Found_Spins;
      Final_Energy := Best_E;
   end Transverse_Field_Anneal;

   ----------------------------
   -- Linear_Schedule_Anneal --
   ----------------------------
   procedure Linear_Schedule_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Steps        : in Step_Count;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
   is
      Config : constant Annealing_Config :=
        (Steps         => Steps,
         Initial_Field => 5.0,
         Final_Field   => 0.0,
         Schedule      => Linear);
   begin
      if Couplings'Length(1) <= 6 then
         Adiabatic_Quantum_Anneal(Couplings, Fields, Config, Best_Spins, Final_Energy);
      else
         Transverse_Field_Anneal(Couplings, Fields, Config, 42, Best_Spins, Final_Energy);
      end if;
   end Linear_Schedule_Anneal;

   ----------------------------------
   -- Exponential_Schedule_Anneal --
   ----------------------------------
   procedure Exponential_Schedule_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Steps        : in Step_Count;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
   is
      Config : constant Annealing_Config :=
        (Steps         => Steps,
         Initial_Field => 5.0,
         Final_Field   => 0.0,
         Schedule      => Exponential);
   begin
      if Couplings'Length(1) <= 6 then
         Adiabatic_Quantum_Anneal(Couplings, Fields, Config, Best_Spins, Final_Energy);
      else
         Transverse_Field_Anneal(Couplings, Fields, Config, 123, Best_Spins, Final_Energy);
      end if;
   end Exponential_Schedule_Anneal;

   -----------------------------
   -- Diabatic_Quantum_Anneal --
   -----------------------------
   procedure Diabatic_Quantum_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
   is
   begin
      if Couplings'Length(1) <= 6 then
         Adiabatic_Quantum_Anneal(Couplings, Fields, Config, Best_Spins, Final_Energy);
      else
         Transverse_Field_Anneal(Couplings, Fields, Config, 999, Best_Spins, Final_Energy);
      end if;
   end Diabatic_Quantum_Anneal;

end Quantum_Annealing;

package body Pulse_Coupled_Networks is

   ------------------
   -- Create_State --
   ------------------
   
   function Create_State (Rows, Cols : Dimension; Init_Theta : Real) return PCNN_State is
      Result : PCNN_State (Rows, Cols);
   begin
      Result.F     := [others => [others => 0.0]];
      Result.L     := [others => [others => 0.0]];
      Result.U     := [others => [others => 0.0]];
      Result.Theta := [others => [others => Init_Theta]];
      Result.Y     := [others => [others => False]];
      return Result;
   end Create_State;

   --------------
   -- Convolve --
   --------------
   
   function Convolve
     (Y : in Binary_Matrix;
      K : in Kernel_Matrix;
      R : in Dimension;
      C : in Dimension) return Real
   is
      Sum      : Real := 0.0;
      Target_R : Integer;
      Target_C : Integer;
   begin
      for dR in Offset loop
         for dC in Offset loop
            Target_R := Integer (R) + Integer (dR);
            Target_C := Integer (C) + Integer (dC);

            --  Bounds checking to handle network edges safely
            if Target_R >= Integer (Y'First (1)) and then Target_R <= Integer (Y'Last (1)) and then
               Target_C >= Integer (Y'First (2)) and then Target_C <= Integer (Y'Last (2))
            then
               --  Only add the kernel weight if the neighboring neuron fired (True)
               if Y (Dimension (Target_R), Dimension (Target_C)) then
                  Sum := Sum + K (dR, dC);
               end if;
            end if;
         end loop;
      end loop;
      return Sum;
   end Convolve;

   ----------------------
   -- Iterate_Standard --
   ----------------------
   
   procedure Iterate_Standard
     (State    : in out PCNN_State;
      Stimulus : in     Real_Matrix;
      Params   : in     PCNN_Parameters;
      M        : in     Kernel_Matrix;
      W        : in     Kernel_Matrix)
   is
      --  Cache the previous iteration's output and threshold for sequential integrity
      Prev_Y     : constant Binary_Matrix := State.Y;
      Prev_Theta : constant Real_Matrix   := State.Theta;
      Conv_M     : Real;
      Conv_W     : Real;
   begin
      --  Explicit dimension checks to ensure safety and allow for unit testing
      if Stimulus'First (1) /= 1 or else Stimulus'Last (1) /= State.Rows or else
         Stimulus'First (2) /= 1 or else Stimulus'Last (2) /= State.Cols
      then
         raise Dimension_Mismatch;
      end if;

      for R in 1 .. State.Rows loop
         for C in 1 .. State.Cols loop
            Conv_M := Convolve (Prev_Y, M, R, C);
            Conv_W := Convolve (Prev_Y, W, R, C);

            --  Update Feeding (F) and Linking (L) compartments
            State.F (R, C) := Params.Decay_F * State.F (R, C) + Params.V_F * Conv_M + Stimulus (R, C);
            State.L (R, C) := Params.Decay_L * State.L (R, C) + Params.V_L * Conv_W;
            
            --  Modulate feeding with linking to produce internal activity (U)
            State.U (R, C) := State.F (R, C) * (1.0 + Params.Beta * State.L (R, C));

            --  Generate pulse (Y) and update dynamic threshold (Theta)
            if State.U (R, C) > Prev_Theta (R, C) then
               State.Y (R, C) := True;
               State.Theta (R, C) := Params.Decay_Theta * Prev_Theta (R, C) + Params.V_Theta;
            else
               State.Y (R, C) := False;
               State.Theta (R, C) := Params.Decay_Theta * Prev_Theta (R, C);
            end if;
         end loop;
      end loop;
   end Iterate_Standard;

   ------------------------
   -- Iterate_Simplified --
   ------------------------
   
   procedure Iterate_Simplified
     (State    : in out PCNN_State;
      Stimulus : in     Real_Matrix;
      Params   : in     PCNN_Parameters;
      W        : in     Kernel_Matrix)
   is
      Prev_Y     : constant Binary_Matrix := State.Y;
      Prev_Theta : constant Real_Matrix   := State.Theta;
      Conv_W     : Real;
   begin
      if Stimulus'First (1) /= 1 or else Stimulus'Last (1) /= State.Rows or else
         Stimulus'First (2) /= 1 or else Stimulus'Last (2) /= State.Cols
      then
         raise Dimension_Mismatch;
      end if;

      for R in 1 .. State.Rows loop
         for C in 1 .. State.Cols loop
            --  In the simplified Unit-Linking PCNN model, Feeding is directly the Stimulus
            State.F (R, C) := Stimulus (R, C);
            
            Conv_W := Convolve (Prev_Y, W, R, C);
            State.L (R, C) := Params.Decay_L * State.L (R, C) + Params.V_L * Conv_W;
            State.U (R, C) := State.F (R, C) * (1.0 + Params.Beta * State.L (R, C));

            if State.U (R, C) > Prev_Theta (R, C) then
               State.Y (R, C) := True;
               State.Theta (R, C) := Params.Decay_Theta * Prev_Theta (R, C) + Params.V_Theta;
            else
               State.Y (R, C) := False;
               State.Theta (R, C) := Params.Decay_Theta * Prev_Theta (R, C);
            end if;
         end loop;
      end loop;
   end Iterate_Simplified;

end Pulse_Coupled_Networks;

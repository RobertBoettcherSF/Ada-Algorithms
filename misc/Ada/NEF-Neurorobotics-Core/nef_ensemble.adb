with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with LIF_Neuron;
with Rover_Control;

package body NEF_Ensemble is

   package EF renames Ada.Numerics.Elementary_Functions;

   ------------------------------------------------------------------
   --  Tiny deterministic LCG for reproducible encoder jitter
   ------------------------------------------------------------------

   type U32 is mod 2 ** 32;

   function Next_U32 (State : in out U32) return U32 is
   begin
      State := State * 1664525 + 1013904223;
      return State;
   end Next_U32;

   function Next_Unit (State : in out U32) return Float is
   begin
      return Float (Next_U32 (State)) / Float (U32'Last);
   end Next_Unit;

   ------------------------------------------------------------------
   --  Linear algebra: solve M x = b for N x N (Gaussian elim + pivot)
   ------------------------------------------------------------------

   subtype Idx is Positive range 1 .. Neuron_Count;
   type Matrix is array (Idx, Idx) of Float;
   type Vec is array (Idx) of Float;

   procedure Solve (M : in out Matrix; B : in out Vec; OK : out Boolean) is
      N : constant Positive := Neuron_Count;
      Pivot_Row : Positive;
      Best, Fac, Sum : Float;
      Tmp : Float;
   begin
      OK := True;
      for Col in 1 .. N loop
         Best := abs M (Col, Col);
         Pivot_Row := Col;
         for Row in Col + 1 .. N loop
            if abs M (Row, Col) > Best then
               Best := abs M (Row, Col);
               Pivot_Row := Row;
            end if;
         end loop;
         if Best < 1.0e-12 then
            OK := False;
            return;
         end if;
         if Pivot_Row /= Col then
            for J in Col .. N loop
               Tmp := M (Col, J);
               M (Col, J) := M (Pivot_Row, J);
               M (Pivot_Row, J) := Tmp;
            end loop;
            Tmp := B (Col);
            B (Col) := B (Pivot_Row);
            B (Pivot_Row) := Tmp;
         end if;
         for Row in Col + 1 .. N loop
            Fac := M (Row, Col) / M (Col, Col);
            for J in Col .. N loop
               M (Row, J) := M (Row, J) - Fac * M (Col, J);
            end loop;
            B (Row) := B (Row) - Fac * B (Col);
         end loop;
      end loop;
      for I in reverse 1 .. N loop
         Sum := B (I);
         for J in I + 1 .. N loop
            Sum := Sum - M (I, J) * B (J);
         end loop;
         B (I) := Sum / M (I, I);
      end loop;
   end Solve;

   ------------------------------------------------------------------

   function Create (Seed : Natural := 42) return Ensemble is
      E     : Ensemble;
      State : U32 := U32 (Seed) * 2654435761 + 1;
      Angle, Jitter, Norm, Ex, Ey : Float;
   begin
      for I in 1 .. Neuron_Count loop
         Angle  := 2.0 * Pi * Float (I - 1) / Float (Neuron_Count);
         Jitter := (Next_Unit (State) - 0.5) * (Pi / Float (Neuron_Count));
         Angle  := Angle + Jitter;
         Ex := EF.Cos (Angle);
         Ey := EF.Sin (Angle);
         Norm := EF.Sqrt (Ex * Ex + Ey * Ey);
         E.Encoders (I, 1) := Ex / Norm;
         E.Encoders (I, 2) := Ey / Norm;
         --  Heterogeneous gains / intercepts (classic educational NEF setup)
         E.Alpha (I) := 0.5 + 1.5 * Next_Unit (State);       -- ~[0.5, 2.0]
         E.Bias (I)  := -0.5 + 1.0 * Next_Unit (State);      -- ~[-0.5, 0.5]
         E.Dec (I)   := 0.0;
      end loop;
      E.Fitted := False;
      return E;
   end Create;

   function Ideal_Rates (E : Ensemble; X, Y : Float) return Rate_Array is
      R : Rate_Array;
      Dot : Float;
   begin
      for I in 1 .. Neuron_Count loop
         Dot := E.Encoders (I, 1) * X + E.Encoders (I, 2) * Y;
         R (I) := E.Alpha (I) * Dot + E.Bias (I);
         if R (I) < 0.0 then
            R (I) := 0.0;
         end if;
      end loop;
      return R;
   end Ideal_Rates;

   function LIF_Rates
     (E     : Ensemble;
      X, Y  : Float;
      Steps : Positive := 200) return Rate_Array
   is
      R     : Rate_Array := [others => 0.0];
      Dot   : Float;
      I_Inj : Float;
      Spiked : Boolean;
      N     : LIF_Neuron.Neuron;
   begin
      for I in 1 .. Neuron_Count loop
         Dot   := E.Encoders (I, 1) * X + E.Encoders (I, 2) * Y;
         I_Inj := E.Alpha (I) * Dot + E.Bias (I) + 1.2;  -- offset to allow spikes
         N := LIF_Neuron.Create;
         for S in 1 .. Steps loop
            LIF_Neuron.Step (N, I_Inj, Spiked);
         end loop;
         R (I) := Float (LIF_Neuron.Spike_Count (N)) / Float (Steps);
      end loop;
      return R;
   end LIF_Rates;

   procedure Fit_Acceleration
     (E          : in out Ensemble;
      Ka         : Float    := 1.0;
      Grid_Min   : Float    := -1.5;
      Grid_Max   : Float    := 1.5;
      Grid_Steps : Positive := 9)
   is
      N_Samp : constant Positive := Grid_Steps * Grid_Steps;
      --  Accumulate A^T A (NxN) and A^T f (N)
      ATA : Matrix := [others => [others => 0.0]];
      ATf : Vec    := [others => 0.0];
      Rates : Rate_Array;
      X, Y, Target, Step : Float;
      OK : Boolean;
      Ridge : constant Float := 1.0e-4;  -- mild Tikhonov for stability
   begin
      if Grid_Steps < 2 then
         raise Constraint_Error with "Grid_Steps must be >= 2";
      end if;
      Step := (Grid_Max - Grid_Min) / Float (Grid_Steps - 1);

      for Ix in 0 .. Grid_Steps - 1 loop
         X := Grid_Min + Float (Ix) * Step;
         for Iy in 0 .. Grid_Steps - 1 loop
            Y := Grid_Min + Float (Iy) * Step;
            Rates  := Ideal_Rates (E, X, Y);
            Target := Rover_Control.Acceleration (X, Y, Ka);
            for I in 1 .. Neuron_Count loop
               ATf (I) := ATf (I) + Rates (I) * Target;
               for J in 1 .. Neuron_Count loop
                  ATA (I, J) := ATA (I, J) + Rates (I) * Rates (J);
               end loop;
            end loop;
         end loop;
      end loop;

      --  Ridge: ATA := ATA + lambda I
      for I in 1 .. Neuron_Count loop
         ATA (I, I) := ATA (I, I) + Ridge * Float (N_Samp);
      end loop;

      Solve (ATA, ATf, OK);
      if not OK then
         raise Program_Error with "NEF decoder solve failed (singular ATA)";
      end if;

      for I in 1 .. Neuron_Count loop
         E.Dec (I) := ATf (I);
      end loop;
      E.Fitted := True;
   end Fit_Acceleration;

   function Decode (E : Ensemble; X, Y : Float) return Float is
      Rates : constant Rate_Array := Ideal_Rates (E, X, Y);
      Acc   : Float := 0.0;
   begin
      if not E.Fitted then
         raise Program_Error with "Decode called before Fit_Acceleration";
      end if;
      for I in 1 .. Neuron_Count loop
         Acc := Acc + Rates (I) * E.Dec (I);
      end loop;
      return Acc;
   end Decode;

   function Is_Fitted (E : Ensemble) return Boolean is
   begin
      return E.Fitted;
   end Is_Fitted;

   function Decoders (E : Ensemble) return Decoder_Array is
   begin
      return E.Dec;
   end Decoders;

   procedure Eval_Error
     (E          : Ensemble;
      Ka         : Float;
      Grid_Min   : Float;
      Grid_Max   : Float;
      Grid_Steps : Positive;
      MSE        : out Float;
      Max_Abs    : out Float)
   is
      Step : Float;
      X, Y, Ref, Approx, Err : Float;
      Sum_Sq : Float := 0.0;
      Count  : Natural := 0;
   begin
      Max_Abs := 0.0;
      Step := (Grid_Max - Grid_Min) / Float (Grid_Steps - 1);
      for Ix in 0 .. Grid_Steps - 1 loop
         X := Grid_Min + Float (Ix) * Step;
         for Iy in 0 .. Grid_Steps - 1 loop
            Y := Grid_Min + Float (Iy) * Step;
            Ref    := Rover_Control.Acceleration (X, Y, Ka);
            Approx := Decode (E, X, Y);
            Err    := Approx - Ref;
            Sum_Sq := Sum_Sq + Err * Err;
            Count  := Count + 1;
            if abs Err > Max_Abs then
               Max_Abs := abs Err;
            end if;
         end loop;
      end loop;
      MSE := Sum_Sq / Float (Count);
   end Eval_Error;

end NEF_Ensemble;

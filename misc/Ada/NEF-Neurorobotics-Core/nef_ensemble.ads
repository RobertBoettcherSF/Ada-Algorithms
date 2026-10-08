--  Minimal educational NEF-style ensemble (not Loihi, not full Nengo).
--  Represents a 2-D state with N rate neurons, solves linear decoders for a
--  scalar target (rover acceleration, eq. 1) via normal equations / least
--  squares on a training grid, then Decode evaluates the approximation.
--
--  Ideas inspired by DeWolf et al., arXiv:2007.10227v2 §3.3 / NEF methods;
--  numerics are intentionally small (N=32) and fully tested in Ada.

package NEF_Ensemble is

   Neuron_Count : constant Positive := 32;
   State_Dim    : constant Positive := 2;

   type Rate_Array is array (1 .. Neuron_Count) of Float;
   type Decoder_Array is array (1 .. Neuron_Count) of Float;

   type Ensemble is private;

   --  Build ensemble with unit-circle encoders and heterogeneous gains/biases.
   --  Seed selects a deterministic pseudo-random encoder jitter (reproducible).
   function Create (Seed : Natural := 42) return Ensemble;

   --  Ideal (rate) activities for state (X, Y). Educational NEF ReLU-style:
   --    a_i = max (0, alpha_i * (e_i · x) + bias_i)
   function Ideal_Rates (E : Ensemble; X, Y : Float) return Rate_Array;

   --  Optional: drive N LIF neurons for Dt*Steps with constant current
   --  proportional to encoder projection (educational spike-rate estimate).
   function LIF_Rates
     (E     : Ensemble;
      X, Y  : Float;
      Steps : Positive := 200) return Rate_Array;

   --  Fit decoders so Decode ≈ Acceleration (X,Y; Ka) on a uniform grid.
   --  Solves (A^T A) d = A^T f with Gaussian elimination (pseudoinverse path
   --  when A^T A is well-conditioned on the training set).
   procedure Fit_Acceleration
     (E          : in out Ensemble;
      Ka         : Float    := 1.0;
      Grid_Min   : Float    := -1.5;
      Grid_Max   : Float    := 1.5;
      Grid_Steps : Positive := 9);

   function Decode (E : Ensemble; X, Y : Float) return Float;
   function Is_Fitted (E : Ensemble) return Boolean;
   function Decoders (E : Ensemble) return Decoder_Array;

   --  Mean-squared and max-abs error of Decode vs Acceleration on the
   --  same style of grid (for V&V thresholds).
   procedure Eval_Error
     (E          : Ensemble;
      Ka         : Float;
      Grid_Min   : Float;
      Grid_Max   : Float;
      Grid_Steps : Positive;
      MSE        : out Float;
      Max_Abs    : out Float);

private

   type Encoder_Array is array (1 .. Neuron_Count, 1 .. State_Dim) of Float;
   type Gain_Array is array (1 .. Neuron_Count) of Float;

   type Ensemble is record
      Encoders : Encoder_Array := [others => [others => 0.0]];
      Alpha    : Gain_Array    := [others => 1.0];
      Bias     : Gain_Array    := [others => 0.0];
      Dec     : Decoder_Array := [others => 0.0];
      Fitted   : Boolean       := False;
   end record;

end NEF_Ensemble;

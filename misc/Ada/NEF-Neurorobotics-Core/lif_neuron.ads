--  Educational discrete-time leaky integrate-and-fire (LIF) neuron.
--  Bounded Float state suitable for V&V assertions. Not a Loihi model.

package LIF_Neuron is

   type Neuron is private;

   --  Defaults chosen for clear educational demos (not biological fidelity).
   Default_Tau       : constant Float := 0.02;   -- membrane time constant (s)
   Default_R         : constant Float := 1.0;    -- input resistance
   Default_V_Thresh  : constant Float := 1.0;
   Default_V_Reset   : constant Float := 0.0;
   Default_V_Rest    : constant Float := 0.0;
   Default_Dt        : constant Float := 0.001;  -- integration step (s)

   function Create
     (Tau      : Float := Default_Tau;
      R        : Float := Default_R;
      V_Thresh : Float := Default_V_Thresh;
      V_Reset  : Float := Default_V_Reset;
      V_Rest   : Float := Default_V_Rest;
      Dt       : Float := Default_Dt) return Neuron;

   --  One Euler step with input current I. Returns True iff a spike occurred.
   procedure Step
     (N      : in out Neuron;
      I      : Float;
      Spiked : out Boolean);

   function Voltage (N : Neuron) return Float;
   function Spike_Count (N : Neuron) return Natural;

   procedure Reset (N : in out Neuron);

private

   type Neuron is record
      V        : Float   := Default_V_Rest;
      Tau      : Float   := Default_Tau;
      R        : Float   := Default_R;
      V_Thresh : Float   := Default_V_Thresh;
      V_Reset  : Float   := Default_V_Reset;
      V_Rest   : Float   := Default_V_Rest;
      Dt       : Float   := Default_Dt;
      Spikes   : Natural := 0;
   end record;

end LIF_Neuron;

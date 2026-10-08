package body LIF_Neuron is

   function Create
     (Tau      : Float := Default_Tau;
      R        : Float := Default_R;
      V_Thresh : Float := Default_V_Thresh;
      V_Reset  : Float := Default_V_Reset;
      V_Rest   : Float := Default_V_Rest;
      Dt       : Float := Default_Dt) return Neuron
   is
      N : Neuron;
   begin
      N.V        := V_Rest;
      N.Tau      := Tau;
      N.R        := R;
      N.V_Thresh := V_Thresh;
      N.V_Reset  := V_Reset;
      N.V_Rest   := V_Rest;
      N.Dt       := Dt;
      N.Spikes   := 0;
      return N;
   end Create;

   procedure Step
     (N      : in out Neuron;
      I      : Float;
      Spiked : out Boolean)
   is
      --  dV/dt = (-(V - V_rest) + R*I) / tau
      DV : constant Float :=
        (-(N.V - N.V_Rest) + N.R * I) / N.Tau;
   begin
      N.V := N.V + N.Dt * DV;
      if N.V >= N.V_Thresh then
         Spiked := True;
         N.V := N.V_Reset;
         N.Spikes := N.Spikes + 1;
      else
         Spiked := False;
      end if;
   end Step;

   function Voltage (N : Neuron) return Float is
   begin
      return N.V;
   end Voltage;

   function Spike_Count (N : Neuron) return Natural is
   begin
      return N.Spikes;
   end Spike_Count;

   procedure Reset (N : in out Neuron) is
   begin
      N.V := N.V_Rest;
      N.Spikes := 0;
   end Reset;

end LIF_Neuron;

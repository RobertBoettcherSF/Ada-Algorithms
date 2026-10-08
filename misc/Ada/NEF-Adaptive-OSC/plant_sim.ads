--  Tiny host-side plant for closed-loop V&V (no real robot).
--  Discrete-time 2-DOF double integrator with diagonal inertia and an
--  optional constant torque disturbance (unmodelled load / bias).
--  Euler step:  qdd = Inv_Inertia * (τ + disturbance); integrate qd, q.

with OSC_PD;

package Plant_Sim is

   N_DOF : constant := OSC_PD.N_DOF;
   subtype Joint_Vector is OSC_PD.Joint_Vector;

   type Plant is record
      Q, Qd          : Joint_Vector := [others => 0.0];
      Inv_Inertia    : Joint_Vector := [1.0, 1.0];  -- 1/I per joint
      Disturbance    : Joint_Vector := [others => 0.0];
      Dt             : Float := 0.01;
   end record;

   function Create
     (Dt          : Float := 0.01;
      Inertia     : Joint_Vector := [1.0, 1.0];
      Disturbance : Joint_Vector := [0.0, 0.0];
      Q0          : Joint_Vector := [0.0, 0.0];
      Qd0         : Joint_Vector := [0.0, 0.0]) return Plant;

   --  One Euler step under applied joint torque Tau.
   procedure Step (P : in out Plant; Tau : Joint_Vector);

   function Position (P : Plant) return Joint_Vector;
   function Velocity (P : Plant) return Joint_Vector;

end Plant_Sim;

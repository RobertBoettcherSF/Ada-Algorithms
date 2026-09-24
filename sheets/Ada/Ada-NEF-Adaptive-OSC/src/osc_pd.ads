--  Educational joint-space PD torque for a small planar arm (2 DOF).
--  Intuition from DeWolf et al. arXiv:2007.10227 §4 (OSC + adaptive residual):
--  the non-adaptive baseline is a PD force/torque law. Here we use *joint-space*
--  PD (not full operational-space with Jacobian / inertia), clean-room Ada —
--  no ABR/nengo code was copied.
--
--  Law:  τ_PD = Kp * e + Kd * edot + gravity_bias
--        e    = q_des - q
--        edot = qd_des - qd

package OSC_PD is
   pragma Pure;

   N_DOF : constant := 2;

   type Joint_Vector is array (1 .. N_DOF) of Float;

   type Gains is record
      Kp : Float := 8.0;
      Kd : Float := 2.0;
   end record;

   Default_Gains : constant Gains := (Kp => 8.0, Kd => 2.0);

   --  Zero gravity compensation by default; tests may inject a constant bias.
   Zero_Bias : constant Joint_Vector := [others => 0.0];

   --  Joint-space PD + optional constant gravity/bias vector.
   function Torque
     (Q, Qd           : Joint_Vector;
      Q_Des, Qd_Des   : Joint_Vector;
      G               : Gains := Default_Gains;
      Gravity_Bias    : Joint_Vector := Zero_Bias) return Joint_Vector;

   function Error
     (Q, Q_Des : Joint_Vector) return Joint_Vector;

   function Error_Dot
     (Qd, Qd_Des : Joint_Vector) return Joint_Vector;

   function Norm (V : Joint_Vector) return Float;

end OSC_PD;

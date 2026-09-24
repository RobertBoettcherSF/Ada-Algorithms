--  Context-sensitive adaptive residual torque (educational LMS / PES-like).
--  Paper intuition (DeWolf et al. arXiv:2007.10227 §4): adaptive term acts as
--  a *state-dependent* integrated error — unlike classical PID-I, which applies
--  the same learned offset regardless of (q, qd). Clean-room Ada; no ABR/nengo.
--
--  Features φ(q, qd): small fixed bounded basis (M = 5).
--  Weights W (N_DOF x M) updated online:
--      ΔW(i, :)  ∝  learning_rate * error(i) * φ
--  Output: τ_adapt = W * φ; total torque = τ_PD + τ_adapt.
--  Weights and per-step rates are bounded for host-sim stability.

with OSC_PD;

package Adaptive_Residual is

   N_DOF : constant := OSC_PD.N_DOF;
   M     : constant := 5;  -- feature dimension

   subtype Joint_Vector is OSC_PD.Joint_Vector;

   type Feature_Vector is array (1 .. M) of Float;
   type Weight_Matrix is array (1 .. N_DOF, 1 .. M) of Float;

   type Controller is record
      W              : Weight_Matrix := [others => [others => 0.0]];
      Learning_Rate  : Float := 0.08;
      Weight_Bound    : Float := 4.0;
      Rate_Bound      : Float := 0.05;
      Enabled        : Boolean := True;
   end record;

   function Create
     (Learning_Rate : Float := 0.08;
      Weight_Bound   : Float := 4.0;
      Rate_Bound     : Float := 0.05) return Controller;

   --  Bounded basis: [1, sat(q1), sat(q2), sat(qd1), sat(qd2)]
   function Features (Q, Qd : Joint_Vector) return Feature_Vector;

   function Torque (C : Controller; Phi : Feature_Vector) return Joint_Vector;

   --  LMS / PES-like update driven by joint tracking error e = q_des - q.
   --  Returns L2 norm of the weight update (for zero-error sanity tests).
   procedure Update
     (C     : in out Controller;
      Phi   : Feature_Vector;
      Error : Joint_Vector;
      Delta_Norm : out Float);

   function Weight_Max_Abs (C : Controller) return Float;

end Adaptive_Residual;

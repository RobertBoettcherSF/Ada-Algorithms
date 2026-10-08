package body Plant_Sim is

   function Create
     (Dt          : Float := 0.01;
      Inertia     : Joint_Vector := [1.0, 1.0];
      Disturbance : Joint_Vector := [0.0, 0.0];
      Q0          : Joint_Vector := [0.0, 0.0];
      Qd0         : Joint_Vector := [0.0, 0.0]) return Plant
   is
      P : Plant;
   begin
      P.Dt := Dt;
      P.Q := Q0;
      P.Qd := Qd0;
      P.Disturbance := Disturbance;
      for I in Joint_Vector'Range loop
         pragma Assert (Inertia (I) > 0.0);
         P.Inv_Inertia (I) := 1.0 / Inertia (I);
      end loop;
      return P;
   end Create;

   procedure Step (P : in out Plant; Tau : Joint_Vector) is
      Qdd : Float;
   begin
      for I in Joint_Vector'Range loop
         Qdd := P.Inv_Inertia (I) * (Tau (I) + P.Disturbance (I));
         P.Qd (I) := P.Qd (I) + Qdd * P.Dt;
         P.Q (I)  := P.Q (I)  + P.Qd (I) * P.Dt;
      end loop;
   end Step;

   function Position (P : Plant) return Joint_Vector is
   begin
      return P.Q;
   end Position;

   function Velocity (P : Plant) return Joint_Vector is
   begin
      return P.Qd;
   end Velocity;

end Plant_Sim;

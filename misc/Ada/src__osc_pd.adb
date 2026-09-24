with Ada.Numerics.Elementary_Functions;

package body OSC_PD is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Error
     (Q, Q_Des : Joint_Vector) return Joint_Vector
   is
      E : Joint_Vector;
   begin
      for I in Joint_Vector'Range loop
         E (I) := Q_Des (I) - Q (I);
      end loop;
      return E;
   end Error;

   function Error_Dot
     (Qd, Qd_Des : Joint_Vector) return Joint_Vector
   is
      Ed : Joint_Vector;
   begin
      for I in Joint_Vector'Range loop
         Ed (I) := Qd_Des (I) - Qd (I);
      end loop;
      return Ed;
   end Error_Dot;

   function Torque
     (Q, Qd           : Joint_Vector;
      Q_Des, Qd_Des   : Joint_Vector;
      G               : Gains := Default_Gains;
      Gravity_Bias    : Joint_Vector := Zero_Bias) return Joint_Vector
   is
      E  : constant Joint_Vector := Error (Q, Q_Des);
      Ed : constant Joint_Vector := Error_Dot (Qd, Qd_Des);
      T  : Joint_Vector;
   begin
      for I in Joint_Vector'Range loop
         T (I) := G.Kp * E (I) + G.Kd * Ed (I) + Gravity_Bias (I);
      end loop;
      return T;
   end Torque;

   function Norm (V : Joint_Vector) return Float is
      S : Float := 0.0;
   begin
      for I in Joint_Vector'Range loop
         S := S + V (I) * V (I);
      end loop;
      return Math.Sqrt (S);
   end Norm;

end OSC_PD;

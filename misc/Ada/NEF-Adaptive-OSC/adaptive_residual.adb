with Ada.Numerics.Elementary_Functions;

package body Adaptive_Residual is

   package Math renames Ada.Numerics.Elementary_Functions;

   --  Soft saturation keeps features O(1) for stability of the LMS update.
   function Sat (X : Float; Limit : Float := 1.5) return Float is
   begin
      if X > Limit then
         return Limit;
      elsif X < -Limit then
         return -Limit;
      else
         return X;
      end if;
   end Sat;

   function Create
     (Learning_Rate : Float := 0.08;
      Weight_Bound   : Float := 4.0;
      Rate_Bound     : Float := 0.05) return Controller
   is
      C : Controller;
   begin
      C.Learning_Rate := Learning_Rate;
      C.Weight_Bound   := Weight_Bound;
      C.Rate_Bound     := Rate_Bound;
      C.W             := [others => [others => 0.0]];
      C.Enabled       := True;
      return C;
   end Create;

   function Features (Q, Qd : Joint_Vector) return Feature_Vector is
      Phi : Feature_Vector;
   begin
      Phi (1) := 1.0;
      Phi (2) := Sat (Q (1));
      Phi (3) := Sat (Q (2));
      Phi (4) := Sat (Qd (1));
      Phi (5) := Sat (Qd (2));
      return Phi;
   end Features;

   function Torque (C : Controller; Phi : Feature_Vector) return Joint_Vector is
      T : Joint_Vector := [others => 0.0];
   begin
      if not C.Enabled then
         return T;
      end if;
      for I in 1 .. N_DOF loop
         for J in 1 .. M loop
            T (I) := T (I) + C.W (I, J) * Phi (J);
         end loop;
      end loop;
      return T;
   end Torque;

   function Clamp (X, Bound : Float) return Float is
   begin
      if X > Bound then
         return Bound;
      elsif X < -Bound then
         return -Bound;
      else
         return X;
      end if;
   end Clamp;

   procedure Update
     (C     : in out Controller;
      Phi   : Feature_Vector;
      Error : Joint_Vector;
      Delta_Norm : out Float)
   is
      Dw  : Float;
      Acc : Float := 0.0;
   begin
      Delta_Norm := 0.0;
      if not C.Enabled then
         return;
      end if;

      for I in 1 .. N_DOF loop
         for J in 1 .. M loop
            Dw := C.Learning_Rate * Error (I) * Phi (J);
            Dw := Clamp (Dw, C.Rate_Bound);
            C.W (I, J) := Clamp (C.W (I, J) + Dw, C.Weight_Bound);
            Acc := Acc + Dw * Dw;
         end loop;
      end loop;
      Delta_Norm := Math.Sqrt (Acc);
   end Update;

   function Weight_Max_Abs (C : Controller) return Float is
      Mabs : Float := 0.0;
   begin
      for I in 1 .. N_DOF loop
         for J in 1 .. M loop
            if abs (C.W (I, J)) > Mabs then
               Mabs := abs (C.W (I, J));
            end if;
         end loop;
      end loop;
      return Mabs;
   end Weight_Max_Abs;

end Adaptive_Residual;

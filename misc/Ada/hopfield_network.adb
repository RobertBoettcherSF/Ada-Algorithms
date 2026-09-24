with Ada.Numerics.Elementary_Functions;

package body Hopfield_Network is

   -- Uses standard Math libraries to compute the activation function
   function Math_Tanh (X : Float) return Float is
      use Ada.Numerics.Elementary_Functions;
   begin
      return Tanh (X);
   end Math_Tanh;

   -----------------------------------------------------------------------------
   -- VALIDATION HELPERS
   -----------------------------------------------------------------------------
   function Is_Valid_Bipolar (V : Discrete_Vector) return Boolean is
   begin
      for Element of V loop
         if Element /= 1 and Element /= -1 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Bipolar;

   function Is_Valid_Bipolar_Matrix (M : Discrete_Pattern_Matrix) return Boolean is
   begin
      for P in M'Range (1) loop
         for N in M'Range (2) loop
            if M (P, N) /= 1 and M (P, N) /= -1 then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Bipolar_Matrix;

   function Is_Square (W : Weight_Matrix) return Boolean is
   begin
      return W'Length (1) = W'Length (2);
   end Is_Square;

   -----------------------------------------------------------------------------
   -- DISCRETE IMPLEMENTATION
   -----------------------------------------------------------------------------
   function Train_Discrete (Patterns : Discrete_Pattern_Matrix) return Weight_Matrix is
      Num_Nodes : constant Float := Float (Patterns'Length (2));
      W         : Weight_Matrix (Patterns'Range (2), Patterns'Range (2)) := 
                    [others => [others => 0.0]];
   begin
      for P in Patterns'Range (1) loop
         for I in Patterns'Range (2) loop
            for J in Patterns'Range (2) loop
               -- Hebbian rule: W_ij = sum (x_i * x_j) / N, with no self connections
               if I /= J then
                  W (I, J) := W (I, J) + (Float (Patterns (P, I) * Patterns (P, J)) / Num_Nodes);
               end if;
            end loop;
         end loop;
      end loop;
      return W;
   end Train_Discrete;

   procedure Update_Discrete_Synchronous
     (Weights : in Weight_Matrix;
      State   : in out Discrete_Vector)
   is
      New_State : Discrete_Vector (State'Range);
      Sum       : Float;
   begin
      for I in State'Range loop
         Sum := 0.0;
         for J in State'Range loop
            Sum := Sum + Weights (I, J) * Float (State (J));
         end loop;
         
         -- Activation function for discrete bipolar networks
         if Sum >= 0.0 then
            New_State (I) := 1;
         else
            New_State (I) := -1;
         end if;
      end loop;
      State := New_State;
   end Update_Discrete_Synchronous;

   procedure Update_Discrete_Asynchronous
     (Weights : in Weight_Matrix;
      State   : in out Discrete_Vector;
      Node    : in Node_Index)
   is
      Sum : Float := 0.0;
   begin
      for J in State'Range loop
         Sum := Sum + Weights (Node, J) * Float (State (J));
      end loop;
      
      -- Update the state of only the requested node
      if Sum >= 0.0 then
         State (Node) := 1;
      else
         State (Node) := -1;
      end if;
   end Update_Discrete_Asynchronous;

   function Energy_Discrete (Weights : Weight_Matrix; State : Discrete_Vector) return Float is
      E : Float := 0.0;
   begin
      for I in State'Range loop
         for J in State'Range loop
            E := E + Weights (I, J) * Float (State (I) * State (J));
         end loop;
      end loop;
      return -0.5 * E;
   end Energy_Discrete;


   -----------------------------------------------------------------------------
   -- CONTINUOUS IMPLEMENTATION
   -----------------------------------------------------------------------------
   function Train_Continuous (Patterns : Continuous_Pattern_Matrix) return Weight_Matrix is
      Num_Nodes : constant Float := Float (Patterns'Length (2));
      W         : Weight_Matrix (Patterns'Range (2), Patterns'Range (2)) := 
                    [others => [others => 0.0]];
   begin
      for P in Patterns'Range (1) loop
         for I in Patterns'Range (2) loop
            for J in Patterns'Range (2) loop
               if I /= J then
                  W (I, J) := W (I, J) + ((Patterns (P, I) * Patterns (P, J)) / Num_Nodes);
               end if;
            end loop;
         end loop;
      end loop;
      return W;
   end Train_Continuous;

   procedure Update_Continuous_Synchronous
     (Weights : in Weight_Matrix;
      State   : in out Continuous_State;
      Dt      : in Float;
      Beta    : in Float := 1.0)
   is
      New_State : Continuous_State (State'Range);
      Sum       : Float;
   begin
      for I in State'Range loop
         Sum := 0.0;
         for J in State'Range loop
            Sum := Sum + Weights (I, J) * State (J).V;
         end loop;
         
         -- Euler integration step: u_i(t+dt) = u_i(t) + dt * (-u_i(t) + Sum_{j} w_ij V_j)
         New_State (I).U := State (I).U + Dt * (-State (I).U + Sum);
         
         -- Apply the continuous sigmoid (hyperbolic tangent) activation
         New_State (I).V := Math_Tanh (Beta * New_State (I).U);
      end loop;
      State := New_State;
   end Update_Continuous_Synchronous;

   function Energy_Continuous (Weights : Weight_Matrix; State : Continuous_State) return Float is
      E : Float := 0.0;
   begin
      for I in State'Range loop
         for J in State'Range loop
            E := E + Weights (I, J) * State (I).V * State (J).V;
         end loop;
      end loop;
      return -0.5 * E;
   end Energy_Continuous;

end Hopfield_Network;

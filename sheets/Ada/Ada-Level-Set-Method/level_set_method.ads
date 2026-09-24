-- level_set_method.ads
-- Package specification for the Level Set Method.
package Level_Set_Method is

   -- Custom types for precise floating-point operations
   type Real is new Float;
   
   -- 2D Grid for the Level Set function Phi
   type Grid_2D is array (Integer range <>, Integer range <>) of Real;
   
   -- Exceptions
   Grid_Too_Small : exception;
   Invalid_Time_Step : exception;

   -- Initializes the grid with a signed distance function for a circle.
   -- Negative inside, Positive outside, Zero on the interface.
   procedure Initialize_Circle
     (Grid   : in out Grid_2D;
      Cx, Cy : Real;
      Radius : Real);

   -- Variant 1: Basic Level Set Update (Euler method with Upwind scheme)
   -- Solves: d(Phi)/dt + F * |Grad(Phi)| = 0
   procedure Update_Basic
     (Grid : in out Grid_2D;
      dt   : Real;
      F    : Real);

   -- Variant 2: Narrow Band Method
   -- Updates only nodes where |Phi| <= Band_Width, significantly reducing computation.
   procedure Update_Narrow_Band
     (Grid       : in out Grid_2D;
      dt         : Real;
      F          : Real;
      Band_Width : Real);

   -- Variant 3: Reinitialization
   -- Solves the Sussman reinitialization equation to maintain the Signed Distance Function 
   -- property (|Grad(Phi)| = 1) without moving the zero level set.
   procedure Reinitialize
     (Grid       : in out Grid_2D;
      Iterations : Positive;
      dt         : Real);

private
   
   -- Helper functions for finite differences and gradients
   function Dx_Forward (Grid : Grid_2D; I, J : Integer) return Real;
   function Dx_Backward (Grid : Grid_2D; I, J : Integer) return Real;
   function Dy_Forward (Grid : Grid_2D; I, J : Integer) return Real;
   function Dy_Backward (Grid : Grid_2D; I, J : Integer) return Real;
   
   -- Godunov's numerical Hamiltonian for the upwind scheme
   function Upwind_Gradient (Grid : Grid_2D; I, J : Integer; F : Real) return Real;
   
   -- Sign function used for reinitialization
   function Sign0 (Value : Real) return Real;

end Level_Set_Method;

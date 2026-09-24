-- level_set_method.adb
-- Implementation of the Level Set Method algorithms.
with Ada.Numerics.Generic_Elementary_Functions;

package body Level_Set_Method is

   -- Instantiate the math functions for our custom strongly-typed Real
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   ---------------------------
   -- Initialization
   ---------------------------
   procedure Initialize_Circle
     (Grid   : in out Grid_2D;
      Cx, Cy : Real;
      Radius : Real)
   is
      Dx, Dy : Real;
   begin
      for I in Grid'Range (1) loop
         for J in Grid'Range (2) loop
            Dx := Real (I) - Cx;
            Dy := Real (J) - Cy;
            -- Signed distance: negative inside, positive outside
            Grid (I, J) := Sqrt (Dx * Dx + Dy * Dy) - Radius;
         end loop;
      end loop;
   end Initialize_Circle;

   ---------------------------
   -- Finite Differences (Neumann Boundary Conditions)
   ---------------------------
   function Dx_Forward (Grid : Grid_2D; I, J : Integer) return Real is
   begin
      if I < Grid'Last (1) then
         return Grid (I + 1, J) - Grid (I, J);
      else
         return 0.0; -- Boundary derivative is zero
      end if;
   end Dx_Forward;

   function Dx_Backward (Grid : Grid_2D; I, J : Integer) return Real is
   begin
      if I > Grid'First (1) then
         return Grid (I, J) - Grid (I - 1, J);
      else
         return 0.0;
      end if;
   end Dx_Backward;

   function Dy_Forward (Grid : Grid_2D; I, J : Integer) return Real is
   begin
      if J < Grid'Last (2) then
         return Grid (I, J + 1) - Grid (I, J);
      else
         return 0.0;
      end if;
   end Dy_Forward;

   function Dy_Backward (Grid : Grid_2D; I, J : Integer) return Real is
   begin
      if J > Grid'First (2) then
         return Grid (I, J) - Grid (I, J - 1);
      else
         return 0.0;
      end if;
   end Dy_Backward;

   ---------------------------
   -- Godunov Upwind Gradient 
   ---------------------------
   function Upwind_Gradient (Grid : Grid_2D; I, J : Integer; F : Real) return Real is
      Dxf : Real := Dx_Forward (Grid, I, J);
      Dxb : Real := Dx_Backward (Grid, I, J);
      Dyf : Real := Dy_Forward (Grid, I, J);
      Dyb : Real := Dy_Backward (Grid, I, J);
      Grad_Sq : Real;
   begin
      -- Max/Min operators for Godunov scheme based on the sign of Speed (F)
      if F > 0.0 then
         Grad_Sq := Real'Max (Dxb, 0.0)**2 + Real'Min (Dxf, 0.0)**2 +
                    Real'Max (Dyb, 0.0)**2 + Real'Min (Dyf, 0.0)**2;
      else
         Grad_Sq := Real'Min (Dxb, 0.0)**2 + Real'Max (Dxf, 0.0)**2 +
                    Real'Min (Dyb, 0.0)**2 + Real'Max (Dyf, 0.0)**2;
      end if;
      return Sqrt (Grad_Sq);
   end Upwind_Gradient;

   ---------------------------
   -- Basic Variant Update
   ---------------------------
   procedure Update_Basic
     (Grid : in out Grid_2D;
      dt   : Real;
      F    : Real)
   is
      New_Grid : Grid_2D (Grid'Range (1), Grid'Range (2));
   begin
      if Grid'Length (1) < 3 or Grid'Length (2) < 3 then
         raise Grid_Too_Small;
      end if;
      if dt < 0.0 then
         raise Invalid_Time_Step;
      end if;

      for I in Grid'Range (1) loop
         for J in Grid'Range (2) loop
            New_Grid (I, J) := Grid (I, J) - dt * F * Upwind_Gradient (Grid, I, J, F);
         end loop;
      end loop;
      Grid := New_Grid;
   end Update_Basic;

   ---------------------------
   -- Narrow Band Variant
   ---------------------------
   procedure Update_Narrow_Band
     (Grid       : in out Grid_2D;
      dt         : Real;
      F          : Real;
      Band_Width : Real)
   is
      New_Grid : Grid_2D (Grid'Range (1), Grid'Range (2));
   begin
      if Grid'Length (1) < 3 or Grid'Length (2) < 3 then
         raise Grid_Too_Small;
      end if;

      New_Grid := Grid; -- Copy initial state (outside band remains unchanged)

      for I in Grid'Range (1) loop
         for J in Grid'Range (2) loop
            if abs (Grid (I, J)) <= Band_Width then
               New_Grid (I, J) := Grid (I, J) - dt * F * Upwind_Gradient (Grid, I, J, F);
            end if;
         end loop;
      end loop;
      Grid := New_Grid;
   end Update_Narrow_Band;

   ---------------------------
   -- Reinitialization 
   ---------------------------
   function Sign0 (Value : Real) return Real is
   begin
      if Value > 0.0001 then return 1.0;
      elsif Value < -0.0001 then return -1.0;
      else return 0.0;
      end if;
   end Sign0;

   procedure Reinitialize
     (Grid       : in out Grid_2D;
      Iterations : Positive;
      dt         : Real)
   is
      New_Grid : Grid_2D (Grid'Range (1), Grid'Range (2));
      S0       : Real;
      Grad     : Real;
   begin
      for K in 1 .. Iterations loop
         New_Grid := Grid;
         for I in Grid'Range (1) loop
            for J in Grid'Range (2) loop
               S0 := Sign0 (Grid (I, J));
               -- For reinitialization, we act as if F = Sign0(Phi_0)
               Grad := Upwind_Gradient (Grid, I, J, S0);
               New_Grid (I, J) := Grid (I, J) - dt * S0 * (Grad - 1.0);
            end loop;
         end loop;
         Grid := New_Grid;
      end loop;
   end Reinitialize;

end Level_Set_Method;

-- verlet_integration.ads
-- Package specification for Verlet Integration variants.
-- Includes Basic Verlet, Velocity Verlet, and Leapfrog integration methods.

package Verlet_Integration is
   
   -- Custom type for high-precision calculations
   type Float_Type is new Long_Float;
   
   -- Vector_3D represents position, velocity, or acceleration
   type Vector_3D is record
      X : Float_Type := 0.0;
      Y : Float_Type := 0.0;
      Z : Float_Type := 0.0;
   end record;
   
   -- Exception raised when Delta Time is zero or negative
   Invalid_Delta_Time : exception;
   
   -- =========================================================================
   -- Helper Functions
   -- =========================================================================
   function "+" (Left, Right : Vector_3D) return Vector_3D;
   function "-" (Left, Right : Vector_3D) return Vector_3D;
   function "*" (Left : Vector_3D; Right : Float_Type) return Vector_3D;
   function "*" (Left : Float_Type; Right : Vector_3D) return Vector_3D;
   function "/" (Left : Vector_3D; Right : Float_Type) return Vector_3D;
   function Are_Close (Left, Right : Vector_3D; Tolerance : Float_Type := 1.0e-5) return Boolean;

   -- =========================================================================
   -- 1. Basic Verlet Integration
   -- Calculates next position using current and previous positions.
   -- Disadvantage: Does not explicitly calculate velocity.
   -- =========================================================================
   procedure Update_Basic_Verlet (
      Pos_Current : in out Vector_3D;
      Pos_Prev    : in out Vector_3D;
      Accel       : in     Vector_3D;
      DT          : in     Float_Type
   );

   -- =========================================================================
   -- 2. Velocity Verlet Integration
   -- More robust, explicitly calculates and updates velocity and position.
   -- Requires knowing the acceleration at the current and next time steps.
   -- =========================================================================
   procedure Update_Velocity_Verlet (
      Pos           : in out Vector_3D;
      Vel           : in out Vector_3D;
      Accel_Current : in     Vector_3D;
      Accel_Next    : in     Vector_3D;
      DT            : in     Float_Type
   );

   -- =========================================================================
   -- 3. Leapfrog Integration (Stormer's method variant)
   -- Position and velocity are updated at interleaved time points.
   -- Vel_Half is velocity at t - (1/2)*dt. It gets updated to t + (1/2)*dt.
   -- =========================================================================
   procedure Update_Leapfrog (
      Pos      : in out Vector_3D;
      Vel_Half : in out Vector_3D;
      Accel    : in     Vector_3D;
      DT       : in     Float_Type
   );

end Verlet_Integration;

-- verlet_integration.adb
-- Implementation of Verlet Integration algorithms and helper math.

package body Verlet_Integration is

   -- -------------------------------------------------------------------------
   -- Helper Functions Implementation
   -- -------------------------------------------------------------------------
   function "+" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X + Right.X, Y => Left.Y + Right.Y, Z => Left.Z + Right.Z);
   end "+";

   function "-" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X - Right.X, Y => Left.Y - Right.Y, Z => Left.Z - Right.Z);
   end "-";

   function "*" (Left : Vector_3D; Right : Float_Type) return Vector_3D is
   begin
      return (X => Left.X * Right, Y => Left.Y * Right, Z => Left.Z * Right);
   end "*";

   function "*" (Left : Float_Type; Right : Vector_3D) return Vector_3D is
   begin
      return Right * Left;
   end "*";

   function "/" (Left : Vector_3D; Right : Float_Type) return Vector_3D is
   begin
      if Right = 0.0 then
         raise Constraint_Error with "Vector division by zero";
      end if;
      return (X => Left.X / Right, Y => Left.Y / Right, Z => Left.Z / Right);
   end "/";

   function Are_Close (Left, Right : Vector_3D; Tolerance : Float_Type := 1.0e-5) return Boolean is
   begin
      return abs (Left.X - Right.X) <= Tolerance and then
             abs (Left.Y - Right.Y) <= Tolerance and then
             abs (Left.Z - Right.Z) <= Tolerance;
   end Are_Close;

   -- -------------------------------------------------------------------------
   -- Basic Verlet Step
   -- Formula: x(t+dt) = 2x(t) - x(t-dt) + a(t)*dt^2
   -- -------------------------------------------------------------------------
   procedure Update_Basic_Verlet (
      Pos_Current : in out Vector_3D;
      Pos_Prev    : in out Vector_3D;
      Accel       : in     Vector_3D;
      DT          : in     Float_Type
   ) is
      Temp_Pos : Vector_3D;
   begin
      if DT <= 0.0 then
         raise Invalid_Delta_Time with "Delta time must be strictly positive.";
      end if;

      Temp_Pos := Pos_Current;
      Pos_Current := (2.0 * Pos_Current) - Pos_Prev + (Accel * (DT * DT));
      Pos_Prev := Temp_Pos;
   end Update_Basic_Verlet;

   -- -------------------------------------------------------------------------
   -- Velocity Verlet Step
   -- Formula: x(t+dt) = x(t) + v(t)*dt + 0.5*a(t)*dt^2
   --          v(t+dt) = v(t) + 0.5*(a(t) + a(t+dt))*dt
   -- -------------------------------------------------------------------------
   procedure Update_Velocity_Verlet (
      Pos           : in out Vector_3D;
      Vel           : in out Vector_3D;
      Accel_Current : in     Vector_3D;
      Accel_Next    : in     Vector_3D;
      DT            : in     Float_Type
   ) is
   begin
      if DT <= 0.0 then
         raise Invalid_Delta_Time with "Delta time must be strictly positive.";
      end if;

      Pos := Pos + (Vel * DT) + (Accel_Current * (0.5 * DT * DT));
      Vel := Vel + ((Accel_Current + Accel_Next) * (0.5 * DT));
   end Update_Velocity_Verlet;

   -- -------------------------------------------------------------------------
   -- Leapfrog Integration Step
   -- Formula: v(t + dt/2) = v(t - dt/2) + a(t)*dt
   --          x(t + dt)   = x(t) + v(t + dt/2)*dt
   -- -------------------------------------------------------------------------
   procedure Update_Leapfrog (
      Pos      : in out Vector_3D;
      Vel_Half : in out Vector_3D;
      Accel    : in     Vector_3D;
      DT       : in     Float_Type
   ) is
   begin
      if DT <= 0.0 then
         raise Invalid_Delta_Time with "Delta time must be strictly positive.";
      end if;

      Vel_Half := Vel_Half + (Accel * DT);
      Pos := Pos + (Vel_Half * DT);
   end Update_Leapfrog;

end Verlet_Integration;

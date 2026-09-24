--  N_Body_Problems body — classical 2-D gravitational n-body survey.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body N_Body_Problems is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Tiny : constant Real := 1.0E-30;

   -------------------------------------------------------------------------
   -- Config
   -------------------------------------------------------------------------

   function Default_Config return NB_Config is
   begin
      return (G => 1.0, Softening => 1.0E-4);
   end Default_Config;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Hypot (X, Y : Real) return Non_Negative is
      AX : constant Real := abs (X);
      AY : constant Real := abs (Y);
      M  : Real;
   begin
      if AX > AY then
         M := AX;
      else
         M := AY;
      end if;
      if M <= Tiny then
         return 0.0;
      end if;
      declare
         SX : constant Real := X / M;
         SY : constant Real := Y / M;
      begin
         return Non_Negative (M * Math.Sqrt (SX * SX + SY * SY));
      end;
   end Hypot;

   function Soft_Denom (DX, DY, Soft_Eps : Real) return Positive_Real is
      R2 : constant Real := DX * DX + DY * DY + Soft_Eps * Soft_Eps;
      R  : Real;
      D  : Real;
   begin
      if R2 <= Tiny then
         return Positive_Real (1.0E-45);
      end if;
      R := Math.Sqrt (R2);
      D := R2 * R;  -- (r^2+eps^2)^{3/2}
      if D <= Tiny then
         return Positive_Real (1.0E-45);
      end if;
      return Positive_Real (D);
   end Soft_Denom;

   function Vec_Add (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end Vec_Add;

   function Vec_Sub (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end Vec_Sub;

   function Vec_Scale (V : Vec2; S : Real) return Vec2 is
   begin
      return (V.X * S, V.Y * S);
   end Vec_Scale;

   function Vec_Norm (V : Vec2) return Non_Negative is
   begin
      return Hypot (V.X, V.Y);
   end Vec_Norm;

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   -------------------------------------------------------------------------
   -- Pairwise force / potential
   -------------------------------------------------------------------------

   function Pair_Force
     (M1, M2      : Non_Negative;
      P1, P2      : Vec2;
      G, Soft_Eps : Non_Negative) return Vec2
   is
      DX    : constant Real := P2.X - P1.X;
      DY    : constant Real := P2.Y - P1.Y;
      Den   : constant Positive_Real := Soft_Denom (DX, DY, Soft_Eps);
      Scale : constant Real := G * M1 * M2 / Den;
   begin
      return (Scale * DX, Scale * DY);
   end Pair_Force;

   function Pair_Potential
     (M1, M2      : Non_Negative;
      P1, P2      : Vec2;
      G, Soft_Eps : Non_Negative) return Real
   is
      DX : constant Real := P2.X - P1.X;
      DY : constant Real := P2.Y - P1.Y;
      R2 : constant Real := DX * DX + DY * DY + Soft_Eps * Soft_Eps;
      R  : Real;
   begin
      if R2 <= Tiny then
         return 0.0;
      end if;
      R := Math.Sqrt (R2);
      if R <= Tiny then
         return 0.0;
      end if;
      return -G * M1 * M2 / R;
   end Pair_Potential;

   -------------------------------------------------------------------------
   -- Direct summation
   -------------------------------------------------------------------------

   procedure Forces_Direct
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Out_F  : out Force_Array)
   is
   begin
      for I in Out_F'Range loop
         Out_F (I) := (0.0, 0.0);
      end loop;
      if Count = 0 then
         return;
      end if;
      for I in 1 .. Count loop
         for J in I + 1 .. Count loop
            declare
               Fij : constant Vec2 :=
                 Pair_Force
                   (Bodies (I).Mass, Bodies (J).Mass,
                    Bodies (I).Pos, Bodies (J).Pos,
                    Config.G, Config.Softening);
            begin
               Out_F (I) := Vec_Add (Out_F (I), Fij);
               Out_F (J) := Vec_Sub (Out_F (J), Fij);
            end;
         end loop;
      end loop;
   end Forces_Direct;

   procedure Accelerations_Direct
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Out_A  : out Accel_Array)
   is
      F : Force_Array (1 .. (if Count = 0 then 1 else Body_Index (Count)));
   begin
      for I in Out_A'Range loop
         Out_A (I) := (0.0, 0.0);
      end loop;
      if Count = 0 then
         return;
      end if;
      Forces_Direct (Bodies, Count, Config, F);
      for I in 1 .. Count loop
         if Bodies (I).Mass > Tiny then
            Out_A (I) :=
              (F (I).X / Bodies (I).Mass, F (I).Y / Bodies (I).Mass);
         else
            Out_A (I) := (0.0, 0.0);
         end if;
      end loop;
   end Accelerations_Direct;

   -------------------------------------------------------------------------
   -- Energies / momentum / COM
   -------------------------------------------------------------------------

   function Kinetic_Energy
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
   is
      KE : Real := 0.0;
      V2 : Real;
   begin
      for I in 1 .. Count loop
         V2 := Bodies (I).Vel.X * Bodies (I).Vel.X
             + Bodies (I).Vel.Y * Bodies (I).Vel.Y;
         KE := KE + 0.5 * Bodies (I).Mass * V2;
      end loop;
      if KE < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (KE);
   end Kinetic_Energy;

   function Potential_Energy
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config) return Real
   is
      PE : Real := 0.0;
   begin
      for I in 1 .. Count loop
         for J in I + 1 .. Count loop
            PE := PE + Pair_Potential
              (Bodies (I).Mass, Bodies (J).Mass,
               Bodies (I).Pos, Bodies (J).Pos,
               Config.G, Config.Softening);
         end loop;
      end loop;
      return PE;
   end Potential_Energy;

   function Total_Energy
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config) return Real
   is
   begin
      return Real (Kinetic_Energy (Bodies, Count))
           + Potential_Energy (Bodies, Count, Config);
   end Total_Energy;

   function Linear_Momentum
     (Bodies : Body_Array; Count : Body_Count) return Vec2
   is
      P : Vec2 := (0.0, 0.0);
   begin
      for I in 1 .. Count loop
         P.X := P.X + Bodies (I).Mass * Bodies (I).Vel.X;
         P.Y := P.Y + Bodies (I).Mass * Bodies (I).Vel.Y;
      end loop;
      return P;
   end Linear_Momentum;

   function Total_Mass
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
   is
      M : Real := 0.0;
   begin
      for I in 1 .. Count loop
         M := M + Bodies (I).Mass;
      end loop;
      return Non_Negative (M);
   end Total_Mass;

   function Center_Of_Mass
     (Bodies : Body_Array; Count : Body_Count) return Vec2
   is
      M  : constant Non_Negative := Total_Mass (Bodies, Count);
      SX : Real := 0.0;
      SY : Real := 0.0;
   begin
      if M <= Tiny then
         raise Empty_System;
      end if;
      for I in 1 .. Count loop
         SX := SX + Bodies (I).Mass * Bodies (I).Pos.X;
         SY := SY + Bodies (I).Mass * Bodies (I).Pos.Y;
      end loop;
      return (SX / M, SY / M);
   end Center_Of_Mass;

   function Angular_Momentum_Z
     (Bodies : Body_Array; Count : Body_Count) return Real
   is
      L : Real := 0.0;
   begin
      for I in 1 .. Count loop
         L := L + Bodies (I).Mass
           * (Bodies (I).Pos.X * Bodies (I).Vel.Y
              - Bodies (I).Pos.Y * Bodies (I).Vel.X);
      end loop;
      return L;
   end Angular_Momentum_Z;

   -------------------------------------------------------------------------
   -- Two-body
   -------------------------------------------------------------------------

   function Reduced_Mass (M1, M2 : Non_Negative) return Non_Negative is
      S : constant Real := M1 + M2;
   begin
      if S <= Tiny then
         return 0.0;
      end if;
      return Non_Negative (M1 * M2 / S);
   end Reduced_Mass;

   function Circular_Orbit_Speed
     (M_Total : Non_Negative;
      A       : Positive_Real;
      G       : Non_Negative := 1.0) return Non_Negative
   is
      Prod : constant Real := G * M_Total / A;
   begin
      if Prod <= Tiny then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Prod));
   end Circular_Orbit_Speed;

   function Circular_Orbit_Period
     (M_Total : Non_Negative;
      A       : Positive_Real;
      G       : Non_Negative := 1.0) return Positive_Real
   is
      A3 : constant Real := Real (A) * Real (A) * Real (A);
      GM : constant Real := G * M_Total;
   begin
      return Positive_Real (Two_Pi * Math.Sqrt (A3 / GM));
   end Circular_Orbit_Period;

   function Circular_Orbit_Energy
     (M1, M2 : Non_Negative;
      A      : Positive_Real;
      G      : Non_Negative := 1.0) return Real
   is
   begin
      return -G * M1 * M2 / (2.0 * A);
   end Circular_Orbit_Energy;

   procedure Make_Circular_Binary
     (M1, M2       : Non_Negative;
      Separation   : Positive_Real;
      G            : Non_Negative;
      Bodies       : out Body_Array;
      Count        : out Body_Count)
   is
      Mtot : constant Real := M1 + M2;
      R1   : constant Real := Real (Separation) * M2 / Mtot;
      R2   : constant Real := Real (Separation) * M1 / Mtot;
      Vrel : constant Non_Negative :=
        Circular_Orbit_Speed (Non_Negative (Mtot), Separation, G);
      V1   : constant Real := Real (Vrel) * M2 / Mtot;
      V2   : constant Real := Real (Vrel) * M1 / Mtot;
   begin
      for I in Bodies'Range loop
         Bodies (I) := (Mass => 0.0, Pos => (0.0, 0.0), Vel => (0.0, 0.0));
      end loop;
      Bodies (1) :=
        (Mass => M1,
         Pos  => (-R1, 0.0),
         Vel  => (0.0, V1));
      Bodies (2) :=
        (Mass => M2,
         Pos  => (R2, 0.0),
         Vel  => (0.0, -V2));
      Count := 2;
   end Make_Circular_Binary;

   -------------------------------------------------------------------------
   -- Integrators
   -------------------------------------------------------------------------

   procedure Euler_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Dt     : Real)
   is
      A : Accel_Array (1 .. (if Count = 0 then 1 else Body_Index (Count)));
   begin
      if Count = 0 or else Dt = 0.0 then
         return;
      end if;
      Accelerations_Direct (Bodies, Count, Config, A);
      for I in 1 .. Count loop
         Bodies (I).Pos.X := Bodies (I).Pos.X + Bodies (I).Vel.X * Dt;
         Bodies (I).Pos.Y := Bodies (I).Pos.Y + Bodies (I).Vel.Y * Dt;
         Bodies (I).Vel.X := Bodies (I).Vel.X + A (I).X * Dt;
         Bodies (I).Vel.Y := Bodies (I).Vel.Y + A (I).Y * Dt;
      end loop;
   end Euler_Step;

   procedure Leapfrog_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Dt     : Real)
   is
      A : Accel_Array (1 .. (if Count = 0 then 1 else Body_Index (Count)));
      Half : constant Real := 0.5 * Dt;
   begin
      if Count = 0 or else Dt = 0.0 then
         return;
      end if;
      Accelerations_Direct (Bodies, Count, Config, A);
      for I in 1 .. Count loop
         Bodies (I).Vel.X := Bodies (I).Vel.X + A (I).X * Half;
         Bodies (I).Vel.Y := Bodies (I).Vel.Y + A (I).Y * Half;
         Bodies (I).Pos.X := Bodies (I).Pos.X + Bodies (I).Vel.X * Dt;
         Bodies (I).Pos.Y := Bodies (I).Pos.Y + Bodies (I).Vel.Y * Dt;
      end loop;
      Accelerations_Direct (Bodies, Count, Config, A);
      for I in 1 .. Count loop
         Bodies (I).Vel.X := Bodies (I).Vel.X + A (I).X * Half;
         Bodies (I).Vel.Y := Bodies (I).Vel.Y + A (I).Y * Half;
      end loop;
   end Leapfrog_Step;

   -------------------------------------------------------------------------
   -- Few-body / monopole note
   -------------------------------------------------------------------------

   function Force_Sum
     (Forces : Force_Array; Count : Body_Count) return Vec2
   is
      S : Vec2 := (0.0, 0.0);
   begin
      for I in 1 .. Count loop
         S.X := S.X + Forces (I).X;
         S.Y := S.Y + Forces (I).Y;
      end loop;
      return S;
   end Force_Sum;

   function Force_Approx_Monopole_Cluster
     (Target_Mass  : Non_Negative;
      Target_Pos   : Vec2;
      Cluster_Mass : Non_Negative;
      Cluster_COM  : Vec2;
      G, Soft_Eps  : Non_Negative) return Vec2
   is
   begin
      return Pair_Force
        (Target_Mass, Cluster_Mass, Target_Pos, Cluster_COM, G, Soft_Eps);
   end Force_Approx_Monopole_Cluster;

   function Accept_Monopole
     (Cluster_Size : Non_Negative;
      Dist         : Non_Negative;
      Theta        : Non_Negative) return Boolean
   is
   begin
      if Dist <= Tiny or else Theta <= Tiny then
         return False;
      end if;
      return Cluster_Size / Dist < Theta;
   end Accept_Monopole;

end N_Body_Problems;

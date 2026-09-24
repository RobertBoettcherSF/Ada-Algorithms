--  Swarm_Intelligence body — educational survey sketches.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Swarm_Intelligence
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Sqrt_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Float (X)));
   end Sqrt_R;

   ---------------------------------------------------------------------------
   -- Near / Config
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vec2; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Vec_Near;

   function Make_Config
     (Separation_W : Non_Negative  := 1.5;
      Alignment_W  : Non_Negative  := 1.0;
      Cohesion_W   : Non_Negative  := 1.0;
      Perception   : Positive_Real := 5.0;
      Max_Speed    : Positive_Real := 2.0;
      Max_Force    : Positive_Real := 0.1;
      Dt           : Positive_Real := 1.0) return Config is
   begin
      return
        (Separation_W => Separation_W,
         Alignment_W  => Alignment_W,
         Cohesion_W   => Cohesion_W,
         Perception   => Perception,
         Max_Speed    => Max_Speed,
         Max_Force    => Max_Force,
         Dt           => Dt);
   end Make_Config;

   ---------------------------------------------------------------------------
   -- Vector helpers
   ---------------------------------------------------------------------------

   function Zero_Vec return Vec2 is
   begin
      return (0.0, 0.0);
   end Zero_Vec;

   function Add (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end Add;

   function Sub (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end Sub;

   function Scale (C : Real; V : Vec2) return Vec2 is
   begin
      return (C * V.X, C * V.Y);
   end Scale;

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function Norm2 (V : Vec2) return Non_Negative is
      S : constant Real := Dot (V, V);
   begin
      if S <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Sqrt_R (S));
   end Norm2;

   function Distance (A, B : Vec2) return Non_Negative is
   begin
      return Norm2 (Sub (A, B));
   end Distance;

   function Normalize (V : Vec2) return Vec2 is
      N : constant Non_Negative := Norm2 (V);
   begin
      if N <= Epsilon_Tol then
         return Zero_Vec;
      end if;
      return Scale (1.0 / Real (N), V);
   end Normalize;

   function Limit (V : Vec2; Max_Mag : Non_Negative) return Vec2 is
      N : constant Non_Negative := Norm2 (V);
   begin
      if Max_Mag <= 0.0 or else N <= Max_Mag then
         return V;
      end if;
      return Scale (Real (Max_Mag) / Real (N), V);
   end Limit;

   ---------------------------------------------------------------------------
   -- PSO-lite
   ---------------------------------------------------------------------------

   function PSO_Velocity_Step
     (V, X, P, G : Vec2;
      Omega, C1, C2, R1, R2 : Real) return Vec2
   is
      Cognitive : constant Vec2 :=
        Scale (C1 * R1, Sub (P, X));
      Social    : constant Vec2 :=
        Scale (C2 * R2, Sub (G, X));
   begin
      return Add (Add (Scale (Omega, V), Cognitive), Social);
   end PSO_Velocity_Step;

   function PSO_Position_Step (X, V : Vec2) return Vec2 is
   begin
      return Add (X, V);
   end PSO_Position_Step;

   ---------------------------------------------------------------------------
   -- ACO pheromone helpers
   ---------------------------------------------------------------------------

   function Evaporate_Pheromone
     (Tau : Non_Negative; Rho : Unit_Interval) return Non_Negative
   is
      Factor : constant Real := 1.0 - Real (Rho);
      Next   : constant Real := Factor * Real (Tau);
   begin
      if Next <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Next);
   end Evaporate_Pheromone;

   function Deposit_Pheromone
     (Tau : Non_Negative; Amount : Non_Negative) return Non_Negative
   is
      Next : constant Real := Real (Tau) + Real (Amount);
   begin
      if Next <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Next);
   end Deposit_Pheromone;

   ---------------------------------------------------------------------------
   -- Neighbourhood scan helpers (skip Index)
   ---------------------------------------------------------------------------

   function Separation_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
   is
      Steer : Vec2 := Zero_Vec;
      Count : Natural := 0;
      Diff  : Vec2;
      Dist  : Non_Negative;
      Self  : constant Boid := F (Index);
   begin
      for I in F'Range loop
         if I /= Index then
            Dist := Distance (Self.Pos, F (I).Pos);
            if Dist > 0.0 and then Dist < Perception then
               Diff := Sub (Self.Pos, F (I).Pos);
               --  Weight by 1/d² (stronger when closer).
               Steer := Add (Steer, Scale (1.0 / (Real (Dist) * Real (Dist)),
                                           Diff));
               Count := Count + 1;
            end if;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      Steer := Scale (1.0 / Real (Count), Steer);
      return Normalize (Steer);
   end Separation_At;

   function Alignment_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
   is
      Avg   : Vec2 := Zero_Vec;
      Count : Natural := 0;
      Dist  : Non_Negative;
      Self  : constant Boid := F (Index);
   begin
      for I in F'Range loop
         if I /= Index then
            Dist := Distance (Self.Pos, F (I).Pos);
            if Dist > 0.0 and then Dist < Perception then
               Avg := Add (Avg, F (I).Vel);
               Count := Count + 1;
            end if;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      Avg := Scale (1.0 / Real (Count), Avg);
      return Normalize (Avg);
   end Alignment_At;

   function Cohesion_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
   is
      Centre : Vec2 := Zero_Vec;
      Count  : Natural := 0;
      Dist   : Non_Negative;
      Self   : constant Boid := F (Index);
      Desired : Vec2;
   begin
      for I in F'Range loop
         if I /= Index then
            Dist := Distance (Self.Pos, F (I).Pos);
            if Dist > 0.0 and then Dist < Perception then
               Centre := Add (Centre, F (I).Pos);
               Count := Count + 1;
            end if;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      Centre := Scale (1.0 / Real (Count), Centre);
      Desired := Sub (Centre, Self.Pos);
      return Normalize (Desired);
   end Cohesion_At;

   --  Self/Peers wrappers: treat Self as unmatched by position; scan all.
   --  Prefer *_At for flock simulations (index-exact skip).

   function Separation
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
   is
      Steer : Vec2 := Zero_Vec;
      Count : Natural := 0;
      Diff  : Vec2;
      Dist  : Non_Negative;
   begin
      for I in Peers'Range loop
         Dist := Distance (Self.Pos, Peers (I).Pos);
         if Dist > Epsilon_Tol and then Dist < Perception then
            Diff := Sub (Self.Pos, Peers (I).Pos);
            Steer := Add (Steer,
                          Scale (1.0 / (Real (Dist) * Real (Dist)), Diff));
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      return Normalize (Scale (1.0 / Real (Count), Steer));
   end Separation;

   function Alignment
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
   is
      Avg   : Vec2 := Zero_Vec;
      Count : Natural := 0;
      Dist  : Non_Negative;
   begin
      for I in Peers'Range loop
         Dist := Distance (Self.Pos, Peers (I).Pos);
         if Dist > Epsilon_Tol and then Dist < Perception then
            Avg := Add (Avg, Peers (I).Vel);
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      return Normalize (Scale (1.0 / Real (Count), Avg));
   end Alignment;

   function Cohesion
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
   is
      Centre : Vec2 := Zero_Vec;
      Count  : Natural := 0;
      Dist   : Non_Negative;
   begin
      for I in Peers'Range loop
         Dist := Distance (Self.Pos, Peers (I).Pos);
         if Dist > Epsilon_Tol and then Dist < Perception then
            Centre := Add (Centre, Peers (I).Pos);
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         return Zero_Vec;
      end if;
      Centre := Scale (1.0 / Real (Count), Centre);
      return Normalize (Sub (Centre, Self.Pos));
   end Cohesion;

   function Combined_Steer
     (F : Flock; Index : Boid_Index; Cfg : Config) return Vec2
   is
      Sep : constant Vec2 :=
        Limit (Scale (Real (Cfg.Separation_W),
                      Separation_At (F, Index, Cfg.Perception)),
               Cfg.Max_Force);
      Ali : constant Vec2 :=
        Limit (Scale (Real (Cfg.Alignment_W),
                      Alignment_At (F, Index, Cfg.Perception)),
               Cfg.Max_Force);
      Coh : constant Vec2 :=
        Limit (Scale (Real (Cfg.Cohesion_W),
                      Cohesion_At (F, Index, Cfg.Perception)),
               Cfg.Max_Force);
   begin
      return Add (Add (Sep, Ali), Coh);
   end Combined_Steer;

   ---------------------------------------------------------------------------
   -- Integration
   ---------------------------------------------------------------------------

   procedure Step_Boid
     (F     : in out Flock;
      Index : Boid_Index;
      Cfg   : Config)
   is
      Acc : constant Vec2 := Combined_Steer (F, Index, Cfg);
      New_V : Vec2;
   begin
      New_V := Limit (Add (F (Index).Vel, Scale (Real (Cfg.Dt), Acc)),
                      Cfg.Max_Speed);
      F (Index).Vel := New_V;
      F (Index).Pos := Add (F (Index).Pos, Scale (Real (Cfg.Dt), New_V));
   end Step_Boid;

   procedure Step_Flock (F : in out Flock; Cfg : Config) is
      Accels : array (F'Range) of Vec2 := [others => Zero_Vec];
      New_V  : Vec2;
   begin
      for I in F'Range loop
         Accels (I) := Combined_Steer (F, I, Cfg);
      end loop;
      for I in F'Range loop
         New_V := Limit (Add (F (I).Vel, Scale (Real (Cfg.Dt), Accels (I))),
                         Cfg.Max_Speed);
         F (I).Vel := New_V;
         F (I).Pos := Add (F (I).Pos, Scale (Real (Cfg.Dt), New_V));
      end loop;
   end Step_Flock;

   function Mean_Speed (F : Flock) return Non_Negative is
      Sum : Real := 0.0;
   begin
      for I in F'Range loop
         Sum := Sum + Real (Norm2 (F (I).Vel));
      end loop;
      return Non_Negative (Sum / Real (F'Length));
   end Mean_Speed;

   function Mean_Nearest_Spacing (F : Flock) return Non_Negative is
      Sum   : Real := 0.0;
      Best  : Non_Negative;
      Dist  : Non_Negative;
      First : Boolean;
   begin
      if F'Length = 1 then
         return 0.0;
      end if;
      for I in F'Range loop
         First := True;
         Best := 0.0;
         for J in F'Range loop
            if J /= I then
               Dist := Distance (F (I).Pos, F (J).Pos);
               if First or else Dist < Best then
                  Best := Dist;
                  First := False;
               end if;
            end if;
         end loop;
         Sum := Sum + Real (Best);
      end loop;
      return Non_Negative (Sum / Real (F'Length));
   end Mean_Nearest_Spacing;

   function Simulate_Flock
     (Initial : Flock;
      Cfg     : Config;
      Steps   : Natural) return Result
   is
      F : Flock (Initial'Range) := Initial;
      R : Result;
   begin
      for S in 1 .. Steps loop
         Step_Flock (F, Cfg);
      end loop;
      R.Mean_Speed   := Mean_Speed (F);
      R.Mean_Spacing := Mean_Nearest_Spacing (F);
      R.Steps        := Steps;
      R.Size         := F'Length;
      return R;
   end Simulate_Flock;

   function Make_Grid_Flock
     (Rows, Cols : Positive;
      Spacing    : Positive_Real := 1.0;
      Speed      : Real := 0.0) return Flock
   is
      N : constant Positive := Rows * Cols;
      F : Flock (1 .. N);
      K : Positive := 1;
   begin
      if N > Max_Boids then
         raise Invalid_Argument;
      end if;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            F (K).Pos :=
              (Real (C - 1) * Real (Spacing),
               Real (R - 1) * Real (Spacing));
            F (K).Vel := (Speed, 0.0);
            K := K + 1;
         end loop;
      end loop;
      return F;
   end Make_Grid_Flock;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Particle_Swarm =>
            return (Kind => Particle_Swarm,
                    Implemented       => False,
                    Stochastic        => True,
                    Continuous_Agents => True);
         when Ant_Colony =>
            return (Kind => Ant_Colony,
                    Implemented       => False,
                    Stochastic        => True,
                    Continuous_Agents => False);
         when Bees =>
            return (Kind => Bees,
                    Implemented       => False,
                    Stochastic        => True,
                    Continuous_Agents => True);
         when Harmony_Search =>
            return (Kind => Harmony_Search,
                    Implemented       => False,
                    Stochastic        => True,
                    Continuous_Agents => True);
         when Flocking_Boids =>
            return (Kind => Flocking_Boids,
                    Implemented       => True,
                    Stochastic        => False,
                    Continuous_Agents => True);
      end case;
   end Classify_Method;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Particle_Swarm  => return "Particle Swarm Optimization";
         when Ant_Colony      => return "Ant Colony Optimization";
         when Bees            => return "Bees Algorithm";
         when Harmony_Search  => return "Harmony Search";
         when Flocking_Boids  => return "Flocking (Boids)";
      end case;
   end Method_Name;

   function Method_Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Implemented;
   end Method_Implemented;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

end Swarm_Intelligence;

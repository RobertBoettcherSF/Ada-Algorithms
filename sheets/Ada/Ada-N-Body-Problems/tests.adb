--  Standalone test suite for N_Body_Problems (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with N_Body_Problems; use N_Body_Problems;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Vec_Near (A, B : Vec2; Tol : Real := 1.0E-6) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Vec_Near;

   type U32 is mod 2**32;
   RNG : U32 := 1;

   procedure Seed (S : Natural) is
   begin
      RNG := U32 (S);
      if RNG = 0 then
         RNG := 1;
      end if;
   end Seed;

   function Next_Unit return Real is
   begin
      RNG := RNG * 1_664_525 + 1_013_904_223;
      return Real (RNG rem 10_000) / 10_000.0;
   end Next_Unit;

   function Cfg
     (G    : Real := 1.0;
      Soft : Real := 1.0E-4) return NB_Config
   is
   begin
      return (G => Non_Negative (G), Softening => Non_Negative (Soft));
   end Cfg;

begin
   Put_Line ("N_Body_Problems test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Hypot / Vec / Soft_Denom");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (Approx (Hypot (3.0, 4.0), 5.0, 1.0E-12), "Hypot 3-4-5");
   Check (Approx (Hypot (0.0, 0.0), 0.0), "Hypot origin");
   Check (Approx (Hypot (5.0, 0.0), 5.0, 1.0E-12), "Hypot x-axis");
   Check (Approx (Hypot (0.0, 7.0), 7.0, 1.0E-12), "Hypot y-axis");
   Check (Approx (Vec_Norm ((3.0, 4.0)), 5.0, 1.0E-12), "Vec_Norm 3-4-5");
   Check (Approx (Dot ((1.0, 2.0), (3.0, 4.0)), 11.0, 1.0E-12), "Dot product");
   declare
      S : constant Vec2 := Vec_Add ((1.0, 2.0), (3.0, 4.0));
      D : constant Vec2 := Vec_Sub ((5.0, 5.0), (1.0, 2.0));
      K : constant Vec2 := Vec_Scale ((2.0, -1.0), 3.0);
   begin
      Check (Vec_Near (S, (4.0, 6.0)), "Vec_Add");
      Check (Vec_Near (D, (4.0, 3.0)), "Vec_Sub");
      Check (Vec_Near (K, (6.0, -3.0)), "Vec_Scale");
   end;
   Check (Soft_Denom (0.0, 0.0, 1.0E-3) > 0.0, "Soft_Denom coincidence > 0");
   Check (Soft_Denom (3.0, 4.0, 0.0) > 0.0, "Soft_Denom eps=0 positive");
   Check (Default_Config.G = 1.0, "Default_Config G");
   Check (Default_Config.Softening > 0.0, "Default_Config Softening > 0");

   ---------------------------------------------------------------------
   Section ("2. Pair_Force / Pair_Potential");
   ---------------------------------------------------------------------
   declare
      F : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.0);
   begin
      Check (Approx (F.X, 1.0, 1.0E-9), "Pair_Force unit X");
      Check (Approx (F.Y, 0.0, 1.0E-9), "Pair_Force unit Y");
   end;
   declare
      F : constant Vec2 :=
        Pair_Force (2.0, 3.0, (0.0, 0.0), (0.0, 2.0), 1.0, 0.0);
      --  F = 6 / 4 * (0,1) = (0, 1.5)
   begin
      Check (Approx (F.X, 0.0, 1.0E-9), "Pair_Force vertical X=0");
      Check (Approx (F.Y, 1.5, 1.0E-9), "Pair_Force vertical Y=1.5");
   end;
   declare
      F12 : constant Vec2 :=
        Pair_Force (1.0, 2.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.0);
      F21 : constant Vec2 :=
        Pair_Force (2.0, 1.0, (1.0, 0.0), (0.0, 0.0), 1.0, 0.0);
   begin
      Check (Approx (F12.X, -F21.X, 1.0E-12), "Newton 3rd Fx");
      Check (Approx (F12.Y, -F21.Y, 1.0E-12), "Newton 3rd Fy");
   end;
   declare
      F : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (0.0, 0.0), 1.0, 1.0E-2);
   begin
      Check (Approx (F.X, 0.0, 1.0E-12), "soft coincidence Fx=0");
      Check (Approx (F.Y, 0.0, 1.0E-12), "soft coincidence Fy=0");
   end;
   declare
      PE : constant Real :=
        Pair_Potential (1.0, 1.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.0);
   begin
      Check (Approx (PE, -1.0, 1.0E-12), "Pair_Potential unit = -1");
   end;
   declare
      PE0 : constant Real :=
        Pair_Potential (2.0, 3.0, (0.0, 0.0), (0.0, 2.0), 1.0, 0.0);
   begin
      Check (Approx (PE0, -3.0, 1.0E-12), "Pair_Potential -G m1 m2 / r");
   end;
   declare
      Fsoft : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.5);
      Fhard : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.0);
   begin
      Check (abs (Fsoft.X) < abs (Fhard.X), "softening weakens force");
   end;

   ---------------------------------------------------------------------
   Section ("3. Empty / single body / Forces_Direct");
   ---------------------------------------------------------------------
   declare
      Empty : Body_Array (1 .. 1);
      F     : Force_Array (1 .. 1);
      A     : Accel_Array (1 .. 1);
      C     : constant NB_Config := Cfg;
   begin
      Empty (1) := (1.0, (0.0, 0.0), (0.0, 0.0));
      Forces_Direct (Empty, 0, C, F);
      Check (True, "Forces_Direct empty no crash");
      Accelerations_Direct (Empty, 0, C, A);
      Check (True, "Accelerations_Direct empty no crash");
      Check (Approx (Kinetic_Energy (Empty, 0), 0.0), "KE empty = 0");
      Check (Approx (Potential_Energy (Empty, 0, C), 0.0), "PE empty = 0");
      Check (Approx (Total_Energy (Empty, 0, C), 0.0), "E empty = 0");
      Check (Vec_Near (Linear_Momentum (Empty, 0), (0.0, 0.0)), "P empty = 0");
      Check (Approx (Total_Mass (Empty, 0), 0.0), "Mass empty = 0");
   end;
   declare
      One : Body_Array (1 .. 1);
      F   : Force_Array (1 .. 1);
      A   : Accel_Array (1 .. 1);
      C   : constant NB_Config := Cfg;
   begin
      One (1) := (Mass => 5.0, Pos => (1.0, 2.0), Vel => (3.0, 4.0));
      Forces_Direct (One, 1, C, F);
      Check (Vec_Near (F (1), (0.0, 0.0)), "single body force = 0");
      Accelerations_Direct (One, 1, C, A);
      Check (Vec_Near (A (1), (0.0, 0.0)), "single body accel = 0");
      Check (Approx (Kinetic_Energy (One, 1), 0.5 * 5.0 * 25.0, 1.0E-9),
             "single KE = 62.5");
      Check (Approx (Potential_Energy (One, 1, C), 0.0), "single PE = 0");
      Check (Approx (Total_Mass (One, 1), 5.0), "single mass");
      Check (Vec_Near (Center_Of_Mass (One, 1), (1.0, 2.0)), "single COM");
      Check (Vec_Near (Linear_Momentum (One, 1), (15.0, 20.0)), "single P");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-body forces equal-opposite / COM / energies");
   ---------------------------------------------------------------------
   declare
      B : Body_Array (1 .. 2);
      F : Force_Array (1 .. 2);
      A : Accel_Array (1 .. 2);
      C : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      S : Vec2;
   begin
      B (1) := (1.0, (0.0, 0.0), (0.0, 0.0));
      B (2) := (1.0, (1.0, 0.0), (0.0, 0.0));
      Forces_Direct (B, 2, C, F);
      Check (Approx (F (1).X, 1.0, 1.0E-9), "two-body F1x = +1");
      Check (Approx (F (2).X, -1.0, 1.0E-9), "two-body F2x = -1");
      Check (Approx (F (1).Y, 0.0, 1.0E-9), "two-body F1y = 0");
      Check (Approx (F (2).Y, 0.0, 1.0E-9), "two-body F2y = 0");
      S := Force_Sum (F, 2);
      Check (Vec_Near (S, (0.0, 0.0), 1.0E-12), "net force ~ 0");
      Accelerations_Direct (B, 2, C, A);
      Check (Approx (A (1).X, 1.0, 1.0E-9), "a1 = F/m");
      Check (Approx (A (2).X, -1.0, 1.0E-9), "a2 = F/m");
      Check (Approx (Potential_Energy (B, 2, C), -1.0, 1.0E-9), "PE = -1");
      Check (Approx (Total_Energy (B, 2, C), -1.0, 1.0E-9), "E = PE (rest)");
      Check (Vec_Near (Center_Of_Mass (B, 2), (0.5, 0.0)), "COM midpoint");
   end;
   declare
      B : Body_Array (1 .. 2);
      F : Force_Array (1 .. 2);
      C : constant NB_Config := Cfg (G => 2.0, Soft => 0.0);
   begin
      B (1) := (2.0, (0.0, 0.0), (0.0, 0.0));
      B (2) := (3.0, (0.0, 4.0), (0.0, 0.0));
      --  F = G*6 / 16 * (0,1) = 12/16 = 0.75 in +Y on body 1
      Forces_Direct (B, 2, C, F);
      Check (Approx (F (1).Y, 0.75, 1.0E-9), "scaled G force Y");
      Check (Approx (F (2).Y, -0.75, 1.0E-9), "scaled G force opposite");
      Check (Approx (Total_Mass (B, 2), 5.0), "total mass 5");
      Check (Vec_Near (Center_Of_Mass (B, 2), (0.0, 2.4), 1.0E-9),
             "COM mass-weighted");
   end;

   ---------------------------------------------------------------------
   Section ("5. Two-body circular orbit helpers");
   ---------------------------------------------------------------------
   Check (Approx (Reduced_Mass (2.0, 2.0), 1.0, 1.0E-12), "μ equal masses");
   Check (Approx (Reduced_Mass (1.0, 3.0), 0.75, 1.0E-12), "μ 1+3");
   Check (Approx (Reduced_Mass (0.0, 0.0), 0.0), "μ both zero");
   Check (Approx (Reduced_Mass (5.0, 0.0), 0.0), "μ one zero");
   declare
      V : constant Non_Negative := Circular_Orbit_Speed (1.0, 1.0, 1.0);
      T : constant Positive_Real := Circular_Orbit_Period (1.0, 1.0, 1.0);
      E : constant Real := Circular_Orbit_Energy (1.0, 1.0, 1.0, 1.0);
   begin
      Check (Approx (Real (V), 1.0, 1.0E-12), "v_circ = 1 for GM=a=1");
      Check (Approx (Real (T), Two_Pi, 1.0E-9), "T = 2π for GM=a=1");
      Check (Approx (E, -0.5, 1.0E-12), "E_circ = -0.5");
   end;
   declare
      --  Kepler a=4, M=1, G=1: sqrt(a^3/GM)=sqrt(64)=8; T=2π*8; v=sqrt(1/4)=0.5
      T : constant Positive_Real := Circular_Orbit_Period (1.0, 4.0, 1.0);
      V : constant Non_Negative := Circular_Orbit_Speed (1.0, 4.0, 1.0);
   begin
      Check (Approx (Real (T), Two_Pi * 8.0, 1.0E-8), "period a=4 exact");
      Check (Approx (Real (V), 0.5, 1.0E-12), "speed a=4 = 0.5");
   end;
   declare
      Bodies : Body_Array (1 .. 2);
      Count  : Body_Count;
      C      : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      F      : Force_Array (1 .. 2);
      COM    : Vec2;
      P      : Vec2;
      R1     : Real;
      V1     : Real;
      Fcent  : Real;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, Bodies, Count);
      Check (Count = 2, "binary count=2");
      Check (Approx (Bodies (1).Mass, 1.0), "binary m1");
      Check (Approx (Bodies (2).Mass, 1.0), "binary m2");
      Check (Approx (Bodies (1).Pos.X, -0.5, 1.0E-12), "binary x1=-a/2");
      Check (Approx (Bodies (2).Pos.X, 0.5, 1.0E-12), "binary x2=+a/2");
      COM := Center_Of_Mass (Bodies, Count);
      Check (Vec_Near (COM, (0.0, 0.0), 1.0E-12), "binary COM at origin");
      P := Linear_Momentum (Bodies, Count);
      Check (Vec_Near (P, (0.0, 0.0), 1.0E-12), "binary total P=0");
      Forces_Direct (Bodies, Count, C, F);
      -- Centripetal balance: |F| = m v^2 / r
      R1 := abs (Bodies (1).Pos.X);
      V1 := abs (Bodies (1).Vel.Y);
      Fcent := Bodies (1).Mass * V1 * V1 / R1;
      Check (Approx (abs (F (1).X), Fcent, 1.0E-9),
             "centripetal force balance");
      Check (Approx (Total_Energy (Bodies, Count, C),
                     Circular_Orbit_Energy (1.0, 1.0, 1.0, 1.0), 1.0E-9),
             "binary E matches circular formula");
      Check (Approx (abs (Angular_Momentum_Z (Bodies, Count)),
                     2.0 * 1.0 * R1 * V1, 1.0E-9),
             "binary |Lz| = 2 m r v");
      Check (abs (Angular_Momentum_Z (Bodies, Count)) > 0.0,
             "binary Lz nonzero");
   end;
   declare
      Bodies : Body_Array (1 .. 2);
      Count  : Body_Count;
      COM    : Vec2;
   begin
      Make_Circular_Binary (1.0, 3.0, 2.0, 1.0, Bodies, Count);
      COM := Center_Of_Mass (Bodies, Count);
      Check (Vec_Near (COM, (0.0, 0.0), 1.0E-12), "unequal binary COM=0");
      Check (Approx (Bodies (1).Pos.X, -1.5, 1.0E-12),
             "unequal: light farther");
      Check (Approx (Bodies (2).Pos.X, 0.5, 1.0E-12),
             "unequal: heavy closer");
   end;

   ---------------------------------------------------------------------
   Section ("6. Leapfrog vs Euler energy on circular binary");
   ---------------------------------------------------------------------
   declare
      BL : Body_Array (1 .. 2);
      BE : Body_Array (1 .. 2);
      Count : Body_Count;
      C : constant NB_Config := Cfg (G => 1.0, Soft => 1.0E-8);
      Tper : Positive_Real;
      Dt   : Real;
      Steps : constant Positive := 200;
      E0L, EL, E0E, EE : Real;
      Drift_L, Drift_E : Real;
      N_Periods : constant := 2;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, BL, Count);
      BE := BL;
      Tper := Circular_Orbit_Period (2.0, 1.0, 1.0);
      Dt := Real (Tper) * Real (N_Periods) / Real (Steps);
      E0L := Total_Energy (BL, Count, C);
      E0E := Total_Energy (BE, Count, C);
      for K in 1 .. Steps loop
         Leapfrog_Step (BL, Count, C, Dt);
      end loop;
      for K in 1 .. Steps loop
         Euler_Step (BE, Count, C, Dt);
      end loop;
      EL := Total_Energy (BL, Count, C);
      EE := Total_Energy (BE, Count, C);
      Drift_L := abs (EL - E0L);
      Drift_E := abs (EE - E0E);
      Check (Drift_L < 5.0E-3, "leapfrog energy drift small over 2 periods");
      Check (Drift_E > Drift_L, "Euler drifts more than leapfrog");
      Check (Near (E0L, Circular_Orbit_Energy (1.0, 1.0, 1.0, 1.0), 1.0E-6),
             "initial E ~ circular");
      -- Momentum conserved by both (no external force)
      Check (Vec_Near (Linear_Momentum (BL, Count), (0.0, 0.0), 1.0E-8),
             "leapfrog momentum conserved");
      Check (Vec_Near (Linear_Momentum (BE, Count), (0.0, 0.0), 1.0E-8),
             "Euler momentum conserved");
      Check (Vec_Near (Center_Of_Mass (BL, Count), (0.0, 0.0), 1.0E-6),
             "leapfrog COM stays origin");
   end;
   declare
      B : Body_Array (1 .. 2);
      Count : Body_Count;
      C : constant NB_Config := Cfg;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, B, Count);
      Euler_Step (B, Count, C, 0.0);
      Check (Approx (B (1).Pos.X, -0.5, 1.0E-12), "Euler dt=0 no-op");
      Leapfrog_Step (B, Count, C, 0.0);
      Check (Approx (B (1).Pos.X, -0.5, 1.0E-12), "Leapfrog dt=0 no-op");
      Euler_Step (B, 0, C, 0.1);
      Check (True, "Euler empty count no-op");
      Leapfrog_Step (B, 0, C, 0.1);
      Check (True, "Leapfrog empty count no-op");
   end;

   ---------------------------------------------------------------------
   Section ("7. Few-body: equal-mass triangle / collinear");
   ---------------------------------------------------------------------
   declare
      B : Body_Array (1 .. 3);
      F : Force_Array (1 .. 3);
      C : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      S : Vec2;
      -- Equilateral triangle side=1, equal mass=1
      H : constant Real := 0.8660254037844386;  -- sqrt(3)/2
   begin
      B (1) := (1.0, (0.0, 0.0), (0.0, 0.0));
      B (2) := (1.0, (1.0, 0.0), (0.0, 0.0));
      B (3) := (1.0, (0.5, H), (0.0, 0.0));
      Forces_Direct (B, 3, C, F);
      S := Force_Sum (F, 3);
      Check (Vec_Near (S, (0.0, 0.0), 1.0E-9), "triangle net force ~0");
      Check (Approx (Total_Mass (B, 3), 3.0), "triangle mass 3");
      Check (Vec_Near (Center_Of_Mass (B, 3), (0.5, H / 3.0), 1.0E-9),
             "triangle COM");
      -- Each pair force magnitude G m m / r^2 = 1
      Check (Approx (Potential_Energy (B, 3, C), -3.0, 1.0E-9),
             "triangle PE = -3 (3 pairs)");
   end;
   declare
      B : Body_Array (1 .. 3);
      F : Force_Array (1 .. 3);
      C : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      S : Vec2;
   begin
      -- Collinear: m at -1, 2m at 0, m at +1  (central config style)
      B (1) := (1.0, (-1.0, 0.0), (0.0, 0.0));
      B (2) := (2.0, (0.0, 0.0), (0.0, 0.0));
      B (3) := (1.0, (1.0, 0.0), (0.0, 0.0));
      Forces_Direct (B, 3, C, F);
      S := Force_Sum (F, 3);
      Check (Vec_Near (S, (0.0, 0.0), 1.0E-12), "collinear net force ~0");
      Check (Approx (F (2).X, 0.0, 1.0E-12), "central body Fx~0 by symmetry");
      Check (Approx (F (1).X, -F (3).X, 1.0E-12), "outer forces opposite");
      Check (Vec_Near (Center_Of_Mass (B, 3), (0.0, 0.0), 1.0E-12),
             "collinear COM at 0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Multi-body force antisymmetry F_ij = -F_ji");
   ---------------------------------------------------------------------
   declare
      N : constant Body_Count := 8;
      B : Body_Array (1 .. N);
      F : Force_Array (1 .. N);
      C : constant NB_Config := Cfg (G => 1.0, Soft => 1.0E-3);
      S : Vec2;
      OK : Boolean := True;
   begin
      Seed (42);
      for I in 1 .. N loop
         B (I).Mass := 0.5 + Next_Unit;
         B (I).Pos.X := Next_Unit * 2.0;
         B (I).Pos.Y := Next_Unit * 2.0;
         B (I).Vel := (0.0, 0.0);
      end loop;
      Forces_Direct (B, N, C, F);
      S := Force_Sum (F, N);
      Check (Vec_Near (S, (0.0, 0.0), 1.0E-10), "random net force ~0");
      -- Pairwise check via recomputing Pair_Force
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            declare
               Fij : constant Vec2 :=
                 Pair_Force
                   (B (I).Mass, B (J).Mass, B (I).Pos, B (J).Pos,
                    C.G, C.Softening);
               Fji : constant Vec2 :=
                 Pair_Force
                   (B (J).Mass, B (I).Mass, B (J).Pos, B (I).Pos,
                    C.G, C.Softening);
            begin
               if not Vec_Near (Fij, Vec_Scale (Fji, -1.0), 1.0E-10) then
                  OK := False;
               end if;
            end;
         end loop;
      end loop;
      Check (OK, "all pairs F_ij = -F_ji");
      Check (Approx (Kinetic_Energy (B, N), 0.0), "random at rest KE=0");
      Check (Potential_Energy (B, N, C) < 0.0, "attractive PE < 0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Softening behaviour");
   ---------------------------------------------------------------------
   declare
      B : Body_Array (1 .. 2);
      F0, Fs : Force_Array (1 .. 2);
      C0 : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      Cs : constant NB_Config := Cfg (G => 1.0, Soft => 0.5);
   begin
      B (1) := (1.0, (0.0, 0.0), (0.0, 0.0));
      B (2) := (1.0, (0.1, 0.0), (0.0, 0.0));
      Forces_Direct (B, 2, C0, F0);
      Forces_Direct (B, 2, Cs, Fs);
      Check (abs (Fs (1).X) < abs (F0 (1).X), "softening reduces close force");
      Check (Potential_Energy (B, 2, Cs) > Potential_Energy (B, 2, C0),
             "softened PE less negative");
   end;

   ---------------------------------------------------------------------
   Section ("10. Monopole cluster approx / Accept_Monopole");
   ---------------------------------------------------------------------
   Check (Accept_Monopole (0.1, 1.0, 0.5), "s/d=0.1 < 0.5 accept");
   Check (not Accept_Monopole (1.0, 1.0, 0.5), "s/d=1 reject");
   Check (not Accept_Monopole (0.5, 1.0, 0.5), "s/d=0.5 reject");
   Check (Accept_Monopole (0.49, 1.0, 0.5), "s/d=0.49 accept");
   Check (not Accept_Monopole (1.0, 0.0, 0.5), "Dist=0 reject");
   Check (not Accept_Monopole (0.1, 1.0, 0.0), "Theta=0 reject");
   Check (Accept_Monopole (0.0, 10.0, 0.5), "zero-size accept");
   declare
      -- Far cluster of two unit masses at (10,0) and (10.1,0): COM≈(10.05,0)
      -- Target unit mass at origin; compare monopole vs exact sum
      Fmono : constant Vec2 :=
        Force_Approx_Monopole_Cluster
          (1.0, (0.0, 0.0), 2.0, (10.05, 0.0), 1.0, 0.0);
      F1 : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (10.0, 0.0), 1.0, 0.0);
      F2 : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (10.1, 0.0), 1.0, 0.0);
      Fex : constant Vec2 := Vec_Add (F1, F2);
   begin
      Check (Approx (Fmono.X, Fex.X, 1.0E-3), "monopole ~ exact far Fx");
      Check (Approx (Fmono.Y, 0.0, 1.0E-12), "monopole Fy=0");
      Check (Approx (Fex.Y, 0.0, 1.0E-12), "exact Fy=0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Integration steps move bodies / multi-step");
   ---------------------------------------------------------------------
   declare
      B : Body_Array (1 .. 2);
      Count : Body_Count;
      C : constant NB_Config := Cfg (G => 1.0, Soft => 1.0E-6);
      X0 : Real;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, B, Count);
      X0 := B (1).Pos.X;
      Leapfrog_Step (B, Count, C, 0.01);
      Check (abs (B (1).Pos.X - X0) > 1.0E-8, "leapfrog moves body");
      Check (abs (B (1).Pos.Y) > 1.0E-8, "leapfrog develops Y");
   end;
   declare
      B : Body_Array (1 .. 2);
      Count : Body_Count;
      C : constant NB_Config := Cfg (G => 1.0, Soft => 1.0E-6);
      E0, E1 : Real;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, B, Count);
      E0 := Total_Energy (B, Count, C);
      for K in 1 .. 50 loop
         Leapfrog_Step (B, Count, C, 0.02);
      end loop;
      E1 := Total_Energy (B, Count, C);
      Check (abs (E1 - E0) < 1.0E-2, "50 leapfrog steps energy bound");
      Check (Vec_Near (Linear_Momentum (B, Count), (0.0, 0.0), 1.0E-8),
             "50 steps P conserved");
   end;
   declare
      B : Body_Array (1 .. 2);
      Count : Body_Count;
      C : constant NB_Config := Cfg;
      Sep0, Sep1 : Real;
   begin
      Make_Circular_Binary (1.0, 1.0, 1.0, 1.0, B, Count);
      Sep0 := Hypot (B (2).Pos.X - B (1).Pos.X, B (2).Pos.Y - B (1).Pos.Y);
      for K in 1 .. 100 loop
         Leapfrog_Step (B, Count, C, Real (Circular_Orbit_Period (2.0, 1.0, 1.0)) / 100.0);
      end loop;
      Sep1 := Hypot (B (2).Pos.X - B (1).Pos.X, B (2).Pos.Y - B (1).Pos.Y);
      Check (Approx (Sep1, Sep0, 5.0E-2), "one period: separation ~stable");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra API / edge checks");
   ---------------------------------------------------------------------
   declare
      B : Body_Array (1 .. 2);
      Raised : Boolean := False;
   begin
      B (1) := (0.0, (0.0, 0.0), (0.0, 0.0));
      B (2) := (0.0, (1.0, 0.0), (0.0, 0.0));
      begin
         declare
            Unused : constant Vec2 := Center_Of_Mass (B, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_System =>
            Raised := True;
      end;
      Check (Raised, "COM raises Empty_System for zero mass");
   end;
   Check (Approx (Circular_Orbit_Speed (0.0, 1.0, 1.0), 0.0), "v=0 if M=0");
   Check (Approx (Circular_Orbit_Energy (0.0, 1.0, 1.0, 1.0), 0.0),
          "E=0 if m1=0");
   declare
      B : Body_Array (1 .. 4);
      F : Force_Array (1 .. 4);
      C : constant NB_Config := Cfg (Soft => 0.01);
   begin
      for I in 1 .. 4 loop
         B (I) := (1.0, (Real (I), 0.0), (0.1 * Real (I), 0.0));
      end loop;
      Forces_Direct (B, 4, C, F);
      Check (Vec_Near (Force_Sum (F, 4), (0.0, 0.0), 1.0E-10),
             "4-body net force 0");
      Check (Kinetic_Energy (B, 4) > 0.0, "4-body KE > 0");
      Check (Total_Energy (B, 4, C) = Total_Energy (B, 4, C), "E finite");
      Check (Angular_Momentum_Z (B, 4) = Angular_Momentum_Z (B, 4),
             "Lz finite");
   end;
   -- Period / speed consistency: v = 2π a / T for relative circular orbit
   declare
      A : constant Positive_Real := 2.0;
      M : constant Non_Negative := 3.0;
      G : constant Non_Negative := 1.0;
      V : constant Non_Negative := Circular_Orbit_Speed (M, A, G);
      T : constant Positive_Real := Circular_Orbit_Period (M, A, G);
   begin
      Check (Approx (Real (V), Two_Pi * Real (A) / Real (T), 1.0E-9),
             "v = 2π a / T");
      Check (Approx (Real (V) * Real (V), G * M / A, 1.0E-12),
             "v² = GM/a");
   end;
   -- Multiple leapfrog vs one big Euler drift comparison already done;
   -- add more Near / config checks
   Check (Near (0.0, 0.0), "Near zeros");
   Check (not Near (0.0, 1.0E-3, 1.0E-6), "Near rejects");
   Check (Cfg (2.0, 0.01).G = 2.0, "Cfg G set");
   Check (Cfg (2.0, 0.01).Softening = 0.01, "Cfg Soft set");

   -- Unequal circular energy vs direct Total_Energy
   declare
      Bodies : Body_Array (1 .. 2);
      Count  : Body_Count;
      C      : constant NB_Config := Cfg (G => 1.0, Soft => 0.0);
      Eform, Edir : Real;
   begin
      Make_Circular_Binary (1.0, 2.0, 3.0, 1.0, Bodies, Count);
      Eform := Circular_Orbit_Energy (1.0, 2.0, 3.0, 1.0);
      Edir  := Total_Energy (Bodies, Count, C);
      Check (Approx (Eform, Edir, 1.0E-9), "unequal circular E match");
      Check (Approx (Eform, -1.0 * 2.0 / (2.0 * 3.0), 1.0E-12),
             "E = -G m1 m2 /(2a)");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("========================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

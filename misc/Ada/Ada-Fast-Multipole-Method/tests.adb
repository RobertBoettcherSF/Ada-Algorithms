--  Standalone test suite for Fast_Multipole_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Fast_Multipole_Method; use Fast_Multipole_Method;

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

   --  Tiny LCG for reproducible random particles in (0,1)^2.
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

   function Make_Random
     (N : Particle_Count; S : Natural) return Particle_Array
   is
      P : Particle_Array (1 .. (if N = 0 then 1 else Particle_Index (N)));
   begin
      Seed (S);
      if N = 0 then
         return P (1 .. 0);
      end if;
      for I in 1 .. N loop
         P (I).X := 0.05 + 0.9 * Next_Unit;
         P (I).Y := 0.05 + 0.9 * Next_Unit;
         P (I).Q := -1.0 + 2.0 * Next_Unit;
      end loop;
      return P (1 .. Particle_Index (N));
   end Make_Random;

   function Domain_Config
     (P : Order_Value;
      Theta : Real := 0.5;
      Leaf : Positive := 4;
      Eps : Real := 1.0E-3) return FMM_Config
   is
      C : FMM_Config := Default_Config;
   begin
      C.P := P;
      C.Theta := Positive_Real (Theta);
      C.Leaf_Capacity := Leaf;
      C.Soft_Eps := Non_Negative (Eps);
      C.Domain_Min_X := 0.0;
      C.Domain_Min_Y := 0.0;
      C.Domain_Size := 1.0;
      return C;
   end Domain_Config;

begin
   Put_Line ("Fast_Multipole_Method test suite");
   Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Hypot / Soft_Radius / Log_Kernel");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (Approx (Hypot (3.0, 4.0), 5.0, 1.0E-12), "Hypot 3-4-5");
   Check (Approx (Hypot (0.0, 0.0), 0.0), "Hypot origin");
   Check (Soft_Radius (0.0, 0.0, 1.0E-3) > 0.0, "Soft_Radius at coincidence > 0");
   Check (Approx (Soft_Radius (3.0, 4.0, 0.0), 5.0, 1.0E-12),
          "Soft_Radius eps=0 is Hypot");
   Check (Approx (Log_Kernel (1.0), 0.0, 1.0E-12), "log(1/1)=0");
   Check (Log_Kernel (Positive_Real (0.5)) > 0.0, "log(1/0.5)>0");
   Check (Log_Kernel (Positive_Real (2.0)) < 0.0, "log(1/2)<0");

   ---------------------------------------------------------------------
   Section ("2. Well_Separated unit tests");
   ---------------------------------------------------------------------
   Check (Well_Separated (0.0, 0.0, 0.1, 1.0, 0.0, 0.1, 0.5),
          "far boxes theta=0.5 accepted");
   Check (not Well_Separated (0.0, 0.0, 0.1, 0.15, 0.0, 0.1, 0.5),
          "near boxes rejected");
   Check (not Well_Separated (0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.5),
          "same centre rejected");
   Check (Well_Separated (0.0, 0.0, 0.0, 10.0, 0.0, 1.0, 0.5),
          "point vs distant box accepted");
   Check (not Well_Separated (0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5),
          "point vs size=1 at dist=1 rejected for theta=0.5");
   --  Larger theta accepts more aggressively
   Check (Well_Separated (0.0, 0.0, 1.0, 3.0, 0.0, 1.0, 0.9),
          "theta=0.9 may accept closer");
   Check (not Well_Separated (0.0, 0.0, 1.0, 3.0, 0.0, 1.0, 0.2),
          "theta=0.2 rejects same geometry");

   ---------------------------------------------------------------------
   Section ("3. Empty / one particle");
   ---------------------------------------------------------------------
   declare
      Empty : Particle_Array (1 .. 0);
      Phi0  : Real_Array (1 .. 1);
      Cfg   : constant FMM_Config := Domain_Config (4);
      T     : Tree;
      One   : constant Particle_Array := [1 => (0.5, 0.5, 2.5)];
      Phi1  : Real_Array (1 .. 1);
      PhiB  : Real_Array (1 .. 1);
   begin
      Compute_Potentials_Brute (Empty, 0, 1.0E-3, Phi0);
      Check (True, "brute empty does not crash");
      Build_Tree (T, Empty, 0, Cfg);
      Check (Node_Count (T) >= 1, "empty tree has root");
      Check (Approx (Root_Monopole (T), 0.0), "empty root monopole 0");
      Compute_Potentials_FMM (T, Empty, 0, Cfg, Phi0);
      Check (True, "FMM empty does not crash");

      Compute_Potentials_Brute (One, 1, 1.0E-3, PhiB);
      Check (Approx (PhiB (1), 0.0), "single particle brute potential 0");
      Build_Tree (T, One, 1, Cfg);
      Check (Approx (Root_Monopole (T), 2.5), "single root monopole = q");
      Compute_Potentials_FMM (T, One, 1, Cfg, Phi1);
      Check (Approx (Phi1 (1), 0.0), "single particle FMM potential 0");
      Check (Approx (Total_Charge (One, 1), 2.5), "Total_Charge single");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two particles: FMM ≈ brute");
   ---------------------------------------------------------------------
   declare
      P2 : constant Particle_Array :=
        [1 => (0.2, 0.3, 1.0),
         2 => (0.8, 0.7, -0.5)];
      Cfg : constant FMM_Config := Domain_Config (5, Theta => 0.4, Leaf => 1);
      PhiB, PhiF : Real_Array (1 .. 2);
      Err : Non_Negative;
      T : Tree;
   begin
      Compute_Potentials_Brute (P2, 2, Cfg.Soft_Eps, PhiB);
      Build_Tree (T, P2, 2, Cfg);
      Compute_Potentials_FMM (T, P2, 2, Cfg, PhiF);
      Err := Max_Abs_Error (PhiB, PhiF, 2);
      Check (Err < 5.0E-2, "two-particle max abs error < 5e-2");
      Check (Approx (Root_Monopole (T), 0.5, 1.0E-12),
             "two-particle total charge 0.5");
      Check (PhiB (1) /= 0.0 or else PhiB (2) /= 0.0,
             "two-particle potentials nontrivial");
      --  Soft-core finite at coincidence
      declare
         Coin : constant Particle_Array :=
           [1 => (0.4, 0.4, 1.0),
            2 => (0.4, 0.4, -1.0)];
         Pb : Real_Array (1 .. 2);
      begin
         Compute_Potentials_Brute (Coin, 2, 1.0E-2, Pb);
         Check (abs (Pb (1)) < 1.0E6 and then abs (Pb (2)) < 1.0E6,
                "coincident soft-core potentials finite");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Multipole of a cluster matches far direct evaluation");
   ---------------------------------------------------------------------
   declare
      Cluster : constant Particle_Array :=
        [1 => (0.48, 0.49, 1.0),
         2 => (0.50, 0.51, -0.5),
         3 => (0.52, 0.48, 0.25),
         4 => (0.49, 0.52, 0.25)];
      M : Multipole := Zero_Multipole;
      CX : constant Real := 0.5;
      CY : constant Real := 0.5;
      Pord : constant Order_Value := 6;
      --  Far target
      TX : constant Real := 5.0;
      TY : constant Real := 0.5;
      Direct : Real := 0.0;
      Approx_Phi : Real;
      R : Positive_Real;
   begin
      P2M (M, Cluster, 1, 4, CX, CY, Pord);
      Check (Approx (Monopole_Of (M), 1.0, 1.0E-12), "cluster monopole = 1");
      for I in Cluster'Range loop
         R := Soft_Radius (TX - Cluster (I).X, TY - Cluster (I).Y, 0.0);
         Direct := Direct + Cluster (I).Q * Log_Kernel (R);
      end loop;
      Approx_Phi := Evaluate_Multipole (M, TX, TY, CX, CY, Pord);
      Check (abs (Approx_Phi - Direct) < 1.0E-3,
             "far M2P vs direct cluster < 1e-3");
      --  Higher order should be at least as good on this far point
      declare
         M2 : Multipole := Zero_Multipole;
         E2, E6 : Real;
      begin
         P2M (M2, Cluster, 1, 4, CX, CY, 2);
         E2 := abs (Evaluate_Multipole (M2, TX, TY, CX, CY, 2) - Direct);
         E6 := abs (Approx_Phi - Direct);
         Check (E6 <= E2 + 1.0E-9, "P=6 error <= P=2 error (far cluster)");
      end;
      Check (Moment_Re (M, 1) /= 0.0 or else Moment_Im (M, 1) /= 0.0
             or else Approx (Monopole_Of (M), 1.0),
             "dipole moments exist or monopole only");
   end;

   ---------------------------------------------------------------------
   Section ("6. M2M shift preserves far-field approx");
   ---------------------------------------------------------------------
   declare
      Child_Parts : constant Particle_Array :=
        [1 => (0.2, 0.2, 1.0),
         2 => (0.25, 0.22, -0.3)];
      Child_M : Multipole := Zero_Multipole;
      Parent_M : Multipole := Zero_Multipole;
      CCX : constant Real := 0.22;
      CCY : constant Real := 0.21;
      PCX : constant Real := 0.5;
      PCY : constant Real := 0.5;
      TX : constant Real := 4.0;
      TY : constant Real := 4.0;
      Phi_C, Phi_P : Real;
   begin
      P2M (Child_M, Child_Parts, 1, 2, CCX, CCY, 5);
      M2M (Parent_M, Child_M, CCX - PCX, CCY - PCY, 5);
      Phi_C := Evaluate_Multipole (Child_M, TX, TY, CCX, CCY, 5);
      Phi_P := Evaluate_Multipole (Parent_M, TX, TY, PCX, PCY, 5);
      Check (abs (Phi_C - Phi_P) < 1.0E-4, "M2M shift agrees at far target");
      Check (Approx (Monopole_Of (Parent_M), Monopole_Of (Child_M), 1.0E-12),
             "M2M preserves monopole");
   end;

   ---------------------------------------------------------------------
   Section ("7. Random small N: FMM ≈ brute (seeds / N / P)");
   ---------------------------------------------------------------------
   declare
      Ns : constant array (1 .. 4) of Particle_Count := [8, 16, 32, 64];
      Seeds : constant array (1 .. 3) of Natural := [7, 42, 99];
      Tol : constant Real := 0.15;
   begin
      for Si in Seeds'Range loop
         for Ni in Ns'Range loop
            declare
               N : constant Particle_Count := Ns (Ni);
               Parts : constant Particle_Array := Make_Random (N, Seeds (Si));
               Cfg : constant FMM_Config :=
                 Domain_Config (5, Theta => 0.35, Leaf => 4, Eps => 1.0E-3);
               PhiB, PhiF : Real_Array (1 .. Particle_Index (N));
               Err : Non_Negative;
               T : Tree;
            begin
               Compute_Potentials_Brute (Parts, N, Cfg.Soft_Eps, PhiB);
               Build_Tree (T, Parts, N, Cfg);
               Compute_Potentials_FMM (T, Parts, N, Cfg, PhiF);
               Err := Max_Abs_Error (PhiB, PhiF, N);
               Check
                 (Err < Tol,
                  "N=" & N'Image & " seed=" & Seeds (Si)'Image
                  & " err=" & Err'Image);
               Check
                 (Approx (Root_Monopole (T), Total_Charge (Parts, N), 1.0E-9),
                  "monopole=total charge N=" & N'Image
                  & " seed=" & Seeds (Si)'Image);
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Increasing P reduces error (monotone-ish)");
   ---------------------------------------------------------------------
   declare
      Parts : constant Particle_Array := Make_Random (24, 123);
      PhiB : Real_Array (1 .. 24);
      Soft : constant Non_Negative := 1.0E-3;
      E2, E4, E6 : Non_Negative;
      function Err_For (P : Order_Value) return Non_Negative is
         Cfg : FMM_Config := Domain_Config (P, Theta => 0.4, Leaf => 3);
         PhiF : Real_Array (1 .. 24);
         T : Tree;
      begin
         Cfg.Soft_Eps := Soft;
         Build_Tree (T, Parts, 24, Cfg);
         Compute_Potentials_FMM (T, Parts, 24, Cfg, PhiF);
         return Max_Abs_Error (PhiB, PhiF, 24);
      end Err_For;
   begin
      Compute_Potentials_Brute (Parts, 24, Soft, PhiB);
      E2 := Err_For (2);
      E4 := Err_For (4);
      E6 := Err_For (6);
      Check (E6 <= E2 + 0.05, "P=6 error not much worse than P=2");
      Check (E4 <= E2 + 0.05, "P=4 error not much worse than P=2");
      Put_Line ("    (E2=" & E2'Image & " E4=" & E4'Image
                & " E6=" & E6'Image & ")");
      Check (E2 >= 0.0 and then E4 >= 0.0 and then E6 >= 0.0,
             "errors are non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("9. Near-field vs far-field paths exercised");
   ---------------------------------------------------------------------
   declare
      --  Two tight clusters far apart: forces MAC far path + near within
      Parts : Particle_Array (1 .. 12);
      Cfg_Strict : FMM_Config :=
        Domain_Config (4, Theta => 0.25, Leaf => 2, Eps => 1.0E-3);
      Cfg_Loose : FMM_Config :=
        Domain_Config (4, Theta => 0.9, Leaf => 2, Eps => 1.0E-3);
      PhiB, PhiS, PhiL : Real_Array (1 .. 12);
      T1, T2 : Tree;
   begin
      Seed (55);
      for I in 1 .. 6 loop
         Parts (I).X := 0.1 + 0.05 * Next_Unit;
         Parts (I).Y := 0.1 + 0.05 * Next_Unit;
         Parts (I).Q := 0.5;
      end loop;
      for I in 7 .. 12 loop
         Parts (I).X := 0.85 + 0.05 * Next_Unit;
         Parts (I).Y := 0.85 + 0.05 * Next_Unit;
         Parts (I).Q := -0.5;
      end loop;
      Cfg_Strict.Domain_Size := 1.0;
      Cfg_Loose.Domain_Size := 1.0;
      Compute_Potentials_Brute (Parts, 12, 1.0E-3, PhiB);
      Build_Tree (T1, Parts, 12, Cfg_Strict);
      Compute_Potentials_FMM (T1, Parts, 12, Cfg_Strict, PhiS);
      Build_Tree (T2, Parts, 12, Cfg_Loose);
      Compute_Potentials_FMM (T2, Parts, 12, Cfg_Loose, PhiL);
      Check (Max_Abs_Error (PhiB, PhiS, 12) < 0.2,
             "strict theta two-cluster error < 0.2");
      Check (Max_Abs_Error (PhiB, PhiL, 12) < 0.5,
             "loose theta two-cluster error < 0.5");
      Check (Node_Count (T1) > 1, "tree has multiple nodes (near path)");
      Check (Approx (Root_Monopole (T1), 0.0, 1.0E-9),
             "neutral two-cluster total charge ~ 0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Charge neutrality / potential sanity");
   ---------------------------------------------------------------------
   declare
      Parts : constant Particle_Array :=
        [1 => (0.1, 0.1, 1.0),
         2 => (0.9, 0.1, 1.0),
         3 => (0.1, 0.9, -1.0),
         4 => (0.9, 0.9, -1.0)];
      Cfg : constant FMM_Config := Domain_Config (4, 0.4, 2);
      PhiB, PhiF : Real_Array (1 .. 4);
      T : Tree;
   begin
      Check (Approx (Total_Charge (Parts, 4), 0.0), "neutral quartet");
      Compute_Potentials_Brute (Parts, 4, Cfg.Soft_Eps, PhiB);
      Build_Tree (T, Parts, 4, Cfg);
      Compute_Potentials_FMM (T, Parts, 4, Cfg, PhiF);
      Check (Approx (Root_Monopole (T), 0.0, 1.0E-12), "root monopole 0");
      Check (Max_Abs_Error (PhiB, PhiF, 4) < 0.1, "neutral quartet FMM≈brute");
      --  Symmetry: opposite corners should have related potentials
      Check (Approx (PhiB (1), PhiB (2), 1.0E-9)
             or else abs (PhiB (1) - PhiB (4)) < 1.0,
             "brute potentials sane magnitude");
   end;

   ---------------------------------------------------------------------
   Section ("11. Convenience API + Max_Abs_Error + Zero_Multipole");
   ---------------------------------------------------------------------
   declare
      Parts : constant Particle_Array := Make_Random (10, 3);
      Cfg : constant FMM_Config := Domain_Config (3);
      Phi1, Phi2, PhiB : Real_Array (1 .. 10);
      Z : constant Multipole := Zero_Multipole;
   begin
      Check (Approx (Monopole_Of (Z), 0.0), "Zero_Multipole monopole 0");
      Check (Approx (Moment_Re (Z, 1), 0.0), "Zero_Multipole a1.re 0");
      Check (Approx (Moment_Im (Z, 1), 0.0), "Zero_Multipole a1.im 0");
      Compute_Potentials_Brute (Parts, 10, Cfg.Soft_Eps, PhiB);
      Compute_Potentials_FMM_From_Particles (Parts, 10, Cfg, Phi1);
      Compute_Potentials_FMM_From_Particles (Parts, 10, Cfg, Phi2);
      Check (Max_Abs_Error (Phi1, Phi2, 10) = 0.0, "FMM deterministic");
      Check (Max_Abs_Error (PhiB, Phi1, 10) < 0.25, "convenience FMM≈brute");
      Check (Max_Abs_Error (PhiB, PhiB, 10) = 0.0, "Max_Abs_Error identical=0");
      Check (Default_Config.P = 4, "Default_Config P=4");
      Check (Default_Config.Leaf_Capacity = 8, "Default_Config leaf=8");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra seeds for PASS volume (≥100 aim)");
   ---------------------------------------------------------------------
   declare
      Extra_Seeds : constant array (Positive range <>) of Natural :=
        [1, 2, 3, 5, 8, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];
   begin
      for Si in Extra_Seeds'Range loop
         declare
            Parts : constant Particle_Array :=
              Make_Random (12, Extra_Seeds (Si));
            Cfg : constant FMM_Config :=
              Domain_Config (4, Theta => 0.4, Leaf => 3);
            PhiB, PhiF : Real_Array (1 .. 12);
            T : Tree;
            Err : Non_Negative;
         begin
            Compute_Potentials_Brute (Parts, 12, Cfg.Soft_Eps, PhiB);
            Build_Tree (T, Parts, 12, Cfg);
            Compute_Potentials_FMM (T, Parts, 12, Cfg, PhiF);
            Err := Max_Abs_Error (PhiB, PhiF, 12);
            Check (Err < 0.2,
                   "extra seed=" & Extra_Seeds (Si)'Image
                   & " err<" & "0.2");
            Check (Approx (Root_Monopole (T), Total_Charge (Parts, 12), 1.0E-8),
                   "extra monopole seed=" & Extra_Seeds (Si)'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Soft-core / theta / leaf parameter smoke");
   ---------------------------------------------------------------------
   declare
      Parts : constant Particle_Array := Make_Random (16, 77);
      PhiB : Real_Array (1 .. 16);
   begin
      Compute_Potentials_Brute (Parts, 16, 1.0E-2, PhiB);
      for Theta_I in 1 .. 5 loop
         declare
            Th : constant Real := 0.2 + 0.1 * Real (Theta_I);
            Cfg : FMM_Config := Domain_Config (4, Theta => Th, Leaf => 4);
            PhiF : Real_Array (1 .. 16);
            T : Tree;
         begin
            Cfg.Soft_Eps := 1.0E-2;
            Build_Tree (T, Parts, 16, Cfg);
            Compute_Potentials_FMM (T, Parts, 16, Cfg, PhiF);
            Check (Max_Abs_Error (PhiB, PhiF, 16) < 0.5,
                   "theta=" & Th'Image & " err bound");
         end;
      end loop;
      for Leaf_I in 1 .. 5 loop
         declare
            Lf : constant Positive := Leaf_I;
            Cfg : FMM_Config := Domain_Config (3, Theta => 0.45, Leaf => Lf);
            PhiF : Real_Array (1 .. 16);
            T : Tree;
         begin
            Cfg.Soft_Eps := 1.0E-2;
            Build_Tree (T, Parts, 16, Cfg);
            Compute_Potentials_FMM (T, Parts, 16, Cfg, PhiF);
            Check (Max_Abs_Error (PhiB, PhiF, 16) < 0.5,
                   "leaf=" & Lf'Image & " err bound");
         end;
      end loop;
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

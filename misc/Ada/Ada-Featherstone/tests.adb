--  Standalone test suite for Featherstone (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Featherstone; use Featherstone;

procedure Tests is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   Pi : constant Real := Real (Ada.Numerics.Pi);

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

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Slice_Near
     (A, B : Real_Array;
      N    : Positive;
      Tol  : Real := 1.0E-4) return Boolean
   is
   begin
      for I in 1 .. N loop
         if abs (A (A'First + I - 1) - B (B'First + I - 1)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Slice_Near;

   function Zeros (N : Positive) return Real_Array is
   begin
      return [for K in 1 .. N => 0.0];
   end Zeros;

begin
   Put_Line ("Featherstone planar ABA / RNEA test suite");
   Put_Line ("==========================================");

   ---------------------------------------------------------------------
   Section ("1. Helpers / Near / Rot / Cross");
   ---------------------------------------------------------------------
   declare
      V : constant Vec2 := Rot (Pi / 2.0, (1.0, 0.0));
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near soft tol");
      Check (Approx (Cross_Z ((1.0, 0.0), (0.0, 1.0)), 1.0), "Cross_Z e1×e2");
      Check (Approx (Cross_Z ((1.0, 2.0), (3.0, 4.0)), -2.0), "Cross_Z 1,2×3,4");
      Check (Approx (V.X, 0.0, 1.0E-12), "Rot90 X");
      Check (Approx (V.Y, 1.0, 1.0E-12), "Rot90 Y");
      Check (Approx (Mag ((3.0, 4.0)), 5.0), "Mag 3-4-5");
      Check (Near_Vec ((1.0, 2.0), (1.0, 2.0)), "Near_Vec equal");
      Check (not Near_Vec ((0.0, 0.0), (1.0, 0.0)), "Near_Vec far");
   end;

   ---------------------------------------------------------------------
   Section ("2. Chain construction / accessors");
   ---------------------------------------------------------------------
   declare
      C : Chain := Create (3);
      L : constant Link :=
        (Mass => 2.0, COM => (0.4, 0.0), I_COM => 0.1, Distal => (0.8, 0.0));
   begin
      Check (N_Links (C) = 3, "Create N=3");
      Check (Approx (Gravity (C).Y, -9.81), "Default gravity Y");
      Set_Link (C, 2, L);
      Check (Approx (Get_Link (C, 2).Mass, 2.0), "Set/Get link mass");
      Check (Approx (Get_Link (C, 2).I_COM, 0.1), "Set/Get I_COM");
      Set_Gravity (C, (0.0, -10.0));
      Check (Approx (Gravity (C).Y, -10.0), "Set_Gravity");
      Set_Q (C, [0.1, 0.2, 0.3]);
      Set_Qd (C, [1.0, -1.0, 0.5]);
      Set_Qdd (C, [0.0, 0.0, 0.0]);
      Set_Tau (C, [0.0, 0.0, 0.0]);
      Check (Approx (Get_Q (C, 2), 0.2), "Get_Q");
      Check (Approx (Get_Qd (C, 1), 1.0), "Get_Qd");
      Check (Approx (Get_Qdd (C, 3), 0.0), "Get_Qdd");
      declare
         U : constant Chain := Make_Uniform_Chain (4, 1.0, 2.0);
      begin
         Check (N_Links (U) = 4, "Uniform N=4");
         Check (Approx (Get_Link (U, 1).Mass, 2.0), "Uniform mass");
         Check (Approx (Get_Link (U, 1).Distal.X, 1.0), "Uniform length");
         Check (Approx (Get_Link (U, 1).COM.X, 0.5), "Uniform COM mid");
         Check (Approx (Get_Link (U, 1).I_COM, 2.0 / 12.0, 1.0E-12),
                "Uniform rod I=mL^2/12");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Forward kinematics");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (2, 1.0, 1.0, (0.0, -9.81));
      FK : FK_Result;
   begin
      Set_Q (C, [0.0, 0.0]);
      FK := Forward_Kinematics (C);
      Check (FK.Used = 2, "FK used=2");
      Check (Near_Vec (FK.Joint_Pos (1), (0.0, 0.0)), "FK j1 at origin");
      Check (Near_Vec (FK.Tip_Pos, (2.0, 0.0), 1.0E-12), "FK tip stretched");
      Check (Near_Vec (FK.COM_Pos (1), (0.5, 0.0), 1.0E-12), "FK COM1");
      Check (Near_Vec (FK.Joint_Pos (2), (1.0, 0.0), 1.0E-12), "FK j2");
      Set_Q (C, [Pi / 2.0, 0.0]);
      FK := Forward_Kinematics (C);
      Check (Approx (FK.Abs_Angle (1), Pi / 2.0), "FK abs angle up");
      Check (Near_Vec (FK.Tip_Pos, (0.0, 2.0), 1.0E-9), "FK tip vertical");
      Set_Q (C, [Pi / 2.0, Pi / 2.0]);
      FK := Forward_Kinematics (C);
      Check (Approx (FK.Abs_Angle (2), Pi), "FK folded abs");
      Check (Near_Vec (FK.Tip_Pos, (-1.0, 1.0), 1.0E-9), "FK folded tip");
   end;

   ---------------------------------------------------------------------
   Section ("4. One-link pendulum gravity torque");
   ---------------------------------------------------------------------
   declare
      G : constant Real := 9.81;
      M : constant Real := 2.0;
      Len : constant Real := 1.5;
      C : Chain := Create (1, (0.0, -G));
      Angles : constant array (1 .. 7) of Real :=
        [0.0, Pi / 6.0, Pi / 4.0, Pi / 2.0, -Pi / 2.0, Pi, -Pi / 3.0];
   begin
      Set_Link (C, 1,
        (Mass => M, COM => (Len, 0.0), I_COM => 0.0, Distal => (Len, 0.0)));
      for K in Angles'Range loop
         declare
            Q : constant Real := Angles (K);
            Expect : constant Real := M * G * Len * Math.Cos (Q);
            Tau : Real_Array (1 .. 1);
         begin
            Set_State (C,
              Q   => [Q],
              Qd  => [0.0],
              Qdd => [0.0],
              Tau => [0.0]);
            Tau := Gravity_Torques (C);
            Check (Approx (Tau (1), Expect, 1.0E-8),
                   "pendulum gravity q=" & K'Image);
         end;
      end loop;
      Set_State (C, Q => [0.0], Qd => [0.0], Qdd => [0.0], Tau => [0.0]);
      declare
         Tg : constant Real_Array := Gravity_Torques (C);
      begin
         Check (Approx (Tg (1), M * G * Len, 1.0E-8), "horizontal hold torque");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. One-link inertia / known qdd");
   ---------------------------------------------------------------------
   declare
      G : constant Real := 10.0;
      M : constant Real := 1.0;
      Len : constant Real := 1.0;
      C : Chain := Create (1, (0.0, -G));
      Tau_App : constant Real := 3.0;
      H_Expect : constant Real := M * Len * Len;
      Qdd_Expect : Real;
      Acc : Real_Array (1 .. 1);
      Tau_Back : Real_Array (1 .. 1);
   begin
      Set_Link (C, 1,
        (Mass => M, COM => (Len, 0.0), I_COM => 0.0, Distal => (Len, 0.0)));
      Set_State (C, Q => [0.0], Qd => [0.0], Qdd => [0.0], Tau => [Tau_App]);
      Qdd_Expect := (Tau_App - (M * G * Len)) / H_Expect;
      Acc := Forward_Dynamics_ABA (C);
      Check (Approx (Acc (1), Qdd_Expect, 1.0E-7), "1-link ABA qdd");
      Acc := Forward_Dynamics_CRBA (C);
      Check (Approx (Acc (1), Qdd_Expect, 1.0E-7), "1-link CRBA qdd");
      declare
         H : constant Mat_NN := Mass_Matrix (C);
      begin
         Check (Approx (H (1, 1), H_Expect, 1.0E-9), "1-link H=mL^2");
      end;
      Set_Qdd (C, [2.5]);
      Tau_Back := Inverse_Dynamics_RNEA (C);
      Set_Tau (C, Tau_Back);
      Acc := Forward_Dynamics_ABA (C);
      Check (Approx (Acc (1), 2.5, 1.0E-6), "1-link RNEA→ABA roundtrip");
      Acc := Forward_Dynamics_CRBA (C);
      Check (Approx (Acc (1), 2.5, 1.0E-6), "1-link RNEA→CRBA roundtrip");
   end;

   ---------------------------------------------------------------------
   Section ("6. Zero motion / static consistency");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (3, 1.0, 1.0, (0.0, -9.81));
      Tau : Real_Array (1 .. 3);
      Acc : Real_Array (1 .. 3);
      Z3  : constant Real_Array := Zeros (3);
   begin
      Set_State (C, Q => Z3, Qd => Z3, Qdd => Z3, Tau => Z3);
      Tau := Inverse_Dynamics_RNEA (C);
      Check (abs (Tau (1)) > 1.0, "static gravity tau1 large");
      Check (abs (Tau (2)) > 0.1, "static gravity tau2");
      Set_Tau (C, Tau);
      Acc := Forward_Dynamics_ABA (C);
      Check (Slice_Near (Acc, Z3, 3, 1.0E-5), "ABA: hold torques → qdd≈0");
      Acc := Forward_Dynamics_CRBA (C);
      Check (Slice_Near (Acc, Z3, 3, 1.0E-5), "CRBA: hold torques → qdd≈0");
      Set_Gravity (C, (0.0, 0.0));
      Tau := Gravity_Torques (C);
      Check (Slice_Near (Tau, Z3, 3, 1.0E-12), "zero-g gravity torques");
   end;

   ---------------------------------------------------------------------
   Section ("7. RNEA ↔ ABA / CRBA cross-checks (2-link)");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (2, 1.0, 1.0, (0.0, -9.81));
      type Cfg4 is array (1 .. 4) of Real;
      type Cfg_Table is array (1 .. 6) of Cfg4;
      Configs : constant Cfg_Table :=
        [[0.0, 0.0, 0.0, 0.0],
         [0.3, -0.5, 0.0, 0.0],
         [1.0, 0.2, 0.5, -0.3],
         [-0.7, 1.1, -1.0, 0.8],
         [Pi / 3.0, -Pi / 4.0, 0.1, 0.2],
         [0.0, Pi / 2.0, 1.5, -1.5]];
      type Acc2 is array (1 .. 2) of Real;
      type Acc_Table is array (1 .. 4) of Acc2;
      Qdds : constant Acc_Table :=
        [[0.0, 0.0], [1.0, -0.5], [-2.0, 3.0], [0.25, 0.25]];
   begin
      for K in 1 .. 6 loop
         for J in 1 .. 4 loop
            declare
               Qdd_In : constant Real_Array :=
                 [Qdds (J) (1), Qdds (J) (2)];
               Tau : Real_Array (1 .. 2);
               Acc : Real_Array (1 .. 2);
               Tau2 : Real_Array (1 .. 2);
            begin
               Set_State (C,
                 Q   => [Configs (K) (1), Configs (K) (2)],
                 Qd  => [Configs (K) (3), Configs (K) (4)],
                 Qdd => Qdd_In,
                 Tau => [0.0, 0.0]);
               Tau := Inverse_Dynamics_RNEA (C);
               Set_Tau (C, Tau);
               Acc := Forward_Dynamics_ABA (C);
               Check (Slice_Near (Acc, Qdd_In, 2, 2.0E-4),
                      "2L ABA↔RNEA cfg" & K'Image & " j" & J'Image);
               Acc := Forward_Dynamics_CRBA (C);
               Check (Slice_Near (Acc, Qdd_In, 2, 2.0E-4),
                      "2L CRBA↔RNEA cfg" & K'Image & " j" & J'Image);
               Set_Tau (C, [1.0, -0.5]);
               Acc := Forward_Dynamics_ABA (C);
               Set_Qdd (C, Acc);
               Tau2 := Inverse_Dynamics_RNEA (C);
               Check (Slice_Near (Tau2, [1.0, -0.5], 2, 2.0E-4),
                      "2L RNEA↔ABA tau cfg" & K'Image & " j" & J'Image);
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Mass matrix SPD / symmetry");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (4, 0.8, 1.5, (0.0, -9.81));
   begin
      Set_Q (C, [0.2, -0.4, 0.6, -0.1]);
      Set_Qd (C, Zeros (4));
      declare
         H : constant Mat_NN := Mass_Matrix (C);
         Sym_OK : Boolean := True;
         Diag_OK : Boolean := True;
      begin
         for I in 1 .. 4 loop
            if H (I, I) <= 0.0 then
               Diag_OK := False;
            end if;
            for J in 1 .. 4 loop
               if abs (H (I, J) - H (J, I)) > 1.0E-8 then
                  Sym_OK := False;
               end if;
            end loop;
         end loop;
         Check (Sym_OK, "H symmetric 4-link");
         Check (Diag_OK, "H diagonal positive");
         Set_Tau (C, [0.1, 0.2, -0.1, 0.05]);
         declare
            Acc : constant Real_Array := Forward_Dynamics_CRBA (C);
         begin
            Check (abs (Acc (1)) < 1.0E6, "CRBA Acc bounded 1");
            Check (abs (Acc (2)) < 1.0E6, "CRBA Acc bounded 2");
            Check (abs (Acc (3)) < 1.0E6, "CRBA Acc bounded 3");
            Check (abs (Acc (4)) < 1.0E6, "CRBA Acc bounded 4");
         end;
         Check (H (1, 1) > H (4, 4), "proximal inertia > distal tip");
      end;
      declare
         C1 : constant Chain := Make_Uniform_Chain (1);
         H1 : constant Mat_NN := Mass_Matrix (C1);
      begin
         Check (H1 (1, 1) > 0.0, "N=1 H>0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. ABA vs CRBA agreement");
   ---------------------------------------------------------------------
   declare
      Seeds : constant array (1 .. 8) of Real :=
        [0.0, 0.3, -0.5, 1.2, -1.7, 0.9, -0.2, 2.0];
   begin
      for N in 1 .. 5 loop
         declare
            C : Chain := Make_Uniform_Chain (N, 1.0, 1.0);
         begin
            for S in Seeds'Range loop
               declare
                  Q, Qd, Tau : Real_Array (1 .. N);
                  A1, A2 : Real_Array (1 .. N);
               begin
                  for I in 1 .. N loop
                     Q (I) := Seeds (S) * Real (I) * 0.37;
                     Qd (I) := Seeds (S) * 0.1 * Real (I);
                     Tau (I) := 0.3 * Real (I) - Seeds (S);
                  end loop;
                  Set_State (C, Q, Qd, Zeros (N), Tau);
                  A1 := Forward_Dynamics_ABA (C);
                  A2 := Forward_Dynamics_CRBA (C);
                  Check (Slice_Near (A1, A2, N, 5.0E-4),
                         "ABA=CRBA N=" & N'Image & " seed" & S'Image);
               end;
            end loop;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Random residual RNEA(ABA(τ))≈τ");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (5, 0.7, 1.2, (0.0, -9.81));
      Ang : constant array (1 .. 10) of Real :=
        [0.1, -0.4, 0.8, -1.1, 1.5, 0.0, 0.6, -0.9, 1.2, -0.3];
   begin
      for S in Ang'Range loop
         declare
            Q, Qd, Tau, Acc, Tau2 : Real_Array (1 .. 5);
         begin
            for I in 1 .. 5 loop
               Q (I) := Ang (S) * Math.Sin (Real (I));
               Qd (I) := 0.4 * Math.Cos (Real (I) + Ang (S));
               Tau (I) := Real (I) * 0.25 - Ang (S);
            end loop;
            Set_State (C, Q, Qd, Zeros (5), Tau);
            Acc := Forward_Dynamics_ABA (C);
            Set_Qdd (C, Acc);
            Tau2 := Inverse_Dynamics_RNEA (C);
            Check (Slice_Near (Tau2, Tau, 5, 1.0E-3),
                   "residual RNEA○ABA seed" & S'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Edge N=1 and velocity-dependent terms");
   ---------------------------------------------------------------------
   declare
      C : Chain := Create (1, (0.0, 0.0));
      Tau0, TauV : Real_Array (1 .. 1);
   begin
      Set_Link (C, 1,
        (Mass => 1.0, COM => (1.0, 0.0), I_COM => 0.0, Distal => (1.0, 0.0)));
      Set_State (C, Q => [0.5], Qd => [3.0], Qdd => [0.0], Tau => [0.0]);
      TauV := Inverse_Dynamics_RNEA (C);
      Check (Approx (TauV (1), 0.0, 1.0E-9), "1DOF no velocity torque");
      Set_Qd (C, [0.0]);
      Tau0 := Inverse_Dynamics_RNEA (C);
      Check (Approx (Tau0 (1), 0.0, 1.0E-9), "1DOF zero-g static");
      Set_Qdd (C, [4.0]);
      Tau0 := Inverse_Dynamics_RNEA (C);
      Check (Approx (Tau0 (1), 4.0, 1.0E-9), "1DOF τ=H qdd=4");
   end;

   ---------------------------------------------------------------------
   Section ("12. Two-link Coriolis nonzero");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (2, 1.0, 1.0, (0.0, 0.0));
      T_Still, T_Move : Real_Array (1 .. 2);
      Z2 : constant Real_Array := Zeros (2);
   begin
      Set_State (C, Q => [0.4, -0.3], Qd => Z2, Qdd => Z2, Tau => Z2);
      T_Still := Bias_Forces (C);
      Set_Qd (C, [1.5, -2.0]);
      T_Move := Bias_Forces (C);
      Check (Slice_Near (T_Still, Z2, 2, 1.0E-10), "2L zero-g zero-vel bias");
      Check (abs (T_Move (1)) + abs (T_Move (2)) > 1.0E-6,
             "2L moving bias nonzero");
      Set_Tau (C, T_Move);
      declare
         Acc : constant Real_Array := Forward_Dynamics_ABA (C);
      begin
         Check (Slice_Near (Acc, Z2, 2, 1.0E-4),
                "2L bias torque cancels motion accel");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Gravity vector direction");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (1, 1.0, 1.0, (0.0, 0.0));
      Tx, Ty : Real_Array (1 .. 1);
   begin
      Set_Link (C, 1,
        (Mass => 1.0, COM => (1.0, 0.0), I_COM => 0.0, Distal => (1.0, 0.0)));
      Set_Q (C, [0.0]);
      Set_Gravity (C, (-9.81, 0.0));
      Tx := Gravity_Torques (C);
      Check (Approx (Tx (1), 0.0, 1.0E-8), "g along -x at q=0 torque 0");
      Set_Gravity (C, (0.0, -9.81));
      Ty := Gravity_Torques (C);
      Check (Approx (Ty (1), 9.81, 1.0E-8), "g along -y torque +mgL");
      Set_Q (C, [Pi / 2.0]);
      Ty := Gravity_Torques (C);
      Check (Approx (Ty (1), 0.0, 1.0E-8), "vertical upright torque 0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Longer chain residual");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (8, 0.5, 0.8, (0.0, -9.81));
      Q, Qd, Tau, Acc, Tau2 : Real_Array (1 .. 8);
   begin
      for I in 1 .. 8 loop
         Q (I) := 0.15 * Real (I);
         Qd (I) := 0.05 * Real (9 - I);
         Tau (I) := 0.1 * Math.Sin (Real (I));
      end loop;
      Set_State (C, Q, Qd, Zeros (8), Tau);
      Acc := Forward_Dynamics_ABA (C);
      Set_Qdd (C, Acc);
      Tau2 := Inverse_Dynamics_RNEA (C);
      Check (Slice_Near (Tau2, Tau, 8, 2.0E-3), "N=8 RNEA○ABA");
      Acc := Forward_Dynamics_CRBA (C);
      Set_Qdd (C, Acc);
      Tau2 := Inverse_Dynamics_RNEA (C);
      Check (Slice_Near (Tau2, Tau, 8, 2.0E-3), "N=8 RNEA○CRBA");
      declare
         H : constant Mat_NN := Mass_Matrix (C);
         OK : Boolean := True;
      begin
         for I in 1 .. 8 loop
            if H (I, I) <= 0.0 then
               OK := False;
            end if;
         end loop;
         Check (OK, "N=8 H diag > 0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. FK tip length conservation");
   ---------------------------------------------------------------------
   declare
      C : Chain := Make_Uniform_Chain (3, 1.0, 1.0);
      FK : FK_Result;
   begin
      Set_Q (C, [0.0, 0.0, 0.0]);
      FK := Forward_Kinematics (C);
      Check (Approx (Mag (FK.Tip_Pos), 3.0, 1.0E-12), "reach max 3");
      Set_Q (C, [Pi, 0.0, 0.0]);
      FK := Forward_Kinematics (C);
      Check (Near_Vec (FK.Tip_Pos, (-3.0, 0.0), 1.0E-9), "reach -x");
      Check (Approx (Get_Q (C, 1), Pi), "state preserved");
   end;

   New_Line;
   Put_Line ("==========================================");
   Put_Line ("PASS: " & Pass_Count'Image);
   Put_Line ("FAIL: " & Fail_Count'Image);
   if Fail_Count /= 0 then
      raise Program_Error with "Test failures:" & Fail_Count'Image;
   end if;
   if Pass_Count < 100 then
      raise Program_Error with "Need >=100 PASS, got" & Pass_Count'Image;
   end if;
   Put_Line ("All tests passed.");
end Tests;

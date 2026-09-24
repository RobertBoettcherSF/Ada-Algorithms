--  Standalone test suite for Lax_Wendroff (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lax_Wendroff; use Lax_Wendroff;

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

   Raised : Boolean;

begin
   Put_Line ("Lax_Wendroff test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Vec_Near helpers");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Abs_Error (1.0, 1.0) = 0.0, "Abs_Error zero");
   Check (Near (Abs_Error (3.0, 1.0), 2.0), "Abs_Error 3-1");
   Check (Near (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
   declare
      A : constant Grid := [1.0, 2.0, 3.0];
      B : constant Grid := [1.0, 2.0, 3.0];
      C : constant Grid := [1.0, 2.0, 3.1];
   begin
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near unequal");
      Check (Vec_Near (A, C, 0.2), "Vec_Near loose Tol");
   end;

   ---------------------------------------------------------------------
   Section ("2. CFL / geometry");
   ---------------------------------------------------------------------
   Check (Near (CFL (1.0, 0.1, 0.2), 0.5), "CFL(a,dt,dx)=0.5");
   Check (Near (CFL (-2.0, 0.1, 0.2), -1.0), "CFL negative a");
   Check (Near (CFL (1.0, 0.2, 0.2), 1.0), "CFL = 1 boundary");
   declare
      S : constant Grid_State := Make_Grid (16, 0.1, 0.05, 1.0, 0.0);
   begin
      Check (Near (Domain_Length (S), 1.6), "Domain_Length 16*0.1");
      Check (Near (X_At (S, 1), 0.0), "X_At first");
      Check (Near (X_At (S, 2), 0.1), "X_At second");
      Check (Near (CFL (S), 0.5), "CFL(State)");
      Check (CFL_OK (S), "CFL_OK true");
   end;
   declare
      S : constant Grid_State := Make_Grid (8, 0.1, 0.2, 1.0);
   begin
      Check (Near (CFL (S), 2.0), "CFL > 1");
      Check (not CFL_OK (S), "CFL_OK false when |nu|>1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Grid / Make_Constant / Make_Gaussian / Make_Pulse");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_State := Make_Grid (32, 1.0 / 32.0, 0.01);
   begin
      Check (G.N = 32, "Make_Grid N");
      Check (Near (G.U (1), 0.0), "Make_Grid zero IC");
      Check (Near (Max_Abs (G.U (1 .. G.N)), 0.0), "Make_Grid max abs 0");
   end;
   declare
      C : constant Grid_State := Make_Constant (20, 0.05, 0.01, 3.5);
   begin
      Check (Near (C.U (1), 3.5), "Make_Constant first");
      Check (Near (C.U (20), 3.5), "Make_Constant last");
      Check (Near (Mass (C), 3.5 * 20.0 * 0.05), "Make_Constant mass");
   end;
   declare
      G : constant Grid_State :=
        Make_Gaussian
          (64, 1.0 / 64.0, 0.005, 1.0, 0.0, 0.5, 0.08, 1.0);
   begin
      Check (G.N = 64, "Gaussian N");
      Check (Max_Abs (G.U (1 .. G.N)) > 0.5, "Gaussian peak tall");
      Check (G.U (1) < G.U (33), "Gaussian taller near centre");
   end;
   declare
      P : constant Grid_State :=
        Make_Pulse (40, 0.025, 0.01, 1.0, 0.0, 0.2, 0.4, 2.0);
      Inside, Outside : Natural := 0;
   begin
      for J in 1 .. P.N loop
         if Near (P.U (J), 2.0) then
            Inside := Inside + 1;
         elsif Near (P.U (J), 0.0) then
            Outside := Outside + 1;
         end if;
      end loop;
      Check (Inside > 0, "Pulse has interior cells");
      Check (Outside > 0, "Pulse has exterior cells");
      Check (Inside + Outside = Natural (P.N), "Pulse only 0/Amp");
   end;

   ---------------------------------------------------------------------
   Section ("4. Invalid_Argument guards");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         S : Grid_State := Make_Grid (8, -0.1, 0.01);
         pragma Unreferenced (S);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Make_Grid rejects Dx <= 0");

   Raised := False;
   begin
      declare
         S : Grid_State := Make_Grid (8, 0.1, 0.0);
         pragma Unreferenced (S);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Make_Grid rejects Dt <= 0");

   Raised := False;
   begin
      declare
         S : Grid_State :=
           Make_Gaussian (8, 0.1, 0.01, Width => -1.0);
         pragma Unreferenced (S);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Make_Gaussian rejects Width <= 0");

   Raised := False;
   begin
      declare
         S : Grid_State :=
           Make_Pulse (8, 0.1, 0.01, Left => 0.5, Right => 0.2);
         pragma Unreferenced (S);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Make_Pulse rejects Right <= Left");

   Raised := False;
   begin
      declare
         S : Grid_State := Make_Grid (8, 0.1, 0.2, 1.0);  -- nu=2
      begin
         Step (S);
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Step rejects |nu| > 1");

   Raised := False;
   begin
      declare
         S : Grid_State := Make_Grid (8, 0.1, 0.2, 1.0);
      begin
         Step_Richtmyer (S);
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Step_Richtmyer rejects |nu| > 1");

   Raised := False;
   begin
      declare
         Unused : Real := CFL (1.0, 0.1, 0.0);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "CFL rejects Dx = 0");

   ---------------------------------------------------------------------
   Section ("5. Constant solution preserved");
   ---------------------------------------------------------------------
   declare
      S : Grid_State := Make_Constant (64, 1.0 / 64.0, 0.005, 2.25, 1.0);
      Exact : Grid (1 .. 64);
   begin
      Advance (S, 40);
      for J in Exact'Range loop
         Exact (J) := 2.25;
      end loop;
      Check (Vec_Near (S.U (1 .. 64), Exact, 1.0E-12),
             "Constant preserved after 40 steps");
      Check (Near (Max_Error (S, Exact), 0.0, 1.0E-12),
             "Max_Error constant ~ 0");
   end;
   declare
      S : Grid_State := Make_Constant (32, 0.05, 0.01, -1.0, -0.5);
   begin
      Advance_Richtmyer (S, 25);
      Check (Near (S.U (1), -1.0, 1.0E-12), "Richtmyer preserves const");
      Check (Near (S.U (16), -1.0, 1.0E-12), "Richtmyer mid const");
   end;

   ---------------------------------------------------------------------
   Section ("6. Mass conservation (periodic linear advection)");
   ---------------------------------------------------------------------
   declare
      S : Grid_State :=
        Make_Gaussian
          (128, 1.0 / 128.0, 0.004, 1.0, 0.0, 0.4, 0.07, 1.0);
      M0, M1 : Real;
   begin
      M0 := Mass (S);
      Advance (S, 50);
      M1 := Mass (S);
      Check (Near (M0, M1, 1.0E-10), "Mass conserved LW 50 steps");
   end;
   declare
      S : Grid_State :=
        Make_Pulse (100, 0.01, 0.005, 1.0, 0.0, 0.2, 0.35, 1.5);
      M0, M1 : Real;
   begin
      M0 := Mass (S);
      Advance_Richtmyer (S, 30);
      M1 := Mass (S);
      Check (Near (M0, M1, 1.0E-10), "Mass conserved Richtmyer");
   end;
   declare
      S : constant Grid_State := Make_Constant (16, 0.1, 0.05, 4.0);
   begin
      Check (Near (Mass (S), 4.0 * 1.6), "Mass of constant field");
   end;

   ---------------------------------------------------------------------
   Section ("7. Wrap_Periodic / Shift_Grid / Exact_Advection");
   ---------------------------------------------------------------------
   Check (Near (Wrap_Periodic (0.25, 0.0, 1.0), 0.25), "Wrap interior");
   Check (Near (Wrap_Periodic (1.25, 0.0, 1.0), 0.25), "Wrap +1");
   Check (Near (Wrap_Periodic (-0.25, 0.0, 1.0), 0.75), "Wrap negative");
   Check (Near (Wrap_Periodic (2.0, 0.0, 1.0), 0.0, 1.0E-12),
          "Wrap exact period");
   Check (Near (Wrap_Periodic (1.1, 0.5, 2.0), 1.1), "Wrap with X_Min");
   declare
      U : constant Grid := [1.0, 2.0, 3.0, 4.0];
      S1 : constant Grid := Shift_Grid (U, 1);
      S0 : constant Grid := Shift_Grid (U, 0);
      SM : constant Grid := Shift_Grid (U, -1);
   begin
      Check (Vec_Near (S0, U), "Shift 0 identity");
      Check (Near (S1 (1), 4.0) and then Near (S1 (2), 1.0),
             "Shift +1");
      Check (Near (SM (1), 2.0) and then Near (SM (4), 1.0),
             "Shift -1");
   end;
   declare
      N  : constant Cell_Count := 32;
      Dx : constant Real := 1.0 / Real (N);
      U0 : Grid (1 .. N);
      Ex : Grid (1 .. N);
      Sh : Grid (1 .. N);
   begin
      for J in 1 .. N loop
         U0 (J) := Real (J);
      end loop;
      --  Distance = 3 Dx → integer shift of +3 cells for a>0 style
      Ex := Exact_Advection (U0, N, Dx, 0.0, 3.0 * Dx);
      Sh := Shift_Grid (U0, 3);
      Check (Vec_Near (Ex, Sh, 1.0E-10),
             "Exact_Advection matches Shift_Grid (integer)");
   end;
   declare
      S : constant Grid_State :=
        Make_Gaussian
          (64, 1.0 / 64.0, 0.005, 1.0, 0.0, 0.5, 0.08, 1.0);
      U0 : constant Grid := S.U (1 .. S.N);
      Ex : Grid (1 .. S.N);
   begin
      Ex := Exact_Advection (S, 0.0);
      Check (Vec_Near (Ex, U0, 1.0E-12), "Exact T=0 recovers IC");
   end;

   ---------------------------------------------------------------------
   Section ("8. Single Step / Advance basic");
   ---------------------------------------------------------------------
   declare
      S : Grid_State :=
        Make_Gaussian
          (64, 1.0 / 64.0, 0.005, 1.0, 0.0, 0.3, 0.06, 1.0);
      M0 : constant Real := Mass (S);
   begin
      Check (CFL_OK (S), "Gaussian CFL OK");
      Check (Near (CFL (S), 0.32, 1.0E-12), "nu = a dt/dx");
      Step (S);
      Check (Near (Mass (S), M0, 1.0E-10), "Mass after one Step");
      Advance (S, 10);
      Check (Near (Mass (S), M0, 1.0E-10), "Mass after Advance");
   end;

   ---------------------------------------------------------------------
   Section ("9. Error grows slowly (smooth Gaussian, CFL < 1)");
   ---------------------------------------------------------------------
   declare
      N  : constant Cell_Count := 128;
      Dx : constant Real := 1.0 / Real (N);
      Dt : constant Real := 0.4 * Dx;  -- nu = 0.4
      S  : Grid_State :=
        Make_Gaussian (N, Dx, Dt, 1.0, 0.0, 0.5, 0.08, 1.0);
      U0 : constant Grid := S.U (1 .. N);
      Steps : constant Positive := 40;
      T    : constant Real := Real (Steps) * Dt;
      Exact : Grid (1 .. N);
      E_L2, E_Max : Real;
   begin
      Advance (S, Steps);
      Exact := Exact_Advection (U0, N, Dx, 0.0, 1.0 * T);
      E_L2 := L2_Error (S, Exact);
      E_Max := Max_Error (S, Exact);
      Check (E_L2 < 5.0E-3, "L2 error modest after 40 steps");
      Check (E_Max < 2.0E-2, "Max error modest after 40 steps");
      Check (E_L2 > 0.0, "L2 error positive (not exact machine)");
   end;
   --  Longer run: error still controlled (order-2, no blow-up)
   declare
      N  : constant Cell_Count := 128;
      Dx : constant Real := 1.0 / Real (N);
      Dt : constant Real := 0.5 * Dx;
      S  : Grid_State :=
        Make_Gaussian (N, Dx, Dt, 1.0, 0.0, 0.5, 0.1, 1.0);
      U0 : constant Grid := S.U (1 .. N);
      Steps : constant Positive := 200;
      T    : constant Real := Real (Steps) * Dt;
      Exact : Grid (1 .. N);
      E_L2 : Real;
   begin
      Advance (S, Steps);
      Exact := Exact_Advection (U0, N, Dx, 0.0, T);
      E_L2 := L2_Error (S, Exact);
      Check (E_L2 < 5.0E-2, "L2 error stays bounded over 200 steps");
      Check (Max_Abs (S.U (1 .. N)) < 2.0, "No blow-up max |u|");
   end;

   ---------------------------------------------------------------------
   Section ("10. Richtmyer matches single-step on linear advection");
   ---------------------------------------------------------------------
   declare
      N  : constant Cell_Count := 64;
      Dx : constant Real := 1.0 / Real (N);
      Dt : constant Real := 0.3 * Dx;
      A  : Grid_State :=
        Make_Gaussian (N, Dx, Dt, 1.0, 0.0, 0.4, 0.07, 1.0);
      B  : Grid_State := A;
   begin
      Advance (A, 15);
      Advance_Richtmyer (B, 15);
      Check (Vec_Near (A.U (1 .. N), B.U (1 .. N), 1.0E-10),
             "LW vs Richtmyer agree (15 steps)");
   end;
   declare
      N  : constant Cell_Count := 32;
      S1 : Grid_State := Make_Pulse (N, 0.05, 0.02, 1.0, 0.0, 0.3, 0.5);
      S2 : Grid_State := S1;
   begin
      Step (S1);
      Step_Richtmyer (S2);
      Check (Vec_Near (S1.U (1 .. N), S2.U (1 .. N), 1.0E-12),
             "One-step LW = Richtmyer");
   end;

   ---------------------------------------------------------------------
   Section ("11. Grid-aligned exact shift comparison");
   ---------------------------------------------------------------------
   declare
      N  : constant Cell_Count := 50;
      Dx : constant Real := 0.02;
      --  nu = 1 ⇒ one cell per step exactly
      Dt : constant Real := Dx;
      S  : Grid_State :=
        Make_Gaussian (N, Dx, Dt, 1.0, 0.0, 0.4, 0.06, 1.0);
      U0 : constant Grid := S.U (1 .. N);
      Exact : Grid (1 .. N);
   begin
      Check (Near (CFL (S), 1.0), "CFL = 1 for aligned shift");
      Advance (S, 5);
      Exact := Shift_Grid (U0, 5);
      Check (Vec_Near (S.U (1 .. N), Exact, 1.0E-10),
             "nu=1: LW matches integer Shift_Grid");
   end;

   ---------------------------------------------------------------------
   Section ("12. Negative advection speed");
   ---------------------------------------------------------------------
   declare
      N  : constant Cell_Count := 64;
      Dx : constant Real := 1.0 / Real (N);
      Dt : constant Real := 0.25 * Dx;
      S  : Grid_State :=
        Make_Gaussian (N, Dx, Dt, -1.0, 0.0, 0.5, 0.08, 1.0);
      U0 : constant Grid := S.U (1 .. N);
      M0 : constant Real := Mass (S);
      Exact : Grid (1 .. N);
      Steps : constant Positive := 20;
   begin
      Check (CFL_OK (S), "Negative a still CFL_OK");
      Check (CFL (S) < 0.0, "CFL negative");
      Advance (S, Steps);
      Exact := Exact_Advection (U0, N, Dx, 0.0, -1.0 * Real (Steps) * Dt);
      Check (Near (Mass (S), M0, 1.0E-10), "Mass with a < 0");
      Check (L2_Error (S, Exact) < 1.0E-2, "L2 ok for a < 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. L2_Error / Max_Error / Max_Abs");
   ---------------------------------------------------------------------
   declare
      U : constant Grid := [1.0, 2.0, 3.0];
      E : constant Grid := [1.0, 2.0, 3.0];
      F : constant Grid := [1.0, 2.0, 4.0];
   begin
      Check (Near (L2_Error (U, E, 0.1), 0.0), "L2 identical");
      Check (Near (Max_Error (U, E), 0.0), "Max identical");
      Check (Near (Max_Error (U, F), 1.0), "Max_Error = 1");
      Check (Near (Max_Abs (U), 3.0), "Max_Abs");
      Check (L2_Error (U, F, 1.0) > 0.0, "L2 positive when differ");
   end;

   ---------------------------------------------------------------------
   Section ("14. Zero field / small grids");
   ---------------------------------------------------------------------
   declare
      S : Grid_State := Make_Grid (4, 0.25, 0.1, 0.5);
   begin
      Advance (S, 10);
      Check (Near (Max_Abs (S.U (1 .. 4)), 0.0), "Zero stays zero");
      Check (Near (Mass (S), 0.0), "Zero mass");
   end;
   declare
      S : Grid_State := Make_Constant (1, 1.0, 0.5, 7.0, 1.0);
   begin
      --  N=1 periodic: neighbours are self; LW must keep constant
      Check (Near (CFL (S), 0.5), "N=1 CFL");
      Step (S);
      Check (Near (S.U (1), 7.0, 1.0E-12), "N=1 constant Step");
   end;

   ---------------------------------------------------------------------
   Section ("15. CFL boundary |nu|=1 accepted");
   ---------------------------------------------------------------------
   declare
      S : Grid_State := Make_Constant (16, 0.1, 0.1, 1.0, 1.0);
   begin
      Check (Near (abs (CFL (S)), 1.0), "|nu|=1");
      Check (CFL_OK (S), "CFL_OK at |nu|=1");
      Step (S);  -- must not raise
      Check (Near (S.U (1), 1.0, 1.0E-12), "Step at |nu|=1 ok");
   end;
   declare
      S : Grid_State := Make_Constant (16, 0.1, 0.1, 1.0, -1.0);
   begin
      Check (Near (CFL (S), -1.0), "nu=-1");
      Step_Richtmyer (S);
      Check (Near (S.U (8), 1.0, 1.0E-12), "Richtmyer at nu=-1");
   end;

   ---------------------------------------------------------------------
   Section ("16. Refinement: finer grid → smaller error");
   ---------------------------------------------------------------------
   declare
      function Run_Error (N : Cell_Count) return Real is
         Dx : constant Real := 1.0 / Real (N);
         Dt : constant Real := 0.4 * Dx;
         S  : Grid_State :=
           Make_Gaussian (N, Dx, Dt, 1.0, 0.0, 0.5, 0.1, 1.0);
         U0 : constant Grid := S.U (1 .. N);
         Steps : constant Positive := N / 2;  -- fixed time ~ 0.2
         T : constant Real := Real (Steps) * Dt;
         Exact : Grid (1 .. N);
      begin
         Advance (S, Steps);
         Exact := Exact_Advection (U0, N, Dx, 0.0, T);
         return L2_Error (S, Exact);
      end Run_Error;

      E32  : constant Real := Run_Error (32);
      E128 : constant Real := Run_Error (128);
   begin
      Check (E128 < E32, "Finer grid smaller L2 error");
      Check (E32 > 0.0, "Coarse error positive");
   end;

   ---------------------------------------------------------------------
   Section ("17. Pulse advects (mass + no blow-up)");
   ---------------------------------------------------------------------
   declare
      S : Grid_State :=
        Make_Pulse (80, 0.0125, 0.005, 1.0, 0.0, 0.1, 0.3, 1.0);
      M0 : constant Real := Mass (S);
   begin
      Advance (S, 60);
      Check (Near (Mass (S), M0, 1.0E-9), "Pulse mass conserved");
      Check (Max_Abs (S.U (1 .. S.N)) < 3.0, "Pulse no blow-up");
      --  Discontinuous IC: LW oscillates (Gibbs) but stays O(1)
      Check (True, "Pulse advance completed");
   end;

   ---------------------------------------------------------------------
   Section ("18. Advance vs repeated Step equivalence");
   ---------------------------------------------------------------------
   declare
      N : constant Cell_Count := 48;
      A : Grid_State :=
        Make_Gaussian (N, 1.0 / Real (N), 0.005, 1.0, 0.0, 0.5, 0.07);
      B : Grid_State := A;
   begin
      Advance (A, 7);
      for K in 1 .. 7 loop
         Step (B);
      end loop;
      Check (Vec_Near (A.U (1 .. N), B.U (1 .. N), 1.0E-14),
             "Advance ≡ repeated Step");
   end;


   ---------------------------------------------------------------------
   Section ("19. Extra CFL / geometry edge cases");
   ---------------------------------------------------------------------
   declare
      S : constant Grid_State := Make_Grid (Max_Cells, 1.0 / Real (Max_Cells),
                                            0.5 / Real (Max_Cells), 1.0);
   begin
      Check (S.N = Max_Cells, "Max_Cells grid builds");
      Check (CFL_OK (S), "Max_Cells CFL_OK");
      Check (Near (Domain_Length (S), 1.0), "Max_Cells domain length 1");
   end;
   declare
      S : constant Grid_State :=
        Make_Gaussian (16, 0.1, 0.05, 0.0, 0.0, 0.5, 0.1, 1.0);
   begin
      Check (Near (CFL (S), 0.0), "a=0 => nu=0");
      Check (CFL_OK (S), "a=0 CFL_OK");
   end;
   declare
      S : Grid_State :=
        Make_Gaussian (16, 0.1, 0.05, 0.0, 0.0, 0.5, 0.1, 1.0);
      U0 : constant Grid := S.U (1 .. 16);
   begin
      Advance (S, 20);
      Check (Vec_Near (S.U (1 .. 16), U0, 1.0E-12),
             "a=0 leaves field unchanged");
   end;
   Check (Near (Abs_Error (0.0, 0.0), 0.0), "Abs_Error 0");
   Check (Near (Wrap_Periodic (5.5, 1.0, 2.0), 1.5, 1.0E-12),
          "Wrap into [1,3)");
   declare
      U : constant Grid := [0.0, 1.0, 0.0, -1.0];
   begin
      Check (Near (Max_Abs (U), 1.0), "Max_Abs mixed signs");
      Check (Near (Mass (U, 0.5), 0.0, 1.0E-12), "Mass cancels");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("======================================");
   Put_Line
     ("Result:"
      & Natural'Image (Pass_Count)
      & " passed,"
      & Natural'Image (Fail_Count)
      & " failed");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

end Tests;

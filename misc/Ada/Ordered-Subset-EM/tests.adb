--  Standalone test suite for Ordered_Subset_EM (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ordered_Subset_EM; use Ordered_Subset_EM;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function All_Nonneg (X : Image) return Boolean is
   begin
      for J in X'Range loop
         if X (J) < 0.0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Nonneg;

begin
   Put_Line ("Ordered_Subset_EM test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Zero helpers / Enforce_Nonnegative");
   ---------------------------------------------------------------------
   declare
      Zi : constant Image := Zero_Image (4);
      Zp : constant Projection := Zero_Projection (3);
      Zm : constant System_Matrix := Zero_Matrix (2, 3);
      X  : Image (1 .. 3) := [-1.0, 2.0, -0.5];
      Raised : Boolean := False;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Zi (1), 0.0) and then Approx (Zi (4), 0.0),
             "Zero_Image elements 0");
      Check (Approx (Zp (1), 0.0) and then Approx (Zp (3), 0.0),
             "Zero_Projection elements 0");
      Check (Approx (Zm (1, 1), 0.0) and then Approx (Zm (2, 3), 0.0),
             "Zero_Matrix elements 0");
      Enforce_Nonnegative (X);
      Check (Approx (X (1), 0.0) and then Approx (X (2), 2.0)
               and then Approx (X (3), 0.0),
             "Enforce_Nonnegative clamps negatives");
      begin
         declare
            Unused : Image := Zero_Image (Max_Pixels + 1);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Capacity_Exceeded =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Zero_Image over capacity raises");
   end;

   ---------------------------------------------------------------------
   Section ("2. Forward / back consistency on tiny A");
   ---------------------------------------------------------------------
   declare
      --  A = [[1, 0], [1, 1], [0, 2]]  (3 bins × 2 pixels)
      A : constant System_Matrix (1 .. 3, 1 .. 2) :=
        [1 => [1.0, 0.0],
         2 => [1.0, 1.0],
         3 => [0.0, 2.0]];
      X : constant Image (1 .. 2) := [2.0, 3.0];
      Y : constant Projection := Forward_Project (A, X);
      --  ŷ = [2, 5, 6]
      B : constant Image := Back_Project (A, Y);
      --  b1 = 1*2 + 1*5 + 0*6 = 7; b2 = 0*2 + 1*5 + 2*6 = 17
      S : constant Image := Sensitivity (A);
   begin
      Check (Approx (Y (1), 2.0) and then Approx (Y (2), 5.0)
               and then Approx (Y (3), 6.0),
             "Forward_Project ŷ = [2,5,6]");
      Check (Approx (B (1), 7.0) and then Approx (B (2), 17.0),
             "Back_Project b = [7,17]");
      Check (Approx (S (1), 2.0) and then Approx (S (2), 3.0),
             "Sensitivity s = [2,3]");
      Check (A'Length (1) = 3 and then A'Length (2) = 2,
             "Tiny A shape 3×2");
      Check (Y'Length = 3 and then X'Length = 2,
             "Forward output length matches bins");
      --  <Ax, y> vs <x, A^T y> consistency with y = ones
      declare
         Ones : constant Projection (1 .. 3) := [1.0, 1.0, 1.0];
         Ax   : constant Projection := Forward_Project (A, X);
         At1  : constant Image := Back_Project (A, Ones);
         LHS  : Real := 0.0;
         RHS  : Real := 0.0;
      begin
         for I in Ax'Range loop
            LHS := LHS + Ax (I) * Ones (I);
         end loop;
         for J in X'Range loop
            RHS := RHS + X (J) * At1 (J);
         end loop;
         Check (Approx (LHS, RHS, 1.0E-8),
                "Forward/back adjoint consistency <Ax,1>=<x,A^T 1>");
         Check (Approx (At1 (1), S (1)) and then Approx (At1 (2), S (2)),
                "Back_Project(ones) = Sensitivity");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Ordered_Subsets covers all bins exactly once");
   ---------------------------------------------------------------------
   declare
      C4 : constant Subset_Map :=
        Make_Ordered_Subsets (8, 4, Contiguous);
      I4 : constant Subset_Map :=
        Make_Ordered_Subsets (8, 4, Interleaved);
      C3 : constant Subset_Map :=
        Make_Ordered_Subsets (7, 3, Contiguous);
      Raised : Boolean := False;
   begin
      Check (Subset_Covers_Exactly_Once (C4, 4),
             "Contiguous 8/4 covers exactly once");
      Check (Subset_Covers_Exactly_Once (I4, 4),
             "Interleaved 8/4 covers exactly once");
      Check (Subset_Covers_Exactly_Once (C3, 3),
             "Contiguous 7/3 covers exactly once");
      --  Contiguous blocks: bins 1-2 →1, 3-4→2, 5-6→3, 7-8→4
      Check (C4 (1) = 1 and then C4 (2) = 1
               and then C4 (3) = 2 and then C4 (8) = 4,
             "Contiguous block assignment");
      --  Interleaved: 1,2,3,4,1,2,3,4
      Check (I4 (1) = 1 and then I4 (2) = 2
               and then I4 (5) = 1 and then I4 (8) = 4,
             "Interleaved assignment");
      begin
         declare
            Bad : Subset_Map := Make_Ordered_Subsets (3, 5, Contiguous);
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "M > I_Bins raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("4. MLEM with 1 subset ≡ OSEM with all-bins subset");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (8, 8);
      Truth : constant Image := Make_Box_Phantom_1D (8);
      Y : constant Projection := Forward_Project (A, Truth);
      Xm : Image := Ones_Image (8, 1.0);
      Xo : Image := Ones_Image (8, 1.0);
      Sub1 : constant Subset_Map :=
        Make_Ordered_Subsets (8, 1, Contiguous);
      Max_Diff : Real := 0.0;
      D : Real;
   begin
      MLEM_Iterate (Xm, A, Y, 5);
      OSEM_Iterate (Xo, A, Y, Sub1, 1, 5);
      for J in Xm'Range loop
         D := abs (Xm (J) - Xo (J));
         if D > Max_Diff then
            Max_Diff := D;
         end if;
      end loop;
      Check (Max_Diff < 1.0E-8,
             "MLEM ≡ OSEM(M=1) after 5 iters (max diff < 1e-8)");
      Check (All_Nonneg (Xm) and then All_Nonneg (Xo),
             "Both reconstructions nonnegative");
      Check (Subset_Covers_Exactly_Once (Sub1, 1),
             "Single-subset map covers once");
      Check (Approx (RMSE (Xm, Xo), 0.0, 1.0E-8),
             "RMSE between MLEM and OSEM(M=1) ~ 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Nonnegative preservation under MLEM/OSEM");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (6, 8);
      Truth : constant Image := Make_Box_Phantom_1D (6);
      Y : constant Projection := Forward_Project (A, Truth);
      X : Image := Ones_Image (6, 0.5);
      Subs : constant Subset_Map :=
        Make_Ordered_Subsets (8, 4, Interleaved);
      Ok : Boolean := True;
   begin
      for K in 1 .. 10 loop
         MLEM_Step (X, A, Y);
         if not All_Nonneg (X) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "MLEM preserves nonnegativity over 10 steps");
      X := Ones_Image (6, 0.5);
      Ok := True;
      OSEM_Iterate (X, A, Y, Subs, 4, 5);
      Check (All_Nonneg (X), "OSEM preserves nonnegativity");
      Check (Ok, "OSEM nonneg flag");
   end;

   ---------------------------------------------------------------------
   Section ("6. Poisson NLL non-increases over MLEM iterations");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (8, 12);
      Truth : constant Image := Make_Box_Phantom_1D (8);
      Y : constant Projection := Forward_Project (A, Truth);
      X : Image := Ones_Image (8, 1.0);
      Prev, Cur : Real;
      Noninc : Boolean := True;
   begin
      Prev := Poisson_NLL (Y, Forward_Project (A, X));
      for K in 1 .. 8 loop
         MLEM_Step (X, A, Y);
         Cur := Poisson_NLL (Y, Forward_Project (A, X));
         if Cur > Prev + 1.0E-6 then
            Noninc := False;
         end if;
         Prev := Cur;
      end loop;
      Check (Noninc, "Poisson_NLL non-increases over 8 MLEM steps");
      Check (KL_Divergence (Y, Forward_Project (A, X)) >= -1.0E-6,
             "KL_Divergence ≥ 0 (numerical floor)");
      Check (Poisson_NLL (Y, Y) < Poisson_NLL (Y, Forward_Project (A, Ones_Image (8))),
             "NLL(Y,Y) better than NLL(Y, A*ones) typically");
      declare
         Perfect : constant Real := KL_Divergence (Y, Y);
      begin
         Check (Perfect < 1.0E-8, "KL(Y_obs, Y_obs) ≈ 0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. OSEM faster early NLL drop vs MLEM");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (8, 16);
      Truth : constant Image := Make_Box_Phantom_1D (8);
      Y : constant Projection := Forward_Project (A, Truth);
      Xm : Image := Ones_Image (8, 1.0);
      Xo : Image := Ones_Image (8, 1.0);
      Subs : constant Subset_Map :=
        Make_Ordered_Subsets (16, 4, Interleaved);
      N0, Nm1, No1, Nm2, No2 : Real;
   begin
      N0 := Poisson_NLL (Y, Forward_Project (A, Xm));
      --  1 full pass: MLEM 1 iter vs OSEM 1 iter (4 subset updates)
      MLEM_Iterate (Xm, A, Y, 1);
      OSEM_Iterate (Xo, A, Y, Subs, 4, 1);
      Nm1 := Poisson_NLL (Y, Forward_Project (A, Xm));
      No1 := Poisson_NLL (Y, Forward_Project (A, Xo));
      Check (Nm1 < N0 and then No1 < N0,
             "Both reduce NLL after 1 full pass");
      Check (No1 <= Nm1 + 1.0E-4,
             "OSEM NLL ≤ MLEM NLL after 1 pass (early acceleration)");
      MLEM_Iterate (Xm, A, Y, 1);
      OSEM_Iterate (Xo, A, Y, Subs, 4, 1);
      Nm2 := Poisson_NLL (Y, Forward_Project (A, Xm));
      No2 := Poisson_NLL (Y, Forward_Project (A, Xo));
      Check (No2 <= Nm2 + 1.0E-3,
             "OSEM still competitive after 2 passes");
      Check (No1 < N0 - 0.01 or else No2 < N0 - 0.01,
             "OSEM achieves meaningful NLL drop");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty / zero sensitivity handling");
   ---------------------------------------------------------------------
   declare
      --  Pixel 2 never observed: column of zeros
      A : constant System_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1.0, 0.0],
         2 => [1.0, 0.0]];
      Y : constant Projection (1 .. 2) := [2.0, 2.0];
      X : Image (1 .. 2) := [1.0, 7.0];
      S : constant Image := Sensitivity (A);
      Raised : Boolean := False;
   begin
      Check (Approx (S (1), 2.0) and then Approx (S (2), 0.0),
             "Sensitivity has zero for unobserved pixel");
      MLEM_Step (X, A, Y);
      Check (Approx (X (2), 7.0),
             "Zero-sensitivity pixel left unchanged");
      Check (X (1) > 0.0, "Observed pixel updated positively");
      Check (Approx (X (1), 2.0), "Observed pixel reaches y/a = 2");
      Check (All_Nonneg (X), "Zero-sens case stays nonnegative");
      --  All-zero matrix → Degenerate_Geometry
      declare
         A0 : constant System_Matrix (1 .. 2, 1 .. 2) :=
           [others => [others => 0.0]];
         X0 : Image (1 .. 2) := [1.0, 1.0];
         Y0 : constant Projection (1 .. 2) := [0.0, 0.0];
      begin
         begin
            MLEM_Step (X0, A0, Y0);
         exception
            when Degenerate_Geometry =>
               Raised := True;
            when others =>
               null;
         end;
      end;
      Check (Raised, "All-zero A raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid dims raise");
   ---------------------------------------------------------------------
   declare
      Raised_Fwd : Boolean := False;
      Raised_Cap : Boolean := False;
      Raised_Sub : Boolean := False;
      A : constant System_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1.0, 0.0], 2 => [0.0, 1.0]];
      X : constant Image (1 .. 3) := [1.0, 1.0, 1.0];
   begin
      begin
         declare
            Unused : Projection := Forward_Project (A, X);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Fwd := True;
         when Constraint_Error =>
            Raised_Fwd := True;
         when others =>
            null;
      end;
      Check (Raised_Fwd, "Forward_Project dim mismatch raises");

      begin
         declare
            Unused : System_Matrix :=
              Make_2D_Parallel_Beam_Matrix (16, 8, 16);
            --  J=256 > Max_Pixels=64
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Capacity_Exceeded =>
            Raised_Cap := True;
         when others =>
            null;
      end;
      Check (Raised_Cap, "Oversized geometry raises Capacity_Exceeded");

      declare
         A2 : constant System_Matrix := Make_1D_Strip_Matrix (4, 4);
         Y2 : constant Projection :=
           Forward_Project (A2, Ones_Image (4));
         X2 : Image := Ones_Image (4);
         Bad_Map : constant Subset_Map (1 .. 4) := [1, 1, 1, 1];  --  missing
      begin
         begin
            OSEM_Iterate (X2, A2, Y2, Bad_Map, 4, 1);
         exception
            when Invalid_Argument =>
               Raised_Sub := True;
            when others =>
               null;
         end;
      end;
      Check (Raised_Sub, "Invalid subset partition raises");
   end;

   ---------------------------------------------------------------------
   Section ("10. Phantom recovery RMSE improves vs initial guess");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (8, 16);
      Truth : constant Image := Make_Box_Phantom_1D (8);
      Y : constant Projection := Forward_Project (A, Truth);
      X : Image := Ones_Image (8, 1.0);
      R0, R1, R5 : Real;
   begin
      R0 := RMSE (X, Truth);
      MLEM_Iterate (X, A, Y, 1);
      R1 := RMSE (X, Truth);
      MLEM_Iterate (X, A, Y, 4);
      R5 := RMSE (X, Truth);
      Check (R1 < R0, "RMSE improves after 1 MLEM iter");
      Check (R5 < R1 + 1.0E-6, "RMSE non-worse after more iters");
      Check (R5 < R0 * 0.5, "RMSE reduced by >50% after 5 iters");
      Check (R0 > 0.0, "Initial RMSE positive vs structured phantom");
      Check (All_Nonneg (X), "Recovered image nonnegative");
      Check (Truth (1) > 0.0 and then Truth (Truth'Last) > 0.0,
             "Phantom endpoints positive background");
   end;

   ---------------------------------------------------------------------
   Section ("11. Subset sensitivity / backproject subset");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix (1 .. 4, 1 .. 2) :=
        [1 => [1.0, 0.0],
         2 => [0.0, 1.0],
         3 => [1.0, 1.0],
         4 => [0.0, 2.0]];
      Map : constant Subset_Map (1 .. 4) := [1, 1, 2, 2];
      S1 : constant Image := Sensitivity_Subset (A, Map, 1);
      S2 : constant Image := Sensitivity_Subset (A, Map, 2);
      S  : constant Image := Sensitivity (A);
      Y  : constant Projection (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      B1 : constant Image := Back_Project_Subset (A, Y, Map, 1);
      --  subset1 bins 1,2: b1=1*1+0*2=1; b2=0*1+1*2=2
   begin
      Check (Approx (S1 (1), 1.0) and then Approx (S1 (2), 1.0),
             "Sensitivity_Subset m=1");
      Check (Approx (S2 (1), 1.0) and then Approx (S2 (2), 3.0),
             "Sensitivity_Subset m=2");
      Check (Approx (S1 (1) + S2 (1), S (1))
               and then Approx (S1 (2) + S2 (2), S (2)),
             "Subset sensitivities sum to full");
      Check (Approx (B1 (1), 1.0) and then Approx (B1 (2), 2.0),
             "Back_Project_Subset m=1");
   end;

   ---------------------------------------------------------------------
   Section ("12. Toy 2-D parallel-beam phantom recovery");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 4;  --  4×4 = 16 pixels
      A : constant System_Matrix :=
        Make_2D_Parallel_Beam_Matrix (N, 4, 4);  --  16 bins
      Truth : constant Image := Make_Box_Phantom_2D (N);
      Y : constant Projection := Forward_Project (A, Truth);
      Xm : Image := Ones_Image (N * N, 1.0);
      Xo : Image := Ones_Image (N * N, 1.0);
      Subs : constant Subset_Map :=
        Make_Ordered_Subsets (16, 4, Contiguous);
      Rm0, Rm, Ro : Real;
   begin
      Check (A'Length (1) = 16 and then A'Length (2) = 16,
             "2-D geometry dims 16×16");
      Rm0 := RMSE (Xm, Truth);
      MLEM_Iterate (Xm, A, Y, 8);
      OSEM_Iterate (Xo, A, Y, Subs, 4, 4);
      Rm := RMSE (Xm, Truth);
      Ro := RMSE (Xo, Truth);
      Check (Rm < Rm0, "2-D MLEM RMSE improves");
      Check (Ro < Rm0, "2-D OSEM RMSE improves");
      Check (All_Nonneg (Xm) and then All_Nonneg (Xo),
             "2-D reconstructions nonnegative");
      Check (Subset_Covers_Exactly_Once (Subs, 4),
             "2-D contiguous 4-subset partition ok");
      Check (Y'Length = 16, "2-D projection length 16");
      declare
         Sens : constant Image := Sensitivity (A);
         Pos : Boolean := False;
      begin
         for J in Sens'Range loop
            if Sens (J) > 0.0 then
               Pos := True;
            end if;
         end loop;
         Check (Pos, "2-D geometry has positive sensitivity somewhere");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. OSEM_Step_Subset single update + monitors");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (4, 4);
      Truth : constant Image := Make_Box_Phantom_1D (4);
      Y : constant Projection := Forward_Project (A, Truth);
      X : Image := Ones_Image (4, 1.0);
      Subs : constant Subset_Map :=
        Make_Ordered_Subsets (4, 2, Contiguous);
      N_Before, N_After : Real;
      Ones : constant Projection (1 .. 4) := [1.0, 1.0, 1.0, 1.0];
   begin
      N_Before := Poisson_NLL (Y, Forward_Project (A, X));
      OSEM_Step_Subset (X, A, Y, Subs, 1);
      Check (All_Nonneg (X), "Single subset step nonnegative");
      OSEM_Step_Subset (X, A, Y, Subs, 2);
      N_After := Poisson_NLL (Y, Forward_Project (A, X));
      Check (N_After <= N_Before + 1.0E-3,
             "One OSEM iteration (2 subsets) does not worsen NLL much");
      Check (KL_Divergence (Y, Y) < 1.0E-6,
             "KL(Y,Y) ≈ 0");
      Check (KL_Divergence (Ones, Ones) < 1.0E-6,
             "KL(ones,ones) ≈ 0");
      --  Perfect data fit after many MLEM iters → small KL
      declare
         Xp : Image := Ones_Image (4, 1.0);
      begin
         MLEM_Iterate (Xp, A, Y, 30);
         Check (KL_Divergence (Y, Forward_Project (A, Xp)) < 0.5,
                "KL small after many MLEM iters on consistent data");
         Check (RMSE (Xp, Truth) < RMSE (Ones_Image (4), Truth),
                "Recovered closer to truth than flat start");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Ones_Image / capacity edge cases");
   ---------------------------------------------------------------------
   declare
      O : constant Image := Ones_Image (5, 2.5);
      Raised : Boolean := False;
   begin
      Check (Approx (O (1), 2.5) and then Approx (O (5), 2.5),
             "Ones_Image fills value");
      begin
         declare
            Unused : Projection := Zero_Projection (Max_Bins + 1);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Capacity_Exceeded =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Zero_Projection over Max_Bins raises");
      declare
         Big : constant Image := Ones_Image (Max_Pixels, 1.0);
         Map : constant Subset_Map :=
           Make_Ordered_Subsets (Max_Bins, Max_Subsets, Interleaved);
      begin
         Check (Big'Length = Max_Pixels,
                "Ones_Image(Max_Pixels) length");
         Check (Map'Length = Max_Bins,
                "Make_Ordered_Subsets at Max_Bins/Max_Subsets");
         Check (Subset_Covers_Exactly_Once (Map, Max_Subsets),
                "Max-capacity subset partition covers once");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Contiguous uneven partition + linearity");
   ---------------------------------------------------------------------
   declare
      Map : constant Subset_Map :=
        Make_Ordered_Subsets (10, 3, Contiguous);
      C1, C2, C3 : Natural := 0;
      A : constant System_Matrix := Make_1D_Strip_Matrix (5, 6);
      Yz : constant Projection := Forward_Project (A, Zero_Image (5));
      Y1 : constant Projection := Forward_Project (A, Ones_Image (5, 1.0));
      Y2 : constant Projection := Forward_Project (A, Ones_Image (5, 2.0));
      Lin_Ok, Zero_Ok : Boolean := True;
   begin
      for I in Map'Range loop
         case Map (I) is
            when 1 => C1 := C1 + 1;
            when 2 => C2 := C2 + 1;
            when others => C3 := C3 + 1;
         end case;
      end loop;
      Check (C1 = 4 and then C2 = 3 and then C3 = 3,
             "Contiguous 10/3 sizes 4,3,3");
      Check (Map (1) = 1 and then Map (5) = 2 and then Map (10) = 3,
             "Contiguous boundaries");
      for I in Yz'Range loop
         if not Approx (Yz (I), 0.0) then
            Zero_Ok := False;
         end if;
         if not Approx (Y2 (I), 2.0 * Y1 (I), 1.0E-8) then
            Lin_Ok := False;
         end if;
      end loop;
      Check (Zero_Ok, "Forward(A,0)=0");
      Check (Lin_Ok, "Forward_Project homogeneous of degree 1");
      Check (Y1'Length = 6 and then A'Length (2) = 5,
             "Strip matrix shape 6×5");
   end;

   ---------------------------------------------------------------------
   Section ("16. MLEM single step algebraic check");
   ---------------------------------------------------------------------
   declare
      --  1 pixel, 1 bin: A=[2], y=4, x0=1 → ŷ=2, ratio=2,
      --  s=2, corr=2*2=4 → x ← 1/2*4 = 2
      A : constant System_Matrix (1 .. 1, 1 .. 1) :=
        [1 => [1 => 2.0]];
      Y : constant Projection (1 .. 1) := [1 => 4.0];
      X : Image (1 .. 1) := [1 => 1.0];
   begin
      MLEM_Step (X, A, Y);
      Check (Approx (X (1), 2.0), "1×1 MLEM step → x=2");
      MLEM_Step (X, A, Y);
      --  ŷ=4, ratio=1, x←2/2*2=2 (fixed point)
      Check (Approx (X (1), 2.0), "1×1 MLEM fixed point at truth");
      Check (Approx (Forward_Project (A, X) (1), 4.0),
             "Forward matches observation at fixed point");
      declare
         Xo : Image (1 .. 1) := [1 => 1.0];
         Sub : constant Subset_Map (1 .. 1) := [1 => 1];
      begin
         OSEM_Step_Subset (Xo, A, Y, Sub, 1);
         Check (Approx (Xo (1), 2.0), "1×1 OSEM subset step → x=2");
         Check (Near (Xo (1), X (1)), "OSEM matches MLEM on 1×1");
      end;
      Check (Approx (Sensitivity (A) (1), 2.0), "1×1 sensitivity = 2");
      Check (Approx (Poisson_NLL (Y, Forward_Project (A, X)),
                     Poisson_NLL (Y, Y), 1.0E-6),
             "NLL at fixed point equals NLL(Y,Y)");
   end;

   ---------------------------------------------------------------------
   Section ("17. Interleaved OSEM multi-pass + Enforce");
   ---------------------------------------------------------------------
   declare
      A : constant System_Matrix := Make_1D_Strip_Matrix (8, 12);
      Truth : constant Image := Make_Box_Phantom_1D (8);
      Y : constant Projection := Forward_Project (A, Truth);
      X : Image := Ones_Image (8, 1.0);
      Subs : constant Subset_Map :=
        Make_Ordered_Subsets (12, 3, Interleaved);
      R0, R3 : Real;
      N0, N3 : Real;
   begin
      R0 := RMSE (X, Truth);
      N0 := Poisson_NLL (Y, Forward_Project (A, X));
      OSEM_Iterate (X, A, Y, Subs, 3, 3);
      R3 := RMSE (X, Truth);
      N3 := Poisson_NLL (Y, Forward_Project (A, X));
      Check (R3 < R0, "Interleaved OSEM RMSE improves in 3 iters");
      Check (N3 < N0, "Interleaved OSEM NLL improves in 3 iters");
      Check (All_Nonneg (X), "Interleaved OSEM nonnegative");
      Check (Subs (1) = 1 and then Subs (2) = 2 and then Subs (3) = 3
               and then Subs (4) = 1,
             "Interleaved 12/3 pattern");
      declare
         Neg : Image (1 .. 3) := [-5.0, -0.1, 3.0];
      begin
         Enforce_Nonnegative (Neg);
         Check (Approx (Neg (1), 0.0) and then Approx (Neg (2), 0.0)
                  and then Approx (Neg (3), 3.0),
                "Enforce keeps positives, zeros negatives");
      end;
      Check (Near (1.0, 1.0, 0.0), "Near with Tol=0 exact");
      Check (not Near (1.0, 1.0 + 1.0E-3, 1.0E-6),
             "Near rejects outside Tol");
      Check (Approx (RMSE (Truth, Truth), 0.0), "RMSE(truth,truth)=0");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0);
   if Fail_Count /= 0 then
      raise Program_Error with "test failures:" & Fail_Count'Image;
   end if;
   Put_Line ("All tests passed.");
end Tests;

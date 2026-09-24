--  Standalone test suite for Thomas_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Thomas_Algorithm; use Thomas_Algorithm;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line ("Thomas_Algorithm (TDMA) test suite");
   Ada.Text_IO.Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Norm2 / Max_Abs");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      V : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      W : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Approx (Norm2 (U), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 (W), 1.0), "Norm2 unit");
      Check (Approx (Max_Abs (U), 4.0), "Max_Abs U");
      Check (Approx (Max_Abs (W), 1.0), "Max_Abs W");
      Check (Near (-2.0, -2.0), "Near negatives");
      Check (Approx (Norm2 (Zero_Vector (2)), 0.0), "Norm2 zero");
      Check (Approx (Max_Abs (Ones_Vector (4, 2.5)), 2.5), "Max_Abs ones");
   end;

   ---------------------------------------------------------------------
   Section ("2. Diagonal dominance helpers");
   ---------------------------------------------------------------------
   declare
      A : Vector (1 .. 3);
      B : Vector (1 .. 3);
      C : Vector (1 .. 3);
      Aw : constant Vector (1 .. 3) := [0.0, 5.0, 5.0];
      Bw : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Cw : constant Vector (1 .. 3) := [5.0, 5.0, 0.0];
   begin
      Make_Poisson_1D (3, A, B, C);
      Check (Is_Diagonally_Dominant (A, B, C), "Poisson weakly DD");
      Check (not Is_Strictly_Diagonally_Dominant (A, B, C),
             "Poisson not strictly DD");
      Make_Constant_Tridiagonal (3, -1.0, 4.0, -1.0, A, B, C);
      Check (Is_Diagonally_Dominant (A, B, C), "const 4/-1 DD");
      Check (Is_Strictly_Diagonally_Dominant (A, B, C),
             "const 4/-1 strictly DD");
      Check (not Is_Diagonally_Dominant (Aw, Bw, Cw), "weak off-diag rejects");
      Check (Approx (A (1), 0.0), "A(1)=0 after builder");
      Check (Approx (C (3), 0.0), "C(N)=0 after builder");
      Check (Approx (B (2), 4.0), "diag middle");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders: Poisson / constant / vectors");
   ---------------------------------------------------------------------
   declare
      A, B, C, D : Vector (1 .. 5);
      Z : constant Vector := Zero_Vector (3);
      O : constant Vector := Ones_Vector (3, 7.0);
   begin
      Make_Poisson_1D_System (5, A, B, C, D, 1.0);
      Check (Approx (B (1), 2.0) and Approx (B (5), 2.0), "Poisson diag ends");
      Check (Approx (A (2), -1.0) and Approx (C (4), -1.0), "Poisson off");
      Check (Approx (A (1), 0.0) and Approx (C (5), 0.0), "Poisson corners 0");
      Check (Approx (D (3), 1.0), "Poisson RHS ones");
      Check (Approx (Z (1), 0.0) and Approx (Z (3), 0.0), "Zero_Vector");
      Check (Approx (O (2), 7.0), "Ones_Vector value");
      Make_Constant_Tridiagonal (5, 0.5, 3.0, 0.25, A, B, C);
      Check (Approx (A (1), 0.0), "const A1");
      Check (Approx (A (3), 0.5), "const A mid");
      Check (Approx (C (5), 0.0), "const CN");
      Check (Approx (C (1), 0.25), "const C1");
      Check (Approx (B (4), 3.0), "const B");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known 2x2 system");
   ---------------------------------------------------------------------
   --  [2 1; 1 2] [x;y] = [3;3]  => x=y=1
   declare
      A : constant Vector (1 .. 2) := [0.0, 1.0];
      B : constant Vector (1 .. 2) := [2.0, 2.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      D : constant Vector (1 .. 2) := [3.0, 3.0];
      R : constant Result := Thomas (A, B, C, D);
      Res : constant Float :=
        Residual_Norm (A, B, C, D, R.X (1 .. 2));
   begin
      Check (R.Success and R.Stat = Ok, "2x2 Success/Ok");
      Check (R.N = 2, "2x2 N");
      Check (Approx (R.X (1), 1.0), "2x2 x1=1");
      Check (Approx (R.X (2), 1.0), "2x2 x2=1");
      Check (Approx (Res, 0.0, 1.0E-5), "2x2 residual ~0");
      Check (Solve (A, B, C, D).Success, "Solve alias Success");
   end;

   ---------------------------------------------------------------------
   Section ("5. Known 3x3 system");
   ---------------------------------------------------------------------
   --  Wikipedia-style: a=[0,2,4], b=[1,3,5]? Use concrete:
   --  row1: 2 x1 + 1 x2       = 5
   --  row2: 1 x1 + 3 x2 + 1 x3 = 10
   --  row3:       1 x2 + 2 x3  = 7
   --  Solution: x=(1,3,2) check: 2+3=5; 1+9+2=12 wait adjust.
   --  Use x=(1,2,3):
   --  2*1 + 1*2 = 4
   --  1*1 + 4*2 + 1*3 = 12
   --  1*2 + 2*3 = 8
   declare
      A : constant Vector (1 .. 3) := [0.0, 1.0, 1.0];
      B : constant Vector (1 .. 3) := [2.0, 4.0, 2.0];
      C : constant Vector (1 .. 3) := [1.0, 1.0, 0.0];
      D : constant Vector (1 .. 3) := [4.0, 12.0, 8.0];
      R : constant Result := Thomas (A, B, C, D);
   begin
      Check (R.Success, "3x3 Success");
      Check (Approx (R.X (1), 1.0), "3x3 x1");
      Check (Approx (R.X (2), 2.0), "3x3 x2");
      Check (Approx (R.X (3), 3.0), "3x3 x3");
      Check (Approx (Residual_Max_Abs (A, B, C, D, R.X (1 .. 3)),
                    0.0, 1.0E-5),
             "3x3 max |r|");
      Check (Is_Diagonally_Dominant (A, B, C), "3x3 DD");
   end;

   ---------------------------------------------------------------------
   Section ("6. Identity / diagonal systems");
   ---------------------------------------------------------------------
   declare
      N : constant := 4;
      A : constant Vector (1 .. N) := [0.0, 0.0, 0.0, 0.0];
      B : constant Vector (1 .. N) := [1.0, 1.0, 1.0, 1.0];
      C : constant Vector (1 .. N) := [0.0, 0.0, 0.0, 0.0];
      D : constant Vector (1 .. N) := [10.0, 20.0, 30.0, 40.0];
      R : constant Result := Thomas (A, B, C, D);
   begin
      Check (R.Success, "diag Success");
      Check (Approx (R.X (1), 10.0), "diag x1");
      Check (Approx (R.X (2), 20.0), "diag x2");
      Check (Approx (R.X (3), 30.0), "diag x3");
      Check (Approx (R.X (4), 40.0), "diag x4");
   end;

   ---------------------------------------------------------------------
   Section ("7. Single unknown n=1");
   ---------------------------------------------------------------------
   declare
      A : constant Vector (1 .. 1) := [0.0];
      B : constant Vector (1 .. 1) := [5.0];
      C : constant Vector (1 .. 1) := [0.0];
      D : constant Vector (1 .. 1) := [15.0];
      R : constant Result := Thomas (A, B, C, D);
      Z : constant Result := Thomas ([0.0], [0.0], [0.0], [1.0]);
   begin
      Check (R.Success and Approx (R.X (1), 3.0), "n=1 x=3");
      Check (Z.Stat = Degenerate, "n=1 zero pivot Degenerate");
      Check (not Z.Success, "n=1 Degenerate not Success");
   end;

   ---------------------------------------------------------------------
   Section ("8. Poisson 1D systems");
   ---------------------------------------------------------------------
   declare
      N : constant := 8;
      A, B, C, D : Vector (1 .. N);
      R : Result;
      Res : Float;
   begin
      Make_Poisson_1D_System (N, A, B, C, D, 1.0);
      R := Thomas (A, B, C, D);
      Check (R.Success, "Poisson8 Success");
      Check (Is_Diagonally_Dominant (A, B, C), "Poisson8 DD");
      Res := Residual_Norm (A, B, C, D, R.X (1 .. N));
      Check (Res < 1.0E-4, "Poisson8 residual small");
      --  For (−1,2,−1)x = 1, solution is quadratic-like positive.
      Check (R.X (1) > 0.0 and R.X (N) > 0.0, "Poisson8 positive ends");
      Check (R.X (N / 2) >= R.X (1), "Poisson8 mid >= end");

      --  Larger Poisson
      declare
         M : constant := 32;
         A2, B2, C2, D2 : Vector (1 .. M);
         R2 : Result;
      begin
         Make_Poisson_1D_System (M, A2, B2, C2, D2, 2.0);
         R2 := Solve (A2, B2, C2, D2);
         Check (R2.Success, "Poisson32 Success");
         Check (Residual_Max_Abs (A2, B2, C2, D2, R2.X (1 .. M)) < 1.0E-3,
                "Poisson32 max|r|");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Manufactured solution (constant / linear)");
   ---------------------------------------------------------------------
   declare
      N : constant := 10;
      A, B, C, D, Xtrue : Vector (1 .. N);
      R : Result;
   begin
      Make_Constant_Tridiagonal (N, -1.0, 4.0, -1.0, A, B, C);
      --  True solution x_i = i
      for I in 1 .. N loop
         Xtrue (I) := Float (I);
      end loop;
      --  Build RHS from A,B,C,Xtrue
      for I in 1 .. N loop
         D (I) := B (I) * Xtrue (I);
         if I > 1 then
            D (I) := D (I) + A (I) * Xtrue (I - 1);
         end if;
         if I < N then
            D (I) := D (I) + C (I) * Xtrue (I + 1);
         end if;
      end loop;
      R := Thomas (A, B, C, D);
      Check (R.Success, "manufactured Success");
      Check (Vec_Near (R.X (1 .. N), Xtrue, 1.0E-4), "manufactured x≈i");
      Check (Approx (Residual_Norm (A, B, C, D, R.X (1 .. N)), 0.0, 1.0E-4),
             "manufactured residual");
   end;

   ---------------------------------------------------------------------
   Section ("10. Degenerate / zero pivot");
   ---------------------------------------------------------------------
   declare
      --  Singular: row1 [0 0 ...] effectively b1=0
      A0 : constant Vector (1 .. 3) := [0.0, 1.0, 1.0];
      B0 : constant Vector (1 .. 3) := [0.0, 2.0, 2.0];
      C0 : constant Vector (1 .. 3) := [1.0, 1.0, 0.0];
      D0 : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      R0 : constant Result := Thomas (A0, B0, C0, D0);
      --  Second pivot may vanish: carefully craft
      A1 : constant Vector (1 .. 2) := [0.0, 2.0];
      B1 : constant Vector (1 .. 2) := [1.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      --  After first: c'=1, denom2 = 2 - 2*1 = 0
      D1 : constant Vector (1 .. 2) := [1.0, 1.0];
      R1 : constant Result := Thomas (A1, B1, C1, D1);
   begin
      Check (R0.Stat = Degenerate, "b1=0 Degenerate");
      Check (R0.Pivot = 1, "pivot index 1");
      Check (not R0.Success, "b1=0 not Success");
      Check (R1.Stat = Degenerate, "second pivot Degenerate");
      Check (R1.Pivot = 2, "pivot index 2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Thomas_In_Place");
   ---------------------------------------------------------------------
   declare
      A : constant Vector (1 .. 3) := [0.0, 1.0, 1.0];
      B : constant Vector (1 .. 3) := [2.0, 4.0, 2.0];
      C : Vector (1 .. 3) := [1.0, 1.0, 0.0];
      D : Vector (1 .. 3) := [4.0, 12.0, 8.0];
      X : Vector (1 .. 3);
      St : Status;
      Pv : Dim_Index;
   begin
      Thomas_In_Place (A, B, C, D, X, St, Pv);
      Check (St = Ok, "in-place Ok");
      Check (Approx (X (1), 1.0) and Approx (X (2), 2.0)
             and Approx (X (3), 3.0),
             "in-place solution");
   end;

   ---------------------------------------------------------------------
   Section ("12. Residual vector components");
   ---------------------------------------------------------------------
   declare
      A : constant Vector (1 .. 2) := [0.0, 1.0];
      B : constant Vector (1 .. 2) := [2.0, 2.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      D : constant Vector (1 .. 2) := [3.0, 3.0];
      X : constant Vector (1 .. 2) := [1.0, 1.0];
      Bad : constant Vector (1 .. 2) := [0.0, 0.0];
      Rv : constant Vector := Residual (A, B, C, D, X);
      Rb : constant Vector := Residual (A, B, C, D, Bad);
   begin
      Check (Approx (Rv (1), 0.0) and Approx (Rv (2), 0.0), "resid exact 0");
      Check (Approx (Rb (1), 3.0), "resid bad r1");
      Check (Approx (Rb (2), 3.0), "resid bad r2");
      Check (Approx (Residual_Norm (A, B, C, D, Bad),
                    Ada.Numerics.Elementary_Functions.Sqrt (18.0), 1.0E-5),
             "resid bad norm");
   end;

   ---------------------------------------------------------------------
   Section ("13. Strict DD constant systems batch");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for N in 2 .. 16 loop
         declare
            A, B, C, D : Vector (1 .. N);
            R : Result;
            Xtrue : Vector (1 .. N);
         begin
            Make_Constant_Tridiagonal (N, -0.5, 3.0, -0.5, A, B, C);
            for I in 1 .. N loop
               Xtrue (I) := Float (I) * 0.5;
            end loop;
            for I in 1 .. N loop
               D (I) := B (I) * Xtrue (I);
               if I > 1 then
                  D (I) := D (I) + A (I) * Xtrue (I - 1);
               end if;
               if I < N then
                  D (I) := D (I) + C (I) * Xtrue (I + 1);
               end if;
            end loop;
            R := Thomas (A, B, C, D);
            if not R.Success
              or else not Vec_Near (R.X (1 .. N), Xtrue, 1.0E-3)
            then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "batch N=2..16 manufactured");
      --  Count individual N checks as separate passes for volume
      for N in 2 .. 16 loop
         declare
            A, B, C, D : Vector (1 .. N);
            R : Result;
         begin
            Make_Poisson_1D_System (N, A, B, C, D);
            R := Solve (A, B, C, D);
            Check (R.Success
                   and then Residual_Max_Abs
                     (A, B, C, D, R.X (1 .. N)) < 1.0E-3,
                   "Poisson N=" & N'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Cap / Max_N sanity");
   ---------------------------------------------------------------------
   declare
      A, B, C, D : Vector (1 .. 64);
      R : Result;
   begin
      Make_Poisson_1D_System (64, A, B, C, D, 1.0);
      R := Thomas (A, B, C, D);
      Check (R.Success, "Poisson64 Success");
      Check (R.N = 64, "Poisson64 N");
      Check (Is_Diagonally_Dominant (A, B, C), "Poisson64 DD");
      Check (Residual_Norm (A, B, C, D, R.X (1 .. 64)) < 1.0E-3,
             "Poisson64 residual");
      Check (Residual_Max_Abs (A, B, C, D, R.X (1 .. 64)) < 1.0E-4,
             "Poisson64 max|r|");
      Check (R.X (1) > 0.0 and R.X (64) > 0.0, "Poisson64 positive ends");
   end;

   ---------------------------------------------------------------------
   Section ("15. Symmetry of Poisson solution for symmetric RHS");
   ---------------------------------------------------------------------
   declare
      N : constant := 7;
      A, B, C, D : Vector (1 .. N);
      R : Result;
   begin
      Make_Poisson_1D_System (N, A, B, C, D, 1.0);
      R := Thomas (A, B, C, D);
      Check (R.Success, "sym Poisson Success");
      Check (Approx (R.X (1), R.X (N), 1.0E-4), "x1≈xN");
      Check (Approx (R.X (2), R.X (N - 1), 1.0E-4), "x2≈xN-1");
      Check (Approx (R.X (3), R.X (N - 2), 1.0E-4), "x3≈xN-2");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

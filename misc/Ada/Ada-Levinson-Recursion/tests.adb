--  Standalone test suite for Levinson_Recursion (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Levinson_Recursion; use Levinson_Recursion;

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
   Ada.Text_IO.Put_Line ("Levinson_Recursion test suite");
   Ada.Text_IO.Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Norm2 / Max_Abs / vectors");
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
   Section ("2. Toeplitz helpers / builders");
   ---------------------------------------------------------------------
   declare
      R : Vector (1 .. 3);
      X : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      Y : Vector (1 .. 3);
   begin
      Make_Constant_Toeplitz (3, 4.0, 1.0, R);
      Check (Approx (R (1), 4.0), "const R1");
      Check (Approx (R (2), 1.0) and Approx (R (3), 1.0), "const off");
      Check (Approx (Toeplitz_Entry (R, 1, 1), 4.0), "entry diag");
      Check (Approx (Toeplitz_Entry (R, 1, 3), 1.0), "entry lag2");
      Check (Approx (Toeplitz_Entry (R, 3, 1), 1.0), "entry sym");
      Y := Multiply_Toeplitz (R, X);
      Check (Approx (Y (1), 4.0), "mult col1 row1");
      Check (Approx (Y (2), 1.0), "mult col1 row2");
      Check (Approx (Y (3), 1.0), "mult col1 row3");
      Make_Exponential_Toeplitz (3, 2.0, 0.5, 1.0, R);
      Check (Approx (R (1), 2.0), "exp diag");
      Check (Approx (R (2), 0.5), "exp lag1");
      Check (Approx (R (3), 0.25), "exp lag2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Known 1x1 and 2x2 SPD Toeplitz");
   ---------------------------------------------------------------------
   declare
      R1 : constant Vector (1 .. 1) := [5.0];
      Y1 : constant Vector (1 .. 1) := [10.0];
      S1 : constant Result := Solve_Levinson (R1, Y1);
      R2 : constant Vector (1 .. 2) := [2.0, 1.0];
      Y2 : constant Vector (1 .. 2) := [3.0, 3.0];
      S2 : constant Result := Solve_Levinson (R2, Y2);
      Rn : constant Float :=
        Residual_Norm (R2, Y2, S2.X (1 .. 2));
   begin
      Check (S1.Success and S1.Stat = Ok, "1x1 Success/Ok");
      Check (Approx (S1.X (1), 2.0), "1x1 x=2");
      Check (S2.Success and S2.Stat = Ok, "2x2 Success/Ok");
      Check (S2.N = 2, "2x2 N");
      Check (Approx (S2.X (1), 1.0), "2x2 x1=1");
      Check (Approx (S2.X (2), 1.0), "2x2 x2=1");
      Check (Approx (Rn, 0.0, 1.0E-5), "2x2 residual ~0");
      Check (Solve (R2, Y2).Success, "Solve alias Success");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known 3x3 SPD Toeplitz");
   ---------------------------------------------------------------------
   --  T = [[4,1,0.5],[1,4,1],[0.5,1,4]], y=[1,2,3]
   --  dense x ≈ [0.08928571, 0.3125, 0.66071429]
   declare
      R : constant Vector (1 .. 3) := [4.0, 1.0, 0.5];
      Y : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      S : constant Result := Solve_Levinson (R, Y);
      TX : constant Vector := Multiply_Toeplitz (R, S.X (1 .. 3));
   begin
      Check (S.Success, "3x3 Success");
      Check (Approx (S.X (1), 0.08928571, 1.0E-5), "3x3 x1");
      Check (Approx (S.X (2), 0.3125, 1.0E-5), "3x3 x2");
      Check (Approx (S.X (3), 0.66071429, 1.0E-5), "3x3 x3");
      Check (Approx (Residual_Norm (R, Y, S.X (1 .. 3)), 0.0, 1.0E-5),
             "3x3 residual");
      Check (Vec_Near (TX, Y, 1.0E-5), "3x3 Tx=y");
      Check (Approx (Residual_Max_Abs (R, Y, S.X (1 .. 3)), 0.0, 1.0E-5),
             "3x3 max abs residual");
   end;

   ---------------------------------------------------------------------
   Section ("5. Durbin Yule-Walker vs dense");
   ---------------------------------------------------------------------
   --  r = [1, 0.5, 0.2, 0.1]; T a = -r[1:]
   declare
      R : constant Vector (1 .. 4) := [1.0, 0.5, 0.2, 0.1];
      D : constant Durbin_Result := Durbin_Yule_Walker (R);
      --  Dense check via Levinson on T (from R(1..3)) with RHS = -R(2..4)
      Rt : constant Vector (1 .. 3) := [1.0, 0.5, 0.2];
      Yt : constant Vector (1 .. 3) := [-0.5, -0.2, -0.1];
      S  : constant Result := Solve_Levinson (Rt, Yt);
   begin
      Check (D.Success and D.Stat = Ok, "Durbin Success");
      Check (D.P = 3, "Durbin P=3");
      Check (Approx (D.A (1), S.X (1), 1.0E-5), "Durbin a1=Levinson");
      Check (Approx (D.A (2), S.X (2), 1.0E-5), "Durbin a2=Levinson");
      Check (Approx (D.A (3), S.X (3), 1.0E-5), "Durbin a3=Levinson");
      Check (D.E > 0.0, "Durbin E>0");
      Check (abs (D.K (1)) <= 1.0 + 1.0E-5, "|k1|<=1");
      Check (abs (D.K (2)) <= 1.0 + 1.0E-5, "|k2|<=1");
      Check (abs (D.K (3)) <= 1.0 + 1.0E-5, "|k3|<=1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Reflection coefficients");
   ---------------------------------------------------------------------
   declare
      R : constant Vector (1 .. 4) := [1.0, 0.5, 0.25, 0.125];
      Refl : constant Reflection_Result := Reflection_Coefficients (R);
      D    : constant Durbin_Result := Durbin_Yule_Walker (R);
      R1   : constant Vector (1 .. 1) := [3.0];
      Ref1 : constant Reflection_Result := Reflection_Coefficients (R1);
   begin
      Check (Refl.Success, "Refl Success");
      Check (Refl.N = 3, "Refl N=3");
      Check (Approx (Refl.K (1), D.K (1)), "Refl k1=Durbin");
      Check (Approx (Refl.K (2), D.K (2)), "Refl k2=Durbin");
      Check (Approx (Refl.K (3), D.K (3)), "Refl k3=Durbin");
      Check (Approx (Refl.E, D.E), "Refl E=Durbin E");
      Check (Approx (Refl.K (1), -0.5), "geometric k1=-0.5");
      Check (Ref1.Success and Ref1.N = 0, "N=1 no coeffs");
      Check (Approx (Ref1.E, 3.0), "N=1 E=t0");
   end;

   ---------------------------------------------------------------------
   Section ("7. Residual identity Tx and random-ish SPD");
   ---------------------------------------------------------------------
   declare
      R : Vector (1 .. 5);
      Y : constant Vector (1 .. 5) := [1.0, -1.0, 2.0, 0.5, -0.5];
      S : Result;
   begin
      Make_Exponential_Toeplitz (5, 3.0, 0.4, 1.0, R);
      S := Solve_Levinson (R, Y);
      Check (S.Success, "exp5 Success");
      Check (Approx (Residual_Norm (R, Y, S.X (1 .. 5)), 0.0, 1.0E-4),
             "exp5 residual");
      Check (Vec_Near (Multiply_Toeplitz (R, S.X (1 .. 5)), Y, 1.0E-4),
             "exp5 Tx≈y");
   end;

   ---------------------------------------------------------------------
   Section ("8. Degenerate / singular detection");
   ---------------------------------------------------------------------
   declare
      --  Zero diagonal
      Rz : constant Vector (1 .. 2) := [0.0, 1.0];
      Yz : constant Vector (1 .. 2) := [1.0, 1.0];
      Sz : constant Result := Solve_Levinson (Rz, Yz);
      --  Rank-deficient-ish: all ones Toeplitz is singular for n>1
      Ro : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Yo : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      So : constant Result := Solve_Levinson (Ro, Yo);
      Dz : constant Durbin_Result :=
        Durbin_Yule_Walker (Vector'(1 => 0.0, 2 => 1.0));
   begin
      Check (not Sz.Success and Sz.Stat = Degenerate, "zero diag Degenerate");
      Check (Sz.Order = 1, "zero diag Order=1");
      Check (not So.Success and So.Stat = Degenerate,
             "all-ones singular Degenerate");
      Check (not Dz.Success and Dz.Stat = Degenerate, "Durbin zero E0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Larger systems n=8,16,32 residual");
   ---------------------------------------------------------------------
   declare
      procedure Check_Size (N : Positive; Diag, Rho : Float) is
         R : Vector (1 .. N);
         Y : Vector (1 .. N);
         S : Result;
      begin
         Make_Exponential_Toeplitz (N, Diag, Rho, 1.0, R);
         for I in 1 .. N loop
            Y (I) := Float (I) * 0.1 - 0.5;
         end loop;
         S := Solve_Levinson (R, Y);
         Check (S.Success, "n=" & N'Image & " Success");
         Check (Approx (Residual_Norm (R, Y, S.X (1 .. N)), 0.0, 1.0E-3),
                "n=" & N'Image & " residual");
         Check (S.N = N, "n=" & N'Image & " N field");
      end Check_Size;
   begin
      Check_Size (8, 2.5, 0.85);
      Check_Size (16, 3.0, 0.7);
      Check_Size (32, 4.0, 0.5);
   end;

   ---------------------------------------------------------------------
   Section ("10. Identity Toeplitz / diagonal dominance easy case");
   ---------------------------------------------------------------------
   declare
      R : constant Vector (1 .. 4) := [1.0, 0.0, 0.0, 0.0];
      Y : constant Vector (1 .. 4) := [2.0, -3.0, 4.0, 0.5];
      S : constant Result := Solve_Levinson (R, Y);
   begin
      Check (S.Success, "identity Success");
      Check (Approx (S.X (1), 2.0) and Approx (S.X (2), -3.0), "id x12");
      Check (Approx (S.X (3), 4.0) and Approx (S.X (4), 0.5), "id x34");
      Check (Approx (Residual_Norm (R, Y, S.X (1 .. 4)), 0.0, 1.0E-6),
             "id residual");
   end;

   ---------------------------------------------------------------------
   Section ("11. Durbin order-1 and order-2 analytic");
   ---------------------------------------------------------------------
   --  Order 1: a1 = -r1/r0, E = r0 (1 - k^2), k = -r1/r0
   declare
      R1 : constant Vector (1 .. 2) := [4.0, 1.0];
      D1 : constant Durbin_Result := Durbin_Yule_Walker (R1);
      R2 : constant Vector (1 .. 3) := [4.0, 1.0, 0.5];
      D2 : constant Durbin_Result := Durbin_Yule_Walker (R2);
      K1 : constant Float := -1.0 / 4.0;
   begin
      Check (D1.Success and D1.P = 1, "Durbin1 Success");
      Check (Approx (D1.K (1), K1), "Durbin1 k1");
      Check (Approx (D1.A (1), K1), "Durbin1 a1=k1");
      Check (Approx (D1.E, 4.0 * (1.0 - K1 * K1), 1.0E-5), "Durbin1 E");
      Check (D2.Success and D2.P = 2, "Durbin2 Success");
      Check (Approx (D2.K (1), K1), "Durbin2 k1");
      Check (abs (D2.K (2)) < 1.0, "Durbin2 |k2|<1");
   end;

   ---------------------------------------------------------------------
   Section ("12. RHS variations / Solve alias / Max_Abs residual");
   ---------------------------------------------------------------------
   declare
      R : constant Vector (1 .. 4) := [5.0, 1.0, 0.5, 0.25];
      Y0 : constant Vector (1 .. 4) := [0.0, 0.0, 0.0, 0.0];
      S0 : constant Result := Solve_Levinson (R, Y0);
      Ye : constant Vector (1 .. 4) := Ones_Vector (4, 1.0);
      Se : constant Result := Solve (R, Ye);
      Rm : constant Float :=
        Residual_Max_Abs (R, Ye, Se.X (1 .. 4));
   begin
      Check (S0.Success, "zero RHS Success");
      Check (Approx (Max_Abs (S0.X (1 .. 4)), 0.0, 1.0E-5), "zero => x=0");
      Check (Se.Success, "ones RHS Success");
      Check (Approx (Rm, 0.0, 1.0E-4), "ones max residual");
      Check (Approx (Residual_Norm (R, Ye, Se.X (1 .. 4)), 0.0, 1.0E-4),
             "ones residual norm");
   end;

   ---------------------------------------------------------------------
   Section ("13. Symmetry of multiply / entry helper");
   ---------------------------------------------------------------------
   declare
      R : Vector (1 .. 6);
      X : constant Vector (1 .. 6) := [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
      Y : Vector (1 .. 6);
   begin
      Make_Constant_Toeplitz (6, 10.0, 2.0, R);
      Y := Multiply_Toeplitz (R, X);
      --  Row 1: 10*1 + 2*2 + 2*3 + 2*4 + 2*5 + 2*6 = 10 + 2*20 = 50
      Check (Approx (Y (1), 50.0), "mult row1");
      Check (Approx (Toeplitz_Entry (R, 4, 4), 10.0), "diag mid");
      Check (Approx (Toeplitz_Entry (R, 2, 5), 2.0), "off mid");
      Check (Approx (Toeplitz_Entry (R, 6, 1), 2.0), "corner sym");
      Check (Near (Y (1), Y (1)), "Near self");
   end;

   ---------------------------------------------------------------------
   Section ("14. Batch small SPD checks");
   ---------------------------------------------------------------------
   declare
      Count_Local : Natural := 0;
   begin
      for N in 2 .. 10 loop
         declare
            R : Vector (1 .. N);
            Y : Vector (1 .. N);
            S : Result;
            Ok_R : Boolean;
         begin
            Make_Exponential_Toeplitz
              (N, 2.0 + Float (N) * 0.1, 0.3, 1.0, R);
            for I in 1 .. N loop
               Y (I) := Float (I mod 3) - 1.0;
            end loop;
            S := Solve_Levinson (R, Y);
            Ok_R := S.Success
              and then Approx
                (Residual_Norm (R, Y, S.X (1 .. N)), 0.0, 5.0E-4);
            Check (Ok_R, "batch n=" & N'Image);
            if Ok_R then
               Count_Local := Count_Local + 1;
            end if;
         end;
      end loop;
      Check (Count_Local = 9, "batch all 2..10");
   end;

   ---------------------------------------------------------------------
   Section ("15. Reflection |k|<1 for SPD exponential");
   ---------------------------------------------------------------------
   declare
      R : Vector (1 .. 8);
      Refl : Reflection_Result;
      All_Ok : Boolean := True;
   begin
      Make_Exponential_Toeplitz (8, 2.0, 0.6, 1.0, R);
      Refl := Reflection_Coefficients (R);
      Check (Refl.Success, "SPD Refl Success");
      for I in 1 .. Refl.N loop
         if abs (Refl.K (I)) > 1.0 + 1.0E-4 then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "all |k_i|<=1 SPD");
      Check (Refl.E > 0.0, "SPD E>0");
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
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

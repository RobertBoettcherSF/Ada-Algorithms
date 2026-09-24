--  Standalone test suite for Gram_Schmidt (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gram_Schmidt; use Gram_Schmidt;

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
   Ada.Text_IO.Put_Line ("Gram_Schmidt test suite");
   Ada.Text_IO.Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Dot / Norm2 / Scale / Add / Sub");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      V : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      W : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      Z : constant Vector := Zero_Vector (3);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Near (-2.0, -2.0), "Near negatives");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Approx (Dot (U, W), 3.0), "Dot U·W");
      Check (Approx (Dot (U, U), 25.0), "Dot U·U");
      Check (Approx (Dot (W, W), 1.0), "Dot unit");
      Check (Approx (Norm2 (U), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 (W), 1.0), "Norm2 unit");
      Check (Approx (Norm2 (Z), 0.0), "Norm2 zero");
      Check (Approx (Scale (W, 2.0) (1), 2.0), "Scale");
      Check (Approx (Add (W, W) (1), 2.0), "Add");
      Check (Approx (Sub (U, V) (1), 0.0), "Sub zero");
      Check (Approx (Ones_Vector (4, 2.5) (3), 2.5), "Ones_Vector");
   end;

   ---------------------------------------------------------------------
   Section ("2. Proj / Column / Set_Column");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 2) := [1.0, 0.0];
      V : constant Vector (1 .. 2) := [3.0, 4.0];
      P : constant Vector := Proj (U, V);
      A : Matrix (1 .. 3, 1 .. 2) := [others => [others => 0.0]];
      C : Vector (1 .. 3);
   begin
      Check (Approx (P (1), 3.0) and Approx (P (2), 0.0), "Proj onto e1");
      Set_Column (A, 1, [1.0, 2.0, 3.0]);
      Set_Column (A, 2, [4.0, 5.0, 6.0]);
      C := Column (A, 2);
      Check (Approx (C (1), 4.0) and Approx (C (3), 6.0), "Column 2");
      Check (Approx (Column (A, 1) (2), 2.0), "Column 1 mid");
      Check (Approx (Norm2 (Proj (U, U)), 1.0), "Proj self unit");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders: basis / independent / Hilbert");
   ---------------------------------------------------------------------
   declare
      B : constant Matrix := Standard_Basis (3);
      I : constant Matrix := Make_Independent (4, 3);
      H : constant Matrix := Make_Hilbert_Columns (3, 3);
      O : constant Matrix := Make_Orthogonal_Already (4, 2);
   begin
      Check (Approx (B (1, 1), 1.0) and Approx (B (2, 3), 0.0),
             "Standard_Basis entries");
      Check (Approx (I (1, 1), 2.0), "Independent diag col1");
      Check (Approx (H (1, 1), 1.0), "Hilbert H11");
      Check (Approx (H (1, 2), 0.5), "Hilbert H12");
      Check (Approx (H (2, 2), 1.0 / 3.0, 1.0E-6), "Hilbert H22");
      Check (Approx (O (1, 1), 1.0) and Approx (O (2, 2), 1.0),
             "Orthogonal_Already");
      Check (Approx (O (3, 1), 0.0) and Approx (O (1, 2), 0.0),
             "Orthogonal_Already zeros");
   end;

   ---------------------------------------------------------------------
   Section ("4. Dependent / nearly dependent / Make_Example");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Dependent (3, 3);
      N : constant Matrix := Make_Nearly_Dependent (3, 3);
      E1 : constant Matrix := Make_Example (Identity_Basis, 2);
      E2 : constant Matrix := Make_Example (Independent_Set, 3, 2);
      E3 : constant Matrix := Make_Example (Hilbert_Columns, 2);
      Sum : Float;
   begin
      Sum := 0.0;
      for R in 1 .. 3 loop
         Sum := Sum + abs (D (R, 3) - (D (R, 1) + D (R, 2)));
      end loop;
      Check (Sum < 1.0E-6, "Dependent last = sum");
      Check (abs (N (1, 3) - N (1, 2)) < 1.0E-3, "Nearly dependent close");
      Check (Approx (E1 (2, 2), 1.0), "Make_Example Identity");
      Check (E2'Length (2) = 2, "Make_Example Independent K=2");
      Check (Approx (E3 (1, 1), 1.0), "Make_Example Hilbert");
   end;

   ---------------------------------------------------------------------
   Section ("5. Identity / already orthonormal input");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Standard_Basis (3);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
      Ro : constant Result := Orthonormalize (V);
   begin
      Check (Rc.Success and Rc.Stat = Ok, "CGS Identity Ok");
      Check (Rc.Rank = 3 and Rc.N = 3 and Rc.K = 3, "CGS Identity dims");
      Check (Is_Orthonormal (Rc.Q, 3, 3), "CGS Identity orthonormal");
      Check (Rm.Success and Rm.Stat = Ok, "MGS Identity Ok");
      Check (Is_Orthonormal (Rm.Q, 3, 3), "MGS Identity orthonormal");
      Check (Ro.Method = Modified, "Orthonormalize default Modified");
      Check (Is_Orthonormal (Ro.Q, 3, 3), "Orthonormalize Identity");
      Check (Approx (Orthonormality_Residual (Rc.Q, 3, 3), 0.0, 1.0E-5),
             "Identity residual ~0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Simple 2D independent set");
   ---------------------------------------------------------------------
   --  v1 = (1,1), v2 = (1,0) → orthonormal span of R^2
   declare
      V : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0]];
      R : constant Result := Classical_GS (V);
      Q1, Q2 : Vector (1 .. 2);
   begin
      Check (R.Success and R.Stat = Ok, "2D Success/Ok");
      Check (R.Rank = 2, "2D Rank=2");
      Check (Is_Orthonormal (R.Q, 2, 2, 1.0E-5), "2D orthonormal");
      Q1 := [R.Q (1, 1), R.Q (2, 1)];
      Q2 := [R.Q (1, 2), R.Q (2, 2)];
      Check (Approx (Norm2 (Q1), 1.0), "2D q1 unit");
      Check (Approx (Norm2 (Q2), 1.0), "2D q2 unit");
      Check (Approx (Dot (Q1, Q2), 0.0, 1.0E-5), "2D q1⊥q2");
   end;

   ---------------------------------------------------------------------
   Section ("6b. Known first vector direction");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0]];
      R : constant Result := Modified_GS (V);
      S : constant Float := 0.70710678118;
   begin
      Check (Approx (abs (R.Q (1, 1)), S, 1.0E-5), "MGS q1 x ≈ 1/√2");
      Check (Approx (abs (R.Q (2, 1)), S, 1.0E-5), "MGS q1 y ≈ 1/√2");
      Check (Near (R.Q (1, 1), R.Q (2, 1), 1.0E-5), "MGS q1 equal comps");
   end;

   ---------------------------------------------------------------------
   Section ("7. Dependent → rank drop");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Dependent (4, 3);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
   begin
      Check (Rc.Success, "CGS dependent Success");
      Check (Rc.Stat = Rank_Deficient, "CGS Rank_Deficient");
      Check (Rc.Rank = 2, "CGS Rank=2 of 3");
      Check (Is_Orthonormal (Rc.Q, 4, Rc.Rank), "CGS dep orthonormal");
      Check (Rm.Stat = Rank_Deficient, "MGS Rank_Deficient");
      Check (Rm.Rank = 2, "MGS Rank=2 of 3");
      Check (Is_Orthonormal (Rm.Q, 4, Rm.Rank), "MGS dep orthonormal");
   end;

   ---------------------------------------------------------------------
   Section ("8. Zero columns / all-zero");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix (1 .. 3, 1 .. 2) := [others => [others => 0.0]];
      R : constant Result := Modified_GS (Z);
      V : Matrix (1 .. 3, 1 .. 3) := Make_Independent (3, 3);
      R2 : Result;
   begin
      Check (not R.Success, "all-zero not Success");
      Check (R.Stat = Zero_Vector, "all-zero Zero_Vector");
      Check (R.Rank = 0, "all-zero Rank=0");
      --  Middle column zero → rank drop by one
      for I in 1 .. 3 loop
         V (I, 2) := 0.0;
      end loop;
      R2 := Classical_GS (V);
      Check (R2.Stat = Rank_Deficient, "mid-zero Rank_Deficient");
      Check (R2.Rank = 2, "mid-zero Rank=2");
      Check (Is_Orthonormal (R2.Q, 3, 2), "mid-zero orthonormal");
   end;

   ---------------------------------------------------------------------
   Section ("9. Independent full rank (CGS and MGS)");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Independent (5, 4);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
      Ro : constant Result := Orthonormalize (V, Classical);
   begin
      Check (Rc.Stat = Ok and Rc.Rank = 4, "CGS indep Ok Rank=4");
      Check (Is_Orthonormal (Rc.Q, 5, 4, 1.0E-4), "CGS indep ortho");
      Check (Rm.Stat = Ok and Rm.Rank = 4, "MGS indep Ok Rank=4");
      Check (Is_Orthonormal (Rm.Q, 5, 4, 1.0E-4), "MGS indep ortho");
      Check (Ro.Method = Classical, "Orthonormalize Classical");
      Check (Ro.Rank = 4, "Orthonormalize Classical Rank");
   end;

   ---------------------------------------------------------------------
   Section ("10. Hilbert columns (mild ill-conditioning)");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Hilbert_Columns (6, 4);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
      Res_C, Res_M : Float;
   begin
      Check (Rc.Success and Rm.Success, "Hilbert Success both");
      Check (Rc.Rank = 4 and Rm.Rank = 4, "Hilbert full Rank");
      Res_C := Orthonormality_Residual (Rc.Q, 6, 4);
      Res_M := Orthonormality_Residual (Rm.Q, 6, 4);
      Check (Is_Orthonormal (Rm.Q, 6, 4, 1.0E-3), "MGS Hilbert ortho");
      Check (Is_Orthonormal (Rc.Q, 6, 4, 5.0E-2), "CGS Hilbert loose ortho");
      --  MGS should not be dramatically worse than CGS residual
      Check (Res_M <= Res_C + 1.0E-3 or else Res_M < 1.0E-3,
             "MGS residual competitive vs CGS");
      Check (Res_C >= 0.0 and Res_M >= 0.0, "residuals nonneg");
   end;

   ---------------------------------------------------------------------
   Section ("11. CGS vs MGS on nearly dependent");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Nearly_Dependent (5, 4);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
      Res_C : constant Float :=
        Orthonormality_Residual (Rc.Q, 5, Rc.Rank);
      Res_M : constant Float :=
        Orthonormality_Residual (Rm.Q, 5, Rm.Rank);
   begin
      Check (Rc.Success and Rm.Success, "nearly-dep Success");
      Check (Rc.Rank >= 3 and Rm.Rank >= 3, "nearly-dep Rank>=3");
      Check (Is_Orthonormal (Rm.Q, 5, Rm.Rank, 5.0E-2)
               or else Rm.Rank < 4,
             "MGS nearly-dep ortho or rank drop");
      Check (Res_M < 1.0 or else Rm.Rank < Rm.K,
             "MGS nearly-dep residual finite");
      Check (Res_M <= Res_C * 10.0 + 1.0E-6 or else Res_M < 1.0E-4,
             "MGS not much worse than CGS");
      Check (Rm.Method = Modified and Rc.Method = Classical,
             "methods tagged");
   end;

   ---------------------------------------------------------------------
   Section ("12. Tall thin / single column / n=k=1");
   ---------------------------------------------------------------------
   declare
      V1 : constant Matrix (1 .. 1, 1 .. 1) := [[5.0]];
      R1 : constant Result := Modified_GS (V1);
      Vt : constant Matrix := Make_Independent (8, 3);
      Rt : constant Result := Classical_GS (Vt);
      Vs : constant Matrix (1 .. 4, 1 .. 1) :=
        [[0.0], [3.0], [4.0], [0.0]];
      Rs : constant Result := Modified_GS (Vs);
   begin
      Check (R1.Success and R1.Rank = 1, "1x1 Success Rank=1");
      Check (Approx (abs (R1.Q (1, 1)), 1.0), "1x1 unit");
      Check (Rt.Rank = 3 and Is_Orthonormal (Rt.Q, 8, 3), "8x3 ortho");
      Check (Rs.Rank = 1, "single col Rank=1");
      Check (Approx (Norm2 ([Rs.Q (1, 1), Rs.Q (2, 1),
                             Rs.Q (3, 1), Rs.Q (4, 1)]), 1.0),
             "single col unit");
      Check (Approx (Rs.Q (2, 1), 0.6, 1.0E-5), "single col 3-4-5 y");
      Check (Approx (Rs.Q (3, 1), 0.8, 1.0E-5), "single col 3-4-5 z");
   end;

   ---------------------------------------------------------------------
   Section ("13. Projection property / span check");
   ---------------------------------------------------------------------
   --  After GS, each original v_j should be in span of q_1..q_rank
   --  (for full-rank independent input): ||v − Q(Qᵀv)|| small.
   declare
      V : constant Matrix := Make_Independent (4, 3);
      R : constant Result := Modified_GS (V);
      Max_Err : Float := 0.0;
   begin
      for J in 1 .. 3 loop
         declare
            Vj : constant Vector := Column (V, J);
            Coeffs : Vector (1 .. 3) := [others => 0.0];
            Recon  : Vector (1 .. 4) := [others => 0.0];
            Err : Float;
         begin
            for I in 1 .. 3 loop
               declare
                  Qi : Vector (1 .. 4);
               begin
                  for Row in 1 .. 4 loop
                     Qi (Row) := R.Q (Row, I);
                  end loop;
                  Coeffs (I) := Dot (Qi, Vj);
                  for Row in 1 .. 4 loop
                     Recon (Row) := Recon (Row) + Coeffs (I) * Qi (Row);
                  end loop;
               end;
            end loop;
            Err := Norm2 (Sub (Vj, Recon));
            if Err > Max_Err then
               Max_Err := Err;
            end if;
         end;
      end loop;
      Check (Max_Err < 1.0E-4, "recon error small (span)");
      Check (R.Rank = 3, "span test Rank=3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Orthogonal already unchanged up to signs");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Orthogonal_Already (5, 3);
      R : constant Result := Classical_GS (V);
   begin
      Check (R.Stat = Ok and R.Rank = 3, "already ortho Ok");
      Check (Is_Orthonormal (R.Q, 5, 3), "already ortho stays");
      Check (Approx (abs (R.Q (1, 1)), 1.0), "e1 preserved abs");
      Check (Approx (abs (R.Q (2, 2)), 1.0), "e2 preserved abs");
      Check (Approx (abs (R.Q (3, 3)), 1.0), "e3 preserved abs");
   end;

   ---------------------------------------------------------------------
   Section ("15. Larger independent / residual helpers");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Independent (12, 8);
      Rm : constant Result := Modified_GS (V);
      Rc : constant Result := Classical_GS (V);
      Empty_Res : constant Float :=
        Orthonormality_Residual (Rm.Q, 12, 0);
   begin
      Check (Rm.Stat = Ok and Rm.Rank = 8, "12x8 MGS Ok");
      Check (Is_Orthonormal (Rm.Q, 12, 8, 1.0E-3), "12x8 MGS ortho");
      Check (Rc.Rank = 8, "12x8 CGS Rank=8");
      Check (Is_Orthonormal (Rc.Q, 12, 8, 1.0E-2), "12x8 CGS ortho");
      Check (Approx (Empty_Res, 0.0), "Rank0 residual 0");
      Check (Is_Orthonormal (Rm.Q, 12, 0), "Rank0 Is_Orthonormal");
   end;

   ---------------------------------------------------------------------
   Section ("16. Duplicate columns / two equal");
   ---------------------------------------------------------------------
   declare
      V : Matrix (1 .. 3, 1 .. 3) := Make_Independent (3, 3);
      R : Result;
   begin
      for I in 1 .. 3 loop
         V (I, 3) := V (I, 1);
      end loop;
      R := Modified_GS (V);
      Check (R.Stat = Rank_Deficient, "dup Rank_Deficient");
      Check (R.Rank = 2, "dup Rank=2");
      Check (Is_Orthonormal (R.Q, 3, 2), "dup orthonormal");
   end;

   ---------------------------------------------------------------------
   Section ("17. Method dispatch / Result fields");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Independent (3, 2);
      Ra : constant Result := Orthonormalize (V, Classical);
      Rb : constant Result := Orthonormalize (V, Modified);
      Rc : constant Result := Classical_GS (V);
      Rd : constant Result := Modified_GS (V);
   begin
      Check (Ra.Method = Classical and Ra.Success, "dispatch Classical");
      Check (Rb.Method = Modified and Rb.Success, "dispatch Modified");
      Check (Ra.N = 3 and Ra.K = 2 and Ra.Rank = 2, "Result dims");
      Check (Rc.Method = Classical, "Classical_GS tagged");
      Check (Rd.Method = Modified, "Modified_GS tagged");
      Check (Is_Orthonormal (Ra.Q, 3, 2) and Is_Orthonormal (Rb.Q, 3, 2),
             "both methods ortho");
   end;

   ---------------------------------------------------------------------
   Section ("18. Proj of orthogonal / Scale edge");
   ---------------------------------------------------------------------
   declare
      E1 : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      E2 : constant Vector (1 .. 3) := [0.0, 1.0, 0.0];
      P  : constant Vector := Proj (E1, E2);
      Z  : constant Vector := Proj (Zero_Vector (3), E1);
   begin
      Check (Approx (Norm2 (P), 0.0), "proj orthogonal → 0");
      Check (Approx (Norm2 (Z), 0.0), "proj onto zero → 0");
      Check (Approx (Scale (E1, 0.0) (1), 0.0), "Scale by 0");
      Check (Vec_Near (Add (E1, E2), [1.0, 1.0, 0.0]), "Add e1+e2");
      Check (Vec_Near (Sub (E1, E1), Zero_Vector (3)), "Sub self");
   end;

   ---------------------------------------------------------------------
   Section ("19. Make_Example Dependent / Nearly / Orthogonal");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Example (Dependent_Set, 4, 3);
      N : constant Matrix := Make_Example (Nearly_Dependent, 4, 3);
      O : constant Matrix := Make_Example (Orthogonal_Already, 3, 2);
      Rd : constant Result := Modified_GS (D);
   begin
      Check (Rd.Stat = Rank_Deficient and Rd.Rank = 2,
             "Example Dependent rank");
      Check (N'Length (1) = 4 and N'Length (2) = 3, "Example Nearly shape");
      Check (Approx (O (1, 1), 1.0) and Approx (O (2, 2), 1.0),
             "Example Orthogonal");
   end;

   ---------------------------------------------------------------------
   Section ("20. Wide vs square residual comparison");
   ---------------------------------------------------------------------
   declare
      V : constant Matrix := Make_Hilbert_Columns (8, 5);
      Rc : constant Result := Classical_GS (V);
      Rm : constant Result := Modified_GS (V);
   begin
      Check (Rc.Rank = 5 and Rm.Rank = 5, "Hilbert 8x5 Rank");
      Check (Is_Orthonormal (Rm.Q, 8, 5, 5.0E-3), "MGS Hilbert 8x5");
      Check (Orthonormality_Residual (Rm.Q, 8, 5) < 1.0E-2,
             "MGS Hilbert residual bound");
      Check (Rc.N = 8 and Rc.K = 5, "Hilbert Result N,K");
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

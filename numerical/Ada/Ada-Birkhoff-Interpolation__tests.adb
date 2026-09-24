--  Standalone test suite for Birkhoff_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Birkhoff_Interpolation; use Birkhoff_Interpolation;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Cubic (X : Float) return Float is
   begin
      return X * X * X - 2.0 * X * X + X;
   end Cubic;

   function Cubic_D (X : Float) return Float is
   begin
      return 3.0 * X * X - 4.0 * X + 1.0;
   end Cubic_D;

begin
   Ada.Text_IO.Put_Line ("Birkhoff_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Condition / Monomial_Derivative_Entry");
   ---------------------------------------------------------------------
   declare
      C : constant Condition := Make_Condition (2.0, 1, 3.5);
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Approx (C.Node, 2.0) and C.Derivative_Order = 1
             and Approx (C.Value, 3.5),
             "Make_Condition fields");

      --  D=0: entry = X^K
      Check (Approx (Monomial_Derivative_Entry (0, 0, 5.0), 1.0),
             "Entry k=0 d=0 → 1");
      Check (Approx (Monomial_Derivative_Entry (1, 0, 5.0), 5.0),
             "Entry k=1 d=0 → x");
      Check (Approx (Monomial_Derivative_Entry (2, 0, 3.0), 9.0),
             "Entry k=2 d=0 → x²");
      Check (Approx (Monomial_Derivative_Entry (3, 0, 2.0), 8.0),
             "Entry k=3 d=0 → x³");

      --  D=1: entry = k * X^(k-1)
      Check (Approx (Monomial_Derivative_Entry (0, 1, 5.0), 0.0),
             "Entry k=0 d=1 → 0");
      Check (Approx (Monomial_Derivative_Entry (1, 1, 5.0), 1.0),
             "Entry k=1 d=1 → 1");
      Check (Approx (Monomial_Derivative_Entry (2, 1, 3.0), 6.0),
             "Entry k=2 d=1 → 2x");
      Check (Approx (Monomial_Derivative_Entry (3, 1, 2.0), 12.0),
             "Entry k=3 d=1 → 3x²");

      --  D=2: entry = k(k-1) X^(k-2)
      Check (Approx (Monomial_Derivative_Entry (1, 2, 9.0), 0.0),
             "Entry k=1 d=2 → 0");
      Check (Approx (Monomial_Derivative_Entry (2, 2, 9.0), 2.0),
             "Entry k=2 d=2 → 2");
      Check (Approx (Monomial_Derivative_Entry (3, 2, 2.0), 12.0),
             "Entry k=3 d=2 → 6x");
      Check (Approx (Monomial_Derivative_Entry (4, 2, 1.0), 12.0),
             "Entry k=4 d=2 → 12");
   end;

   ---------------------------------------------------------------------
   Section ("2. Validate empty / too many / ok");
   ---------------------------------------------------------------------
   declare
      Emp : Conditions (1 .. 0);
      Ok3 : constant Conditions :=
        [Make_Condition (0.0, 0, 1.0),
         Make_Condition (1.0, 0, 2.0),
         Make_Condition (2.0, 0, 3.0)];
      Bad : Condition_List;
   begin
      Check (Validate (Emp) = Ill_Started, "Validate empty Ill_Started");
      Check (Validate (Ok3) = Ok, "Validate 3 ok");
      Check (Validate (Bad) = Ill_Started, "Validate invalid list");
      Bad.Count := 0;
      Bad.Valid := True;
      Check (Validate (Bad) = Ill_Started, "Validate zero-count list");
   end;

   ---------------------------------------------------------------------
   Section ("3. Lagrange recovery (quadratic y=x²)");
   ---------------------------------------------------------------------
   declare
      X  : constant Abscissae := [-1.0, 0.0, 1.0];
      Y  : constant Ordinates := [1.0, 0.0, 1.0];
      L  : constant Condition_List := Make_Lagrange_Conditions (X, Y);
      FR : Fit_Result;
      E  : Eval_Result;
   begin
      Check (L.Valid and L.Count = 3 and L.Stat = Ok, "Lagrange list ok");
      FR := Fit (L);
      Check (FR.Success and FR.Stat = Ok, "Lagrange Fit Ok");
      Check (FR.Poly.Valid and FR.Poly.N = 3, "Lagrange poly N=3");
      --  P(x)=x² → c0=0, c1=0, c2=1
      Check (Approx (FR.Poly.Coeffs (0), 0.0), "Lagrange c0=0");
      Check (Approx (FR.Poly.Coeffs (1), 0.0), "Lagrange c1=0");
      Check (Approx (FR.Poly.Coeffs (2), 1.0), "Lagrange c2=1");
      Check (Matches_All (FR.Poly, L), "Lagrange Matches_All nodes");

      E := Evaluate (FR.Poly, 0.5);
      Check (E.Success and Approx (E.Value, 0.25), "Lagrange P(0.5)=0.25");
      E := Evaluate (FR.Poly, -0.5);
      Check (E.Success and Approx (E.Value, 0.25), "Lagrange P(-0.5)=0.25");
      E := Evaluate (FR.Poly, 2.0);
      Check (E.Success and Approx (E.Value, 4.0), "Lagrange P(2)=4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Hermite two-point recovers known cubic");
   ---------------------------------------------------------------------
   declare
      L  : constant Condition_List :=
        Make_Hermite_Two_Point (0.0, Cubic (0.0), Cubic_D (0.0),
                                1.0, Cubic (1.0), Cubic_D (1.0));
      FR : Fit_Result;
      E  : Eval_Result;
      Ok_Cond : Boolean := True;
      Ok_Grid : Boolean := True;
      T  : Float;
   begin
      Check (L.Valid and L.Count = 4, "Hermite list Count=4");
      Check (L.Data (1).Derivative_Order = 0
             and L.Data (2).Derivative_Order = 1
             and L.Data (3).Derivative_Order = 0
             and L.Data (4).Derivative_Order = 1,
             "Hermite orders 0,1,0,1");
      FR := Fit (L);
      Check (FR.Success and FR.Stat = Ok, "Hermite Fit Ok");
      Check (FR.Poly.N = 4, "Hermite degree < 4");
      --  p(x)=x³−2x²+x → c=[0,-0? wait: 0 + 1*x + (-2)*x² + 1*x³]
      Check (Approx (FR.Poly.Coeffs (0), 0.0, 1.0E-4), "Hermite c0");
      Check (Approx (FR.Poly.Coeffs (1), 1.0, 1.0E-4), "Hermite c1");
      Check (Approx (FR.Poly.Coeffs (2), -2.0, 1.0E-4), "Hermite c2");
      Check (Approx (FR.Poly.Coeffs (3), 1.0, 1.0E-4), "Hermite c3");
      Check (Matches_All (FR.Poly, L, 1.0E-4), "Hermite Matches_All");

      for K in 0 .. 10 loop
         T := Float (K) * 0.1;
         E := Evaluate (FR.Poly, T);
         if not (E.Success and Approx (E.Value, Cubic (T), 1.0E-3)) then
            Ok_Grid := False;
         end if;
      end loop;
      Check (Ok_Grid, "Hermite evaluates cubic on [0,1] grid");

      E := Evaluate_Derivative (FR.Poly, 1, 0.5);
      Check (E.Success and Approx (E.Value, Cubic_D (0.5), 1.0E-3),
             "Hermite P'(0.5)");
      E := Evaluate_Derivative (FR.Poly, 2, 0.5);
      --  p''=6x-4; p''(0.5)=-1
      Check (E.Success and Approx (E.Value, -1.0, 1.0E-3),
             "Hermite P''(0.5)=-1");

      for I in 1 .. L.Count loop
         if not Matches_Condition (FR.Poly, L.Data (I), 1.0E-4) then
            Ok_Cond := False;
         end if;
      end loop;
      Check (Ok_Cond, "Each Hermite condition matched");
   end;

   ---------------------------------------------------------------------
   Section ("5. Birkhoff Pólya regular (wiki unique example)");
   ---------------------------------------------------------------------
   declare
      --  P'(−1), P(0), P'(1) — Wikipedia: always unique
      L  : constant Condition_List :=
        Make_Birkhoff_Polya_Regular (-1.0, -2.0, 0.0, 0.0, 1.0, 2.0);
      FR : Fit_Result;
      E  : Eval_Result;
   begin
      Check (L.Valid and L.Count = 3, "Polya list Count=3");
      Check (L.Data (1).Derivative_Order = 1
             and L.Data (2).Derivative_Order = 0
             and L.Data (3).Derivative_Order = 1,
             "Polya orders 1,0,1 (lacunary)");
      FR := Fit (L);
      Check (FR.Success and FR.Stat = Ok, "Polya Fit Ok");
      Check (Matches_All (FR.Poly, L, 1.0E-4), "Polya Matches_All");
      --  Target x²
      Check (Approx (FR.Poly.Coeffs (0), 0.0, 1.0E-4), "Polya c0=0");
      Check (Approx (FR.Poly.Coeffs (1), 0.0, 1.0E-4), "Polya c1=0");
      Check (Approx (FR.Poly.Coeffs (2), 1.0, 1.0E-4), "Polya c2=1");
      E := Evaluate (FR.Poly, 3.0);
      Check (E.Success and Approx (E.Value, 9.0), "Polya P(3)=9");
      E := Evaluate_Derivative (FR.Poly, 1, -1.0);
      Check (E.Success and Approx (E.Value, -2.0), "Polya P'(-1)=-2");
      E := Evaluate_Derivative (FR.Poly, 1, 1.0);
      Check (E.Success and Approx (E.Value, 2.0), "Polya P'(1)=2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Singular / inconsistent incidence rejected");
   ---------------------------------------------------------------------
   declare
      --  Wiki: P(-1)=0, P(1)=0, P'(0)=1 — inconsistent for degree < 3
      L_Bad : constant Condition_List :=
        Make_Birkhoff_Singular_Example (-1.0, 0.0, 0.0, 1.0, 1.0, 0.0);
      FR : Fit_Result;
      --  Homogeneous singular: P(-1)=0, P'(0)=0, P(1)=0 — singular (non-unique)
      L_Hom : constant Condition_List :=
        Make_Birkhoff_Singular_Example (-1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
      FR2 : Fit_Result;
   begin
      Check (L_Bad.Valid and L_Bad.Count = 3, "Singular list Count=3");
      Check (L_Bad.Data (1).Derivative_Order = 0
             and L_Bad.Data (2).Derivative_Order = 1
             and L_Bad.Data (3).Derivative_Order = 0,
             "Singular orders 0,1,0");
      FR := Fit (L_Bad);
      Check (not FR.Success, "Inconsistent Fit fails");
      Check (FR.Stat = Inconsistent,
             "Wiki bad example Status=Inconsistent");
      Check (not FR.Poly.Valid, "Poly not Valid on failure");

      FR2 := Fit (L_Hom);
      Check (not FR2.Success, "Homogeneous singular Fit fails");
      Check (FR2.Stat = Singular,
             "Homogeneous Status=Singular");
   end;

   ---------------------------------------------------------------------
   Section ("7. Make_Example presets");
   ---------------------------------------------------------------------
   declare
      FR : Fit_Result;
      E  : Eval_Result;
   begin
      FR := Make_Example (Lagrange_Quadratic);
      Check (FR.Success and FR.Stat = Ok, "Example Lagrange_Quadratic");
      E := Evaluate (FR.Poly, 0.5);
      Check (E.Success and Approx (E.Value, 0.25), "Example LQ P(0.5)");

      FR := Make_Example (Hermite_Two_Point_Cubic);
      Check (FR.Success, "Example Hermite_Two_Point_Cubic");
      E := Evaluate (FR.Poly, 0.5);
      Check (E.Success and Approx (E.Value, Cubic (0.5), 1.0E-3),
             "Example Hermite mid");

      FR := Make_Example (Birkhoff_Polya_Regular);
      Check (FR.Success, "Example Birkhoff_Polya_Regular");
      Check (Approx (FR.Poly.Coeffs (2), 1.0, 1.0E-4), "Example Polya c2");

      FR := Make_Example (Known_Cubic_Lagrange);
      Check (FR.Success and FR.Poly.N = 5, "Example Known_Cubic N=5");
      E := Evaluate (FR.Poly, 0.75);
      Check (E.Success and Approx (E.Value, Cubic (0.75), 2.0E-3),
             "Example Known_Cubic P(0.75)");
      Check (Matches_All
               (FR.Poly,
                Make_Lagrange_Conditions
                  ([0.0, 0.5, 1.0, 1.5, 2.0],
                   [0.0, 0.125, 0.0, 0.375, 2.0]),
                2.0E-3),
             "Example Known_Cubic Matches_All");
   end;

   ---------------------------------------------------------------------
   Section ("8. Evaluate / Horner / derivatives / Ill_Started");
   ---------------------------------------------------------------------
   declare
      P : Polynomial;
      E : Eval_Result;
      FR : Fit_Result;
      L : constant Condition_List :=
        Make_Lagrange_Conditions ([0.0, 1.0], [2.0, 5.0]);
   begin
      E := Evaluate (P, 1.0);
      Check (not E.Success and E.Stat = Ill_Started,
             "Evaluate invalid Ill_Started");
      E := Evaluate_Derivative (P, 0, 1.0);
      Check (not E.Success and E.Stat = Ill_Started,
             "Eval_Deriv invalid Ill_Started");

      FR := Fit (L);
      Check (FR.Success, "Linear Fit Ok");
      --  P(x)=2+3x
      Check (Approx (FR.Poly.Coeffs (0), 2.0) and
             Approx (FR.Poly.Coeffs (1), 3.0),
             "Linear coeffs 2+3x");
      E := Evaluate (FR.Poly, 2.0);
      Check (E.Success and Approx (E.Value, 8.0), "Linear P(2)=8");
      E := Evaluate_Derivative (FR.Poly, 1, 99.0);
      Check (E.Success and Approx (E.Value, 3.0), "Linear P'=3");
      E := Evaluate_Derivative (FR.Poly, 2, 0.0);
      Check (E.Success and Approx (E.Value, 0.0), "Linear P''=0");
      E := Evaluate_Derivative (FR.Poly, 5, 0.0);
      Check (E.Success and Approx (E.Value, 0.0), "High order deriv 0");
      Check (not Matches_Condition
               (P, Make_Condition (0.0, 0, 0.0)),
             "Matches_Condition rejects invalid poly");
   end;

   ---------------------------------------------------------------------
   Section ("9. Dimension / too many / builders edge cases");
   ---------------------------------------------------------------------
   declare
      X_Mis : constant Abscissae := [0.0, 1.0];
      Y_Mis : constant Ordinates := [0.0, 1.0, 2.0];
      L_Mis : constant Condition_List :=
        Make_Lagrange_Conditions (X_Mis, Y_Mis);
      X_Emp : Abscissae (1 .. 0);
      Y_Emp : Ordinates (1 .. 0);
      L_Emp : constant Condition_List :=
        Make_Lagrange_Conditions (X_Emp, Y_Emp);
      FR : Fit_Result;
      Big_X : Abscissae (0 .. Max_Conditions);  -- 10 points > Max 9
      Big_Y : Ordinates (0 .. Max_Conditions);
      L_Big : Condition_List;
      Raw : Conditions (1 .. Max_Conditions + 1);
   begin
      Check (not L_Mis.Valid and L_Mis.Stat = Dimension_Error,
             "Lagrange mismatch Dimension_Error");
      Check (not L_Emp.Valid and L_Emp.Stat = Ill_Started,
             "Lagrange empty Ill_Started");
      FR := Fit (L_Mis);
      Check (not FR.Success and FR.Stat = Ill_Started,
             "Fit invalid list Ill_Started");

      for I in Big_X'Range loop
         Big_X (I) := Float (I);
         Big_Y (I) := Float (I);
      end loop;
      L_Big := Make_Lagrange_Conditions (Big_X, Big_Y);
      Check (not L_Big.Valid and L_Big.Stat = Too_Many_Conditions,
             "Lagrange Too_Many_Conditions");

      for I in Raw'Range loop
         Raw (I) := Make_Condition (Float (I), 0, 0.0);
      end loop;
      FR := Fit (Raw);
      Check (not FR.Success and FR.Stat = Too_Many_Conditions,
             "Fit Too_Many_Conditions");
   end;

   ---------------------------------------------------------------------
   Section ("10. Degree-0 constant / Slice / Max_Conditions Lagrange");
   ---------------------------------------------------------------------
   declare
      L1 : constant Condition_List :=
        Make_Lagrange_Conditions ([4.0], [7.0]);
      FR : Fit_Result;
      E  : Eval_Result;
      S  : Conditions (1 .. 1);
      X9 : Abscissae (0 .. 8);
      Y9 : Ordinates (0 .. 8);
      L9 : Condition_List;
      All_Ok : Boolean := True;
   begin
      FR := Fit (L1);
      Check (FR.Success and FR.Poly.N = 1, "Deg0 Fit N=1");
      Check (Approx (FR.Poly.Coeffs (0), 7.0), "Deg0 c0=7");
      E := Evaluate (FR.Poly, -100.0);
      Check (E.Success and Approx (E.Value, 7.0), "Deg0 anywhere");
      S := Slice (L1);
      Check (S'Length = 1 and Approx (S (1).Value, 7.0), "Slice deg0");

      for I in 0 .. 8 loop
         X9 (I) := Float (I);
         Y9 (I) := Float (I);  -- y=x
      end loop;
      L9 := Make_Lagrange_Conditions (X9, Y9);
      Check (L9.Valid and L9.Count = 9, "Max 9 Lagrange conditions");
      FR := Fit (L9);
      Check (FR.Success and FR.Stat = Ok, "Max Fit Ok");
      for I in 0 .. 8 loop
         E := Evaluate (FR.Poly, Float (I));
         if not (E.Success and Approx (E.Value, Float (I), 2.0E-3)) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Max Lagrange recovers y=x at nodes");
      E := Evaluate (FR.Poly, 4.5);
      Check (E.Success and Approx (E.Value, 4.5, 5.0E-3),
             "Max Lagrange mid P(4.5)≈4.5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Mixed lacunary + Hermite vs Lagrange special case");
   ---------------------------------------------------------------------
   declare
      --  Another regular: value at 0 and first derivs at ±1 already tested.
      --  Contiguous Hermite three-point value-only equals Lagrange.
      X : constant Abscissae := [0.0, 1.0, 2.0];
      Y : constant Ordinates := [1.0, 0.0, 1.0];  -- (x-1)²
      L : constant Condition_List := Make_Lagrange_Conditions (X, Y);
      FR : Fit_Result;
      E  : Eval_Result;
      --  Manual conditions same as Lagrange
      Manual : constant Conditions :=
        [Make_Condition (0.0, 0, 1.0),
         Make_Condition (1.0, 0, 0.0),
         Make_Condition (2.0, 0, 1.0)];
      FR2 : Fit_Result;
   begin
      FR := Fit (L);
      FR2 := Fit (Manual);
      Check (FR.Success and FR2.Success, "Lagrange ≡ manual Fit");
      Check (Approx (FR.Poly.Coeffs (0), FR2.Poly.Coeffs (0))
             and Approx (FR.Poly.Coeffs (1), FR2.Poly.Coeffs (1))
             and Approx (FR.Poly.Coeffs (2), FR2.Poly.Coeffs (2)),
             "Lagrange ≡ manual coeffs");
      E := Evaluate (FR.Poly, 1.5);
      Check (E.Success and Approx (E.Value, 0.25), "P(1.5)=(0.5)²");

      --  Second-derivative condition alone at one point + values
      --  P(0)=0, P(1)=1, P''(0)=0 → for degree < 3: forces linear? 
      --  P=c0+c1 x+c2 x²; P(0)=c0=0; P''(0)=2 c2=0 → c2=0; P(1)=c1=1
      --  → P(x)=x (regular)
      declare
         Mix : constant Conditions :=
           [Make_Condition (0.0, 0, 0.0),
            Make_Condition (1.0, 0, 1.0),
            Make_Condition (0.0, 2, 0.0)];
         FRM : constant Fit_Result := Fit (Mix);
      begin
         Check (FRM.Success and FRM.Stat = Ok, "Mixed P,P,P'' Fit Ok");
         Check (Approx (FRM.Poly.Coeffs (0), 0.0)
                and Approx (FRM.Poly.Coeffs (1), 1.0)
                and Approx (FRM.Poly.Coeffs (2), 0.0),
                "Mixed recovers P(x)=x");
         Check (Matches_All (FRM.Poly, Mix), "Mixed Matches_All");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Status exhaust / Fit_Result Success flag");
   ---------------------------------------------------------------------
   declare
      FR : Fit_Result;
      L  : Condition_List;
   begin
      Check (Status'Pos (Ok) = 0, "Status Ok pos");
      Check (Status'Pos (Singular) = 1, "Status Singular pos");
      Check (Status'Pos (Inconsistent) = 2, "Status Inconsistent pos");
      Check (Status'Pos (Too_Many_Conditions) = 3, "Status Too_Many pos");
      Check (Status'Pos (Ill_Started) = 4, "Status Ill_Started pos");
      Check (Status'Pos (Dimension_Error) = 5, "Status Dimension_Error pos");

      L := Make_Hermite_Two_Point (0.0, 0.0, 0.0, 1.0, 1.0, 0.0);
      FR := Fit (L);
      Check (FR.Success = (FR.Stat = Ok), "Success ≡ Stat=Ok");
      Check (FR.Poly.Valid = FR.Success, "Valid ≡ Success");

      --  Same Hermite recovers smoothstep-like cubic with zero slopes
      Check (Approx (Evaluate (FR.Poly, 0.0).Value, 0.0), "H00-like @0");
      Check (Approx (Evaluate (FR.Poly, 1.0).Value, 1.0), "H00-like @1");
      Check (Approx (Evaluate (FR.Poly, 0.5).Value, 0.5, 1.0E-4),
             "Zero-slope mid = 0.5");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;

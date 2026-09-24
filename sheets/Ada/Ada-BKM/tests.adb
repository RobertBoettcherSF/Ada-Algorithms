--  Standalone test suite for Bkm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Bkm; use Bkm;

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

   function Close
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Close;

begin
   Ada.Text_IO.Put_Line ("Bkm test suite");
   Ada.Text_IO.Put_Line ("==============");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E, R : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      E := Abs_Error (3.0, 1.0);
      Check (Close (E, 2.0), "Abs_Error 3-1");
      Check (Close (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Close (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      R := Rel_Error (5.1, 5.0);
      Check (Close (R, 0.02, 1.0E-12), "Rel_Error 5.1 vs 5");
      Check (Close (Rel_Error (0.0, 0.0), 0.0), "Rel_Error 0/0");
      Check (Rel_Error (1.0, 0.0) > 1.0E20, "Rel_Error nonzero/0 sentinel");
   end;

   ---------------------------------------------------------------------
   Section ("2. Prefill log tables");
   ---------------------------------------------------------------------
   declare
      A0, A1, Am1 : Long_Float;
      S : Long_Float := 0.0;
   begin
      A0 := Log_Table (0);
      Check (Close (A0, Ln_2, 1.0E-14), "A_0 = ln(1+1) = ln 2");
      A1 := Log_Table (1);
      Check (Close (A1, Exact_Ln (1.5), 1.0E-14), "A_1 = ln(1.5)");
      Check (Log_Table (2) < A1, "A_k decreasing");
      Check (Log_Table (10) < Log_Table (5), "A_10 < A_5");
      Check (Close (Log_Table (3), Exact_Ln (1.0 + 0.125), 1.0E-14),
             "A_3 = ln(1+1/8)");

      Am1 := Log_Table_Minus (1);
      Check (Close (Am1, Exact_Ln (0.5), 1.0E-14), "A_1^- = ln(1-1/2) = -ln 2");
      Check (Log_Table_Minus (2) < 0.0, "A_2^- negative");
      Check (Log_Table_Minus (2) > Am1, "A_k^- increases toward 0");

      for K in 0 .. 20 loop
         S := S + Log_Table (K);
      end loop;
      Check (S < Sum_Bound + 0.01, "partial sum < Sum_Bound+ε");
      Check (S > 1.5, "partial sum of A_k > 1.5");
      Check (Close (Log_Table (0), Exact_Ln (2.0), 1.0E-14),
             "A_0 matches Exact_Ln(2)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Exp canonical values");
   ---------------------------------------------------------------------
   declare
      V : Long_Float;
   begin
      V := Exp (0.0);
      Check (Close (V, 1.0, 1.0E-12), "exp(0) = 1");

      V := Exp (1.0);
      Check (Close (V, E_Const, 1.0E-9), "exp(1) ≈ e");
      Check (Close (V, Exact_Exp (1.0), 1.0E-9), "exp(1) vs Exact_Exp");

      V := Exp (Ln_2);
      Check (Close (V, 2.0, 1.0E-9), "exp(ln 2) ≈ 2");

      V := Exp (2.0 * Ln_2);
      Check (Close (V, 4.0, 1.0E-9), "exp(2 ln 2) ≈ 4");

      V := Exp (-Ln_2);
      Check (Close (V, 0.5, 1.0E-9), "exp(-ln 2) ≈ 1/2");

      V := Exp (-1.0);
      Check (Close (V, 1.0 / E_Const, 1.0E-9), "exp(-1) ≈ 1/e");

      V := Exp (0.5);
      Check (Close (V, Exact_Exp (0.5), 1.0E-9), "exp(0.5) vs oracle");

      V := Exp (-0.5);
      Check (Close (V, Exact_Exp (-0.5), 1.0E-9), "exp(-0.5) vs oracle");

      Check (Close (Exp (3.0 * Ln_2), 8.0, 1.0E-8), "exp(3 ln 2) ≈ 8");
      Check (Close (Exp (-3.0 * Ln_2), 0.125, 1.0E-8), "exp(-3 ln 2) ≈ 1/8");
   end;

   ---------------------------------------------------------------------
   Section ("4. Ln canonical values");
   ---------------------------------------------------------------------
   declare
      V : Long_Float;
   begin
      V := Ln (1.0);
      Check (Close (V, 0.0, 1.0E-12), "ln(1) = 0");

      V := Ln (E_Const);
      Check (Close (V, 1.0, 1.0E-9), "ln(e) ≈ 1");
      Check (Close (V, Exact_Ln (E_Const), 1.0E-9), "ln(e) vs Exact_Ln");

      V := Ln (2.0);
      Check (Close (V, Ln_2, 1.0E-9), "ln(2) ≈ Ln_2");

      V := Ln (0.5);
      Check (Close (V, -Ln_2, 1.0E-9), "ln(1/2) ≈ -ln 2");

      V := Ln (4.0);
      Check (Close (V, 2.0 * Ln_2, 1.0E-9), "ln(4) ≈ 2 ln 2");

      V := Ln (0.25);
      Check (Close (V, -2.0 * Ln_2, 1.0E-9), "ln(1/4) ≈ -2 ln 2");

      V := Ln (10.0);
      Check (Close (V, Exact_Ln (10.0), 1.0E-9), "ln(10) vs oracle");

      V := Ln (0.1);
      Check (Close (V, Exact_Ln (0.1), 1.0E-9), "ln(0.1) vs oracle");

      Check (Close (Ln (16.0), 4.0 * Ln_2, 1.0E-9), "ln(16) ≈ 4 ln 2");
      Check (Close (Ln (E_Const * E_Const), 2.0, 1.0E-8), "ln(e²) ≈ 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Invalid_Argument for non-positive Ln");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Dummy  : Long_Float := 0.0;
   begin
      Raised := False;
      begin
         Dummy := Ln (0.0);
      exception
         when Invalid_Argument =>
            Raised := True;
            Dummy := -1.0;
      end;
      Check (Raised and then Dummy = -1.0, "Ln(0) raises Invalid_Argument");

      Raised := False;
      Dummy := 0.0;
      begin
         Dummy := Ln (-1.0);
      exception
         when Invalid_Argument =>
            Raised := True;
            Dummy := -1.0;
      end;
      Check (Raised and then Dummy = -1.0, "Ln(-1) raises Invalid_Argument");

      Raised := False;
      Dummy := 0.0;
      begin
         Dummy := Ln (-0.001);
      exception
         when Invalid_Argument =>
            Raised := True;
            Dummy := -1.0;
      end;
      Check (Raised and then Dummy = -1.0, "Ln(-0.001) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("6. Round-trip Exp(Ln(x)) ≈ x on positives");
   ---------------------------------------------------------------------
   declare
      Xs : constant array (Positive range <>) of Long_Float :=
        [0.01, 0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0,
         E_Const, 4.0, 5.0, 7.0, 10.0, 16.0, 100.0, 1000.0];
      Y : Long_Float;
   begin
      for I in Xs'Range loop
         Y := Exp (Ln (Xs (I)));
         Check (Close (Y, Xs (I), 1.0E-7),
                "Exp(Ln(x))≈x for sample");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Round-trip Ln(Exp(y)) ≈ y on suitable range");
   ---------------------------------------------------------------------
   declare
      Ys : constant array (Positive range <>) of Long_Float :=
        [-5.0, -3.0, -2.0, -1.0, -0.5, -0.1, 0.0, 0.1, 0.5,
         1.0, 1.5, 2.0, 3.0, 4.0, 5.0, Ln_2, -Ln_2];
      X : Long_Float;
   begin
      for I in Ys'Range loop
         X := Ln (Exp (Ys (I)));
         Check (Close (X, Ys (I), 1.0E-7),
                "Ln(Exp(y))≈y for sample");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Exp vs Exact_Exp grid");
   ---------------------------------------------------------------------
   declare
      Y : Long_Float;
      V : Long_Float;
   begin
      Y := -4.0;
      while Y <= 4.0 + 1.0E-12 loop
         V := Exp (Y);
         Check (Close (V, Exact_Exp (Y), 1.0E-7),
                "Exp vs Exact_Exp grid");
         Y := Y + 0.5;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Ln vs Exact_Ln grid");
   ---------------------------------------------------------------------
   declare
      Xs : constant array (Positive range <>) of Long_Float :=
        [0.05, 0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.0,
         3.0, 5.0, 8.0, 12.0, 20.0, 50.0, 200.0];
      V : Long_Float;
   begin
      for I in Xs'Range loop
         V := Ln (Xs (I));
         Check (Close (V, Exact_Ln (Xs (I)), 1.0E-7),
                "Ln vs Exact_Ln grid");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Iteration cap / monotonic improvement");
   ---------------------------------------------------------------------
   declare
      E8, E20, E40 : Long_Float;
      L8, L20, L40 : Long_Float;
   begin
      E8  := Exp (1.0, 8);
      E20 := Exp (1.0, 20);
      E40 := Exp (1.0, 40);
      Check (Abs_Error (E40, E_Const) <= Abs_Error (E8, E_Const) + 1.0E-12,
             "Exp(1) error at 40 ≤ error at 8");
      Check (Abs_Error (E20, E_Const) <= Abs_Error (E8, E_Const) + 1.0E-12,
             "Exp(1) error at 20 ≤ error at 8");
      Check (Close (E40, Exact_Exp (1.0), 1.0E-9), "Exp(1,40) tight");

      L8  := Ln (E_Const, 8);
      L20 := Ln (E_Const, 20);
      L40 := Ln (E_Const, 40);
      Check (Abs_Error (L40, 1.0) <= Abs_Error (L8, 1.0) + 1.0E-12,
             "Ln(e) error at 40 ≤ error at 8");
      Check (Abs_Error (L20, 1.0) <= Abs_Error (L8, 1.0) + 1.0E-12,
             "Ln(e) error at 20 ≤ error at 8");
      Check (Close (L40, 1.0, 1.0E-9), "Ln(e,40) tight");
   end;

   ---------------------------------------------------------------------
   Section ("11. Identities and constants");
   ---------------------------------------------------------------------
   declare
      V : Long_Float;
   begin
      Check (Close (Exp (Ln_2 + Ln_2), 4.0, 1.0E-8), "exp(ln2+ln2)=4");
      Check (Close (Ln (8.0) / Ln_2, 3.0, 1.0E-8), "ln(8)/ln2 = 3");
      Check (Close (Exp (Ln (5.0)), 5.0, 1.0E-7), "exp(ln 5)≈5");
      Check (Close (Ln (Exp (2.5)), 2.5, 1.0E-7), "ln(exp 2.5)≈2.5");

      --  exp(a+b) ≈ exp(a)·exp(b) on a modest pair
      V := Exp (0.3 + 0.4);
      Check (Close (V, Exp (0.3) * Exp (0.4), 1.0E-7),
             "exp(0.3+0.4)≈exp0.3·exp0.4");

      --  ln(a·b) ≈ ln(a)+ln(b)
      V := Ln (3.0 * 7.0);
      Check (Close (V, Ln (3.0) + Ln (7.0), 1.0E-7),
             "ln(3·7)≈ln3+ln7");

      Check (Close (Prod_Bound, Exact_Exp (Sum_Bound), 5.0E-2),
             "Prod_Bound ≈ exp(Sum_Bound)");
      Check (Close (Sum_Bound, Exact_Ln (Prod_Bound), 5.0E-2),
             "Sum_Bound ≈ ln(Prod_Bound)");
      Check (Close (E_Const, Exact_Exp (1.0), 1.0E-14), "E_Const vs oracle");
      Check (Close (Ln_2, Exact_Ln (2.0), 1.0E-14), "Ln_2 vs oracle");
      Check (Close (Log_Table (0) + Log_Table (1),
                    Exact_Ln (2.0 * 1.5), 1.0E-12),
             "A_0+A_1 = ln(2·1.5)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Small / large magnitude sanity");
   ---------------------------------------------------------------------
   declare
      V : Long_Float;
   begin
      V := Exp (10.0 * Ln_2);
      Check (Close (V, 1024.0, 1.0E-6), "exp(10 ln 2) ≈ 1024");
      V := Exp (-10.0 * Ln_2);
      Check (Close (V, 1.0 / 1024.0, 1.0E-9), "exp(-10 ln 2) ≈ 1/1024");
      V := Ln (1024.0);
      Check (Close (V, 10.0 * Ln_2, 1.0E-8), "ln(1024) ≈ 10 ln 2");
      V := Ln (1.0 / 1024.0);
      Check (Close (V, -10.0 * Ln_2, 1.0E-8), "ln(1/1024) ≈ -10 ln 2");
      Check (Close (Exp (0.001), Exact_Exp (0.001), 1.0E-9),
             "exp(0.001) tiny");
      Check (Close (Ln (1.001), Exact_Ln (1.001), 1.0E-9),
             "ln(1.001) tiny");
      Check (Exp (-20.0) > 0.0, "exp(-20) positive");
      Check (Exp (-20.0) < 1.0E-8, "exp(-20) small");
      Check (Ln (1.0E-6) < 0.0, "ln(1e-6) negative");
      Check (Close (Ln (1.0E-6), Exact_Ln (1.0E-6), 1.0E-6),
             "ln(1e-6) vs oracle");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count) &
      "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;

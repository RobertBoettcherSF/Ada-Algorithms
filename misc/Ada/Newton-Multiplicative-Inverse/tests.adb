--  Standalone test suite for Newton_Multiplicative_Inverse (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Newton_Multiplicative_Inverse; use Newton_Multiplicative_Inverse;

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

   function Approx
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Approx;

   Pi : constant Long_Float := Ada.Numerics.Pi;

begin
   Ada.Text_IO.Put_Line ("Newton_Multiplicative_Inverse test suite");
   Ada.Text_IO.Put_Line ("========================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      E := Abs_Error (3.0, 1.0);
      Check (Approx (E, 2.0), "Abs_Error 3-1");
      Check (Approx (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Approx (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      Check (Approx (Rel_Error (1.001, 1.0), 0.001, 1.0E-12),
             "Rel_Error 0.1%");
      Check (Approx (Rel_Error (2.0, 0.0), 2.0), "Rel_Error Exact=0");
      Check (Approx (Rel_Error (-2.0, -1.0), 1.0), "Rel_Error negatives");
   end;

   ---------------------------------------------------------------------
   Section ("2. Exact_Reciprocal oracle");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Check (Approx (Exact_Reciprocal (2.0), 0.5), "Exact 1/2");
      Check (Approx (Exact_Reciprocal (0.5), 2.0), "Exact 1/0.5");
      Check (Approx (Exact_Reciprocal (-4.0), -0.25), "Exact 1/(-4)");
      Check (Approx (Exact_Reciprocal (1.0), 1.0), "Exact 1/1");
      Raised := False;
      begin
         declare
            Unused : Long_Float := Exact_Reciprocal (0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Reciprocal(0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Classic reciprocals: 2, 0.5, 1, 4, 10");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
   begin
      R := Reciprocal_Newton (2.0);
      Check (R.Status = Converged, "1/2 converged");
      Check (Approx (R.Value, 0.5, 1.0E-12), "1/2 = 0.5");
      Check (Approx (2.0 * R.Value, 1.0, 1.0E-12), "2*(1/2)=1");

      R := Reciprocal_Newton (0.5);
      Check (R.Status = Converged and then Approx (R.Value, 2.0, 1.0E-12),
             "1/0.5 = 2");
      Check (Approx (0.5 * R.Value, 1.0, 1.0E-12), "0.5*(1/0.5)=1");

      R := Reciprocal_Newton (1.0);
      Check (R.Status = Converged and then Approx (R.Value, 1.0, 1.0E-12),
             "1/1 = 1");

      R := Reciprocal_Newton (4.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.25, 1.0E-12),
             "1/4 = 0.25");

      R := Reciprocal_Newton (10.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.1, 1.0E-12),
             "1/10 = 0.1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Pi-ish and irrationals vs Exact_Reciprocal");
   ---------------------------------------------------------------------
   declare
      R   : Reciprocal_Result;
      Ex  : Long_Float;
      Args : constant array (Positive range <>) of Long_Float :=
        [Pi, Pi / 2.0, 3.0 * Pi, Ada.Numerics.e,
         1.414_213_562_37, 2.718_281_828_46, 0.123_456_789];
   begin
      for A of Args loop
         R  := Reciprocal_Newton (A);
         Ex := Exact_Reciprocal (A);
         Check (R.Status = Converged, "irrational converged");
         Check (Approx (R.Value, Ex, 1.0E-12), "vs Exact_Reciprocal");
         Check (Approx (A * R.Value, 1.0, 1.0E-11), "a*x ≈ 1");
         Check (Rel_Error (R.Value, Ex) < 1.0E-12, "rel error tiny");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Negatives");
   ---------------------------------------------------------------------
   declare
      R  : Reciprocal_Result;
      Ex : Long_Float;
   begin
      R := Reciprocal_Newton (-2.0);
      Check (R.Status = Converged and then Approx (R.Value, -0.5, 1.0E-12),
             "1/(-2) = -0.5");
      Check (Approx ((-2.0) * R.Value, 1.0, 1.0E-12), "(-2)*x=1");

      R := Reciprocal_Newton (-0.5);
      Check (R.Status = Converged and then Approx (R.Value, -2.0, 1.0E-12),
             "1/(-0.5) = -2");

      R := Reciprocal_Newton (-Pi);
      Ex := Exact_Reciprocal (-Pi);
      Check (R.Status = Converged and then Approx (R.Value, Ex, 1.0E-12),
             "1/(-π) vs oracle");
      Check (Approx ((-Pi) * R.Value, 1.0, 1.0E-11), "(-π)*x=1");

      R := Reciprocal_Newton (-100.0);
      Check (R.Status = Converged and then Approx (R.Value, -0.01, 1.0E-12),
             "1/(-100) = -0.01");
   end;

   ---------------------------------------------------------------------
   Section ("6. Zero rejected (Bad_Domain / Invalid_Argument)");
   ---------------------------------------------------------------------
   declare
      R      : Reciprocal_Result;
      Raised : Boolean;
   begin
      R := Reciprocal_Newton (0.0);
      Check (R.Status = Bad_Domain, "Reciprocal_Newton(0) Bad_Domain");
      Check (R.Iterations = 0, "zero: Iterations=0");
      Check (R.Value = 0.0, "zero: Value=0");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Reciprocal (0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Reciprocal(0) raises Invalid_Argument");

      R := Divide_Newton (5.0, 0.0);
      Check (R.Status = Bad_Domain, "Divide_Newton(*,0) Bad_Domain");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide (5.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide(*,0) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("7. a · x ≈ 1 identity batch");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      R      : Reciprocal_Result;
      A      : Long_Float;
   begin
      for K in 1 .. 50 loop
         A := Long_Float (K) * 0.37 - 9.0;
         if A /= 0.0 then
            R := Reciprocal_Newton (A);
            if R.Status /= Converged
              or else not Approx (A * R.Value, 1.0, 1.0E-10)
            then
               Ok_All := False;
            end if;
         end if;
      end loop;
      Check (Ok_All, "a*x≈1 for 50 scattered nonzero a");
   end;

   ---------------------------------------------------------------------
   Section ("8. Convergence / iteration counts");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
   begin
      R := Reciprocal_Newton (2.0);
      Check (R.Status = Converged and then R.Iterations >= 1, "iters ≥ 1");
      Check (R.Iterations <= 20, "iters ≤ 20 for a=2 (quadratic)");

      R := Reciprocal_Newton (1.0E6);
      Check (R.Status = Converged, "large a=1e6 converged");
      Check (Approx (R.Value, 1.0E-6, 1.0E-15), "1/1e6");
      Check (R.Iterations <= 25, "iters modest for 1e6");

      R := Reciprocal_Newton (1.0E-6);
      Check (R.Status = Converged, "tiny a=1e-6 converged");
      Check (Approx (R.Value, 1.0E6, 1.0E-3), "1/1e-6");
      Check (Approx (1.0E-6 * R.Value, 1.0, 1.0E-10), "tiny a*x=1");

      --  Tight tol still converges quickly.
      R := Reciprocal_Newton (7.0, Tol => 1.0E-15);
      Check (R.Status = Converged, "tight tol converged");
      Check (Approx (R.Value, Exact_Reciprocal (7.0), 1.0E-14),
             "tight vs oracle");

      --  Max_Iter = 1 may or may not finish; Status is either Converged
      --  or Max_Iterations_Reached (never Bad_Domain for nonzero).
      R := Reciprocal_Newton (3.0, Max_Iter => 1);
      Check (R.Status /= Bad_Domain, "Max_Iter=1 not Bad_Domain");
   end;

   ---------------------------------------------------------------------
   Section ("9. Division via reciprocal");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
   begin
      R := Divide_Newton (10.0, 2.0);
      Check (R.Status = Converged and then Approx (R.Value, 5.0, 1.0E-12),
             "10/2 = 5");
      Check (Approx (Divide (10.0, 2.0), 5.0, 1.0E-12), "Divide 10/2");

      R := Divide_Newton (1.0, 4.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.25, 1.0E-12),
             "1/4 via Divide_Newton");

      R := Divide_Newton (-9.0, 3.0);
      Check (R.Status = Converged and then Approx (R.Value, -3.0, 1.0E-12),
             "-9/3 = -3");

      R := Divide_Newton (9.0, -3.0);
      Check (R.Status = Converged and then Approx (R.Value, -3.0, 1.0E-12),
             "9/(-3) = -3");

      R := Divide_Newton (-8.0, -2.0);
      Check (R.Status = Converged and then Approx (R.Value, 4.0, 1.0E-12),
             "(-8)/(-2) = 4");

      R := Divide_Newton (Pi, 2.0);
      Check (R.Status = Converged
             and then Approx (R.Value, Pi / 2.0, 1.0E-12),
             "π/2 via Divide_Newton");

      Check (Approx (Divide (1.0, Pi), Exact_Reciprocal (Pi), 1.0E-12),
             "Divide(1,π)=1/π");

      --  0 / a = 0 for a ≠ 0.
      R := Divide_Newton (0.0, 5.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.0, 1.0E-15),
             "0/5 = 0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Reciprocal convenience wrapper");
   ---------------------------------------------------------------------
   begin
      Check (Approx (Reciprocal (5.0), 0.2, 1.0E-12), "Reciprocal(5)");
      Check (Approx (Reciprocal (-5.0), -0.2, 1.0E-12), "Reciprocal(-5)");
      Check (Approx (Reciprocal (0.25), 4.0, 1.0E-12), "Reciprocal(0.25)");
      Check (Approx (5.0 * Reciprocal (5.0), 1.0, 1.0E-12),
             "5*Reciprocal(5)=1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Power-series inverse: constants and linear");
   ---------------------------------------------------------------------
   declare
      P  : Series_Coeffs (0 .. Max_Series_Degree);
      S  : Series_Result;
   begin
      --  p(t) = 2  ⇒  q(t) = 1/2
      P := [others => 0.0];
      P (0) := 2.0;
      S := Series_Inverse_Newton (P, Degree => 0);
      Check (S.Status = Converged, "series const converged");
      Check (Approx (S.Coeffs (0), 0.5, 1.0E-12), "series 1/2");

      --  p(t) = 1 + t  ⇒  q(t) = 1 − t + t^2 − t^3 + … (geom.)
      P := [others => 0.0];
      P (0) := 1.0;
      P (1) := 1.0;
      S := Series_Inverse_Newton (P, Degree => 4);
      Check (S.Status = Converged, "1+t inverse converged");
      Check (Approx (S.Coeffs (0), 1.0, 1.0E-10), "geom q0=1");
      Check (Approx (S.Coeffs (1), -1.0, 1.0E-10), "geom q1=-1");
      Check (Approx (S.Coeffs (2), 1.0, 1.0E-10), "geom q2=1");
      Check (Approx (S.Coeffs (3), -1.0, 1.0E-10), "geom q3=-1");
      Check (Approx (S.Coeffs (4), 1.0, 1.0E-10), "geom q4=1");
   end;

   ---------------------------------------------------------------------
   Section ("12. Power-series inverse: quadratic and product check");
   ---------------------------------------------------------------------
   declare
      P   : Series_Coeffs (0 .. Max_Series_Degree);
      S   : Series_Result;
      Acc : Long_Float;
      Ok  : Boolean;
   begin
      --  p(t) = 2 + 3 t + t^2
      P := [others => 0.0];
      P (0) := 2.0;
      P (1) := 3.0;
      P (2) := 1.0;
      S := Series_Inverse_Newton (P, Degree => 5);
      Check (S.Status = Converged, "quadratic series converged");

      --  trunc5 (p · q) should be (1, 0, 0, 0, 0, 0)
      Ok := True;
      for N in 0 .. 5 loop
         Acc := 0.0;
         for K in 0 .. N loop
            Acc := Acc + P (K) * S.Coeffs (N - K);
         end loop;
         if N = 0 then
            if not Approx (Acc, 1.0, 1.0E-9) then
               Ok := False;
            end if;
         else
            if not Approx (Acc, 0.0, 1.0E-9) then
               Ok := False;
            end if;
         end if;
      end loop;
      Check (Ok, "trunc (p·q) = 1 through degree 5");
      Check (Approx (S.Coeffs (0), 0.5, 1.0E-10), "q0 = 1/p0 = 1/2");

      --  p0 = 0 → Bad_Domain
      P := [others => 0.0];
      P (1) := 1.0;
      S := Series_Inverse_Newton (P, Degree => 3);
      Check (S.Status = Bad_Domain, "series p0=0 Bad_Domain");
   end;

   ---------------------------------------------------------------------
   Section ("13. Power-series: 1 − t/2 geometric-ish");
   ---------------------------------------------------------------------
   declare
      P : Series_Coeffs (0 .. Max_Series_Degree);
      S : Series_Result;
      --  1/(1 − t/2) = sum (t/2)^k
      Expect : constant array (0 .. 6) of Long_Float :=
        [1.0,
         0.5,
         0.25,
         0.125,
         0.0625,
         0.03125,
         0.015625];
   begin
      P := [others => 0.0];
      P (0) := 1.0;
      P (1) := -0.5;
      S := Series_Inverse_Newton (P, Degree => 6);
      Check (S.Status = Converged, "1-t/2 inverse converged");
      for K in Expect'Range loop
         Check (Approx (S.Coeffs (K), Expect (K), 1.0E-9),
                "geom (1/2)^k coeff");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Scale extremes and signs batch");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      R      : Reciprocal_Result;
      Samples : constant array (Positive range <>) of Long_Float :=
        [1.0E-8, 1.0E-4, 0.01, 0.1, 0.5, 0.9, 1.1, 2.0, 10.0,
         100.0, 1.0E4, 1.0E8, -1.0E-5, -3.5, -999.0, -0.001];
   begin
      for A of Samples loop
         R := Reciprocal_Newton (A);
         if R.Status /= Converged
           or else Rel_Error (R.Value, Exact_Reciprocal (A)) > 1.0E-9
           or else not Approx (A * R.Value, 1.0, 1.0E-10)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "scale/sign sample batch vs oracle");
   end;

   ---------------------------------------------------------------------
   Section ("15. Divide batch vs built-in /");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      Quot   : Long_Float;
   begin
      for I in 1 .. 20 loop
         for J in 1 .. 10 loop
            declare
               B : constant Long_Float := Long_Float (I) + 0.25;
               A : constant Long_Float := Long_Float (J) - 5.5;
            begin
               if A /= 0.0 then
                  Quot := Divide (B, A);
                  if not Approx (Quot, B / A, 1.0E-10) then
                     Ok_All := False;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok_All, "Divide vs built-in / (200 pairs)");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("========================================");
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

--  Standalone test suite for Odlyzko_Schonhage (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Odlyzko_Schonhage; use Odlyzko_Schonhage;

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

   Raised_OK : Boolean;
   Unused_R  : Real;
   pragma Unreferenced (Unused_R);

   function Arrays_Near
     (A, B : Complex_Array; Tol : Real) return Boolean
   is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      declare
         Off : constant Integer := B'First - A'First;
      begin
         for I in A'Range loop
            if not Near (A (I), B (I + Off), Tol) then
               return False;
            end if;
         end loop;
      end;
      return True;
   end Arrays_Near;

   function Reals_Near
     (A, B : Real_Array; Tol : Real) return Boolean
   is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      declare
         Off : constant Integer := B'First - A'First;
      begin
         for I in A'Range loop
            if not Near (A (I), B (I + Off), Tol) then
               return False;
            end if;
         end loop;
      end;
      return True;
   end Reals_Near;

begin
   Put_Line ("Odlyzko_Schonhage — educational Dirichlet / FFT tests");
   Put_Line ("Max_N =" & Max_N'Image & "  Max_M =" & Max_M'Image);

   ------------------------------------------------------------------
   Section ("1. Complex arithmetic / Near / power-of-two");
   ------------------------------------------------------------------
   declare
      A : constant Complex := (1.0, 2.0);
      B : constant Complex := (3.0, -1.0);
      S : constant Complex := A + B;
      D : constant Complex := A - B;
      P : constant Complex := A * B;
   begin
      Check (Near (S.Re, 4.0) and then Near (S.Im, 1.0), "Complex +");
      Check (Near (D.Re, -2.0) and then Near (D.Im, 3.0), "Complex -");
      Check (Near (P.Re, 5.0) and then Near (P.Im, 5.0), "Complex *");
      Check (Near (Conjugate (A), (1.0, -2.0)), "Conjugate");
      Check (Near (Abs_Value ((3.0, 4.0)), 5.0), "|3+4i|=5");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near Real tight");
      Check (not Near (1.0, 1.1, 1.0E-3), "Near Real reject");
      Check (Near (A, A), "Near Complex identical");
      Check (not Near (A, B), "Near Complex distinct");
   end;

   Check (Is_Power_Of_Two (1), "2^0=1");
   Check (Is_Power_Of_Two (2), "2");
   Check (Is_Power_Of_Two (4), "4");
   Check (Is_Power_Of_Two (8), "8");
   Check (Is_Power_Of_Two (256), "256");
   Check (not Is_Power_Of_Two (0), "0 not pot");
   Check (not Is_Power_Of_Two (3), "3 not pot");
   Check (not Is_Power_Of_Two (6), "6 not pot");
   Check (not Is_Power_Of_Two (255), "255 not pot");
   Check (Near ((1.0, 0.0) * (0.0, 1.0), (0.0, 1.0)), "1*(i)=i");
   Check (Near ((0.0, 1.0) * (0.0, 1.0), (-1.0, 0.0)), "i*i=-1");

   ------------------------------------------------------------------
   Section ("2. FFT round-trip (DFT then IDFT)");
   ------------------------------------------------------------------
   declare
      X : Complex_Array (1 .. 8);
      Y : Complex_Array (1 .. 8);
   begin
      for I in X'Range loop
         X (I) := (Real (I), Real (I) * 0.5);
         Y (I) := X (I);
      end loop;
      DFT (Y);
      IDFT (Y);
      Check (Arrays_Near (X, Y, 1.0E-9), "DFT+IDFT round-trip N=8");
   end;

   declare
      X : Complex_Array (1 .. 1);
   begin
      X (1) := (7.0, -2.0);
      DFT (X);
      IDFT (X);
      Check (Near (X (1), (7.0, -2.0)), "DFT+IDFT N=1");
   end;

   declare
      X : Complex_Array (1 .. 4);
   begin
      X := [(1.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0)];
      DFT (X);
      Check (Near (X (1), (1.0, 0.0), 1.0E-9), "impulse DFT[0]");
      Check (Near (X (2), (1.0, 0.0), 1.0E-9), "impulse DFT[1]");
      Check (Near (X (3), (1.0, 0.0), 1.0E-9), "impulse DFT[2]");
      Check (Near (X (4), (1.0, 0.0), 1.0E-9), "impulse DFT[3]");
   end;

   declare
      X : Complex_Array (1 .. 16);
      Orig : Complex_Array (1 .. 16);
   begin
      for I in X'Range loop
         X (I) := (Real (I * I), -Real (I));
         Orig (I) := X (I);
      end loop;
      DFT (X);
      IDFT (X);
      Check (Arrays_Near (X, Orig, 1.0E-8), "DFT+IDFT round-trip N=16");
   end;

   declare
      X : Complex_Array (1 .. 32);
      Orig : Complex_Array (1 .. 32);
   begin
      for I in X'Range loop
         X (I) := (Real (I mod 7), Real ((I * 3) mod 5));
         Orig (I) := X (I);
      end loop;
      DFT (X);
      IDFT (X);
      Check (Arrays_Near (X, Orig, 1.0E-8), "DFT+IDFT N=32");
   end;

   Raised_OK := False;
   begin
      declare
         Bad : Complex_Array (1 .. 3) := [others => (0.0, 0.0)];
      begin
         DFT (Bad);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "DFT non-pot raises");

   Raised_OK := False;
   begin
      declare
         Bad : Complex_Array (1 .. 3) := [others => (0.0, 0.0)];
      begin
         IDFT (Bad);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "IDFT non-pot raises");

   ------------------------------------------------------------------
   Section ("3. Polynomial multipoint FFT vs naive");
   ------------------------------------------------------------------
   declare
      Coeffs : constant Complex_Array (1 .. 3) :=
        [(1.0, 0.0), (2.0, 0.0), (3.0, 0.0)];
      F : Complex_Array (1 .. 8);
      N : Complex_Array (1 .. 8);
   begin
      Polynomial_Eval_FFT (Coeffs, F);
      Polynomial_Eval_Naive (Coeffs, N);
      Check (Arrays_Near (F, N, 1.0E-8), "poly FFT vs naive deg2 @ 8 roots");
      Check (Near (F (1).Re, 6.0, 1.0E-8) and then Near (F (1).Im, 0.0),
             "Q(1)=6 via FFT");
   end;

   declare
      Coeffs : constant Complex_Array (1 .. 4) :=
        [(0.5, 0.0), (-1.0, 0.25), (0.0, 1.0), (2.0, -0.5)];
      F, Nv : Complex_Array (1 .. 4);
   begin
      Polynomial_Eval_FFT (Coeffs, F);
      Polynomial_Eval_Naive (Coeffs, Nv);
      Check (Arrays_Near (F, Nv, 1.0E-8), "poly FFT vs naive complex N=4");
   end;

   Raised_OK := False;
   begin
      declare
         C : constant Complex_Array (1 .. 2) := [others => (1.0, 0.0)];
         V : Complex_Array (1 .. 3);
      begin
         Polynomial_Eval_FFT (C, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "poly FFT bad Len raises");

   Raised_OK := False;
   begin
      declare
         C : constant Complex_Array (1 .. 5) := [others => (1.0, 0.0)];
         V : Complex_Array (1 .. 4);
      begin
         Polynomial_Eval_Naive (C, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "poly naive coeffs>Len raises");

   ------------------------------------------------------------------
   Section ("4. Naive Dirichlet / Zeta_Partial vs π²/6");
   ------------------------------------------------------------------
   declare
      Z2_10  : constant Real := Naive_Dirichlet_Poly (2.0, 10);
      Z2_50  : constant Real := Naive_Dirichlet_Poly (2.0, 50);
      Z2_200 : constant Real := Zeta_Partial (2.0, 200);
   begin
      Check (Z2_10 > 1.5 and then Z2_10 < Pi_Squared_Over_6,
             "zeta_10(2) in (1.5, π²/6)");
      Check (Z2_50 > Z2_10, "partial zeta grows with N");
      Check (Z2_200 > Z2_50, "zeta_200 > zeta_50");
      Check (Near (Z2_200, Pi_Squared_Over_6, 5.0E-3),
             "zeta_200(2) near π²/6 (tol 5e-3)");
      Check (abs (Z2_200 - Pi_Squared_Over_6)
               < abs (Z2_50 - Pi_Squared_Over_6),
             "error shrinks N=50→200");
   end;

   Check (Near (Naive_Dirichlet_Poly (2.0, 1), 1.0), "P(2),N=1 → 1");
   Check (Near (Naive_Dirichlet_Poly (2.0, 2), 1.0 + 0.25),
          "P(2),N=2 → 1.25");
   Check (Near (Naive_Dirichlet_Poly (2.0, 3), 1.25 + 1.0 / 9.0, 1.0E-12),
          "P(2),N=3");
   Check (Near (Naive_Dirichlet_Poly (2.0, 4),
                1.25 + 1.0 / 9.0 + 0.0625, 1.0E-12),
          "P(2),N=4");

   declare
      Z3 : constant Real := Naive_Dirichlet_Poly (3.0, 100);
   begin
      Check (Z3 > 1.0 and then Z3 < 1.21, "zeta_100(3) in (1, 1.21)");
   end;

   declare
      A : constant Real := Naive_Dirichlet_Poly (2.0, 5);
      B : constant Real := Naive_Dirichlet_Poly (2.0, 6);
   begin
      Check (B > A, "Dirichlet increases with N");
      Check (Near (B - A, 1.0 / 36.0), "6th term = 6^{-2}");
   end;

   Check (Zeta_Partial (2.0, 20) = Naive_Dirichlet_Poly (2.0, 20),
          "Zeta_Partial alias");

   Raised_OK := False;
   begin
      Unused_R := Naive_Dirichlet_Poly (1.0, 10);
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Naive s=1 raises");

   Raised_OK := False;
   begin
      Unused_R := Naive_Dirichlet_Poly (0.5, 5);
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Naive s=0.5 raises");

   ------------------------------------------------------------------
   Section ("5. Eta_Partial");
   ------------------------------------------------------------------
   declare
      E1 : constant Real := Eta_Partial (1.0, 100);
      E2 : constant Real := Eta_Partial (2.0, 50);
   begin
      Check (Near (E1, 0.693_147, 5.0E-3), "eta_100(1) ~ ln2");
      Check (Near (E2, 0.822_467, 5.0E-3), "eta_50(2) ~ π²/12");
      Check (Eta_Partial (2.0, 1) = 1.0, "eta N=1");
      Check (Near (Eta_Partial (2.0, 2), 1.0 - 0.25), "eta N=2");
   end;

   Raised_OK := False;
   begin
      Unused_R := Eta_Partial (0.0, 10);
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Eta s=0 raises");

   ------------------------------------------------------------------
   Section ("6. Naive_Batch vs Fast_Batch_Geometric");
   ------------------------------------------------------------------
   declare
      M : constant Batch_Count := 8;
      N : constant Truncation := 32;
      S0 : constant Real := 2.0;
      H  : constant Real := 0.05;
      Absci : Real_Array (1 .. M);
      Naive_V, Fast_V : Real_Array (1 .. M);
   begin
      for J in 0 .. M - 1 loop
         Absci (1 + J) := S0 + Real (J) * H;
      end loop;
      Naive_Batch (Absci, N, Naive_V);
      Fast_Batch_Geometric (S0, H, M, N, Fast_V);
      Check (Reals_Near (Naive_V, Fast_V, 1.0E-8),
             "geometric vs naive batch M=8 N=32");
      Check (Near (Naive_V (1), Naive_Dirichlet_Poly (S0, N)),
             "batch[0] = single Naive");
   end;

   declare
      M : constant Batch_Count := 16;
      N : constant Truncation := 64;
      S0 : constant Real := 1.5;
      H  : constant Real := 0.1;
      Absci : Real_Array (1 .. M);
      Naive_V, Fast_V : Real_Array (1 .. M);
      Max_Diff : Real := 0.0;
   begin
      for J in 0 .. M - 1 loop
         Absci (1 + J) := S0 + Real (J) * H;
      end loop;
      Naive_Batch (Absci, N, Naive_V);
      Fast_Batch_Geometric (S0, H, M, N, Fast_V);
      for I in Naive_V'Range loop
         Max_Diff := Real'Max (Max_Diff, abs (Naive_V (I) - Fast_V (I)));
      end loop;
      Check (Reals_Near (Naive_V, Fast_V, 1.0E-8),
             "geometric vs naive M=16 N=64 tol 1e-8");
      Check (Max_Diff < 1.0E-9, "geometric max diff < 1e-9");
   end;

   declare
      V1, V2 : Real_Array (1 .. 4);
   begin
      Fast_Batch_Geometric (2.0, 0.05, 4, 10, V1);
      Fast_Batch_Geometric (2.0, 0.05, 4, 20, V2);
      Check (V2 (1) > V1 (1), "fast batch grows with N");
      Check (V2 (4) > V1 (4), "fast batch last abscissa grows");
   end;

   for H_I in 1 .. 5 loop
      declare
         H : constant Real := 0.02 * Real (H_I);
         M : constant Batch_Count := 4;
         N : constant Truncation := 12;
         Absci : Real_Array (1 .. M);
         Nv, Fv : Real_Array (1 .. M);
      begin
         for J in 0 .. M - 1 loop
            Absci (1 + J) := 2.0 + Real (J) * H;
         end loop;
         Naive_Batch (Absci, N, Nv);
         Fast_Batch_Geometric (2.0, H, M, N, Fv);
         Check (Reals_Near (Nv, Fv, 1.0E-8),
                "geometric grid H step #" & Integer'Image (H_I));
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("7. Odlyzko_Schonhage_Sketch vs Naive_Batch");
   ------------------------------------------------------------------
   declare
      M : constant Batch_Count := 8;
      N : constant Truncation := 24;
      S0 : constant Real := 2.0;
      H  : constant Real := 0.01;
      Absci : Real_Array (1 .. M);
      Naive_V, OS_V : Real_Array (1 .. M);
   begin
      for J in 0 .. M - 1 loop
         Absci (1 + J) := S0 + Real (J) * H;
      end loop;
      Naive_Batch (Absci, N, Naive_V);
      Odlyzko_Schonhage_Sketch (S0, H, M, N, OS_V);
      Check (Reals_Near (Naive_V, OS_V, 1.0E-8),
             "OS sketch vs naive H=0.01 M=8");
   end;

   declare
      M : constant Batch_Count := 16;
      N : constant Truncation := 48;
      S0 : constant Real := 2.5;
      H  : constant Real := 0.1;
      Absci : Real_Array (1 .. M);
      Naive_V, OS_V : Real_Array (1 .. M);
   begin
      for J in 0 .. M - 1 loop
         Absci (1 + J) := S0 + Real (J) * H;
      end loop;
      Naive_Batch (Absci, N, Naive_V);
      Odlyzko_Schonhage_Sketch (S0, H, M, N, OS_V);
      Check (Reals_Near (Naive_V, OS_V, 1.0E-8),
             "OS sketch vs naive H=0.1 (fallback)");
   end;

   declare
      M : constant Batch_Count := 4;
      N : constant Truncation := 16;
      Fast_V, OS_V : Real_Array (1 .. M);
   begin
      Fast_Batch_Geometric (3.0, 0.25, M, N, Fast_V);
      Odlyzko_Schonhage_Sketch (3.0, 0.25, M, N, OS_V);
      Check (Reals_Near (Fast_V, OS_V, 1.0E-8),
             "OS sketch matches geometric");
   end;

   for K in 1 .. 4 loop
      declare
         M : constant Batch_Count := 4;
         N : constant Truncation := Truncation (8 * K);
         Absci : Real_Array (1 .. M);
         Nv, Ov : Real_Array (1 .. M);
      begin
         for J in 0 .. M - 1 loop
            Absci (1 + J) := 2.0 + Real (J) * 0.03;
         end loop;
         Naive_Batch (Absci, N, Nv);
         Odlyzko_Schonhage_Sketch (2.0, 0.03, M, N, Ov);
         Check (Reals_Near (Nv, Ov, 1.0E-8),
                "OS sketch N=" & Truncation'Image (N));
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument / API smoke");
   ------------------------------------------------------------------
   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 4);
         A : constant Real_Array (1 .. 3) := [2.0, 2.1, 2.2];
      begin
         Naive_Batch (A, 10, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Naive_Batch length mismatch raises");

   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 2);
         A : constant Real_Array (1 .. 2) := [0.5, 2.0];
      begin
         Naive_Batch (A, 10, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Naive_Batch S<=1 raises");

   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 4);
      begin
         Fast_Batch_Geometric (2.0, -0.1, 4, 8, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Fast_Batch H<=0 raises");

   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 4);
      begin
         Fast_Batch_Geometric (1.0, 0.1, 4, 8, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Fast_Batch S0<=1 raises");

   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 3);
      begin
         Fast_Batch_Geometric (2.0, 0.1, 4, 8, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Fast_Batch Values length raises");

   Raised_OK := False;
   begin
      declare
         V : Real_Array (1 .. 4);
      begin
         Odlyzko_Schonhage_Sketch (0.5, 0.1, 4, 8, V);
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "OS sketch S0<=1 raises");

   ------------------------------------------------------------------
   Section ("9. Caps / batch single-point smoke");
   ------------------------------------------------------------------
   Check (Max_N'Image = " 256", "Max_N=256");
   Check (Max_M'Image = " 256", "Max_M=256");
   Check (Near (Near_Tol, 1.0E-9), "Near_Tol");

   declare
      Ss : constant Real_Array (1 .. 5) := [2.0, 2.5, 3.0, 4.0, 5.0];
      Vs : Real_Array (1 .. 5);
   begin
      Naive_Batch (Ss, 40, Vs);
      Check (Near (Vs (1), Naive_Dirichlet_Poly (2.0, 40), 1.0E-12),
             "batch matches single s=2");
      Check (Near (Vs (2), Naive_Dirichlet_Poly (2.5, 40), 1.0E-12),
             "batch matches single s=2.5");
      Check (Near (Vs (3), Naive_Dirichlet_Poly (3.0, 40), 1.0E-12),
             "batch matches single s=3");
      Check (Near (Vs (4), Naive_Dirichlet_Poly (4.0, 40), 1.0E-12),
             "batch matches single s=4");
      Check (Near (Vs (5), Naive_Dirichlet_Poly (5.0, 40), 1.0E-12),
             "batch matches single s=5");
   end;

   --  Extra FFT size-2 / size-64 smoke
   declare
      X : Complex_Array (1 .. 2);
      Orig : Complex_Array (1 .. 2);
   begin
      X := [(3.0, 1.0), (-2.0, 4.0)];
      Orig := X;
      DFT (X);
      IDFT (X);
      Check (Arrays_Near (X, Orig, 1.0E-9), "DFT+IDFT N=2");
   end;

   declare
      X : Complex_Array (1 .. 64);
      Orig : Complex_Array (1 .. 64);
   begin
      for I in X'Range loop
         X (I) := (Real (I), 0.0);
         Orig (I) := X (I);
      end loop;
      DFT (X);
      IDFT (X);
      Check (Arrays_Near (X, Orig, 1.0E-7), "DFT+IDFT N=64");
   end;

   --  More OS / geometric pairs
   for K in 1 .. 6 loop
      declare
         M : constant Batch_Count := 8;
         N : constant Truncation := 20;
         H : constant Real := 0.015 * Real (K);
         Absci : Real_Array (1 .. M);
         Nv, Fv, Ov : Real_Array (1 .. M);
      begin
         for J in 0 .. M - 1 loop
            Absci (1 + J) := 2.2 + Real (J) * H;
         end loop;
         Naive_Batch (Absci, N, Nv);
         Fast_Batch_Geometric (2.2, H, M, N, Fv);
         Odlyzko_Schonhage_Sketch (2.2, H, M, N, Ov);
         Check (Reals_Near (Nv, Fv, 1.0E-8),
                "geo pair #" & Integer'Image (K));
         Check (Reals_Near (Nv, Ov, 1.0E-8),
                "OS pair #" & Integer'Image (K));
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("Summary");
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

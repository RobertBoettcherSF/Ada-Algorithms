--  Standalone test suite for Binary_Splitting (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Binary_Splitting; use Binary_Splitting;

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
      return abs (A - B) <= Tol;
   end Approx;

   --  Known partial sums of e as rationals Num/Den for small N.
   --  e_N = Σ_{k=0}^{N} 1/k! = Num/Den with Den = N!.
   type Frac is record
      Num, Den : Long_Integer;
   end record;

   function Known_E_Frac (N : Split_Index) return Frac is
      Den : constant Long_Integer := Factorial (N);
      Num : Long_Integer := 0;
   begin
      for K in 0 .. N loop
         Num := Num + Den / Factorial (K);
      end loop;
      return (Num => Num, Den => Den);
   end Known_E_Frac;

begin
   Ada.Text_IO.Put_Line ("Binary_Splitting test suite");
   Ada.Text_IO.Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error helpers");
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
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty range A = B");
   ---------------------------------------------------------------------
   declare
      R0 : constant Split_Result := Binary_Split (0, 0);
      R5 : constant Split_Result := Binary_Split (5, 5);
      I0 : constant Split_Result := Binary_Split_Iterative (0, 0);
   begin
      Check (R0.P = 0 and R0.Q = 1, "empty (0,0) -> (0,1)");
      Check (R5.P = 0 and R5.Q = 1, "empty (5,5) -> (0,1)");
      Check (I0.P = 0 and I0.Q = 1, "iter empty (0,0)");
      Check (Approx (Partial_Sum (R0), 1.0), "empty partial = 1 (0! term)");
      Check (Approx (Approximate_E (0), 1.0), "Approximate_E(0) = 1");
      Check (Approx (Sum_Naive_Float (0), 1.0), "Naive_Float(0) = 1");
      Check (Exact_Numerator (0) = 1, "Exact_Numerator(0) = 1");
      Check (Exact_Denominator (0) = 1, "Exact_Denominator(0) = 1");
      Check (Factorial (0) = 1, "0! = 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Single-term base cases B = A+1");
   ---------------------------------------------------------------------
   declare
      R01 : constant Split_Result := Binary_Split (0, 1);
      R12 : constant Split_Result := Binary_Split (1, 2);
      R23 : constant Split_Result := Binary_Split (2, 3);
      I01 : constant Split_Result := Binary_Split_Iterative (0, 1);
   begin
      Check (R01.P = 1 and R01.Q = 1, "BS(0,1) = (1,1)");
      Check (R12.P = 1 and R12.Q = 2, "BS(1,2) = (1,2)");
      Check (R23.P = 1 and R23.Q = 3, "BS(2,3) = (1,3)");
      Check (I01.P = R01.P and I01.Q = R01.Q, "iter ≡ rec (0,1)");
      Check (Approx (Partial_Sum (R01), 2.0), "partial (0,1) = 2");
      Check (Approx (Approximate_E (1), 2.0), "e_1 = 2");
      Check (Approx (Sum_Naive_Float (1), 2.0), "naive e_1 = 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Small recursive combines");
   ---------------------------------------------------------------------
   declare
      R02 : constant Split_Result := Binary_Split (0, 2);
      R03 : constant Split_Result := Binary_Split (0, 3);
      R04 : constant Split_Result := Binary_Split (0, 4);
   begin
      --  BS(0,2): left(0,1)=(1,1), right(1,2)=(1,2) -> P=1*2+1=3, Q=2
      Check (R02.P = 3 and R02.Q = 2, "BS(0,2) = (3,2)");
      Check (Approx (Partial_Sum (R02), 2.5), "e_2 = 5/2");

      --  BS(0,3): (P,Q)=(10,6), (10+6)/6 = 8/3
      Check (R03.P = 10 and R03.Q = 6, "BS(0,3) = (10,6)");
      Check (Approx (Partial_Sum (R03), 8.0 / 3.0), "e_3 = 8/3");

      --  e_4 = 1+1+1/2+1/6+1/24 = 65/24
      Check (R04.Q = 24, "BS(0,4).Q = 24 = 4!");
      Check (R04.P + R04.Q = 65, "BS(0,4) num = 65");
      Check (Approx (Partial_Sum (R04), 65.0 / 24.0), "e_4 = 65/24");
   end;

   ---------------------------------------------------------------------
   Section ("5. Recursive ≡ iterative for many intervals");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for A in Bound range 0 .. 10 loop
         for B in Bound range A .. 12 loop
            declare
               R : constant Split_Result := Binary_Split (A, B);
               I : constant Split_Result := Binary_Split_Iterative (A, B);
            begin
               if R.P /= I.P or else R.Q /= I.Q then
                  Ok := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok, "rec ≡ iter for all 0<=A<=B<=12 (A<=10)");

      for N in Split_Index range 0 .. Max_N loop
         declare
            R : constant Split_Result := Binary_Split (0, N);
            I : constant Split_Result := Binary_Split_Iterative (0, N);
         begin
            if R.P /= I.P or else R.Q /= I.Q then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "rec ≡ iter Binary_Split(0,N) for N=0..Max_N");
   end;

   ---------------------------------------------------------------------
   Section ("6. Exact Num/Den vs hand Factorial sum");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for N in Split_Index range 0 .. Max_N loop
         declare
            K : constant Frac := Known_E_Frac (N);
            Num : constant Long_Integer := Exact_Numerator (N);
            Den : constant Long_Integer := Exact_Denominator (N);
         begin
            if Num /= K.Num or else Den /= K.Den then
               Ok := False;
            end if;
            if Den /= Factorial (N) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "Exact Num/Den match Factorial oracle N=0..Max_N");
      Check (Factorial (5) = 120, "5! = 120");
      Check (Factorial (10) = 3_628_800, "10! = 3628800");
      Check (Exact_Denominator (10) = Factorial (10), "Den(10)=10!");
   end;

   ---------------------------------------------------------------------
   Section ("7. Approximate_E vs Sum_Naive_Float vs known e");
   ---------------------------------------------------------------------
   declare
      --  e ≈ 2.71828182845904523536
      E_Ref : constant Long_Float := 2.71828182845904523536;
      Ok_Close : Boolean := True;
   begin
      Check (Approx (Approximate_E (0), 1.0), "e_0 = 1");
      Check (Approx (Approximate_E (1), 2.0), "e_1 = 2");
      Check (Approx (Approximate_E (2), 2.5), "e_2 = 2.5");
      Check (Approx (Approximate_E (5), 163.0 / 60.0), "e_5 = 163/60");

      for N in Split_Index range 0 .. Max_N loop
         declare
            A : constant Long_Float := Approximate_E (N);
            S : constant Long_Float := Sum_Naive_Float (N);
            K : constant Frac := Known_E_Frac (N);
            Exact : constant Long_Float :=
              Long_Float (K.Num) / Long_Float (K.Den);
         begin
            if not Approx (A, Exact, 1.0E-12)
              or else not Approx (S, Exact, 1.0E-12)
            then
               Ok_Close := False;
            end if;
         end;
      end loop;
      Check (Ok_Close, "Approx_E and Naive match exact ratio N=0..Max_N");

      --  Truncation error e − e_N ≈ 1/(N!·N) roughly; for N=15 already tiny.
      Check (Abs_Error (Approximate_E (15), E_Ref) < 1.0E-10,
             "|e_15 − e| < 1e-10");
      Check (Abs_Error (Approximate_E (20), E_Ref) < 1.0E-14,
             "|e_20 − e| < 1e-14");
      Check (Abs_Error (Sum_Naive_Float (20), E_Ref) < 1.0E-14,
             "|naive_20 − e| < 1e-14");
      Check (Near (Approximate_E (20), Sum_Naive_Float (20), 1.0E-14),
             "Approx_E(20) Near Naive(20)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Ratio / Partial_Sum helpers");
   ---------------------------------------------------------------------
   declare
      R : constant Split_Result := Binary_Split (0, 4);
   begin
      Check (Approx (Ratio (R), Long_Float (R.P) / Long_Float (R.Q)),
             "Ratio matches P/Q");
      Check (Approx (Partial_Sum (R), Approximate_E (4)),
             "Partial_Sum ≡ Approximate_E(4)");
      Check (R.Q > 0, "Q positive");
      Check (R.P > 0, "P positive for (0,4)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sub-interval identity");
   ---------------------------------------------------------------------
   --  For A < B: Q(A,B) = B!/A! and (P+Q)/Q = Σ_{n=A}^{B} A!/n!
   declare
      Ok : Boolean := True;
   begin
      for A in Bound range 0 .. 6 loop
         for B in Bound range A .. 10 loop
            declare
               R : constant Split_Result := Binary_Split (A, B);
               Expect_Q : Long_Integer;
               Expect_Sum : Long_Integer := 0;  -- Σ A!/n! * (B!/A!) = Σ B!/n!
               Got_Num : Long_Integer;
            begin
               Expect_Q := Factorial (B) / Factorial (A);
               if R.Q /= Expect_Q then
                  Ok := False;
               end if;
               --  P + Q should equal Σ_{n=A}^{B} B!/n!
               for N in A .. B loop
                  Expect_Sum := Expect_Sum + Factorial (B) / Factorial (N);
               end loop;
               Got_Num := R.P + R.Q;
               if Got_Num /= Expect_Sum then
                  Ok := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok, "Q=B!/A! and P+Q=Σ B!/n! on subintervals");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument defence");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            R : Split_Result;
         begin
            R := Binary_Split (3, 2);
            pragma Unreferenced (R);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "BS(3,2) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            --  Force out-of-range via unchecked cast path: call with
            --  B > Max_N by using a local that bypasses subtype — we
            --  instead verify Max_N boundary succeeds and document cap.
            R : constant Split_Result := Binary_Split (0, Max_N);
         begin
            Check (R.Q = Factorial (Max_N), "BS(0,Max_N).Q = Max_N!");
            Check (R.P > 0, "BS(0,Max_N).P > 0");
            Raised := True;  -- reached without exception
         end;
      exception
         when others =>
            Raised := False;
      end;
      Check (Raised, "BS(0,Max_N) succeeds");
   end;

   ---------------------------------------------------------------------
   Section ("11. Monotone convergence toward e");
   ---------------------------------------------------------------------
   declare
      Prev : Long_Float := Approximate_E (0);
      Ok_F : Boolean := True;
      Ok_Z : Boolean := True;
      E_Ref : constant Long_Float := 2.71828182845904523536;
      --  Exact step: Den_{N+1}=(N+1)·Den_N and Num_{N+1}=(N+1)·Num_N+1
      --  (safe for N ≤ 12; larger N overflows Long_Integer in the product).
   begin
      Check (Prev < E_Ref, "e_0 < e");
      for N in Split_Index range 1 .. 16 loop
         declare
            Cur : constant Long_Float := Approximate_E (N);
         begin
            if Cur < Prev or else Cur > E_Ref + 1.0E-14 then
               Ok_F := False;
            end if;
            Prev := Cur;
         end;
      end loop;
      Check (Ok_F, "e_N Long_Float nondec. and ≤ e (N=1..16)");

      for N in Split_Index range 0 .. 12 loop
         declare
            N0 : constant Long_Integer := Exact_Numerator (N);
            D0 : constant Long_Integer := Exact_Denominator (N);
            N1 : constant Long_Integer := Exact_Numerator (N + 1);
            D1 : constant Long_Integer := Exact_Denominator (N + 1);
            Step : constant Long_Integer := Long_Integer (N + 1);
         begin
            if D1 /= D0 * Step or else N1 /= N0 * Step + 1 then
               Ok_Z := False;
            end if;
            --  Cross-multiply safe for N ≤ 12 (products ≪ 2^63).
            if N0 * D1 >= N1 * D0 then
               Ok_Z := False;
            end if;
         end;
      end loop;
      Check (Ok_Z, "exact step Num/Den and e_N < e_{N+1} for N=0..12");
      Check (Near (Approximate_E (Max_N), E_Ref, 1.0E-14),
             "Approximate_E(Max_N) Near e");
   end;

   ---------------------------------------------------------------------
   Section ("12. Batch: Naive vs split agreement");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Max_Diff : Long_Float := 0.0;
   begin
      for N in Split_Index range 0 .. Max_N loop
         declare
            D : constant Long_Float :=
              Abs_Error (Approximate_E (N), Sum_Naive_Float (N));
         begin
            if D > Max_Diff then
               Max_Diff := D;
            end if;
            if D > 1.0E-12 then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "batch |Approx−Naive| ≤ 1e-12 for all N");
      Check (Max_Diff < 1.0E-12, "max |Approx−Naive| < 1e-12");
   end;

   ---------------------------------------------------------------------
   Section ("13. Known small factorials and splits");
   ---------------------------------------------------------------------
   declare
      R : Split_Result;
   begin
      Check (Factorial (1) = 1, "1! = 1");
      Check (Factorial (2) = 2, "2! = 2");
      Check (Factorial (3) = 6, "3! = 6");
      Check (Factorial (4) = 24, "4! = 24");
      Check (Factorial (6) = 720, "6! = 720");
      Check (Factorial (7) = 5_040, "7! = 5040");
      Check (Factorial (8) = 40_320, "8! = 40320");
      Check (Factorial (9) = 362_880, "9! = 362880");

      R := Binary_Split (3, 6);
      Check (R.Q = Factorial (6) / Factorial (3), "Q(3,6)=6!/3!");
      R := Binary_Split (0, 7);
      Check (R.Q = 5_040, "Q(0,7)=7!");
      Check (Exact_Numerator (3) = 16, "num e_3 = 16");
      Check (Exact_Denominator (3) = 6, "den e_3 = 6");
   end;

   ---------------------------------------------------------------------
   Section ("14. Mid-interval combine manual check");
   ---------------------------------------------------------------------
   declare
      --  Manual: BS(0,6) via m=3
      L : constant Split_Result := Binary_Split (0, 3);
      R : constant Split_Result := Binary_Split (3, 6);
      C : constant Split_Result :=
        (P => L.P * R.Q + R.P, Q => L.Q * R.Q);
      Full : constant Split_Result := Binary_Split (0, 6);
   begin
      Check (C.P = Full.P and C.Q = Full.Q, "manual combine (0,3)+(3,6)=(0,6)");
      Check (Full.Q = 720, "6! via full split");
      Check (Approx (Partial_Sum (Full), Approximate_E (6)),
             "partial full ≡ Approx_E(6)");
   end;

   ---------------------------------------------------------------------
   Section ("15. Caps and constants");
   ---------------------------------------------------------------------
   declare
      Num_Max : constant Long_Integer := Exact_Numerator (Max_N);
      Den_Max : constant Long_Integer := Exact_Denominator (Max_N);
      Fac_Max : constant Long_Integer := Factorial (Max_N);
   begin
      Check (Den_Max = Fac_Max, "Den(Max_N) = Max_N!");
      Check (Num_Max > Den_Max, "numerator > N! (e_N > 1)");
      Check (Binary_Split (0, Max_N).Q = Fac_Max,
             "BS(0,Max_N).Q = Max_N!");
      Check (Binary_Split_Iterative (0, Max_N).Q = Fac_Max,
             "iter(0,Max_N).Q = Max_N!");
      Check (Abs_Error (Approximate_E (Max_N), Sum_Naive_Float (Max_N))
               < 1.0E-14,
             "|Approx−Naive|(Max_N) < 1e-14");
      --  Room in Long_Integer: e·20! ≈ 6.61e18 < 2^63−1 ≈ 9.22e18.
      Check (Num_Max < Long_Integer'Last / 1,
             "Exact_Numerator(Max_N) < Long_Integer'Last");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra: Ratio on subintervals and e_5 exact");
   ---------------------------------------------------------------------
   declare
      R : constant Split_Result := Binary_Split (1, 5);
      --  Σ_{n=1}^{5} 1!/n! = 1+1/2+1/6+1/24+1/120 = 206/120
      Expect : constant Long_Float := 206.0 / 120.0;
   begin
      Check (R.Q = Factorial (5) / Factorial (1), "Q(1,5)=5!/1!");
      Check (R.P + R.Q = 206, "P+Q (1,5) = 206");
      Check (Approx (Partial_Sum (R), Expect), "partial (1,5) = 206/120");
      Check (Approx (Approximate_E (5), 163.0 / 60.0), "e_5 = 163/60");
      Check (Exact_Numerator (5) = 326, "num e_5 = 326");
      Check (Exact_Denominator (5) = 120, "den e_5 = 120 = 5!");
      Check (Approx (Ratio (Binary_Split (0, 2)), 1.5), "Ratio(0,2)=3/2");
      Check (Binary_Split (4, 4).P = 0, "empty mid P=0");
      Check (Binary_Split (7, 8).P = 1 and Binary_Split (7, 8).Q = 8,
             "BS(7,8)=(1,8)");
      Check (Near (Sum_Naive_Float (5), Approximate_E (5)),
             "Naive Near Approx at N=5");
      Check (Abs_Error (0.0, 0.0) = 0.0, "Abs_Error 0");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===========================");
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

--  Standalone test suite for Kahan_Summation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Kahan_Summation; use Kahan_Summation;

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

   --  Exact sum in Long_Float (oracle).
   function Exact_Sum (Data : Float_Array) return Long_Float is
      S : Long_Float := 0.0;
   begin
      for X of Data loop
         S := S + Long_Float (X);
      end loop;
      return S;
   end Exact_Sum;

begin
   Ada.Text_IO.Put_Line ("Kahan_Summation test suite");
   Ada.Text_IO.Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error helpers");
   ---------------------------------------------------------------------
   declare
      E : Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Approx (Abs_Error (3.0, 1.0), 2.0), "Abs_Error Float");
      Check (Approx (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      E := Abs_Error_Exact (1.0, Long_Float'(1.0));
      Check (Approx (E, 0.0), "Abs_Error vs Long_Float exact");
      E := Abs_Error_Exact (1.5, Long_Float'(1.0));
      Check (Approx (E, 0.5), "Abs_Error vs Long_Float 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty / one / two terms");
   ---------------------------------------------------------------------
   declare
      Empty : Float_Array (1 .. 0);
      One   : constant Float_Array := [42.0];
      Two   : constant Float_Array := [1.5, 2.5];
      Neg   : constant Float_Array := [-3.0, 1.0];
   begin
      Check (Approx (Sum_Naive (Empty), 0.0), "Naive empty");
      Check (Approx (Sum_Kahan (Empty), 0.0), "Kahan empty");
      Check (Approx (Sum_Neumaier (Empty), 0.0), "Neumaier empty");
      Check (Approx (Sum_Pairwise (Empty), 0.0), "Pairwise empty");

      Check (Approx (Sum_Naive (One), 42.0), "Naive one");
      Check (Approx (Sum_Kahan (One), 42.0), "Kahan one");
      Check (Approx (Sum_Neumaier (One), 42.0), "Neumaier one");
      Check (Approx (Sum_Pairwise (One), 42.0), "Pairwise one");

      Check (Approx (Sum_Naive (Two), 4.0), "Naive two");
      Check (Approx (Sum_Kahan (Two), 4.0), "Kahan two");
      Check (Approx (Sum_Neumaier (Two), 4.0), "Neumaier two");
      Check (Approx (Sum_Pairwise (Two), 4.0), "Pairwise two");

      Check (Approx (Sum_Naive (Neg), -2.0), "Naive neg+pos");
      Check (Approx (Sum_Kahan (Neg), -2.0), "Kahan neg+pos");
      Check (Approx (Sum_Neumaier (Neg), -2.0), "Neumaier neg+pos");
      Check (Approx (Sum_Pairwise (Neg), -2.0), "Pairwise neg+pos");
   end;

   ---------------------------------------------------------------------
   Section ("3. Exact integers that fit in Float");
   ---------------------------------------------------------------------
   declare
      Ones   : constant Float_Array := Make_Constant (100, 1.0);
      Tens   : constant Float_Array := Make_Constant (50, 10.0);
      Mix    : constant Float_Array := [1.0, 2.0, 3.0, 4.0, 5.0];
      Zeros  : constant Float_Array := Make_Constant (20, 0.0);
      Exact1 : constant Long_Float := Exact_Sum (Ones);
      Exact2 : constant Long_Float := Exact_Sum (Tens);
      Exact3 : constant Long_Float := Exact_Sum (Mix);
   begin
      Check (Approx (Sum_Naive (Ones), 100.0), "Naive 100 ones");
      Check (Approx (Sum_Kahan (Ones), 100.0), "Kahan 100 ones");
      Check (Approx (Sum_Neumaier (Ones), 100.0), "Neumaier 100 ones");
      Check (Approx (Sum_Pairwise (Ones), 100.0), "Pairwise 100 ones");
      Check (Abs_Error_Exact (Sum_Kahan (Ones), Exact1) = 0.0,
             "Kahan exact vs Long_Float ones");

      Check (Approx (Sum_Naive (Tens), 500.0), "Naive 50*10");
      Check (Approx (Sum_Kahan (Tens), 500.0), "Kahan 50*10");
      Check (Approx (Sum_Neumaier (Tens), 500.0), "Neumaier 50*10");
      Check (Abs_Error_Exact (Sum_Naive (Tens), Exact2) = 0.0,
             "Naive exact tens");

      Check (Approx (Sum_Naive (Mix), 15.0), "Naive 1..5");
      Check (Approx (Sum_Kahan (Mix), 15.0), "Kahan 1..5");
      Check (Approx (Sum_Pairwise (Mix), 15.0), "Pairwise 1..5");
      Check (Abs_Error_Exact (Sum_Kahan (Mix), Exact3) = 0.0,
             "Kahan exact mix");

      Check (Approx (Sum_Naive (Zeros), 0.0), "Naive zeros");
      Check (Approx (Sum_Kahan (Zeros), 0.0), "Kahan zeros");
      Check (Approx (Sum_Neumaier (Zeros), 0.0), "Neumaier zeros");
   end;

   ---------------------------------------------------------------------
   Section ("4. Pathological: large + many tiny (Kahan beats naive)");
   ---------------------------------------------------------------------
   --  ulp(1.0) ≈ 1.19e-7 in IEEE single; 1e-8 added to 1.0 is lost naïvely.
   declare
      N      : constant Term_Count := 10_000;
      Data   : constant Float_Array :=
        Make_Large_Then_Small (N, 1.0, 1.0E-8);
      Exact  : constant Long_Float := Exact_Sum (Data);
      --  Exact ≈ 1.0 + 9999 * 1e-8 = 1.00009999
      Sn     : constant Float := Sum_Naive (Data);
      Sk     : constant Float := Sum_Kahan (Data);
      Sneu   : constant Float := Sum_Neumaier (Data);
      Sp     : constant Float := Sum_Pairwise (Data);
      En     : constant Float := Abs_Error_Exact (Sn, Exact);
      Ek     : constant Float := Abs_Error_Exact (Sk, Exact);
      Eneu   : constant Float := Abs_Error_Exact (Sneu, Exact);
      Ep     : constant Float := Abs_Error_Exact (Sp, Exact);
   begin
      Check (Data'Length = 10_000, "pathological length 10000");
      Check (Data (1) = 1.0, "first is large");
      Check (Data (2) = 1.0E-8, "second is small");
      Check (Exact > 1.00009 and Exact < 1.00011, "oracle in (1.00009,1.00011)");

      --  Naïve collapses toward 1.0; compensated methods recover better.
      Check (Near (Sn, 1.0, 1.0E-4), "Naive near 1.0 (lost digits)");
      Check (En > 5.0E-5, "Naive abs error noticeable");
      Check (Ek < En, "Kahan_err < Naive_err");
      Check (Eneu < En, "Neumaier_err < Naive_err");
      Check (Ek < 1.0E-5 or Near (Sk, Float (Exact), 1.0E-4),
             "Kahan close to oracle");
      Check (Eneu <= Ek + 1.0E-6 or Eneu < En,
             "Neumaier competitive");
      Check (Ep <= En or Ep < 1.0E-4, "Pairwise not worse than naive scale");
      Check (not Near (Sk, 1.0, 1.0E-5) or Ek < En,
             "Kahan does not fully collapse");
   end;

   ---------------------------------------------------------------------
   Section ("5. Shorter pathological series");
   ---------------------------------------------------------------------
   declare
      Data  : constant Float_Array :=
        Make_Large_Then_Small (1_001, 1.0E+3, 1.0E-4);
      Exact : constant Long_Float := Exact_Sum (Data);
      Sn    : constant Float := Sum_Naive (Data);
      Sk    : constant Float := Sum_Kahan (Data);
      En    : constant Float := Abs_Error_Exact (Sn, Exact);
      Ek    : constant Float := Abs_Error_Exact (Sk, Exact);
   begin
      Check (Ek <= En, "short path: Kahan_err <= Naive_err");
      Check (Abs_Error_Exact (Sum_Neumaier (Data), Exact) <= En,
             "short path: Neumaier_err <= Naive_err");
      Check (Data'Length = 1_001, "short path length");
   end;

   ---------------------------------------------------------------------
   Section ("6. Neumaier Peters example [A, Huge, A, -Huge]");
   ---------------------------------------------------------------------
   declare
      Data : constant Float_Array := Make_Neumaier_Peters (1.0, 1.0E+20);
      Sk   : constant Float := Sum_Kahan (Data);
      Sneu : constant Float := Sum_Neumaier (Data);
      Sn   : constant Float := Sum_Naive (Data);
   begin
      Check (Data'Length = 4, "Peters length 4");
      Check (Data (1) = 1.0 and Data (3) = 1.0, "Peters A slots");
      Check (Data (2) = 1.0E+20 and Data (4) = -1.0E+20, "Peters Huge");
      --  Kahan / naïve typically lose the two 1.0 → ~0; Neumaier → ~2.
      Check (Near (Sk, 0.0, 1.0E-3) or abs (Sk) < 1.0,
             "Kahan ~0 on Peters (known weakness)");
      Check (Near (Sn, 0.0, 1.0E-3) or abs (Sn) < 1.0,
             "Naive ~0 on Peters");
      Check (Near (Sneu, 2.0, 1.0E-3), "Neumaier recovers ~2");
      Check (Abs_Error (Sneu, 2.0) < Abs_Error (Sk, 2.0),
             "Neumaier closer to 2 than Kahan");
   end;

   ---------------------------------------------------------------------
   Section ("7. Accumulator API");
   ---------------------------------------------------------------------
   declare
      Acc  : Accumulator := Make_Empty;
      Acc2 : Accumulator;
      Data : constant Float_Array := [1.0, 2.0, 3.0, 4.0];
      Path : constant Float_Array :=
        Make_Large_Then_Small (5_000, 1.0, 1.0E-8);
      Exact : constant Long_Float := Exact_Sum (Path);
   begin
      Check (Count (Acc) = 0, "empty Count");
      Check (Approx (Total (Acc), 0.0), "empty Total");
      Check (Approx (Compensation (Acc), 0.0), "empty Compensation");

      Add (Acc, 10.0);
      Check (Count (Acc) = 1, "Count after one Add");
      Check (Approx (Total (Acc), 10.0), "Total after one Add");

      Add (Acc, 5.0);
      Check (Count (Acc) = 2, "Count after two Adds");
      Check (Approx (Total (Acc), 15.0), "Total 10+5");

      Reset (Acc);
      Check (Count (Acc) = 0 and Approx (Total (Acc), 0.0),
             "Reset clears");

      Acc2 := Make_Empty;
      Add_Many (Acc2, Data);
      Check (Count (Acc2) = 4, "Add_Many Count");
      Check (Approx (Total (Acc2), 10.0), "Add_Many Total 1+2+3+4");
      Check (Approx (Total (Acc2), Sum_Kahan (Data)),
             "Add_Many matches Sum_Kahan");

      Reset (Acc2);
      Add_Many (Acc2, Path);
      Check (Count (Acc2) = 5_000, "path Acc Count");
      Check (Abs_Error_Exact (Total (Acc2), Exact) <
               Abs_Error_Exact (Sum_Naive (Path), Exact),
             "Acc better than Naive on path");
      Check (Near (Total (Acc2), Sum_Kahan (Path)),
             "Acc Total = Sum_Kahan path");
   end;

   ---------------------------------------------------------------------
   Section ("8. Builders / constants / agreement on mild data");
   ---------------------------------------------------------------------
   declare
      C0 : constant Float_Array := Make_Constant (0, 9.0);
      C3 : constant Float_Array := Make_Constant (3, 7.0);
      L  : constant Float_Array :=
        Make_Large_Then_Small (4, 100.0, 0.25);
      Mild : constant Float_Array :=
        [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
      Sn : constant Float := Sum_Naive (Mild);
      Sk : constant Float := Sum_Kahan (Mild);
      Sp : constant Float := Sum_Pairwise (Mild);
      Sneu : constant Float := Sum_Neumaier (Mild);
   begin
      Check (C0'Length = 0, "Make_Constant N=0");
      Check (C3'Length = 3 and C3 (1) = 7.0 and C3 (3) = 7.0,
             "Make_Constant 3*7");
      Check (Approx (Sum_Naive (C3), 21.0), "sum Make_Constant");
      Check (L (1) = 100.0 and L (2) = 0.25 and L'Length = 4,
             "Make_Large_Then_Small shape");
      Check (Approx (Sum_Kahan (L), 100.75), "Kahan 100+3*0.25");

      --  Mild data: all methods agree closely.
      Check (Near (Sn, Sk, 1.0E-5), "mild Naive≈Kahan");
      Check (Near (Sk, Sneu, 1.0E-5), "mild Kahan≈Neumaier");
      Check (Near (Sk, Sp, 1.0E-5), "mild Kahan≈Pairwise");
      Check (Near (Sn, 5.5, 1.0E-4), "mild sum ≈ 5.5");
   end;

   ---------------------------------------------------------------------
   Section ("9. Pairwise longer / signed / Max_Length edge");
   ---------------------------------------------------------------------
   declare
      Long_Ones : constant Float_Array := Make_Constant (2_048, 1.0);
      Alt : Float_Array (1 .. 64);
      Acc : Accumulator := Make_Empty;
   begin
      Check (Approx (Sum_Pairwise (Long_Ones), 2048.0),
             "Pairwise 2048 ones");
      Check (Approx (Sum_Kahan (Long_Ones), 2048.0),
             "Kahan 2048 ones");
      Check (Approx (Sum_Naive (Long_Ones), 2048.0),
             "Naive 2048 ones");

      for I in Alt'Range loop
         if I mod 2 = 1 then
            Alt (I) := 1.0;
         else
            Alt (I) := -1.0;
         end if;
      end loop;
      Check (Approx (Sum_Kahan (Alt), 0.0), "Kahan alternating ±1");
      Check (Approx (Sum_Neumaier (Alt), 0.0), "Neumaier alternating");
      Check (Approx (Sum_Pairwise (Alt), 0.0), "Pairwise alternating");
      Check (Approx (Sum_Naive (Alt), 0.0), "Naive alternating");

      Add (Acc, -1.0);
      Add (Acc, -2.0);
      Add (Acc, 5.0);
      Check (Approx (Total (Acc), 2.0), "Acc signed mix");
      Check (Count (Acc) = 3, "Acc signed count");
   end;

   ---------------------------------------------------------------------
   Section ("10. More Abs_Error / compensation introspection");
   ---------------------------------------------------------------------
   declare
      Acc  : Accumulator := Make_Empty;
      Data : constant Float_Array :=
        Make_Large_Then_Small (100, 1.0, 1.0E-8);
   begin
      Add_Many (Acc, Data);
      Check (Count (Acc) = 100, "intro Count 100");
      --  After many tiny adds lost into 1.0, compensation should be nonzero
      --  (or Total should still beat naïve).
      Check
        (Compensation (Acc) /= 0.0
         or else Abs_Error_Exact (Total (Acc), Exact_Sum (Data))
                 < Abs_Error_Exact (Sum_Naive (Data), Exact_Sum (Data)),
         "compensation or Acc beats Naive");
      Check (Near (Total (Acc), Sum_Kahan (Data)),
             "intro Total = Sum_Kahan");
      Check (Abs_Error (0.0, 0.0) = 0.0, "Abs_Error 0,0");
      Check (Abs_Error (-1.0, 1.0) = 2.0, "Abs_Error signed");
      Check (Abs_Error_Exact (Float'(0.0), Long_Float'(0.0)) = 0.0,
             "Abs_Error LF zero");
   end;

   ---------------------------------------------------------------------
   Section ("11. Agreement: integers / three methods on ramp");
   ---------------------------------------------------------------------
   declare
      Ramp : Float_Array (1 .. 20);
      Exact : Long_Float;
   begin
      for I in Ramp'Range loop
         Ramp (I) := Float (I);
      end loop;
      Exact := Exact_Sum (Ramp);  --  210
      Check (Approx (Sum_Naive (Ramp), 210.0), "Naive ramp 1..20");
      Check (Approx (Sum_Kahan (Ramp), 210.0), "Kahan ramp");
      Check (Approx (Sum_Neumaier (Ramp), 210.0), "Neumaier ramp");
      Check (Approx (Sum_Pairwise (Ramp), 210.0), "Pairwise ramp");
      Check (Abs_Error_Exact (Sum_Kahan (Ramp), Exact) = 0.0,
             "Kahan exact ramp");
      Check (Abs_Error_Exact (Sum_Pairwise (Ramp), Exact) = 0.0,
             "Pairwise exact ramp");
   end;

   ---------------------------------------------------------------------
   Section ("12. Batch: many small exact Float sums");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for N in Term_Count range 1 .. 30 loop
         declare
            D : constant Float_Array := Make_Constant (N, 2.0);
            Expect : constant Float := Float (2 * N);
         begin
            if not Approx (Sum_Kahan (D), Expect)
              or else not Approx (Sum_Naive (D), Expect)
              or else not Approx (Sum_Neumaier (D), Expect)
              or else not Approx (Sum_Pairwise (D), Expect)
            then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "batch N=1..30 of 2.0 all methods");

      for N in Term_Count range 1 .. 15 loop
         declare
            D : constant Float_Array := Make_Constant (N, -0.5);
            Expect : constant Float := -0.5 * Float (N);
            Acc : Accumulator := Make_Empty;
         begin
            Add_Many (Acc, D);
            if not Approx (Total (Acc), Expect)
              or else Count (Acc) /= N
            then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "batch Acc N=1..15 of -0.5");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("==========================");
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

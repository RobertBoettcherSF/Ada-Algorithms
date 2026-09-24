--  Standalone test suite for Square_Root_Algorithms (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Square_Root_Algorithms; use Square_Root_Algorithms;

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

   function Builtin_Sqrt (S : Long_Float) return Long_Float is
   begin
      if S = 0.0 then
         return 0.0;
      else
         return Ada.Numerics.Long_Elementary_Functions.Sqrt (S);
      end if;
   end Builtin_Sqrt;

   --  Oracle integer floor sqrt via binary search (independent of package).
   function Integer_Sqrt_Oracle (N : Natural) return Natural is
      Lo  : Natural := 0;
      Hi  : Natural := N;
      Mid : Natural;
      Sq  : Natural;
   begin
      if N < 2 then
         return N;
      end if;
      --  Cap Hi to avoid Mid*Mid overflow: Hi <= sqrt(Natural'Last) roughly.
      if Hi > 2**16 then
         --  For typical 32/64-bit Natural, binary search with care.
         Hi := N;
      end if;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > 0 and then Mid > Natural'Last / Mid then
            Hi := Mid - 1;
         else
            Sq := Mid * Mid;
            if Sq <= N then
               Lo := Mid;
            else
               Hi := Mid - 1;
            end if;
         end if;
      end loop;
      return Lo;
   end Integer_Sqrt_Oracle;

begin
   Ada.Text_IO.Put_Line ("Square_Root_Algorithms test suite");
   Ada.Text_IO.Put_Line ("=================================");

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
   Section ("2. Domain: negatives and zero");
   ---------------------------------------------------------------------
   declare
      H, B, I, D : Sqrt_Result;
   begin
      H := Sqrt_Heron (-1.0);
      Check (H.Status = Bad_Domain, "Heron(-1) Bad_Domain");
      B := Sqrt_Bisection (-0.5);
      Check (B.Status = Bad_Domain, "Bisection(-0.5) Bad_Domain");
      I := Sqrt_Inv_Newton (-2.0);
      Check (I.Status = Bad_Domain, "InvNewton(-2) Bad_Domain");
      D := Sqrt_Digit_Float (-3.0);
      Check (D.Status = Bad_Domain, "DigitFloat(-3) Bad_Domain");

      H := Sqrt_Heron (0.0);
      Check (H.Status = Converged and then H.Value = 0.0, "Heron(0)=0");
      B := Sqrt_Bisection (0.0);
      Check (B.Status = Converged and then B.Value = 0.0, "Bisection(0)=0");
      I := Sqrt_Inv_Newton (0.0);
      Check (I.Status = Converged and then I.Value = 0.0, "InvNewton(0)=0");
      D := Sqrt_Digit_Float (0.0);
      Check (D.Status = Converged and then D.Value = 0.0, "DigitFloat(0)=0");
      Check (Sqrt_Digit_By_Digit (0) = 0, "DigitByDigit(0)=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Perfect squares (Heron / Bisection / Inv)");
   ---------------------------------------------------------------------
   declare
      H, B, I : Sqrt_Result;
      Squares : constant array (Positive range <>) of Natural :=
        [1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225];
   begin
      for K in Squares'Range loop
         declare
            S : constant Long_Float := Long_Float (Squares (K));
            R : constant Long_Float := Builtin_Sqrt (S);
         begin
            H := Sqrt_Heron (S);
            Check (H.Status = Converged and then Approx (H.Value, R),
                   "Heron perfect " & Natural'Image (Squares (K)));
            B := Sqrt_Bisection (S, Tol => 1.0E-12);
            Check (B.Status = Converged and then Approx (B.Value, R, 1.0E-9),
                   "Bisection perfect " & Natural'Image (Squares (K)));
            I := Sqrt_Inv_Newton (S);
            Check (I.Status = Converged and then Approx (I.Value, R, 1.0E-8),
                   "InvNewton perfect " & Natural'Image (Squares (K)));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic: sqrt(2), sqrt(0.25), sqrt(1)");
   ---------------------------------------------------------------------
   declare
      H2  : constant Sqrt_Result := Sqrt_Heron (2.0);
      B2  : constant Sqrt_Result := Sqrt_Bisection (2.0);
      I2  : constant Sqrt_Result := Sqrt_Inv_Newton (2.0);
      S2  : constant Long_Float := Builtin_Sqrt (2.0);
      H25 : constant Sqrt_Result := Sqrt_Heron (0.25);
      B25 : constant Sqrt_Result := Sqrt_Bisection (0.25);
      H1  : constant Sqrt_Result := Sqrt_Heron (1.0);
   begin
      Check (H2.Status = Converged, "Heron sqrt(2) converged");
      Check (Approx (H2.Value, S2, 1.0E-10), "Heron sqrt(2) vs builtin");
      Check (Approx (H2.Value, 1.414_213_562_37, 1.0E-9),
             "Heron sqrt(2) ~ 1.414213562");

      Check (B2.Status = Converged, "Bisection sqrt(2) converged");
      Check (Approx (B2.Value, S2, 1.0E-10), "Bisection sqrt(2) vs builtin");

      Check (I2.Status = Converged, "InvNewton sqrt(2) converged");
      Check (Approx (I2.Value, S2, 1.0E-9), "InvNewton sqrt(2) vs builtin");

      Check (H25.Status = Converged and then Approx (H25.Value, 0.5),
             "Heron sqrt(0.25)=0.5");
      Check (B25.Status = Converged and then Approx (B25.Value, 0.5, 1.0E-10),
             "Bisection sqrt(0.25)=0.5");
      Check (H1.Status = Converged and then Approx (H1.Value, 1.0),
             "Heron sqrt(1)=1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Methods agree within Tol");
   ---------------------------------------------------------------------
   declare
      Samples : constant array (Positive range <>) of Long_Float :=
        [0.01, 0.25, 0.5, 1.0, 2.0, 3.0, 10.0, 50.0, 100.0, 1234.5];
      Ok : Boolean := True;
   begin
      for K in Samples'Range loop
         declare
            S : constant Long_Float := Samples (K);
            H : constant Sqrt_Result := Sqrt_Heron (S);
            B : constant Sqrt_Result := Sqrt_Bisection (S);
            I : constant Sqrt_Result := Sqrt_Inv_Newton (S);
         begin
            if H.Status /= Converged
              or else B.Status /= Converged
              or else I.Status /= Converged
              or else not Approx (H.Value, B.Value, 1.0E-8)
              or else not Approx (H.Value, I.Value, 1.0E-7)
            then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "Heron/Bisection/Inv agree on samples");
   end;

   ---------------------------------------------------------------------
   Section ("6. Digit-by-digit floor vs integer oracle");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for N in 0 .. 200 loop
         if Sqrt_Digit_By_Digit (N) /= Integer_Sqrt_Oracle (N) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "DigitByDigit = oracle for 0..200");

      Check (Sqrt_Digit_By_Digit (1) = 1, "isqrt(1)=1");
      Check (Sqrt_Digit_By_Digit (2) = 1, "isqrt(2)=1");
      Check (Sqrt_Digit_By_Digit (3) = 1, "isqrt(3)=1");
      Check (Sqrt_Digit_By_Digit (4) = 2, "isqrt(4)=2");
      Check (Sqrt_Digit_By_Digit (8) = 2, "isqrt(8)=2");
      Check (Sqrt_Digit_By_Digit (9) = 3, "isqrt(9)=3");
      Check (Sqrt_Digit_By_Digit (15) = 3, "isqrt(15)=3");
      Check (Sqrt_Digit_By_Digit (16) = 4, "isqrt(16)=4");
      Check (Sqrt_Digit_By_Digit (99) = 9, "isqrt(99)=9");
      Check (Sqrt_Digit_By_Digit (100) = 10, "isqrt(100)=10");
      Check (Sqrt_Digit_By_Digit (10_000) = 100, "isqrt(10000)=100");
      Check (Sqrt_Digit_By_Digit (1_000_000) = 1000, "isqrt(1e6)=1000");
   end;

   ---------------------------------------------------------------------
   Section ("7. Is_Perfect_Square");
   ---------------------------------------------------------------------
   begin
      Check (Is_Perfect_Square (0), "0 is perfect square");
      Check (Is_Perfect_Square (1), "1 is perfect square");
      Check (Is_Perfect_Square (4), "4 is perfect square");
      Check (Is_Perfect_Square (9), "9 is perfect square");
      Check (Is_Perfect_Square (100), "100 is perfect square");
      Check (not Is_Perfect_Square (2), "2 not perfect square");
      Check (not Is_Perfect_Square (8), "8 not perfect square");
      Check (not Is_Perfect_Square (10), "10 not perfect square");
      Check (not Is_Perfect_Square (99), "99 not perfect square");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sqrt_Digit_Float educational digits");
   ---------------------------------------------------------------------
   declare
      D2  : constant Sqrt_Result := Sqrt_Digit_Float (2.0, 6);
      D25 : constant Sqrt_Result := Sqrt_Digit_Float (0.25, 4);
      D4  : constant Sqrt_Result := Sqrt_Digit_Float (4.0, 3);
      S2  : constant Long_Float := Builtin_Sqrt (2.0);
   begin
      Check (D2.Status = Converged, "DigitFloat(2) converged");
      Check (Approx (D2.Value, S2, 1.0E-5), "DigitFloat(2) ~ sqrt(2)");
      Check (D25.Status = Converged and then Approx (D25.Value, 0.5, 1.0E-3),
             "DigitFloat(0.25)~0.5");
      Check (D4.Status = Converged and then Approx (D4.Value, 2.0, 1.0E-3),
             "DigitFloat(4)~2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Convenience Sqrt + exception");
   ---------------------------------------------------------------------
   begin
      Check (Approx (Sqrt (9.0), 3.0), "Sqrt(9)=3");
      Check (Approx (Sqrt (2.0), Builtin_Sqrt (2.0), 1.0E-10),
             "Sqrt(2) vs builtin");
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Dummy : constant Long_Float := Sqrt (-1.0);
            begin
               Check (Dummy < 0.0, "unreachable Sqrt(-1) value");
            end;
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Sqrt(-1) raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Heron vs Bisection pairwise");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Xs : constant array (Positive range <>) of Long_Float :=
        [0.0, 1.0E-6, 0.01, 0.25, 1.0, 2.0, 7.0, 16.0, 100.0, 1.0E6];
   begin
      for K in Xs'Range loop
         declare
            H : constant Sqrt_Result := Sqrt_Heron (Xs (K));
            B : constant Sqrt_Result :=
              Sqrt_Bisection (Xs (K), Tol => 1.0E-12);
         begin
            if H.Status /= Converged
              or else B.Status /= Converged
              or else not Approx (H.Value, B.Value, 1.0E-8)
            then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "Heron vs Bisection on Xs");
   end;

   ---------------------------------------------------------------------
   Section ("11. Iteration counts positive for nontrivial");
   ---------------------------------------------------------------------
   declare
      H : constant Sqrt_Result := Sqrt_Heron (2.0);
      B : constant Sqrt_Result := Sqrt_Bisection (2.0);
      I : constant Sqrt_Result := Sqrt_Inv_Newton (2.0);
   begin
      Check (H.Iterations > 0, "Heron iterations > 0 for sqrt(2)");
      Check (B.Iterations > 0, "Bisection iterations > 0 for sqrt(2)");
      Check (I.Iterations > 0, "InvNewton iterations > 0 for sqrt(2)");
      Check (H.Iterations < B.Iterations,
             "Heron fewer iters than bisection (typical)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Batch: Heron(k^2)=k for k=1..40");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for K in 1 .. 40 loop
         declare
            X : constant Long_Float := Long_Float (K * K);
            R : constant Sqrt_Result := Sqrt_Heron (X);
         begin
            if R.Status /= Converged
              or else not Approx (R.Value, Long_Float (K), 1.0E-8)
            then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "Heron(k^2)=k for k=1..40");
   end;

   ---------------------------------------------------------------------
   Section ("13. Batch: DigitByDigit(k^2)=k and floor checks");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for K in 0 .. 50 loop
         if Sqrt_Digit_By_Digit (K * K) /= K then
            Ok_All := False;
         end if;
         if K > 0
           and then Sqrt_Digit_By_Digit (K * K - 1) /= K - 1
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "DigitByDigit perfect and near-perfect 0..50");
   end;

   ---------------------------------------------------------------------
   Section ("14. Small fractions and large values");
   ---------------------------------------------------------------------
   declare
      H_Small : constant Sqrt_Result := Sqrt_Heron (1.0E-8);
      H_Large : constant Sqrt_Result := Sqrt_Heron (1.0E12);
      B_Small : constant Sqrt_Result :=
        Sqrt_Bisection (1.0E-8, Tol => 1.0E-14);
   begin
      Check (H_Small.Status = Converged
               and then Approx (H_Small.Value, 1.0E-4, 1.0E-10),
             "Heron sqrt(1e-8)=1e-4");
      Check (H_Large.Status = Converged
               and then Approx (H_Large.Value, 1.0E6, 1.0E-3),
             "Heron sqrt(1e12)=1e6");
      Check (B_Small.Status = Converged
               and then Approx (B_Small.Value, 1.0E-4, 1.0E-9),
             "Bisection sqrt(1e-8)=1e-4");
   end;

   ---------------------------------------------------------------------
   Section ("15. DigitFloat vs Heron agreement");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
      Xs : constant array (Positive range <>) of Long_Float :=
        [1.0, 2.0, 3.0, 4.0, 9.0, 16.0, 0.25, 0.01];
   begin
      for K in Xs'Range loop
         declare
            D : constant Sqrt_Result := Sqrt_Digit_Float (Xs (K), 6);
            H : constant Sqrt_Result := Sqrt_Heron (Xs (K));
         begin
            if D.Status /= Converged
              or else H.Status /= Converged
              or else not Approx (D.Value, H.Value, 2.0E-5)
            then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "DigitFloat(6) vs Heron within 2e-5");
   end;

   ---------------------------------------------------------------------
   -- Summary
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

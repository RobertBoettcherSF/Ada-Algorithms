--  Standalone test suite for Nth_Root (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Nth_Root; use Nth_Root;

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

   --  Oracle via Exp/Log (Ada Long_Float "**" needs Natural exponent).
   function Builtin_Root (X : Long_Float; N : Degree) return Long_Float is
      Inv_N : constant Long_Float := 1.0 / Long_Float (N);
   begin
      if X = 0.0 then
         return 0.0;
      elsif X < 0.0 then
         return -Ada.Numerics.Long_Elementary_Functions.Exp
           (Inv_N * Ada.Numerics.Long_Elementary_Functions.Log (-X));
      else
         return Ada.Numerics.Long_Elementary_Functions.Exp
           (Inv_N * Ada.Numerics.Long_Elementary_Functions.Log (X));
      end if;
   end Builtin_Root;

begin
   Ada.Text_IO.Put_Line ("Nth_Root test suite");
   Ada.Text_IO.Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Pow_Int helpers");
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

      Check (Approx (Pow_Int (2.0, 0), 1.0), "Pow_Int 2^0");
      Check (Approx (Pow_Int (2.0, 1), 2.0), "Pow_Int 2^1");
      Check (Approx (Pow_Int (2.0, 10), 1024.0), "Pow_Int 2^10");
      Check (Approx (Pow_Int (3.0, 5), 243.0), "Pow_Int 3^5");
      Check (Approx (Pow_Int (-2.0, 3), -8.0), "Pow_Int (-2)^3");
      Check (Approx (Pow_Int (-2.0, 4), 16.0), "Pow_Int (-2)^4");
      Check (Approx (Pow_Int (1.5, 2), 2.25), "Pow_Int 1.5^2");
      Check (Approx (Pow_Int (0.0, 5), 0.0), "Pow_Int 0^5");
      Check (Approx (Pow_Int (0.0, 0), 1.0), "Pow_Int 0^0 := 1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Known squares and cubes");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
   begin
      R := Root_Newton (4.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 2.0),
             "sqrt(4) = 2");
      R := Root_Newton (9.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 3.0),
             "sqrt(9) = 3");
      R := Root_Newton (16.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 4.0),
             "sqrt(16) = 4");
      R := Root_Newton (25.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 5.0),
             "sqrt(25) = 5");
      R := Root_Newton (100.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 10.0),
             "sqrt(100) = 10");

      R := Root_Newton (8.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, 2.0),
             "cbrt(8) = 2");
      R := Root_Newton (27.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, 3.0),
             "cbrt(27) = 3");
      R := Root_Newton (64.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, 4.0),
             "cbrt(64) = 4");
      R := Root_Newton (125.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, 5.0),
             "cbrt(125) = 5");
      R := Root_Newton (1.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, 1.0),
             "cbrt(1) = 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Classic: 2^{1/2}, 8^{1/3}, 16^{1/4}");
   ---------------------------------------------------------------------
   declare
      R2  : constant Root_Result := Root_Newton (2.0, 2);
      R8  : constant Root_Result := Root_Newton (8.0, 3);
      R16 : constant Root_Result := Root_Newton (16.0, 4);
      S2  : constant Long_Float := Builtin_Root (2.0, 2);
      S8  : constant Long_Float := Builtin_Root (8.0, 3);
      S16 : constant Long_Float := Builtin_Root (16.0, 4);
   begin
      Check (R2.Status = Converged, "2^{1/2} converged");
      Check (Approx (R2.Value, S2, 1.0E-10), "2^{1/2} vs **");
      Check (Approx (R2.Value, 1.414_213_562_37, 1.0E-9),
             "2^{1/2} ~ 1.414213562");

      Check (R8.Status = Converged and then Approx (R8.Value, 2.0),
             "8^{1/3} = 2");
      Check (Approx (R8.Value, S8, 1.0E-10), "8^{1/3} vs **");

      Check (R16.Status = Converged and then Approx (R16.Value, 2.0),
             "16^{1/4} = 2");
      Check (Approx (R16.Value, S16, 1.0E-10), "16^{1/4} vs **");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identity r^n ≈ x");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      R      : Root_Result;
      Back   : Long_Float;
   begin
      for N in Degree range 2 .. 12 loop
         for K in 1 .. 8 loop
            declare
               X : constant Long_Float := Long_Float (K) * 1.5;
            begin
               R := Root_Newton (X, N);
               if R.Status /= Converged then
                  Ok_All := False;
               else
                  Back := Pow_Int (R.Value, N);
                  if not Approx (Back, X, 1.0E-8) then
                     Ok_All := False;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok_All, "identity Pow_Int(Root(X,N),N) ≈ X for N=2..12");

      R := Root_Newton (81.0, 4);
      Check (R.Status = Converged
             and then Approx (Pow_Int (R.Value, 4), 81.0, 1.0E-8),
             "81^{1/4}^4 ≈ 81");
      R := Root_Newton (32.0, 5);
      Check (R.Status = Converged
             and then Approx (Pow_Int (R.Value, 5), 32.0, 1.0E-8),
             "32^{1/5}^5 ≈ 32");
   end;

   ---------------------------------------------------------------------
   Section ("5. Sqrt / Cbrt wrappers");
   ---------------------------------------------------------------------
   begin
      Check (Approx (Sqrt (4.0), 2.0), "Sqrt(4)");
      Check (Approx (Sqrt (2.0), Builtin_Root (2.0, 2), 1.0E-10),
             "Sqrt(2) vs **");
      Check (Approx (Cbrt (8.0), 2.0), "Cbrt(8)");
      Check (Approx (Cbrt (27.0), 3.0), "Cbrt(27)");
      Check (Approx (Cbrt (-8.0), -2.0), "Cbrt(-8)");
      Check (Approx (Cbrt (-27.0), -3.0), "Cbrt(-27)");
      Check (Approx (Sqrt (0.0), 0.0), "Sqrt(0)");
      Check (Approx (Cbrt (0.0), 0.0), "Cbrt(0)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Odd roots of negatives");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
   begin
      R := Root_Newton (-8.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, -2.0),
             "(-8)^{1/3} = -2");
      R := Root_Newton (-32.0, 5);
      Check (R.Status = Converged and then Approx (R.Value, -2.0),
             "(-32)^{1/5} = -2");
      R := Root_Newton (-1.0, 3);
      Check (R.Status = Converged and then Approx (R.Value, -1.0),
             "(-1)^{1/3} = -1");
      R := Root_Newton (-243.0, 5);
      Check (R.Status = Converged and then Approx (R.Value, -3.0),
             "(-243)^{1/5} = -3");
      Check (Approx (Root (-8.0, 3), -2.0), "Root(-8,3)");
      Check (Approx (Pow_Int (Root (-32.0, 5), 5), -32.0, 1.0E-8),
             "identity odd negative");
   end;

   ---------------------------------------------------------------------
   Section ("7. Invalid arguments (even root of negative)");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
      Raised : Boolean;
   begin
      R := Root_Newton (-4.0, 2);
      Check (R.Status = Bad_Domain, "Newton sqrt(-4) Bad_Domain");
      R := Root_Newton (-16.0, 4);
      Check (R.Status = Bad_Domain, "Newton 4th(-16) Bad_Domain");
      R := Root_Newton (-1.0, 2);
      Check (R.Status = Bad_Domain, "Newton sqrt(-1) Bad_Domain");

      Raised := False;
      begin
         declare
            Unused : constant Long_Float := Sqrt (-1.0);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Sqrt(-1) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : constant Long_Float := Root (-16.0, 4);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Root(-16,4) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : constant Long_Float := Root (4.0, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (not Raised, "Root(4,2) does not raise");
   end;

   ---------------------------------------------------------------------
   Section ("8. N = 1 and edge cases");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
   begin
      R := Root_Newton (42.0, 1);
      Check (R.Status = Converged and then Approx (R.Value, 42.0)
             and then R.Iterations = 0,
             "Root(42,1) = 42, 0 iters");
      R := Root_Newton (-7.0, 1);
      Check (R.Status = Converged and then Approx (R.Value, -7.0),
             "Root(-7,1) = -7");
      R := Root_Newton (0.0, 2);
      Check (R.Status = Converged and then Approx (R.Value, 0.0),
             "sqrt(0) = 0");
      R := Root_Newton (0.0, 5);
      Check (R.Status = Converged and then Approx (R.Value, 0.0),
             "5th(0) = 0");
      R := Root_Newton (1.0, 7);
      Check (R.Status = Converged and then Approx (R.Value, 1.0),
             "7th(1) = 1");
      Check (Approx (Root (0.5, 2), Builtin_Root (0.5, 2), 1.0E-9),
             "sqrt(0.5) vs **");
      Check (Approx (Root (0.001, 3), Builtin_Root (0.001, 3), 1.0E-8),
             "cbrt(0.001) vs **");
   end;

   ---------------------------------------------------------------------
   Section ("9. Newton vs Long_Float ** oracle");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      R      : Root_Result;
      B      : Long_Float;
   begin
      for N in Degree range 2 .. 10 loop
         for K in 1 .. 10 loop
            declare
               X : constant Long_Float := Long_Float (K);
            begin
               R := Root_Newton (X, N);
               B := Builtin_Root (X, N);
               if R.Status /= Converged
                 or else not Approx (R.Value, B, 1.0E-8)
               then
                  Ok_All := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok_All, "Newton vs ** for X=1..10, N=2..10");

      Check (Approx (Root_Newton (12345.0, 2).Value,
                     Builtin_Root (12345.0, 2), 1.0E-8),
             "sqrt(12345) vs **");
      Check (Approx (Root_Newton (1.0E6, 3).Value,
                     Builtin_Root (1.0E6, 3), 1.0E-8),
             "cbrt(1e6) vs **");
   end;

   ---------------------------------------------------------------------
   Section ("10. Halley vs Newton");
   ---------------------------------------------------------------------
   declare
      Rn, Rh : Root_Result;
      Ok_All : Boolean := True;
   begin
      for N in Degree range 2 .. 8 loop
         Rn := Root_Newton (2.0, N);
         Rh := Root_Halley (2.0, N);
         if Rn.Status /= Converged or else Rh.Status /= Converged then
            Ok_All := False;
         elsif not Approx (Rn.Value, Rh.Value, 1.0E-8) then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "Halley ≡ Newton on 2^{1/N}, N=2..8");

      Rh := Root_Halley (8.0, 3);
      Check (Rh.Status = Converged and then Approx (Rh.Value, 2.0),
             "Halley cbrt(8)");
      Rh := Root_Halley (-8.0, 3);
      Check (Rh.Status = Converged and then Approx (Rh.Value, -2.0),
             "Halley cbrt(-8)");
      Rh := Root_Halley (-4.0, 2);
      Check (Rh.Status = Bad_Domain, "Halley sqrt(-4) Bad_Domain");
      Rh := Root_Halley (16.0, 4);
      Check (Rh.Status = Converged and then Approx (Rh.Value, 2.0),
             "Halley 16^{1/4}");
   end;

   ---------------------------------------------------------------------
   Section ("11. Integer_Nth_Root floor");
   ---------------------------------------------------------------------
   begin
      Check (Integer_Nth_Root (0, 2) = 0, "int sqrt(0)");
      Check (Integer_Nth_Root (1, 2) = 1, "int sqrt(1)");
      Check (Integer_Nth_Root (4, 2) = 2, "int sqrt(4)");
      Check (Integer_Nth_Root (8, 2) = 2, "int floor sqrt(8)");
      Check (Integer_Nth_Root (9, 2) = 3, "int sqrt(9)");
      Check (Integer_Nth_Root (15, 2) = 3, "int floor sqrt(15)");
      Check (Integer_Nth_Root (16, 2) = 4, "int sqrt(16)");
      Check (Integer_Nth_Root (100, 2) = 10, "int sqrt(100)");

      Check (Integer_Nth_Root (8, 3) = 2, "int cbrt(8)");
      Check (Integer_Nth_Root (26, 3) = 2, "int floor cbrt(26)");
      Check (Integer_Nth_Root (27, 3) = 3, "int cbrt(27)");
      Check (Integer_Nth_Root (63, 3) = 3, "int floor cbrt(63)");
      Check (Integer_Nth_Root (64, 3) = 4, "int cbrt(64)");

      Check (Integer_Nth_Root (16, 4) = 2, "int 16^{1/4}");
      Check (Integer_Nth_Root (80, 4) = 2, "int floor 80^{1/4}");
      Check (Integer_Nth_Root (81, 4) = 3, "int 81^{1/4}");
      Check (Integer_Nth_Root (32, 5) = 2, "int 32^{1/5}");
      Check (Integer_Nth_Root (31, 5) = 1, "int floor 31^{1/5}");
      Check (Integer_Nth_Root (42, 1) = 42, "int root N=1");
      Check (Integer_Nth_Root (1_000_000, 2) = 1000, "int sqrt(1e6)");
      Check (Integer_Nth_Root (1_000_000, 3) = 100, "int cbrt(1e6)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Iteration counts and Max_Iter");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
   begin
      R := Root_Newton (2.0, 2);
      Check (R.Status = Converged and then R.Iterations > 0
             and then R.Iterations < 50,
             "sqrt(2) converges in < 50 iters");
      R := Root_Newton (2.0, 2, Tol => 1.0E-6);
      Check (R.Status = Converged, "looser Tol still converges");
      R := Root_Newton (2.0, 2, Tol => 1.0E-12, Max_Iter => 1);
      Check (R.Status = Max_Iterations_Reached
             or else R.Status = Converged,
             "Max_Iter=1 yields max or lucky converge");
      --  Force max-iter path with absurdly tight tol and 1 iter on hard case
      R := Root_Newton (1.0E20, 17, Tol => 0.0, Max_Iter => 1);
      Check (R.Status = Max_Iterations_Reached
             or else R.Status = Converged,
             "hard case Max_Iter=1 status ok");
   end;

   ---------------------------------------------------------------------
   Section ("13. Fractions and larger degrees");
   ---------------------------------------------------------------------
   declare
      R : Root_Result;
      Ok_All : Boolean := True;
   begin
      R := Root_Newton (0.25, 2);
      Check (R.Status = Converged and then Approx (R.Value, 0.5),
             "sqrt(0.25)=0.5");
      R := Root_Newton (0.125, 3);
      Check (R.Status = Converged and then Approx (R.Value, 0.5),
             "cbrt(0.125)=0.5");

      for N in Degree range 2 .. 16 loop
         R := Root_Newton (Pow_Int (3.0, N), N);
         if R.Status /= Converged
           or else not Approx (R.Value, 3.0, 1.0E-6)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "(3^N)^{1/N} = 3 for N=2..16");

      R := Root_Newton (Pow_Int (2.0, 10), 10);
      Check (R.Status = Converged and then Approx (R.Value, 2.0, 1.0E-6),
             "1024^{1/10} = 2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Batch Root convenience");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for K in 1 .. 20 loop
         declare
            X : constant Long_Float := Long_Float (K * K);
         begin
            if not Approx (Root (X, 2), Long_Float (K), 1.0E-8) then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "Root(k^2,2)=k for k=1..20");

      Ok_All := True;
      for K in 1 .. 10 loop
         declare
            X : constant Long_Float := Long_Float (K * K * K);
         begin
            if not Approx (Root (X, 3), Long_Float (K), 1.0E-8) then
               Ok_All := False;
            end if;
         end;
      end loop;
      Check (Ok_All, "Root(k^3,3)=k for k=1..10");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===================");
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

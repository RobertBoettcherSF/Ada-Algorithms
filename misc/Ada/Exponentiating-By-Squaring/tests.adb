--  Standalone test suite for Exponentiating_By_Squaring (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Exponentiating_By_Squaring; use Exponentiating_By_Squaring;

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

   --  Non-static view of package constant (avoid -gnatwc).
   function Max_NE return Natural is (Max_Naive_Exp);

   function Raised_Invalid (Op : access procedure) return Boolean is
   begin
      Op.all;
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

   function Near_F (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      if A = B then
         return True;
      end if;
      declare
         D : constant Float := abs (A - B);
      begin
         if abs (B) > 1.0 then
            return D / abs (B) <= Tol;
         else
            return D <= Tol;
         end if;
      end;
   end Near_F;

   function Same_Mat (L, R : Matrix_2x2) return Boolean is
     (L.A11 = R.A11 and then L.A12 = R.A12
      and then L.A21 = R.A21 and then L.A22 = R.A22);

begin
   Ada.Text_IO.Put_Line ("Exponentiating_By_Squaring test suite");
   Ada.Text_IO.Put_Line ("======================================");

   ------------------------------------------------------------------
   Section ("1. Helpers: Abs_LI / Mod_Nonneg / Mod_Mul");
   ------------------------------------------------------------------
   Check (Abs_LI (5) = 5, "Abs_LI 5");
   Check (Abs_LI (-7) = 7, "Abs_LI -7");
   Check (Abs_LI (0) = 0, "Abs_LI 0");
   Check (Mod_Nonneg (5, 3) = 2, "Mod_Nonneg 5 mod 3");
   Check (Mod_Nonneg (-1, 5) = 4, "Mod_Nonneg -1 mod 5");
   Check (Mod_Nonneg (14, 7) = 0, "Mod_Nonneg 14 mod 7");
   Check (Mod_Nonneg (0, 9) = 0, "Mod_Nonneg 0 mod 9");
   Check (Mod_Mul (7, 15, 17) = 3, "7*15 mod 17 = 3");
   Check (Mod_Mul (-1, 5, 17) = 12, "(-1)*5 mod 17");
   Check (Mod_Mul (0, 99, 17) = 0, "0*99 mod 17");
   Check (Max_NE = 10_000, "Max_Naive_Exp=10000");

   ------------------------------------------------------------------
   Section ("2. Classic powers: 2^10, 3^0, 5^1, (-2)^odd/even");
   ------------------------------------------------------------------
   Check (Power_Recursive (2, 10) = 1024, "rec 2^10=1024");
   Check (Power_Iterative (2, 10) = 1024, "iter 2^10=1024");
   Check (Power_Left_To_Right (2, 10) = 1024, "ltr 2^10=1024");
   Check (Power_Naive (2, 10) = 1024, "naive 2^10=1024");

   Check (Power_Recursive (3, 0) = 1, "rec 3^0=1");
   Check (Power_Iterative (3, 0) = 1, "iter 3^0=1");
   Check (Power_Left_To_Right (3, 0) = 1, "ltr 3^0=1");
   Check (Power_Naive (3, 0) = 1, "naive 3^0=1");

   Check (Power_Recursive (5, 1) = 5, "rec 5^1=5");
   Check (Power_Iterative (5, 1) = 5, "iter 5^1=5");
   Check (Power_Left_To_Right (5, 1) = 5, "ltr 5^1=5");
   Check (Power_Naive (5, 1) = 5, "naive 5^1=5");

   Check (Power_Recursive (-2, 3) = -8, "rec (-2)^3=-8");
   Check (Power_Iterative (-2, 3) = -8, "iter (-2)^3=-8");
   Check (Power_Left_To_Right (-2, 3) = -8, "ltr (-2)^3=-8");
   Check (Power_Naive (-2, 3) = -8, "naive (-2)^3=-8");

   Check (Power_Recursive (-2, 4) = 16, "rec (-2)^4=16");
   Check (Power_Iterative (-2, 4) = 16, "iter (-2)^4=16");
   Check (Power_Left_To_Right (-2, 4) = 16, "ltr (-2)^4=16");
   Check (Power_Naive (-2, 4) = 16, "naive (-2)^4=16");

   Check (Power_Recursive (-2, 5) = -32, "rec (-2)^5=-32");
   Check (Power_Iterative (-2, 1) = -2, "iter (-2)^1=-2");
   Check (Power_Recursive (-3, 2) = 9, "rec (-3)^2=9");
   Check (Power_Iterative (-3, 3) = -27, "iter (-3)^3=-27");

   ------------------------------------------------------------------
   Section ("3. Zero base: 0^n and 0^0 convention");
   ------------------------------------------------------------------
   Check (Power_Recursive (0, 0) = 1, "rec 0^0=1");
   Check (Power_Iterative (0, 0) = 1, "iter 0^0=1");
   Check (Power_Left_To_Right (0, 0) = 1, "ltr 0^0=1");
   Check (Power_Naive (0, 0) = 1, "naive 0^0=1");
   Check (Power_Recursive (0, 1) = 0, "rec 0^1=0");
   Check (Power_Iterative (0, 5) = 0, "iter 0^5=0");
   Check (Power_Left_To_Right (0, 3) = 0, "ltr 0^3=0");
   Check (Power_Naive (0, 7) = 0, "naive 0^7=0");
   Check (Power_Recursive (0, 10) = 0, "rec 0^10=0");
   Check (Pow_Mod (0, 0, 17) = 1, "0^0 mod 17=1");
   Check (Pow_Mod (0, 5, 17) = 0, "0^5 mod 17=0");

   ------------------------------------------------------------------
   Section ("4. Recursive ≡ iterative ≡ LTR ≡ naive");
   ------------------------------------------------------------------
   declare
      Bases : constant array (Positive range <>) of Long_Integer :=
        [1, 2, 3, 4, 5, 7, 9, 10, -1, -2, -5, -8, 0];
      Exps  : constant array (Positive range <>) of Natural :=
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15];
      All_Ok : Boolean := True;
      R, I, L, N : Long_Integer;
   begin
      for B of Bases loop
         for E of Exps loop
            --  Skip huge |B|^E that may overflow Long_Integer.
            if Abs_LI (B) <= 3 or else E <= 8 then
               if Abs_LI (B) <= 12 or else E <= 5 then
                  R := Power_Recursive (B, E);
                  I := Power_Iterative (B, E);
                  L := Power_Left_To_Right (B, E);
                  N := Power_Naive (B, E);
                  if not (R = I and then I = L and then L = N) then
                     All_Ok := False;
                  end if;
               end if;
            end if;
         end loop;
      end loop;
      Check (All_Ok, "grid rec=iter=ltr=naive (safe domain)");
   end;

   Check (Power_Recursive (2, 16) = Power_Iterative (2, 16),
          "rec=iter 2^16");
   Check (Power_Iterative (2, 20) = Power_Left_To_Right (2, 20),
          "iter=ltr 2^20");
   Check (Power_Recursive (3, 8) = Power_Naive (3, 8),
          "rec=naive 3^8");
   Check (Power_Recursive (2, 30) = 1_073_741_824, "rec 2^30");
   Check (Power_Iterative (2, 30) = 1_073_741_824, "iter 2^30");
   Check (Power_Left_To_Right (2, 30) = 1_073_741_824, "ltr 2^30");

   ------------------------------------------------------------------
   Section ("5. Pow_Mod vs classical / non-modular");
   ------------------------------------------------------------------
   Check (Pow_Mod (2, 10, 1000) = 24, "2^10 mod 1000=24");
   Check (Pow_Mod (3, 5, 7) = 5, "3^5 mod 7=5");
   Check (Pow_Mod (5, 0, 17) = 1, "5^0 mod 17=1");
   Check (Pow_Mod (5, 1, 17) = 5, "5^1 mod 17=5");
   Check (Pow_Mod (2, 10, 1024) = 0, "2^10 mod 1024=0");
   Check (Pow_Mod (7, 3, 10) = 3, "7^3=343 mod 10=3");
   Check (Pow_Mod (-2, 5, 17) = Mod_Nonneg (-32, 17), "(-2)^5 mod 17");
   Check (Pow_Mod (10, 9, 17) = Power_Iterative (10, 9) rem 17,
          "10^9 mod 17 vs classical rem");
   declare
      M : constant Long_Integer := 1_000_000_007;
      A : constant Long_Integer := Pow_Mod (2, 100, M);
      B : constant Long_Integer :=
        Mod_Mul (Pow_Mod (2, 50, M), Pow_Mod (2, 50, M), M);
   begin
      Check (A = B, "2^100 ≡ (2^50)^2 mod 10^9+7");
   end;
   --  By Fermat a^{p-1}≡1; 3^96 ≡ 1 ⇒ 3^100 ≡ 3^4 mod 97.
   Check (Pow_Mod (3, 96, 97) = 1, "3^96 ≡ 1 mod 97 (Fermat)");
   Check (Pow_Mod (3, 100, 97) = Pow_Mod (3, 4, 97),
          "3^100 ≡ 3^4 mod 97");

   declare
      procedure Bad_Mod is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Pow_Mod (2, 5, 1);
      end Bad_Mod;
      procedure Bad_Mod0 is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Pow_Mod (2, 5, 0);
      end Bad_Mod0;
      procedure Neg_Exp is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Pow_Mod (2, -1, 17);
      end Neg_Exp;
   begin
      Check (Raised_Invalid (Bad_Mod'Access), "Pow_Mod Modulus=1");
      Check (Raised_Invalid (Bad_Mod0'Access), "Pow_Mod Modulus=0");
      Check (Raised_Invalid (Neg_Exp'Access), "Pow_Mod negative Exp");
   end;

   --  Mod pow agrees with classical for small values.
   declare
      Ok : Boolean := True;
   begin
      for B in Long_Integer range 0 .. 12 loop
         for E in Natural range 0 .. 8 loop
            declare
               Classical : constant Long_Integer :=
                 Power_Iterative (B, E);
               Modular   : constant Long_Integer :=
                 Pow_Mod (B, Long_Integer (E), 97);
            begin
               if Modular /= Mod_Nonneg (Classical, 97) then
                  Ok := False;
               end if;
            end;
         end loop;
      end loop;
      Check (Ok, "Pow_Mod ≡ classical rem 97 (B=0..12,E=0..8)");
   end;

   ------------------------------------------------------------------
   Section ("6. Power_Naive limits / Invalid_Argument");
   ------------------------------------------------------------------
   declare
      procedure Too_Big is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Power_Naive (2, Max_Naive_Exp + 1);
      end Too_Big;
   begin
      Check (Raised_Invalid (Too_Big'Access), "naive Exp>Max");
   end;
   Check (Power_Naive (1, Max_NE) = 1, "1^Max_Naive_Exp=1");
   Check (Power_Naive (-1, 100) = 1, "(-1)^100=1");
   Check (Power_Naive (-1, 101) = -1, "(-1)^101=-1");

   ------------------------------------------------------------------
   Section ("7. Multiplication_Count educational counter");
   ------------------------------------------------------------------
   Reset_Multiplication_Count;
   Enable_Counting (False);
   declare
      Ignore : Long_Integer;
      pragma Unreferenced (Ignore);
   begin
      Ignore := Power_Iterative (2, 10);
   end;
   Check (Multiplication_Count = 0, "count stays 0 when disabled");
   Check (not Counting_Enabled, "counting disabled");

   Enable_Counting (True);
   Reset_Multiplication_Count;
   declare
      Ignore : Long_Integer;
      pragma Unreferenced (Ignore);
   begin
      Ignore := Power_Iterative (2, 10);
   end;
   --  2^10 = 1024: binary 1010 → squares + multiplies; expect > 0.
   Check (Multiplication_Count > 0, "iter 2^10 counted some muls");
   Check (Counting_Enabled, "counting enabled");

   declare
      C_Rec, C_Iter, C_Naive : Natural;
      Ignore : Long_Integer;
      pragma Unreferenced (Ignore);
   begin
      Reset_Multiplication_Count;
      Ignore := Power_Recursive (3, 8);
      C_Rec := Multiplication_Count;

      Reset_Multiplication_Count;
      Ignore := Power_Iterative (3, 8);
      C_Iter := Multiplication_Count;

      Reset_Multiplication_Count;
      Ignore := Power_Naive (3, 8);
      C_Naive := Multiplication_Count;

      Check (C_Rec > 0 and then C_Iter > 0, "rec/iter counts > 0");
      Check (C_Naive = 8, "naive 3^8 uses 8 muls");
      Check (C_Rec < C_Naive and then C_Iter < C_Naive,
             "binary fewer muls than naive for 3^8");
   end;

   Enable_Counting (False);
   Reset_Multiplication_Count;

   ------------------------------------------------------------------
   Section ("8. Power_Float (negative exponents)");
   ------------------------------------------------------------------
   Check (Near_F (Power_Float (2.0, 10), 1024.0), "float 2^10");
   Check (Near_F (Power_Float (3.0, 0), 1.0), "float 3^0");
   Check (Near_F (Power_Float (5.0, 1), 5.0), "float 5^1");
   Check (Near_F (Power_Float (2.0, -1), 0.5), "float 2^{-1}");
   Check (Near_F (Power_Float (2.0, -3), 0.125), "float 2^{-3}");
   Check (Near_F (Power_Float (4.0, -2), 0.0625), "float 4^{-2}");
   Check (Near_F (Power_Float (-2.0, 3), -8.0), "float (-2)^3");
   Check (Near_F (Power_Float (-2.0, 4), 16.0), "float (-2)^4");
   Check (Near_F (Power_Float (0.0, 5), 0.0), "float 0^5");
   Check (Near_F (Power_Float (0.0, 0), 1.0), "float 0^0=1");
   Check (Near_F (Power_Float (10.0, -2), 0.01), "float 10^{-2}");

   declare
      procedure Zero_Neg is
         X : Float;
         pragma Unreferenced (X);
      begin
         X := Power_Float (0.0, -1);
      end Zero_Neg;
      procedure Zero_Zero_Neg is
         X : Float;
         pragma Unreferenced (X);
      begin
         X := Power_Float (0.0, -3);
      end Zero_Zero_Neg;
   begin
      Check (Raised_Invalid (Zero_Neg'Access), "float 0^{-1} invalid");
      Check (Raised_Invalid (Zero_Zero_Neg'Access), "float 0^{-3} invalid");
   end;

   ------------------------------------------------------------------
   Section ("9. 2×2 matrix powering (Fibonacci companion)");
   ------------------------------------------------------------------
   declare
      --  F = [[1,1],[1,0]]; F^n = [[F_{n+1}, F_n],[F_n, F_{n-1}]]
      --  with F_0=0, F_1=1, F_2=1, F_3=2, F_4=3, F_5=5, …
      F : constant Matrix_2x2 :=
        (A11 => 1, A12 => 1, A21 => 1, A22 => 0);
      Id : constant Matrix_2x2 := Identity_2x2;
      P0, P1, P5, P6 : Matrix_2x2;
   begin
      Check (Same_Mat (Id, (1, 0, 0, 1)), "identity values");
      P0 := Power_Matrix_2x2 (F, 0);
      Check (Same_Mat (P0, Id), "F^0 = I");
      P1 := Power_Matrix_2x2 (F, 1);
      Check (Same_Mat (P1, F), "F^1 = F");
      P5 := Power_Matrix_2x2 (F, 5);
      --  F_5=5, F_6=8, F_4=3 → [[8,5],[5,3]]
      Check (P5.A11 = 8 and then P5.A12 = 5
             and then P5.A21 = 5 and then P5.A22 = 3,
             "F^5 = [[8,5],[5,3]]");
      P6 := Power_Matrix_2x2 (F, 6);
      Check (P6.A11 = 13 and then P6.A12 = 8
             and then P6.A21 = 8 and then P6.A22 = 5,
             "F^6 = [[13,8],[8,5]]");
      Check (Same_Mat
               (Multiply_2x2 (Power_Matrix_2x2 (F, 3),
                              Power_Matrix_2x2 (F, 4)),
                Power_Matrix_2x2 (F, 7)),
             "F^3 F^4 = F^7");
   end;

   declare
      Z : constant Matrix_2x2 := (0, 0, 0, 0);
      P : Matrix_2x2;
   begin
      P := Power_Matrix_2x2 (Z, 0);
      Check (Same_Mat (P, Identity_2x2), "0^0 matrix → I");
      P := Power_Matrix_2x2 (Z, 3);
      Check (Same_Mat (P, Z), "zero matrix^3 = 0");
   end;

   ------------------------------------------------------------------
   Section ("10. Extra spot checks / edge cases");
   ------------------------------------------------------------------
   Check (Power_Recursive (1, 100) = 1, "1^100");
   Check (Power_Iterative (1, 1000) = 1, "1^1000");
   Check (Power_Recursive (-1, 0) = 1, "(-1)^0");
   Check (Power_Iterative (-1, 50) = 1, "(-1)^50");
   Check (Power_Left_To_Right (-1, 51) = -1, "(-1)^51");
   Check (Power_Recursive (10, 5) = 100_000, "10^5");
   Check (Power_Iterative (10, 6) = 1_000_000, "10^6");
   declare
      R123 : constant Long_Integer := Pow_Mod (123, 456, 789);
   begin
      Check (R123 >= 0, "Pow_Mod(123,456,789) ≥ 0");
      Check (R123 < 789, "Pow_Mod(123,456,789) < 789");
   end;

   --  Compare Pow_Mod to iterative+mod for medium values.
   declare
      Ok : Boolean := True;
      M  : constant Long_Integer := 997;
   begin
      for B in Long_Integer range -20 .. 20 loop
         for E in Natural range 0 .. 12 loop
            if Pow_Mod (B, Long_Integer (E), M) /=
              Mod_Nonneg (Power_Iterative (B, E), M)
            then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "Pow_Mod ≡ iter rem 997 (B=-20..20,E=0..12)");
   end;

   Check (Power_Float (0.5, 2) = 0.25, "float (1/2)^2");
   Check (Near_F (Power_Float (0.5, -2), 4.0), "float (1/2)^{-2}=4");
   Check (Near_F (Power_Float (-0.5, 3), -0.125), "float (-1/2)^3");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("======================================");
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

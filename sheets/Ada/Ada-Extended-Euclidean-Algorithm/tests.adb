--  Standalone test suite for Extended_Euclidean (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Extended_Euclidean; use Extended_Euclidean;

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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function L (X : Long_Integer) return Long_Integer is (X);

   procedure Expect_Invalid_Inverse (Label : String; A, M : Long_Integer) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Long_Integer := Modular_Inverse (A, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Inverse: " & Label);
   end Expect_Invalid_Inverse;

begin
   Ada.Text_IO.Put_Line ("Extended_Euclidean tests");
   Ada.Text_IO.Put_Line ("========================");

   ------------------------------------------------------------------
   Section ("1. Abs_LI / Mod_Nonneg");
   ------------------------------------------------------------------
   Check (Abs_LI (L (0)) = 0, "Abs_LI(0)");
   Check (Abs_LI (L (5)) = 5, "Abs_LI(5)");
   Check (Abs_LI (L (-5)) = 5, "Abs_LI(-5)");
   Check (Mod_Nonneg (L (7), L (5)) = 2, "Mod_Nonneg 7 mod 5");
   Check (Mod_Nonneg (L (-1), L (5)) = 4, "Mod_Nonneg -1 mod 5");
   Check (Mod_Nonneg (L (0), L (9)) = 0, "Mod_Nonneg 0");
   Check (Mod_Nonneg (L (15), L (5)) = 0, "Mod_Nonneg multiple");

   ------------------------------------------------------------------
   Section ("2. Gcd basics");
   ------------------------------------------------------------------
   Check (Gcd (L (0), L (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (L (0), L (7)) = 7, "gcd(0,7)=7");
   Check (Gcd (L (7), L (0)) = 7, "gcd(7,0)=7");
   Check (Gcd (L (-7), L (0)) = 7, "gcd(-7,0)=7");
   Check (Gcd (L (0), L (-7)) = 7, "gcd(0,-7)=7");
   Check (Gcd (L (54), L (24)) = 6, "gcd(54,24)=6");
   Check (Gcd (L (24), L (54)) = 6, "gcd(24,54)=6");
   Check (Gcd (L (-54), L (24)) = 6, "gcd(-54,24)=6");
   Check (Gcd (L (17), L (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (L (100), L (25)) = 25, "gcd(100,25)=25");
   Check (Gcd (L (270), L (192)) = 6, "gcd(270,192)=6");
   Check (Gcd (L (1), L (1)) = 1, "gcd(1,1)=1");
   Check (Gcd (L (2), L (4)) = 2, "gcd(2,4)=2");
   Check (Gcd (L (12), L (18)) = Gcd (L (18), L (12)), "gcd commutative");

   ------------------------------------------------------------------
   Section ("3. Extended_Gcd Wikipedia examples");
   ------------------------------------------------------------------
   declare
      R : Extended_Gcd_Result;
   begin
      R := Extended_Gcd (L (240), L (46));
      Check (R.Gcd = 2, "xgcd(240,46).Gcd=2");
      Check (Verify_Bezout (L (240), L (46), R), "Bezout 240,46");

      R := Extended_Gcd (L (54), L (24));
      Check (R.Gcd = 6, "xgcd(54,24).Gcd=6");
      Check (Verify_Bezout (L (54), L (24), R), "Bezout 54,24");

      R := Extended_Gcd (L (17), L (13));
      Check (R.Gcd = 1, "xgcd(17,13).Gcd=1");
      Check (Verify_Bezout (L (17), L (13), R), "Bezout 17,13");

      R := Extended_Gcd (L (0), L (0));
      Check (R.Gcd = 0, "xgcd(0,0).Gcd=0");
      Check (Verify_Bezout (L (0), L (0), R), "Bezout 0,0");

      R := Extended_Gcd (L (42), L (0));
      Check (R.Gcd = 42, "xgcd(42,0).Gcd");
      Check (Verify_Bezout (L (42), L (0), R), "Bezout 42,0");

      R := Extended_Gcd (L (0), L (42));
      Check (R.Gcd = 42, "xgcd(0,42).Gcd");
      Check (Verify_Bezout (L (0), L (42), R), "Bezout 0,42");

      R := Extended_Gcd (L (1), L (1));
      Check (R.Gcd = 1, "xgcd(1,1).Gcd");
      Check (Verify_Bezout (L (1), L (1), R), "Bezout 1,1");

      R := Extended_Gcd (L (270), L (192));
      Check (R.Gcd = 6, "xgcd(270,192).Gcd");
      Check (Verify_Bezout (L (270), L (192), R), "Bezout 270,192");

      R := Extended_Gcd (L (35), L (15));
      Check (R.Gcd = 5, "xgcd(35,15).Gcd");
      Check (Verify_Bezout (L (35), L (15), R), "Bezout 35,15");
   end;

   ------------------------------------------------------------------
   Section ("4. Signed Extended_Gcd");
   ------------------------------------------------------------------
   declare
      R : Extended_Gcd_Result;
   begin
      R := Extended_Gcd (L (-240), L (46));
      Check (R.Gcd = 2, "xgcd(-240,46).Gcd");
      Check (Verify_Bezout (L (-240), L (46), R), "Bezout -240,46");

      R := Extended_Gcd (L (240), L (-46));
      Check (R.Gcd = 2, "xgcd(240,-46).Gcd");
      Check (Verify_Bezout (L (240), L (-46), R), "Bezout 240,-46");

      R := Extended_Gcd (L (-240), L (-46));
      Check (R.Gcd = 2, "xgcd(-240,-46).Gcd");
      Check (Verify_Bezout (L (-240), L (-46), R), "Bezout -240,-46");

      R := Extended_Gcd (L (-17), L (13));
      Check (R.Gcd = 1, "xgcd(-17,13).Gcd");
      Check (Verify_Bezout (L (-17), L (13), R), "Bezout -17,13");

      R := Extended_Gcd (L (0), L (-42));
      Check (R.Gcd = 42, "xgcd(0,-42).Gcd");
      Check (Verify_Bezout (L (0), L (-42), R), "Bezout 0,-42");

      R := Extended_Gcd (L (-42), L (0));
      Check (R.Gcd = 42, "xgcd(-42,0).Gcd");
      Check (Verify_Bezout (L (-42), L (0), R), "Bezout -42,0");
   end;

   ------------------------------------------------------------------
   Section ("5. Quotients_By_Gcd");
   ------------------------------------------------------------------
   declare
      Q : Quotient_Pair;
   begin
      Q := Quotients_By_Gcd (L (240), L (46));
      Check (Q.A_Over_G = 120 and then Q.B_Over_G = 23, "quotients 240/46");

      Q := Quotients_By_Gcd (L (54), L (24));
      Check (Q.A_Over_G = 9 and then Q.B_Over_G = 4, "quotients 54/24");

      Q := Quotients_By_Gcd (L (-54), L (24));
      Check (Q.A_Over_G = -9 and then Q.B_Over_G = 4, "quotients -54/24");

      Q := Quotients_By_Gcd (L (17), L (13));
      Check (Q.A_Over_G = 17 and then Q.B_Over_G = 13, "quotients coprime");

      Q := Quotients_By_Gcd (L (0), L (0));
      Check (Q.A_Over_G = 0 and then Q.B_Over_G = 0, "quotients 0,0");
   end;

   ------------------------------------------------------------------
   Section ("6. Are_Coprime");
   ------------------------------------------------------------------
   Check (Are_Coprime (L (17), L (13)), "coprime 17,13");
   Check (Are_Coprime (L (1), L (99)), "coprime 1,99");
   Check (not Are_Coprime (L (54), L (24)), "not coprime 54,24");
   Check (not Are_Coprime (L (0), L (0)), "not coprime 0,0");
   Check (Are_Coprime (L (-17), L (13)), "coprime -17,13");

   ------------------------------------------------------------------
   Section ("7. Modular_Inverse");
   ------------------------------------------------------------------
   declare
      Inv : Long_Integer;
   begin
      Inv := Modular_Inverse (L (3), L (11));
      Check (Is_Modular_Inverse (L (3), Inv, L (11)), "3 inverse mod 11");

      Inv := Modular_Inverse (L (7), L (40));
      Check (Is_Modular_Inverse (L (7), Inv, L (40)), "7 inverse mod 40");

      Inv := Modular_Inverse (L (5), L (17));
      Check (Is_Modular_Inverse (L (5), Inv, L (17)), "5 inverse mod 17");

      Inv := Modular_Inverse (L (1), L (97));
      Check (Inv = 1, "1 inverse mod 97");

      Inv := Modular_Inverse (L (96), L (97));
      Check (Is_Modular_Inverse (L (96), Inv, L (97)), "96 inverse mod 97");

      Inv := Modular_Inverse (L (123), L (4567));
      Check (Is_Modular_Inverse (L (123), Inv, L (4567)), "123 inverse mod 4567");

      Inv := Modular_Inverse (L (-3), L (11));
      Check (Is_Modular_Inverse (L (-3), Inv, L (11)), "-3 inverse mod 11");

      Expect_Invalid_Inverse ("4 mod 10", L (4), L (10));
      Expect_Invalid_Inverse ("6 mod 9", L (6), L (9));
      Expect_Invalid_Inverse ("M=1", L (1), L (1));
      Expect_Invalid_Inverse ("M=0", L (1), L (0));
      Expect_Invalid_Inverse ("M=-5", L (1), L (-5));
   end;

   ------------------------------------------------------------------
   Section ("8. Pairwise Bézout grid");
   ------------------------------------------------------------------
   declare
      R : Extended_Gcd_Result;
      Pairs : constant array (Positive range <>) of Long_Integer :=
        [2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 99, 78, 1001, 91, 100, 35];
   begin
      for I in Pairs'Range loop
         for J in Pairs'Range loop
            R := Extended_Gcd (Pairs (I), Pairs (J));
            Check (R.Gcd = Gcd (Pairs (I), Pairs (J)), "G matches gcd");
            Check (Verify_Bezout (Pairs (I), Pairs (J), R), "Bezout pair");
            Check (R.Gcd >= 0, "Gcd non-neg");
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. RSA-flavored toy modulus");
   ------------------------------------------------------------------
   declare
      R   : Extended_Gcd_Result;
      Inv : Long_Integer;
      E   : constant Long_Integer := 65537;
      N   : constant Long_Integer := 3233;  -- 61*53 toy
   begin
      R := Extended_Gcd (E, N);
      Check (R.Gcd = 1, "65537 coprime to 3233");
      Check (Verify_Bezout (E, N, R), "Bezout e,n");
      Inv := Modular_Inverse (E, N);
      Check (Is_Modular_Inverse (E, Inv, N), "e inverse mod n toy");
   end;

   ------------------------------------------------------------------
   Section ("10. Educational bound constant");
   ------------------------------------------------------------------
   declare
      Bound : constant Long_Integer := Max_Educational;
   begin
      Check (Bound = L (1_000_000), "Max_Educational");
      Check (Gcd (Bound, L (15)) = 5, "gcd Max_Educational,15");
   end;
   declare
      R : constant Extended_Gcd_Result :=
        Extended_Gcd (Max_Educational, L (999_999));
   begin
      Check (Verify_Bezout (Max_Educational, L (999_999), R),
             "Bezout Max_Educational");
   end;

   ------------------------------------------------------------------
   Section ("11. xgcd vs gcd agreement");
   ------------------------------------------------------------------
   declare
      R1 : constant Extended_Gcd_Result := Extended_Gcd (L (12), L (18));
      R2 : constant Extended_Gcd_Result := Extended_Gcd (L (18), L (12));
   begin
      Check (R1.Gcd = R2.Gcd, "xgcd G commutative");
      Check (Verify_Bezout (L (12), L (18), R1), "Bezout 12,18");
      Check (Verify_Bezout (L (18), L (12), R2), "Bezout 18,12");
      Check (Gcd (Gcd (L (12), L (18)), L (9)) = 3, "gcd associative sketch");
   end;

   ------------------------------------------------------------------
   Section ("12. Larger educational primes");
   ------------------------------------------------------------------
   declare
      R : Extended_Gcd_Result;
      A : constant Long_Integer := 1_000_003;
      B : constant Long_Integer := 1_000_033;
   begin
      R := Extended_Gcd (A, B);
      Check (R.Gcd = 1, "large primes gcd 1");
      Check (Verify_Bezout (A, B, R), "Bezout large primes");
      Check
        (Is_Modular_Inverse (A, Modular_Inverse (A, B), B),
         "inverse A mod B");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count) &
      "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

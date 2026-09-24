--  Standalone test suite for Extended_Euclidean_Algorithm (SPARK port).
--  Preconditions replace exceptions; Bézout identity checked here (not in Post).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Extended_Euclidean_Algorithm; use Extended_Euclidean_Algorithm;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   function E (X : Integer) return Educational is (Educational (X));

begin
   Ada.Text_IO.Put_Line ("Extended_Euclidean_Algorithm (SPARK) tests");
   Ada.Text_IO.Put_Line ("==========================================");

   Section ("1. Mod_Nonneg / Divides");
   Check (Mod_Nonneg (E (7), E (5)) = 2, "Mod_Nonneg 7 mod 5");
   Check (Mod_Nonneg (E (0), E (9)) = 0, "Mod_Nonneg 0");
   Check (Mod_Nonneg (E (15), E (5)) = 0, "Mod_Nonneg multiple");
   Check (Divides (E (5), E (10)), "Divides(5,10)");
   Check (not Divides (E (5), E (11)), "not Divides(5,11)");
   Check (not Divides (E (0), E (0)), "not Divides(0,0)");

   Section ("2. Gcd basics");
   Check (Gcd (E (0), E (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (E (0), E (7)) = 7, "gcd(0,7)=7");
   Check (Gcd (E (7), E (0)) = 7, "gcd(7,0)=7");
   Check (Gcd (E (54), E (24)) = 6, "gcd(54,24)=6");
   Check (Gcd (E (24), E (54)) = 6, "gcd(24,54)=6");
   Check (Gcd (E (17), E (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (E (100), E (25)) = 25, "gcd(100,25)=25");
   Check (Gcd (E (270), E (192)) = 6, "gcd(270,192)=6");
   Check (Gcd (E (1), E (1)) = 1, "gcd(1,1)=1");
   Check (Gcd (E (2), E (4)) = 2, "gcd(2,4)=2");
   Check (Gcd (E (12), E (18)) = Gcd (E (18), E (12)), "gcd commutative");
   Check (Divides (Gcd (E (54), E (24)), E (54)), "gcd divides 54");
   Check (Divides (Gcd (E (54), E (24)), E (24)), "gcd divides 24");

   Section ("3. Extended_Gcd Wikipedia examples + Bézout");
   declare
      R : Extended_Gcd_Result;
   begin
      R := Extended_Gcd (E (240), E (46));
      Check (R.Gcd = 2, "xgcd(240,46).Gcd=2");
      Check (Verify_Bezout (E (240), E (46), R), "Bezout 240,46");

      R := Extended_Gcd (E (54), E (24));
      Check (R.Gcd = 6, "xgcd(54,24).Gcd=6");
      Check (Verify_Bezout (E (54), E (24), R), "Bezout 54,24");

      R := Extended_Gcd (E (17), E (13));
      Check (R.Gcd = 1, "xgcd(17,13).Gcd=1");
      Check (Verify_Bezout (E (17), E (13), R), "Bezout 17,13");

      R := Extended_Gcd (E (0), E (0));
      Check (R.Gcd = 0, "xgcd(0,0).Gcd=0");
      Check (Verify_Bezout (E (0), E (0), R), "Bezout 0,0");

      R := Extended_Gcd (E (42), E (0));
      Check (R.Gcd = 42, "xgcd(42,0).Gcd");
      Check (Verify_Bezout (E (42), E (0), R), "Bezout 42,0");

      R := Extended_Gcd (E (0), E (42));
      Check (R.Gcd = 42, "xgcd(0,42).Gcd");
      Check (Verify_Bezout (E (0), E (42), R), "Bezout 0,42");

      R := Extended_Gcd (E (1), E (1));
      Check (R.Gcd = 1, "xgcd(1,1).Gcd");
      Check (Verify_Bezout (E (1), E (1), R), "Bezout 1,1");

      R := Extended_Gcd (E (270), E (192));
      Check (R.Gcd = 6, "xgcd(270,192).Gcd");
      Check (Verify_Bezout (E (270), E (192), R), "Bezout 270,192");

      R := Extended_Gcd (E (35), E (15));
      Check (R.Gcd = 5, "xgcd(35,15).Gcd");
      Check (Verify_Bezout (E (35), E (15), R), "Bezout 35,15");
   end;

   Section ("4. Quotients_By_Gcd");
   declare
      Q : Quotient_Pair;
   begin
      Q := Quotients_By_Gcd (E (240), E (46));
      Check (Q.A_Over_G = 120 and then Q.B_Over_G = 23, "quotients 240/46");
      Q := Quotients_By_Gcd (E (54), E (24));
      Check (Q.A_Over_G = 9 and then Q.B_Over_G = 4, "quotients 54/24");
      Q := Quotients_By_Gcd (E (17), E (13));
      Check (Q.A_Over_G = 17 and then Q.B_Over_G = 13, "quotients coprime");
      Q := Quotients_By_Gcd (E (0), E (0));
      Check (Q.A_Over_G = 0 and then Q.B_Over_G = 0, "quotients 0,0");
   end;

   Section ("5. Are_Coprime");
   Check (Are_Coprime (E (17), E (13)), "coprime 17,13");
   Check (Are_Coprime (E (1), E (99)), "coprime 1,99");
   Check (not Are_Coprime (E (54), E (24)), "not coprime 54,24");
   Check (not Are_Coprime (E (0), E (0)), "not coprime 0,0");
   Check (Are_Coprime (E (8), E (9)), "coprime 8,9");

   Section ("6. Modular_Inverse");
   declare
      Inv : Educational;
   begin
      Inv := Modular_Inverse (E (3), E (11));
      Check (Is_Modular_Inverse (E (3), Inv, E (11)), "3 inverse mod 11");
      Inv := Modular_Inverse (E (7), E (40));
      Check (Is_Modular_Inverse (E (7), Inv, E (40)), "7 inverse mod 40");
      Inv := Modular_Inverse (E (5), E (17));
      Check (Is_Modular_Inverse (E (5), Inv, E (17)), "5 inverse mod 17");
      Inv := Modular_Inverse (E (1), E (97));
      Check (Inv = 1, "1 inverse mod 97");
      Inv := Modular_Inverse (E (96), E (97));
      Check (Is_Modular_Inverse (E (96), Inv, E (97)), "96 inverse mod 97");
      Inv := Modular_Inverse (E (123), E (997));
      Check (Is_Modular_Inverse (E (123), Inv, E (997)), "123 inverse mod 997");
      Check (not Are_Coprime (E (4), E (10)), "not coprime 4,10 (no inverse)");
      Check (not Are_Coprime (E (6), E (9)), "not coprime 6,9 (no inverse)");
   end;

   Section ("7. Pairwise Bézout grid");
   declare
      R : Extended_Gcd_Result;
      Pairs : constant array (Positive range <>) of Educational :=
        [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 99, 78, 91,
         100, 35, 270, 192, 54, 24, 17, 13, 512, 768];
   begin
      for I in Pairs'Range loop
         for J in Pairs'Range loop
            R := Extended_Gcd (Pairs (I), Pairs (J));
            Check (R.Gcd = Gcd (Pairs (I), Pairs (J)), "G matches gcd");
            Check (Verify_Bezout (Pairs (I), Pairs (J), R), "Bezout pair");
            Check (R.X = Abs (R.X) or else R.X < 0, "X signed ok");
         end loop;
      end loop;
   end;

   Section ("8. RSA-flavored toy modulus");
   declare
      R   : Extended_Gcd_Result;
      Inv : Educational;
      Exp : constant Educational := 17;
      N   : constant Educational := 312;  -- 312=8*39; gcd(17,312)=1
   begin
      R := Extended_Gcd (Exp, N);
      Check (R.Gcd = 1, "17 coprime to 312");
      Check (Verify_Bezout (Exp, N, R), "Bezout e,n");
      Inv := Modular_Inverse (Exp, N);
      Check (Is_Modular_Inverse (Exp, Inv, N), "e inverse mod n toy");
   end;

   Section ("9. Educational bound");
   declare
      Bound : constant Educational := Max_Educational;
      R     : Extended_Gcd_Result;
   begin
      Check (Bound = E (1_000), "Max_Educational");
      Check (Gcd (Bound, E (15)) = 5, "gcd Max_Educational,15");
      R := Extended_Gcd (Max_Educational, E (999));
      Check (Verify_Bezout (Max_Educational, E (999), R),
             "Bezout Max_Educational");
      Check (R.Gcd = Gcd (Max_Educational, E (999)), "xgcd=gcd at bound");
   end;

   Section ("10. xgcd vs gcd agreement");
   declare
      R1 : constant Extended_Gcd_Result := Extended_Gcd (E (12), E (18));
      R2 : constant Extended_Gcd_Result := Extended_Gcd (E (18), E (12));
   begin
      Check (R1.Gcd = R2.Gcd, "xgcd G commutative");
      Check (Verify_Bezout (E (12), E (18), R1), "Bezout 12,18");
      Check (Verify_Bezout (E (18), E (12), R2), "Bezout 18,12");
      Check (Gcd (Gcd (E (12), E (18)), E (9)) = 3, "gcd associative sketch");
   end;

   Section ("11. Educational primes");
   declare
      R : Extended_Gcd_Result;
      A : constant Educational := 887;
      B : constant Educational := 907;
   begin
      R := Extended_Gcd (A, B);
      Check (R.Gcd = 1, "educational primes gcd 1");
      Check (Verify_Bezout (A, B, R), "Bezout educational primes");
      Check
        (Is_Modular_Inverse (A, Modular_Inverse (A, B), B),
         "inverse A mod B");
   end;

   Section ("12. Zero / one edge Bézout");
   declare
      R : Extended_Gcd_Result;
   begin
      R := Extended_Gcd (E (1), E (0));
      Check (R.Gcd = 1 and then Verify_Bezout (E (1), E (0), R), "Bezout 1,0");
      R := Extended_Gcd (E (0), E (1));
      Check (R.Gcd = 1 and then Verify_Bezout (E (0), E (1), R), "Bezout 0,1");
      R := Extended_Gcd (E (1), E (1));
      Check (Verify_Bezout (E (1), E (1), R), "Bezout 1,1 again");
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

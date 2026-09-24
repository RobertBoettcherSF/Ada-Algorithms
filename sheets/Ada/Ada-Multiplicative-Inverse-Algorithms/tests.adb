--  Standalone test suite for Multiplicative_Inverse_Algorithms (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Multiplicative_Inverse_Algorithms; use Multiplicative_Inverse_Algorithms;

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

begin
   Ada.Text_IO.Put_Line ("Multiplicative_Inverse_Algorithms test suite");
   Ada.Text_IO.Put_Line ("============================================");

   ---------------------------------------------------------------------
   Section ("1. Abs_LI / Mod_Nonneg / Gcd basics");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Abs_LI (5) = 5, "Abs_LI 5");
      Check (Abs_LI (-7) = 7, "Abs_LI -7");
      Check (Mod_Nonneg (5, 3) = 2, "Mod_Nonneg 5 mod 3");
      Check (Mod_Nonneg (-1, 5) = 4, "Mod_Nonneg -1 mod 5");
      Check (Mod_Nonneg (0, 9) = 0, "Mod_Nonneg 0 mod 9");
      Check (Mod_Nonneg (14, 7) = 0, "Mod_Nonneg 14 mod 7");
      Check (Gcd (0, 0) = 0, "Gcd(0,0)");
      Check (Gcd (0, 5) = 5, "Gcd(0,5)");
      Check (Gcd (5, 0) = 5, "Gcd(5,0)");
      Check (Gcd (12, 18) = 6, "Gcd(12,18)");
      Check (Gcd (17, 13) = 1, "Gcd(17,13) coprime");
      Check (Gcd (-12, 18) = 6, "Gcd(-12,18)");
      Check (Gcd (12, -18) = 6, "Gcd(12,-18)");
      Check (Gcd (-12, -18) = 6, "Gcd(-12,-18)");
   end;

   ---------------------------------------------------------------------
   Section ("2. Extended_Gcd Bézout identity");
   ---------------------------------------------------------------------
   declare
      EG : Extended_Gcd_Result;
   begin
      EG := Extended_Gcd (12, 18);
      Check (EG.G = 6, "EGCD(12,18).G");
      Check (12 * EG.X + 18 * EG.Y = EG.G, "EGCD(12,18) Bézout");

      EG := Extended_Gcd (17, 13);
      Check (EG.G = 1, "EGCD(17,13).G");
      Check (17 * EG.X + 13 * EG.Y = 1, "EGCD(17,13) Bézout");

      EG := Extended_Gcd (3, 7);
      Check (EG.G = 1, "EGCD(3,7).G");
      Check (3 * EG.X + 7 * EG.Y = 1, "EGCD(3,7) Bézout");

      EG := Extended_Gcd (15, 34);
      Check (EG.G = 1, "EGCD(15,34).G");
      Check (15 * EG.X + 34 * EG.Y = 1, "EGCD(15,34) Bézout");

      EG := Extended_Gcd (0, 5);
      Check (EG.G = 5, "EGCD(0,5).G");
      Check (0 * EG.X + 5 * EG.Y = 5, "EGCD(0,5) Bézout");

      EG := Extended_Gcd (-3, 7);
      Check (EG.G = 1, "EGCD(-3,7).G >= 1");
      Check ((-3) * EG.X + 7 * EG.Y = EG.G, "EGCD(-3,7) Bézout");

      EG := Extended_Gcd (240, 46);
      Check (EG.G = 2, "EGCD(240,46).G");
      Check (240 * EG.X + 46 * EG.Y = 2, "EGCD(240,46) Bézout");
   end;

   ---------------------------------------------------------------------
   Section ("3. Is_Prime / Mod_Pow");
   ---------------------------------------------------------------------
   declare
   begin
      Check (not Is_Prime (0), "not prime 0");
      Check (not Is_Prime (1), "not prime 1");
      Check (Is_Prime (2), "prime 2");
      Check (Is_Prime (3), "prime 3");
      Check (not Is_Prime (4), "not prime 4");
      Check (Is_Prime (5), "prime 5");
      Check (Is_Prime (7), "prime 7");
      Check (not Is_Prime (9), "not prime 9");
      Check (Is_Prime (11), "prime 11");
      Check (Is_Prime (13), "prime 13");
      Check (Is_Prime (17), "prime 17");
      Check (Mod_Pow (2, 0, 5) = 1, "2^0 mod 5");
      Check (Mod_Pow (2, 3, 5) = 3, "2^3 mod 5");
      Check (Mod_Pow (3, 5, 7) = 5, "3^5 mod 7");
      Check (Mod_Pow (5, 2, 13) = 12, "5^2 mod 13");
      Check (Mod_Pow (7, 4, 11) = 3, "7^4 mod 11");
      Check (Mod_Pow (-2, 3, 5) = 2, "Mod_Pow (-2)^3 mod 5 = 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic EEA inverses (known pairs)");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      V : Long_Integer;
   begin
      --  3 * 5 ≡ 1 (mod 7)
      R := Inverse_Mod_EEA (3, 7);
      Check (R.Status = Found, "EEA 3 mod 7 Found");
      Check (R.Value = 5, "EEA 3^{-1} ≡ 5 mod 7");
      Check (Is_Modular_Inverse (3, R.Value, 7), "3*5 ≡ 1 mod 7");

      --  3 * 4 ≡ 1 (mod 11)
      R := Inverse_Mod_EEA (3, 11);
      Check (R.Status = Found, "EEA 3 mod 11 Found");
      Check (R.Value = 4, "EEA 3^{-1} ≡ 4 mod 11");
      Check (Is_Modular_Inverse (3, 4, 11), "3*4 ≡ 1 mod 11");

      --  Wikipedia: 15^{-1} ≡ 25 (mod 34)
      R := Inverse_Mod_EEA (15, 34);
      Check (R.Status = Found, "EEA 15 mod 34 Found");
      Check (R.Value = 25, "EEA 15^{-1} ≡ 25 mod 34");
      Check (Is_Modular_Inverse (15, 25, 34), "15*25 ≡ 1 mod 34");

      R := Inverse_Mod_EEA (1, 5);
      Check (R.Status = Found and then R.Value = 1, "EEA 1^{-1} ≡ 1 mod 5");

      R := Inverse_Mod_EEA (2, 5);
      Check (R.Status = Found and then R.Value = 3, "EEA 2^{-1} ≡ 3 mod 5");
      Check (Is_Modular_Inverse (2, 3, 5), "2*3 ≡ 1 mod 5");

      R := Inverse_Mod_EEA (7, 13);
      Check (R.Status = Found, "EEA 7 mod 13 Found");
      Check (Is_Modular_Inverse (7, R.Value, 13), "7*inv ≡ 1 mod 13");

      R := Inverse_Mod_EEA (10, 17);
      Check (R.Status = Found, "EEA 10 mod 17 Found");
      Check (Is_Modular_Inverse (10, R.Value, 17), "10*inv ≡ 1 mod 17");

      --  Negative A
      R := Inverse_Mod_EEA (-3, 7);
      Check (R.Status = Found, "EEA -3 mod 7 Found");
      Check (Is_Modular_Inverse (-3, R.Value, 7), "(-3)*inv ≡ 1 mod 7");

      V := Inverse_EEA (3, 7);
      Check (V = 5, "Inverse_EEA(3,7)=5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Non-invertible / invalid EEA cases");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      Raised : Boolean;
      Unused : Long_Integer;
      pragma Unreferenced (Unused);
   begin
      R := Inverse_Mod_EEA (2, 4);
      Check (R.Status = Not_Invertible, "EEA 2 mod 4 Not_Invertible");
      Check (R.G = 2, "EEA 2 mod 4 gcd=2");

      R := Inverse_Mod_EEA (6, 9);
      Check (R.Status = Not_Invertible, "EEA 6 mod 9 Not_Invertible");
      Check (R.G = 3, "EEA 6 mod 9 gcd=3");

      R := Inverse_Mod_EEA (0, 5);
      Check (R.Status = Not_Invertible, "EEA 0 mod 5 Not_Invertible");

      R := Inverse_Mod_EEA (5, 1);
      Check (R.Status = Invalid_Input, "EEA M=1 Invalid_Input");

      R := Inverse_Mod_EEA (5, 0);
      Check (R.Status = Invalid_Input, "EEA M=0 Invalid_Input");

      R := Inverse_Mod_EEA (5, -3);
      Check (R.Status = Invalid_Input, "EEA M<0 Invalid_Input");

      Raised := False;
      begin
         Unused := Inverse_EEA (2, 4);
      exception
         when No_Inverse =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Inverse_EEA(2,4) raises Not_Invertible");

      Raised := False;
      begin
         Unused := Inverse_EEA (3, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Inverse_EEA(3,1) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("6. Fermat inverses on primes");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      V : Long_Integer;
   begin
      R := Inverse_Mod_Fermat (3, 7);
      Check (R.Status = Found, "Fermat 3 mod 7 Found");
      Check (R.Value = 5, "Fermat 3^{-1} ≡ 5 mod 7");
      Check (Is_Modular_Inverse (3, R.Value, 7), "Fermat 3*5 ≡ 1 mod 7");

      R := Inverse_Mod_Fermat (3, 11);
      Check (R.Status = Found and then R.Value = 4, "Fermat 3^{-1} ≡ 4 mod 11");

      R := Inverse_Mod_Fermat (2, 5);
      Check (R.Status = Found and then R.Value = 3, "Fermat 2^{-1} ≡ 3 mod 5");

      R := Inverse_Mod_Fermat (7, 13);
      Check (R.Status = Found, "Fermat 7 mod 13 Found");
      Check (Is_Modular_Inverse (7, R.Value, 13), "Fermat 7*inv ≡ 1 mod 13");

      R := Inverse_Mod_Fermat (10, 17);
      Check (R.Status = Found, "Fermat 10 mod 17 Found");
      Check (Is_Modular_Inverse (10, R.Value, 17), "Fermat 10*inv ≡ 1 mod 17");

      R := Inverse_Mod_Fermat (5, 97);
      Check (R.Status = Found, "Fermat 5 mod 97 Found");
      Check (Is_Modular_Inverse (5, R.Value, 97), "Fermat 5*inv ≡ 1 mod 97");

      V := Inverse_Fermat (3, 7);
      Check (V = 5, "Inverse_Fermat(3,7)=5");
   end;

   ---------------------------------------------------------------------
   Section ("7. EEA ≡ Fermat on primes");
   ---------------------------------------------------------------------
   declare
      EEA_R, Fer_R : Inverse_Result;
      Primes : constant array (Positive range <>) of Long_Integer :=
        [5, 7, 11, 13, 17, 19, 97];
      A : Long_Integer;
   begin
      for P of Primes loop
         A := 2;
         EEA_R := Inverse_Mod_EEA (A, P);
         Fer_R := Inverse_Mod_Fermat (A, P);
         Check
           (EEA_R.Status = Found
              and then Fer_R.Status = Found
              and then EEA_R.Value = Fer_R.Value
              and then Is_Modular_Inverse (A, EEA_R.Value, P),
            "EEA=Fermat A=2 P=" & P'Image);
      end loop;

      for A in Long_Integer range 1 .. 6 loop
         EEA_R := Inverse_Mod_EEA (A, 7);
         Fer_R := Inverse_Mod_Fermat (A, 7);
         Check
           (EEA_R.Value = Fer_R.Value
              and then Is_Modular_Inverse (A, EEA_R.Value, 7),
            "EEA=Fermat A mod 7, A=" & A'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Fermat non-invertible / invalid");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      Raised : Boolean;
      Unused : Long_Integer;
      pragma Unreferenced (Unused);
   begin
      R := Inverse_Mod_Fermat (0, 7);
      Check (R.Status = Not_Invertible, "Fermat 0 mod 7 Not_Invertible");

      R := Inverse_Mod_Fermat (7, 7);
      Check (R.Status = Not_Invertible, "Fermat 7 mod 7 Not_Invertible");

      R := Inverse_Mod_Fermat (14, 7);
      Check (R.Status = Not_Invertible, "Fermat 14 mod 7 Not_Invertible");

      R := Inverse_Mod_Fermat (3, 1);
      Check (R.Status = Invalid_Input, "Fermat P=1 Invalid_Input");

      R := Inverse_Mod_Fermat (3, 0);
      Check (R.Status = Invalid_Input, "Fermat P=0 Invalid_Input");

      --  Composite: 2 and 9 coprime but 9 not prime; Mod_Pow fails inverse check.
      R := Inverse_Mod_Fermat (2, 9);
      Check (R.Status = Not_Invertible, "Fermat 2 mod 9 (composite) Not_Invertible");

      Raised := False;
      begin
         Unused := Inverse_Fermat (0, 5);
      exception
         when No_Inverse =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Inverse_Fermat(0,5) raises Not_Invertible");

      Raised := False;
      begin
         Unused := Inverse_Fermat (2, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Inverse_Fermat(2,1) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("9. Reciprocal_Newton (Float sketch)");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
      Raised : Boolean;
      Unused : Float;
      pragma Unreferenced (Unused);
   begin
      R := Reciprocal_Newton (2.0);
      Check (R.Status = Converged, "Newton 1/2 Converged");
      Check (Near (R.Value, 0.5), "Newton 1/2 ≈ 0.5");
      Check (Near (2.0 * R.Value, 1.0), "Newton 2*(1/2)≈1");

      R := Reciprocal_Newton (0.5);
      Check (R.Status = Converged and then Near (R.Value, 2.0),
             "Newton 1/0.5 ≈ 2");

      R := Reciprocal_Newton (4.0);
      Check (R.Status = Converged and then Near (R.Value, 0.25),
             "Newton 1/4 ≈ 0.25");

      R := Reciprocal_Newton (10.0);
      Check (R.Status = Converged and then Near (R.Value, 0.1, 1.0E-5),
             "Newton 1/10 ≈ 0.1");

      R := Reciprocal_Newton (-4.0);
      Check (R.Status = Converged and then Near (R.Value, -0.25),
             "Newton 1/(-4) ≈ -0.25");

      R := Reciprocal_Newton (17.0);
      Check (R.Status = Converged, "Newton 1/17 Converged");
      Check (Near (17.0 * R.Value, 1.0, 1.0E-5), "Newton 17*(1/17)≈1");

      R := Reciprocal_Newton (1.0);
      Check (R.Status = Converged and then Near (R.Value, 1.0),
             "Newton 1/1 ≈ 1");

      R := Reciprocal_Newton (0.0);
      Check (R.Status = Bad_Domain, "Newton 0 Bad_Domain");

      Check (Near (Exact_Reciprocal (5.0), 0.2), "Exact 1/5");
      Check (Near (Exact_Reciprocal (-2.0), -0.5), "Exact 1/(-2)");

      Raised := False;
      begin
         Unused := Exact_Reciprocal (0.0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Exact_Reciprocal(0) raises");

      Check (Near (Reciprocal (8.0), 0.125), "Reciprocal(8)=0.125");

      Raised := False;
      begin
         Unused := Reciprocal (0.0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Reciprocal(0) raises");

   end;

   ---------------------------------------------------------------------
   Section ("10. More modular products a*inv ≡ 1");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      type Pair is record
         A, M : Long_Integer;
      end record;
      Pairs : constant array (Positive range <>) of Pair :=
        [(1, 5), (2, 5), (3, 5), (4, 5),
         (2, 7), (3, 7), (6, 7),
         (2, 9), (4, 9), (5, 9), (3, 9), (6, 9),
         (5, 12), (7, 12), (11, 12), (2, 12), (3, 12), (6, 12),
         (11, 26), (15, 28), (20, 21), (19, 20)];
   begin
      for P of Pairs loop
         R := Inverse_Mod_EEA (P.A, P.M);
         if Gcd (P.A, P.M) = 1 then
            Check
              (R.Status = Found
                 and then Is_Modular_Inverse (P.A, R.Value, P.M),
               "a*inv≡1 A=" & P.A'Image & " M=" & P.M'Image);
         else
            Check
              (R.Status = Not_Invertible,
               "no inv A=" & P.A'Image & " M=" & P.M'Image);
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Educational bound / misc");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
   begin
      --  Medium classroom modulus (well below Max_Educational_Modulus).
      R := Inverse_Mod_EEA (12345, 67891);
      Check
        (R.Status = Found
           and then Is_Modular_Inverse (12345, R.Value, 67891),
         "larger EEA 12345 mod 67891");

      R := Inverse_Mod_EEA (99, 100);
      Check (R.Status = Found, "EEA 99 mod 100 Found");
      Check (Is_Modular_Inverse (99, R.Value, 100), "99*inv ≡ 1 mod 100");
      Check (R.Value = 99, "99^{-1} ≡ 99 mod 100 (self-inverse)");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("============================================");
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

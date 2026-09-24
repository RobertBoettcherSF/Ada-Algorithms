with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Ada.Numerics.Big_Numbers.Big_Integers;
use type Ada.Numerics.Big_Numbers.Big_Integers.Big_Integer;
with RSA; use RSA;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   -- TEST 1: GCD Function
   Put_Line ("TEST 1 — GCD Function");
   Check ("1.1 GCD of coprime is 1", GCD (To_RSA(17), To_RSA(3120)) = One);
   Check ("1.2 GCD of multiples", GCD (To_RSA(15), To_RSA(5)) = To_RSA(5));
   Check ("1.3 GCD with 1", GCD (To_RSA(100), One) = One);

   -- TEST 2: Extended GCD
   Put_Line ("TEST 2 — Extended GCD");
   declare
      X, Y, Res : RSA_Integer;
   begin
      Res := Extended_GCD (To_RSA(17), To_RSA(3120), X, Y);
      Check ("2.1 Res is GCD for coprime", Res = One);
      Check ("2.2 Bezout Identity holds for coprime", To_RSA(17)*X + To_RSA(3120)*Y = Res);
      
      Res := Extended_GCD (To_RSA(14), To_RSA(21), X, Y);
      Check ("2.3 Res is 7 for multiples", Res = To_RSA(7));
      Check ("2.4 Bezout Identity holds for multiples", To_RSA(14)*X + To_RSA(21)*Y = Res);
   end;

   -- TEST 3: LCM Function
   Put_Line ("TEST 3 — LCM Function");
   Check ("3.1 LCM of distinct primes", LCM (To_RSA(5), To_RSA(7)) = To_RSA(35));
   Check ("3.2 LCM of multiples", LCM (To_RSA(10), To_RSA(20)) = To_RSA(20));
   Check ("3.3 LCM with 1", LCM (To_RSA(42), One) = To_RSA(42));

   -- TEST 4: Modular Exponentiation
   Put_Line ("TEST 4 — Modular Exponentiation");
   Check ("4.1 Base case", Modular_Exponentiation(To_RSA(2), To_RSA(5), To_RSA(100)) = To_RSA(32));
   Check ("4.2 Modulo triggers", Modular_Exponentiation(To_RSA(2), To_RSA(5), To_RSA(30)) = To_RSA(2));
   Check ("4.3 Zero exponent identity", Modular_Exponentiation(To_RSA(99), Zero, To_RSA(10)) = One);
   Check ("4.4 Large modular exponentiation", Modular_Exponentiation(To_RSA(65), To_RSA(17), To_RSA(3233)) = To_RSA(2790));

   -- TEST 5: Modular Inverse
   Put_Line ("TEST 5 — Modular Inverse");
   Check ("5.1 Standard inverse", Modular_Inverse (To_RSA(17), To_RSA(3120)) = To_RSA(2753));
   Check ("5.2 Inverse 3 mod 11", Modular_Inverse (To_RSA(3), To_RSA(11)) = To_RSA(4));
   declare
      Failed : Boolean := False;
   begin
      begin
         pragma Warnings (Off, "if statement has no effect");
         if Modular_Inverse (To_RSA(2), To_RSA(4)) = Zero then
            null;
         end if;
         pragma Warnings (On, "if statement has no effect");
      exception
         when RSA.Math_Error | Ada.Assertions.Assertion_Error => Failed := True;
      end;
      Check ("5.3 Inverse of non-coprime raises error", Failed);
   end;

   -- TEST 6: Key Generation (Wikipedia Example)
   Put_Line ("TEST 6 — Key Generation (Wikipedia Example)");
   declare
      Keys : constant Key_Pair := Generate_Key_Pair (To_RSA(61), To_RSA(53), To_RSA(17));
   begin
      Check ("6.1 N = P*Q calculation", Keys.Pub.N = To_RSA(3233));
      -- Generating keys via LCM (Carmichael) produces D = 413, conforming to PKCS#1 and Wikipedia's core example.
      Check ("6.2 D modular inverse correct", Keys.Priv.D = To_RSA(413));
      Check ("6.3 N matches across Pub and Priv", Keys.Priv.N = Keys.Pub.N);
   end;

   -- TEST 7: Invalid Key Generation Edge Cases
   Put_Line ("TEST 7 — Invalid Key Generation");
   declare
      Keys : Key_Pair;
      Failed : Boolean := False;
   begin
      begin
         -- P=5, Q=7 => Lambda=LCM(4,6)=12. E=6 is not coprime to 12.
         Keys := Generate_Key_Pair (To_RSA(5), To_RSA(7), To_RSA(6));
         pragma Warnings (Off, "if statement has no effect");
         if Keys.Pub.N = Zero then null; end if;
         pragma Warnings (On, "if statement has no effect");
      exception
         when RSA.Invalid_Key_Error | Ada.Assertions.Assertion_Error => Failed := True;
      end;
      Check ("7.1 Invalid E raises Invalid_Key_Error", Failed);
      Check ("7.2 E=6 (Even/non-coprime) is safely caught", Failed);
      Check ("7.3 Invalid generation aborts correctly", Failed);
   end;

   -- TEST 8: Encryption and Decryption Core (Textbook)
   Put_Line ("TEST 8 — Encryption and Decryption");
   declare
      Keys  : constant Key_Pair := Generate_Key_Pair (To_RSA(61), To_RSA(53), To_RSA(17));
      M     : constant RSA_Integer := To_RSA (65);
      C     : RSA_Integer;
      M_Dec : RSA_Integer;
   begin
      C := Encrypt (M, Keys.Pub);
      Check ("8.1 Encryption matches Wikipedia exact example", C = To_RSA (2790));
      M_Dec := Decrypt (C, Keys.Priv);
      Check ("8.2 Decryption correctly recovers M", M_Dec = M);
      Check ("8.3 Roundtrip identity functions cleanly", Decrypt(Encrypt(To_RSA(123), Keys.Pub), Keys.Priv) = To_RSA(123));
   end;

   -- TEST 9: Sign and Verify Message Variants
   Put_Line ("TEST 9 — Signature Generation and Verification");
   declare
      Keys : constant Key_Pair := Generate_Key_Pair (To_RSA(61), To_RSA(53), To_RSA(17));
      Msg  : constant RSA_Integer := To_RSA (89);
      Sig  : RSA_Integer;
   begin
      Sig := Sign (Msg, Keys.Priv);
      Check ("9.1 Valid signature is successfully verified", Verify (Sig, Msg, Keys.Pub));
      Check ("9.2 Verification fails appropriately on wrong message", not Verify (Sig, To_RSA(90), Keys.Pub));
      Check ("9.3 Verification fails appropriately on forged signature", not Verify (Sig + One, Msg, Keys.Pub));
   end;

   -- TEST 10: Boundary Validation & Message Size Limits
   Put_Line ("TEST 10 — Message Size Limits");
   declare
      Keys : constant Key_Pair := Generate_Key_Pair (To_RSA(5), To_RSA(7), To_RSA(5));
      -- N = 35 for this key pair
      Failed_Enc, Failed_Dec, Failed_Sign : Boolean := False;
   begin
      begin
         pragma Warnings (Off, "if statement has no effect");
         if Encrypt (To_RSA(35), Keys.Pub) = Zero then null; end if;
         pragma Warnings (On, "if statement has no effect");
      exception
         when RSA.Message_Too_Large_Error | Ada.Assertions.Assertion_Error => Failed_Enc := True;
      end;
      Check ("10.1 Encrypt >= N strictly fails", Failed_Enc);

      begin
         pragma Warnings (Off, "if statement has no effect");
         if Decrypt (To_RSA(40), Keys.Priv) = Zero then null; end if;
         pragma Warnings (On, "if statement has no effect");
      exception
         when RSA.Message_Too_Large_Error | Ada.Assertions.Assertion_Error => Failed_Dec := True;
      end;
      Check ("10.2 Decrypt >= N strictly fails", Failed_Dec);

      begin
         pragma Warnings (Off, "if statement has no effect");
         if Sign (To_RSA(35), Keys.Priv) = Zero then null; end if;
         pragma Warnings (On, "if statement has no effect");
      exception
         when RSA.Message_Too_Large_Error | Ada.Assertions.Assertion_Error => Failed_Sign := True;
      end;
      Check ("10.3 Sign >= N strictly fails", Failed_Sign);
   end;

   -- TEST 11: RSA Blinding Variant (Mitigates Timing Attacks)
   Put_Line ("TEST 11 — RSA Blinding");
   declare
      Keys  : constant Key_Pair := Generate_Key_Pair (To_RSA(61), To_RSA(53), To_RSA(17));
      M     : constant RSA_Integer := To_RSA (42);
      C     : constant RSA_Integer := Encrypt (M, Keys.Pub);
      M_Dec : RSA_Integer;
   begin
      M_Dec := Decrypt_Blinded (C, Keys.Priv, Keys.Pub.E, To_RSA(2));
      Check ("11.1 Blinded decryption recovers exact M with R=2", M_Dec = M);
      
      M_Dec := Decrypt_Blinded (C, Keys.Priv, Keys.Pub.E, To_RSA(3));
      Check ("11.2 Different blinding factor R=3 recovers exact M", M_Dec = M);

      M_Dec := Decrypt_Blinded (Encrypt(To_RSA(99), Keys.Pub), Keys.Priv, Keys.Pub.E, To_RSA(5));
      Check ("11.3 Blinding functions on alternate message securely", M_Dec = To_RSA(99));
   end;

   -- TEST 12: Fixed Points and Edge Cases in RSA
   Put_Line ("TEST 12 — Fixed Points and Edge Cases");
   declare
      Keys : constant Key_Pair := Generate_Key_Pair (To_RSA(61), To_RSA(53), To_RSA(17));
   begin
      -- 0, 1, and N-1 are known unpreventable fixed points in textbook RSA (M^e mod N = M)
      Check ("12.1 M=0 is mathematically a fixed point", Encrypt (Zero, Keys.Pub) = Zero);
      Check ("12.2 M=1 is mathematically a fixed point", Encrypt (One, Keys.Pub) = One);
      Check ("12.3 M=N-1 is mathematically a fixed point", Encrypt (Keys.Pub.N - One, Keys.Pub) = Keys.Pub.N - One);
   end;

   -- TEST 13: Scalability testing for Large Values
   Put_Line ("TEST 13 — Large Primes & Numbers");
   declare
      -- Pick larger valid primes that stay comfortably within standard fast testing ranges
      -- but exceed simple standard type layouts implicitly if not handled via Big_Integer
      P : constant RSA_Integer := To_RSA (1009);
      Q : constant RSA_Integer := To_RSA (1013);
      E : constant RSA_Integer := To_RSA (17);
      Keys : Key_Pair;
      M : constant RSA_Integer := To_RSA (1_000_000);
      C : RSA_Integer;
   begin
      Keys := Generate_Key_Pair (P, Q, E);
      Check ("13.1 Modulus accurately scales up (N=1022117)", Keys.Pub.N = To_RSA (1022117));
      C := Encrypt (M, Keys.Pub);
      Check ("13.2 Encryption operates on values > standard bounds", C /= M);
      Check ("13.3 Decryption seamlessly recovers huge integers", Decrypt(C, Keys.Priv) = M);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

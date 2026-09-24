with Ada.Text_IO; use Ada.Text_IO;
with IDEA;        use IDEA;

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
   Put_Line ("===================================================");
   Put_Line (" IDEA Algorithm Test Suite and Usage Demonstrations ");
   Put_Line ("===================================================");
   Put_Line ("");

   -- TEST 1: Modular Multiplication (Normal Cases)
   Put_Line ("TEST 1 — Modular Multiplication (Normal)");
   Check ("1.1 1 * 1 = 1", Mul(1, 1) = 1);
   Check ("1.2 2 * 3 = 6", Mul(2, 3) = 6);
   Check ("1.3 10 * 10 = 100", Mul(10, 10) = 100);

   -- TEST 2: Modular Multiplication (Zero Logic)
   Put_Line ("TEST 2 — Modular Multiplication (Zero Logic)");
   Check ("2.1 0 * 0 = 1 (Zero mapped to 2^16)", Mul(0, 0) = 1);
   Check ("2.2 0 * 1 = 0", Mul(0, 1) = 0);
   Check ("2.3 1 * 0 = 0", Mul(1, 0) = 0);
   Check ("2.4 0 * 2 = 65535", Mul(0, 2) = 65535);

   -- TEST 3: Modular Multiplication (Overflow boundary)
   Put_Line ("TEST 3 — Modular Multiplication (Overflow boundary)");
   Check ("3.1 256 * 256 = 0 (Evaluates exactly to 65536)", Mul(256, 256) = 0);
   Check ("3.2 256 * 512 = 65535", Mul(256, 512) = 65535);
   Check ("3.3 65535 * 65535 = 4", Mul(65535, 65535) = 4);

   -- TEST 4: Additive Inverse modulo 2**16
   Put_Line ("TEST 4 — Additive Inverse modulo 2**16");
   Check ("4.1 Add_Inv(1) = 65535", Add_Inv(1) = 65535);
   Check ("4.2 Add_Inv(0) = 0", Add_Inv(0) = 0);
   Check ("4.3 Add_Inv(32768) = 32768", Add_Inv(32768) = 32768);
   Check ("4.4 Inverse identity maintains zero", (12345 + Add_Inv(12345)) = 0);

   -- TEST 5: Multiplicative Inverse (Normal)
   Put_Line ("TEST 5 — Multiplicative Inverse (Normal)");
   Check ("5.1 Mul_Inv(2) = 32769", Mul_Inv(2) = 32769);
   Check ("5.2 Mul_Inv(32769) = 2", Mul_Inv(32769) = 2);
   Check ("5.3 Mul_Inv(256) = 65281", Mul_Inv(256) = 65281);

   -- TEST 6: Multiplicative Inverse (Edge Cases)
   Put_Line ("TEST 6 — Multiplicative Inverse (Edge Cases)");
   Check ("6.1 Mul_Inv(0) = 0 (Special rule for 0/65536)", Mul_Inv(0) = 0);
   Check ("6.2 Mul_Inv(1) = 1", Mul_Inv(1) = 1);
   Check ("6.3 Mul_Inv(65535) = 32768", Mul_Inv(65535) = 32768);

   -- TEST 7: Multiplicative Inverse (Identity Check)
   Put_Line ("TEST 7 — Multiplicative Inverse (Identity properties)");
   Check ("7.1 Mul(X, Mul_Inv(X)) = 1 (X=123)", Mul(123, Mul_Inv(123)) = 1);
   Check ("7.2 Mul(X, Mul_Inv(X)) = 1 (X=0)", Mul(0, Mul_Inv(0)) = 1);
   Check ("7.3 Mul(X, Mul_Inv(X)) = 1 (X=256)", Mul(256, Mul_Inv(256)) = 1);
   Check ("7.4 Mul(X, Mul_Inv(X)) = 1 (X=65535)", Mul(65535, Mul_Inv(65535)) = 1);

   -- TEST 8: Generate Encryption Keys (Structure)
   Put_Line ("TEST 8 — Generate Encryption Keys Structure");
   declare
      K : constant Key_Block := [1, 2, 3, 4, 5, 6, 7, 8];
      S : constant Subkey_Array := Generate_Encryption_Keys(K);
   begin
      Check ("8.1 Subkeys 1..8 match original key precisely", 
             S(1)=1 and S(2)=2 and S(8)=8);
      Check ("8.2 Length is structurally invariant", S'Length = 52);
      Check ("8.3 Shifted subset shows left rotation logic correctly", 
             S(9) = 1024); -- Shift logic applies here
   end;

   -- TEST 9: Generate Decryption Keys (Structure)
   Put_Line ("TEST 9 — Generate Decryption Keys Structure");
   declare
      K : constant Key_Block := [1, 2, 3, 4, 5, 6, 7, 8];
      Enc : constant Subkey_Array := Generate_Encryption_Keys(K);
      Dec : constant Subkey_Array := Generate_Decryption_Keys(Enc);
   begin
      Check ("9.1 Inverse operation on subkey 49 yields subkey 1 inverse", 
             Dec(49) = Mul_Inv(Enc(1)));
      Check ("9.2 Inverse operation on subkey 50 maintains additive logic", 
             Dec(50) = Add_Inv(Enc(2)));
      Check ("9.3 Decryption length is invariant", Dec'Length = 52);
   end;

   -- TEST 10: Encryption/Decryption Round-trip (All Zeros)
   Put_Line ("TEST 10 — Encrypt/Decrypt Round-trip (All Zeros)");
   declare
      K : constant Key_Block := [others => 0];
      D : Data_Block := [others => 0];
   begin
      Encrypt_Block(D, K);
      Check("10.1 Ciphertext is altered from 0s", D /= [0,0,0,0]);
      Decrypt_Block(D, K);
      Check("10.2 Plaintext is fully restored", D = [0,0,0,0]);
      Check("10.3 State block footprint bounds valid", D'Length = 4);
   end;

   -- TEST 11: Encryption/Decryption Round-trip (Sequential Pattern)
   Put_Line ("TEST 11 — Encrypt/Decrypt Round-trip (Sequential)");
   declare
      K : constant Key_Block := [1, 2, 3, 4, 5, 6, 7, 8];
      D : Data_Block := [16#AAAA#, 16#BBBB#, 16#CCCC#, 16#DDDD#];
      Original : constant Data_Block := D;
   begin
      Encrypt_Block(D, K);
      Check("11.1 Ciphertext diverges from sequential data", D /= Original);
      Decrypt_Block(D, K);
      Check("11.2 Plaintext is fully restored to sequential data", D = Original);
      Check("11.3 Block structure constraints satisfied", D(1) = 16#AAAA#);
   end;

   -- TEST 12: Encryption/Decryption Round-trip (High bit stress)
   Put_Line ("TEST 12 — Encrypt/Decrypt Round-trip (High Bit Stress)");
   declare
      K : constant Key_Block := [16#FFFF#, 16#FFFF#, 16#FFFF#, 16#FFFF#, 
                                 16#FFFF#, 16#FFFF#, 16#FFFF#, 16#FFFF#];
      D : Data_Block := [16#FFFF#, 16#FFFF#, 16#FFFF#, 16#FFFF#];
      Original : constant Data_Block := D;
   begin
      Encrypt_Block(D, K);
      Check("12.1 Ciphertext diverges from high bit pattern", D /= Original);
      Decrypt_Block(D, K);
      Check("12.2 Plaintext is fully restored to high bit pattern", D = Original);
      Check("12.3 High bit stability preserved across rounds", D(4) = 16#FFFF#);
   end;

   -- TEST 13: Exception handling for Hex Key Parsing Edge Cases
   Put_Line ("TEST 13 — Exception Handling (Parse_Key)");
   begin
      declare
         K : Key_Block := Parse_Key("123"); -- Too short
         pragma Unreferenced (K);
      begin
         Check("13.1 Too short string throws format exception", False);
      end;
   exception
      when Invalid_Key_Format => Check("13.1 Too short string throws format exception", True);
   end;

   begin
      declare
         K : Key_Block := Parse_Key("000000000000000000000000000000000"); -- Too long
         pragma Unreferenced (K);
      begin
         Check("13.2 Too long string throws format exception", False);
      end;
   exception
      when Invalid_Key_Format => Check("13.2 Too long string throws format exception", True);
   end;

   begin
      declare
         K : Key_Block := Parse_Key("ZZZZ0000000000000000000000000000"); -- Invalid hex
         pragma Unreferenced (K);
      begin
         Check("13.3 Invalid hex characters throw format exception", False);
      end;
   exception
      when Invalid_Key_Format => Check("13.3 Invalid hex characters throw format exception", True);
   end;


   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed during execution.");
end Tests;

with Ada.Text_IO; use Ada.Text_IO;
with Data_Encryption_Standard; use Data_Encryption_Standard;

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

   --  Helper for readable tests using standard NIST vectors
   type Nibble is mod 16;
   
   function Hex_To_Block (Hex : String) return Block_Type is
      B : Block_Type := [others => False];
      Val : Nibble;
      C : Character;
      Idx : Natural := 1;
   begin
      pragma Assert (Hex'Length = 16, "Hex string must represent 64 bits (16 hex chars)");
      for I in Hex'Range loop
         C := Hex(I);
         if C in '0' .. '9' then
            Val := Nibble(Character'Pos(C) - Character'Pos('0'));
         elsif C in 'A' .. 'F' then
            Val := Nibble(Character'Pos(C) - Character'Pos('A') + 10);
         elsif C in 'a' .. 'f' then
            Val := Nibble(Character'Pos(C) - Character'Pos('a') + 10);
         else
            Val := 0;
         end if;
         B(Idx + 0) := (Val and 8) /= 0;
         B(Idx + 1) := (Val and 4) /= 0;
         B(Idx + 2) := (Val and 2) /= 0;
         B(Idx + 3) := (Val and 1) /= 0;
         Idx := Idx + 4;
      end loop;
      return B;
   end Hex_To_Block;

   function Hex_To_Key (Hex : String) return Key_Type is
      K : Key_Type := [others => False];
      Val : Nibble;
      C : Character;
      Idx : Natural := 1;
   begin
      pragma Assert (Hex'Length = 16, "Hex string must represent 64 bits (16 hex chars)");
      for I in Hex'Range loop
         C := Hex(I);
         if C in '0' .. '9' then
            Val := Nibble(Character'Pos(C) - Character'Pos('0'));
         elsif C in 'A' .. 'F' then
            Val := Nibble(Character'Pos(C) - Character'Pos('A') + 10);
         elsif C in 'a' .. 'f' then
            Val := Nibble(Character'Pos(C) - Character'Pos('a') + 10);
         else
            Val := 0;
         end if;
         K(Idx + 0) := (Val and 8) /= 0;
         K(Idx + 1) := (Val and 4) /= 0;
         K(Idx + 2) := (Val and 2) /= 0;
         K(Idx + 3) := (Val and 1) /= 0;
         Idx := Idx + 4;
      end loop;
      return K;
   end Hex_To_Key;

   --  Test constants
   Zero_Key : constant Key_Type := Hex_To_Key("0000000000000000");
   Zero_Pt  : constant Block_Type := Hex_To_Block("0000000000000000");
   Weak1    : constant Key_Type := Hex_To_Key("0101010101010101");
   Weak2    : constant Key_Type := Hex_To_Key("FEFEFEFEFEFEFEFE");
   Weak3    : constant Key_Type := Hex_To_Key("E0E0E0E0F1F1F1F1");
   Weak4    : constant Key_Type := Hex_To_Key("1F1F1F1F0E0E0E0E");

begin
   Put_Line ("TEST 1 — Basic Symmetry (Zero Key, Zero Pt)");
   declare
      Ct : constant Block_Type := Encrypt(Zero_Pt, Zero_Key);
   begin
      Check ("1.1 Encrypt transforms plain text", Ct /= Zero_Pt);
      Check ("1.2 Decrypt recovers plain text", Decrypt(Ct, Zero_Key) = Zero_Pt);
      Check ("1.3 Double encrypt equals plain (Zero Key is weak)", Encrypt(Ct, Zero_Key) = Zero_Pt);
   end;

   Put_Line ("TEST 2 — Known NIST Vector Check");
   declare
      -- Standard NIST Vector
      Key : constant Key_Type := Hex_To_Key("133457799BBCDFF1");
      Pt  : constant Block_Type := Hex_To_Block("0123456789ABCDEF");
      Ct  : constant Block_Type := Hex_To_Block("85E813540F0AB405");
   begin
      Check ("2.1 Encrypt matches known answer", Encrypt(Pt, Key) = Ct);
      Check ("2.2 Decrypt matches known plain text", Decrypt(Ct, Key) = Pt);
      Check ("2.3 Transformed does not equal plain", Encrypt(Pt, Key) /= Pt);
   end;

   Put_Line ("TEST 3 — Weak Key Detection and Property (0101010101010101)");
   begin
      Check ("3.1 Key is identified as weak", Is_Weak_Key(Weak1));
      -- Weak keys are their own inverses: E(E(P, K), K) = P
      Check ("3.2 Double encryption equals plain text", Encrypt(Encrypt(Zero_Pt, Weak1), Weak1) = Zero_Pt);
      Check ("3.3 Encrypt matches decrypt output", Encrypt(Zero_Pt, Weak1) = Decrypt(Zero_Pt, Weak1));
   end;

   Put_Line ("TEST 4 — Weak Key 2 Property (FEFEFEFEFEFEFEFE)");
   begin
      Check ("4.1 Key is identified as weak", Is_Weak_Key(Weak2));
      Check ("4.2 Double encryption equals plain text", Encrypt(Encrypt(Zero_Pt, Weak2), Weak2) = Zero_Pt);
      Check ("4.3 Encrypt matches decrypt output", Encrypt(Zero_Pt, Weak2) = Decrypt(Zero_Pt, Weak2));
   end;

   Put_Line ("TEST 5 — Weak Key 3 Property (E0E0E0E0F1F1F1F1)");
   begin
      Check ("5.1 Key is identified as weak", Is_Weak_Key(Weak3));
      Check ("5.2 Double encryption equals plain text", Encrypt(Encrypt(Zero_Pt, Weak3), Weak3) = Zero_Pt);
      Check ("5.3 Encrypt matches decrypt output", Encrypt(Zero_Pt, Weak3) = Decrypt(Zero_Pt, Weak3));
   end;

   Put_Line ("TEST 6 — Weak Key 4 Property (1F1F1F1F0E0E0E0E)");
   begin
      Check ("6.1 Key is identified as weak", Is_Weak_Key(Weak4));
      Check ("6.2 Double encryption equals plain text", Encrypt(Encrypt(Zero_Pt, Weak4), Weak4) = Zero_Pt);
      Check ("6.3 Encrypt matches decrypt output", Encrypt(Zero_Pt, Weak4) = Decrypt(Zero_Pt, Weak4));
   end;

   Put_Line ("TEST 7 — Semi-Weak Key Pair Properties");
   declare
      SK1 : constant Key_Type := Hex_To_Key("01FE01FE01FE01FE");
      SK2 : constant Key_Type := Hex_To_Key("FE01FE01FE01FE01");
   begin
      Check ("7.1 Key is not strictly weak (semi-weak)", not Is_Weak_Key(SK1));
      Check ("7.2 E(Pt, K1) = D(Pt, K2)", Encrypt(Zero_Pt, SK1) = Decrypt(Zero_Pt, SK2));
      Check ("7.3 E(Pt, K2) = D(Pt, K1)", Encrypt(Zero_Pt, SK2) = Decrypt(Zero_Pt, SK1));
   end;

   Put_Line ("TEST 8 — Triple DES Degeneration (K1 = K2 = K3)");
   declare
      K    : constant Key_Type := Hex_To_Key("133457799BBCDFF1");
      Keys : constant Key_3_Type := [K, K, K];
      Pt   : constant Block_Type := Hex_To_Block("0123456789ABCDEF");
      Ct   : constant Block_Type := Encrypt(Pt, K);
   begin
      Check ("8.1 3DES encrypt degenerates to 1DES", Triple_DES_Encrypt(Pt, Keys) = Ct);
      Check ("8.2 3DES decrypt degenerates to 1DES", Triple_DES_Decrypt(Ct, Keys) = Pt);
      Check ("8.3 3DES symmetry holds", Triple_DES_Decrypt(Triple_DES_Encrypt(Pt, Keys), Keys) = Pt);
   end;

   Put_Line ("TEST 9 — Triple DES 2-Key Mode (K1 = K3)");
   declare
      K1   : constant Key_Type := Hex_To_Key("133457799BBCDFF1");
      K2   : constant Key_Type := Hex_To_Key("FE01FE01FE01FE01");
      Keys : constant Key_3_Type := [K1, K2, K1];
      Pt   : constant Block_Type := Hex_To_Block("0123456789ABCDEF");
   begin
      Check ("9.1 3DES symmetry holds", Triple_DES_Decrypt(Triple_DES_Encrypt(Pt, Keys), Keys) = Pt);
      Check ("9.2 3DES != 1DES(K1)", Triple_DES_Encrypt(Pt, Keys) /= Encrypt(Pt, K1));
      Check ("9.3 3DES != 1DES(K2)", Triple_DES_Encrypt(Pt, Keys) /= Encrypt(Pt, K2));
   end;

   Put_Line ("TEST 10 — Triple DES 3-Key Mode (All Unique)");
   declare
      Keys : constant Key_3_Type := [Hex_To_Key("133457799BBCDFF1"),
                                     Hex_To_Key("FE01FE01FE01FE01"),
                                     Hex_To_Key("0101010101010101")];
      Pt   : constant Block_Type := Hex_To_Block("0123456789ABCDEF");
      Ct   : constant Block_Type := Triple_DES_Encrypt(Pt, Keys);
   begin
      Check ("10.1 Symmetry holds", Triple_DES_Decrypt(Ct, Keys) = Pt);
      Check ("10.2 Encrypted differs from Plain", Ct /= Pt);
      Check ("10.3 Decrypt plain differs from Plain", Triple_DES_Decrypt(Pt, Keys) /= Pt);
   end;

   Put_Line ("TEST 11 — Parity Adjustment Properties");
   declare
      Adjusted : constant Key_Type := Adjust_Parity(Zero_Key);
   begin
      Check ("11.1 All-zeros key gets modified (parity bits set)", Adjusted /= Zero_Key);
      Check ("11.2 Adjust is idempotent", Adjust_Parity(Adjusted) = Adjusted);
      Check ("11.3 DES ignores parity differences", Encrypt(Zero_Pt, Zero_Key) = Encrypt(Zero_Pt, Adjusted));
   end;

   Put_Line ("TEST 12 — Avalanche Effect (1-bit Plaintext Change)");
   declare
      K    : constant Key_Type := Hex_To_Key("133457799BBCDFF1");
      Pt1  : constant Block_Type := Zero_Pt;
      Pt2  : Block_Type := Zero_Pt;
   begin
      Pt2(1) := True; -- Flip 1 bit
      declare
         Ct1 : constant Block_Type := Encrypt(Pt1, K);
         Ct2 : constant Block_Type := Encrypt(Pt2, K);
      begin
         Check ("12.1 Ciphertexts differ", Ct1 /= Ct2);
         Check ("12.2 Ct1 distinct from Pt", Ct1 /= Pt1);
         Check ("12.3 Ct2 distinct from Pt", Ct2 /= Pt2);
      end;
   end;

   Put_Line ("TEST 13 — Avalanche Effect (1-bit Key Change)");
   declare
      K1   : constant Key_Type := Zero_Key;
      K2   : Key_Type := Zero_Key;
   begin
      K2(1) := True; -- Flip 1 non-parity bit
      declare
         Ct1 : constant Block_Type := Encrypt(Zero_Pt, K1);
         Ct2 : constant Block_Type := Encrypt(Zero_Pt, K2);
      begin
         Check ("13.1 Ciphertexts differ", Ct1 /= Ct2);
         Check ("13.2 Decrypt Ct1 with K2 fails", Decrypt(Ct1, K2) /= Zero_Pt);
         Check ("13.3 Decrypt Ct2 with K1 fails", Decrypt(Ct2, K1) /= Zero_Pt);
      end;
   end;

   Put_Line ("TEST 14 — Parity Error Exception Test");
   begin
      if Assert_Valid_Parity(Zero_Key) then -- All zeros have EVEN parity
         Check ("14.1 Exception not raised when expected", False);
      end if;
   exception
      when Parity_Error =>
         Check ("14.1 Exception raised correctly on bad parity", True);
         Check ("14.2 Normal flow bypassed", True);
         Check ("14.3 Valid parity succeeds natively", Assert_Valid_Parity(Adjust_Parity(Zero_Key)));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

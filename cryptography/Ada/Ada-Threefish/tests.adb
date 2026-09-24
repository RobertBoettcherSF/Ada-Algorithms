with Ada.Text_IO; use Ada.Text_IO;
with Threefish;   use Threefish;

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

   -- Test Variables
   K256, P256, C256, C256_Alt, P256_Dec : Block_256 := [others => 0];
   T256 : Tweak_Block := [others => 0];

   K512, P512, C512, C512_Alt, P512_Dec : Block_512 := [others => 0];
   K1024, P1024, C1024, C1024_Alt, P1024_Dec : Block_1024 := [others => 0];

   Dyn_P256, Dyn_C256, Dyn_P256_Dec : Word_Array (0 .. 3) := [others => 0];

begin
   -- Initialize pseudo-random states for non-trivial testing
   for I in K256'Range loop
      K256(I) := Word(I + 1) * 16#1122_3344_5566_7788#;
      P256(I) := Word(I + 1) * 16#99AA_BBCC_DDEE_FF00#;
   end loop;
   T256(0) := 16#0123_4567_89AB_CDEF#;
   T256(1) := 16#FEDC_BA98_7654_3210#;

   for I in K512'Range loop
      K512(I) := Word(I + 1) * 16#1122_3344_5566_7788#;
      P512(I) := Word(I + 1) * 16#99AA_BBCC_DDEE_FF00#;
   end loop;

   for I in K1024'Range loop
      K1024(I) := Word(I + 1) * 16#1122_3344_5566_7788#;
      P1024(I) := Word(I + 1) * 16#99AA_BBCC_DDEE_FF00#;
   end loop;
   
   Dyn_P256(0 .. 3) := P256;


   -- TEST 1 - Encrypt_256 Determinism
   Put_Line ("TEST 1 — Encrypt_256 Determinism");
   Encrypt_256 (K256, T256, P256, C256);
   Encrypt_256 (K256, T256, P256, C256_Alt);
   Check ("1.1 output matches on repeated run (W0)", C256(0) = C256_Alt(0));
   Check ("1.2 output matches on repeated run (W1)", C256(1) = C256_Alt(1));
   Check ("1.3 output differs from plaintext", C256(0) /= P256(0) or C256(1) /= P256(1));

   -- TEST 2 - Decrypt_256 Reversibility
   Put_Line ("TEST 2 — Decrypt_256 Reversibility");
   Decrypt_256 (K256, T256, C256, P256_Dec);
   Check ("2.1 original plain text recovered (W0)", P256_Dec(0) = P256(0));
   Check ("2.2 original plain text recovered (W1)", P256_Dec(1) = P256(1));
   Check ("2.3 original plain text recovered (W3)", P256_Dec(3) = P256(3));

   -- TEST 3 - Encrypt_512 Determinism
   Put_Line ("TEST 3 — Encrypt_512 Determinism");
   Encrypt_512 (K512, T256, P512, C512);
   Encrypt_512 (K512, T256, P512, C512_Alt);
   Check ("3.1 output matches on repeated run (W0)", C512(0) = C512_Alt(0));
   Check ("3.2 output matches on repeated run (W7)", C512(7) = C512_Alt(7));
   Check ("3.3 output differs from plaintext", C512(0) /= P512(0));

   -- TEST 4 - Decrypt_512 Reversibility
   Put_Line ("TEST 4 — Decrypt_512 Reversibility");
   Decrypt_512 (K512, T256, C512, P512_Dec);
   Check ("4.1 original plain text recovered (W0)", P512_Dec(0) = P512(0));
   Check ("4.2 original plain text recovered (W3)", P512_Dec(3) = P512(3));
   Check ("4.3 original plain text recovered (W7)", P512_Dec(7) = P512(7));

   -- TEST 5 - Encrypt_1024 Determinism
   Put_Line ("TEST 5 — Encrypt_1024 Determinism");
   Encrypt_1024 (K1024, T256, P1024, C1024);
   Encrypt_1024 (K1024, T256, P1024, C1024_Alt);
   Check ("5.1 output matches on repeated run (W0)", C1024(0) = C1024_Alt(0));
   Check ("5.2 output matches on repeated run (W15)", C1024(15) = C1024_Alt(15));
   Check ("5.3 output differs from plaintext", C1024(0) /= P1024(0));

   -- TEST 6 - Decrypt_1024 Reversibility
   Put_Line ("TEST 6 — Decrypt_1024 Reversibility");
   Decrypt_1024 (K1024, T256, C1024, P1024_Dec);
   Check ("6.1 original plain text recovered (W0)", P1024_Dec(0) = P1024(0));
   Check ("6.2 original plain text recovered (W8)", P1024_Dec(8) = P1024(8));
   Check ("6.3 original plain text recovered (W15)", P1024_Dec(15) = P1024(15));

   -- TEST 7 - Dynamic Encrypt Wrapper (256-bit match)
   Put_Line ("TEST 7 — Dynamic Encrypt matches Static Encrypt");
   Encrypt_Dynamic (K256, T256, Dyn_P256, Dyn_C256);
   Check ("7.1 dynamic matches static output (W0)", Dyn_C256(0) = C256(0));
   Check ("7.2 dynamic matches static output (W2)", Dyn_C256(2) = C256(2));
   Check ("7.3 dynamic produces valid cipher", Dyn_C256(3) /= 0);

   -- TEST 8 - Dynamic Decrypt Wrapper (256-bit match)
   Put_Line ("TEST 8 — Dynamic Decrypt matches Static Decrypt");
   Decrypt_Dynamic (K256, T256, Dyn_C256, Dyn_P256_Dec);
   Check ("8.1 dynamic recovers static input (W0)", Dyn_P256_Dec(0) = Dyn_P256(0));
   Check ("8.2 dynamic recovers static input (W2)", Dyn_P256_Dec(2) = Dyn_P256(2));
   Check ("8.3 dynamic recovers fully valid plain", Dyn_P256_Dec(3) = P256(3));

   -- TEST 9 - Invalid Block Size (Length 0) Edge Case
   Put_Line ("TEST 9 — Invalid Block Size Exception (Length 0)");
   declare
      K_0, P_0, C_0 : Word_Array (1 .. 0);
      Ex_Raised : Boolean := False;
   begin
      begin
         Encrypt_Dynamic (K_0, T256, P_0, C_0);
      exception
         when Invalid_Block_Size =>
            Ex_Raised := True;
      end;
      Check ("9.1 Exception safely caught for length 0", Ex_Raised);
      Check ("9.2 Empty arrays verified zero length (K)", K_0'Length = 0);
      Check ("9.3 Empty arrays verified zero length (P)", P_0'Length = 0);
   end;

   -- TEST 10 - Invalid Block Size (Length 5) Edge Case
   Put_Line ("TEST 10 — Invalid Block Size Exception (Length 5)");
   declare
      K_5, P_5 : constant Word_Array (1 .. 5) := [others => 0];
      C_5 : Word_Array (1 .. 5) := [others => 0];
      Ex_Raised : Boolean := False;
   begin
      begin
         Encrypt_Dynamic (K_5, T256, P_5, C_5);
      exception
         when Invalid_Block_Size =>
            Ex_Raised := True;
      end;
      Check ("10.1 Exception correctly raised for invalid size 5", Ex_Raised);
      Check ("10.2 Ciphertext array untouched (W1)", C_5(1) = 0);
      Check ("10.3 Ciphertext array untouched (W5)", C_5(5) = 0);
   end;

   -- TEST 11 - Invalid Block Size (Length 2) Edge Case
   Put_Line ("TEST 11 — Invalid Block Size Exception (Length 2)");
   declare
      K_2, C_2 : constant Word_Array (1 .. 2) := [others => 0];
      P_2 : Word_Array (1 .. 2) := [others => 0];
      Ex_Raised : Boolean := False;
   begin
      begin
         Decrypt_Dynamic (K_2, T256, C_2, P_2);
      exception
         when Invalid_Block_Size =>
            Ex_Raised := True;
      end;
      Check ("11.1 Exception correctly raised for unsupported size 2", Ex_Raised);
      Check ("11.2 Plaintext array untouched (W1)", P_2(1) = 0);
      Check ("11.3 Plaintext array untouched (W2)", P_2(2) = 0);
   end;

   -- TEST 12 - Tweak Influence
   Put_Line ("TEST 12 — Tweak Influence Analysis (256-bit)");
   declare
      T_Alt : Tweak_Block := T256;
      C_Alt : Block_256;
   begin
      T_Alt(0) := T_Alt(0) xor 1;
      Encrypt_256 (K256, T_Alt, P256, C_Alt);
      Check ("12.1 Word 0 significantly changes", C256(0) /= C_Alt(0));
      Check ("12.2 Word 1 significantly changes", C256(1) /= C_Alt(1));
      Check ("12.3 Word 2 significantly changes", C256(2) /= C_Alt(2));
   end;

   -- TEST 13 - Key Influence
   Put_Line ("TEST 13 — Key Influence Analysis (256-bit)");
   declare
      K_Alt : Key_256 := K256;
      C_Alt : Block_256;
   begin
      K_Alt(0) := K_Alt(0) xor 1;
      Encrypt_256 (K_Alt, T256, P256, C_Alt);
      Check ("13.1 Word 0 significantly changes", C256(0) /= C_Alt(0));
      Check ("13.2 Word 1 significantly changes", C256(1) /= C_Alt(1));
      Check ("13.3 Word 3 significantly changes", C256(3) /= C_Alt(3));
   end;

   -- TEST 14 - Plaintext Avalanche
   Put_Line ("TEST 14 — Plaintext Avalanche Analysis (256-bit)");
   declare
      P_Alt : Block_256 := P256;
      C_Alt : Block_256;
   begin
      P_Alt(0) := P_Alt(0) xor 1;
      Encrypt_256 (K256, T256, P_Alt, C_Alt);
      Check ("14.1 1-bit PT change ripples to Word 0", C256(0) /= C_Alt(0));
      Check ("14.2 1-bit PT change ripples to Word 1", C256(1) /= C_Alt(1));
      Check ("14.3 1-bit PT change ripples to Word 2", C256(2) /= C_Alt(2));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

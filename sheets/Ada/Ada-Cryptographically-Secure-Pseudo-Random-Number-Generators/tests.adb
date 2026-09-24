with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Csprng; use Csprng;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Zero_Key   : constant Cha_Cha_Key := [others => 0];
   Zero_Nonce : constant Cha_Cha_Nonce := [others => 0];
   Alt_Nonce  : constant Cha_Cha_Nonce := [1 => 1, others => 0];

   -------------------------------------------------------------------------
   -- TEST RUNNERS
   -------------------------------------------------------------------------
   procedure Test_ChaCha_Determinism is
      Gen1, Gen2 : Cha_Cha_20_Generator;
      B1, B2     : Byte_Array (1 .. 64);
   begin
      Put_Line ("TEST 1 - ChaCha20 Determinism");
      Initialize (Gen1, Zero_Key, Zero_Nonce);
      Initialize (Gen2, Zero_Key, Zero_Nonce);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 matches", B1 (1) = B2 (1));
      Check ("Byte 32 matches", B1 (32) = B2 (32));
      Check ("Byte 64 matches", B1 (64) = B2 (64));
   end Test_ChaCha_Determinism;

   procedure Test_ChaCha_Block_Crossing is
      Gen1, Gen2 : Cha_Cha_20_Generator;
      B1, B2     : Byte_Array (1 .. 128);
   begin
      Put_Line ("TEST 2 - ChaCha20 Block Crossing");
      Initialize (Gen1, Zero_Key, Zero_Nonce);
      Initialize (Gen2, Zero_Key, Zero_Nonce);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 65 matches", B1 (65) = B2 (65));
      Check ("Byte 100 matches", B1 (100) = B2 (100));
      Check ("Byte 128 matches", B1 (128) = B2 (128));
   end Test_ChaCha_Block_Crossing;

   procedure Test_ChaCha_Nonce_Independence is
      Gen1, Gen2 : Cha_Cha_20_Generator;
      B1, B2     : Byte_Array (1 .. 64);
   begin
      Put_Line ("TEST 3 - ChaCha20 Nonce Independence");
      Initialize (Gen1, Zero_Key, Zero_Nonce);
      Initialize (Gen2, Zero_Key, Alt_Nonce);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 differs", B1 (1) /= B2 (1));
      Check ("Byte 32 differs", B1 (32) /= B2 (32));
      Check ("Byte 64 differs", B1 (64) /= B2 (64));
   end Test_ChaCha_Nonce_Independence;

   procedure Test_BBS_Determinism is
      Gen1, Gen2 : Bbs_Generator;
      B1, B2     : Byte_Array (1 .. 3);
   begin
      Put_Line ("TEST 4 - BBS Determinism");
      Initialize (Gen1, 11, 19, 3);
      Initialize (Gen2, 11, 19, 3);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 matches", B1 (1) = B2 (1));
      Check ("Byte 2 matches", B1 (2) = B2 (2));
      Check ("Byte 3 matches", B1 (3) = B2 (3));
   end Test_BBS_Determinism;

   procedure Test_BBS_Large_Primes is
      Gen1, Gen2 : Bbs_Generator;
      B1, B2     : Byte_Array (1 .. 3);
   begin
      Put_Line ("TEST 5 - BBS Large Primes Limit Check");
      Initialize (Gen1, 10007, 10039, 42);
      Initialize (Gen2, 10007, 10039, 42);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 matches", B1 (1) = B2 (1));
      Check ("Byte 2 matches", B1 (2) = B2 (2));
      Check ("Byte 3 matches", B1 (3) = B2 (3));
   end Test_BBS_Large_Primes;

   procedure Test_BBS_Invalid_P_Q_Congruence is
      Gen : Bbs_Generator;
   begin
      Put_Line ("TEST 6 - BBS Invalid Congruence");
      begin
         Initialize (Gen, 5, 19, 3); -- P is 1 mod 4
         Check ("Should fail on P=5", False);
      exception
         when Crypto_Error => Check ("Caught invalid P", True);
      end;
      begin
         Initialize (Gen, 11, 5, 3); -- Q is 1 mod 4
         Check ("Should fail on Q=5", False);
      exception
         when Crypto_Error => Check ("Caught invalid Q", True);
      end;
      begin
         Initialize (Gen, 13, 17, 3); -- Both invalid
         Check ("Should fail on both invalid", False);
      exception
         when Crypto_Error => Check ("Caught invalid P and Q", True);
      end;
   end Test_BBS_Invalid_P_Q_Congruence;

   procedure Test_BBS_Invalid_Equality_And_Seed is
      Gen : Bbs_Generator;
   begin
      Put_Line ("TEST 7 - BBS Edge Cases");
      begin
         Initialize (Gen, 11, 11, 3); -- P = Q
         Check ("Should fail on P=Q", False);
      exception
         when Crypto_Error => Check ("Caught P=Q", True);
      end;
      begin
         Initialize (Gen, 11, 19, 209); -- Seed = M
         Check ("Should fail on Seed=M", False);
      exception
         when Crypto_Error => Check ("Caught Seed multiple of M", True);
      end;
      begin
         Initialize (Gen, 11, 19, 0); -- Seed = 0
         Check ("Should fail on Seed=0", False);
      exception
         when Crypto_Error => Check ("Caught Seed=0", True);
      end;
   end Test_BBS_Invalid_Equality_And_Seed;

   procedure Test_RC4_RFC_Vector is
      Gen : Rc4_Generator;
      Buf : Byte_Array (1 .. 4);
      Key : constant Byte_Array := [75, 101, 121]; -- "Key"
   begin
      Put_Line ("TEST 8 - RC4 Known Vector");
      Initialize (Gen, Key);
      Generate (Gen, Buf);
      Check ("Byte 1 is EB", Buf (1) = 16#EB#);
      Check ("Byte 2 is 9F", Buf (2) = 16#9F#);
      Check ("Byte 3 is 77", Buf (3) = 16#77#);
      Check ("Byte 4 is 81", Buf (4) = 16#81#);
   end Test_RC4_RFC_Vector;

   procedure Test_RC4_Empty_Key_And_Determinism is
      Gen1, Gen2 : Rc4_Generator;
      B1, B2     : Byte_Array (1 .. 100);
      Empty_Key  : constant Byte_Array (1 .. 0) := [others => 0];
   begin
      Put_Line ("TEST 9 - RC4 Edge Cases and Determinism");
      begin
         Initialize (Gen1, Empty_Key);
         Check ("Should fail on empty key", False);
      exception
         when Crypto_Error => Check ("Caught empty key exception", True);
      end;
      Initialize (Gen1, [1 => 42]);
      Initialize (Gen2, [1 => 42]);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 matches", B1 (1) = B2 (1));
      Check ("Byte 100 matches", B1 (100) = B2 (100));
   end Test_RC4_Empty_Key_And_Determinism;

   procedure Test_Polymorphic_Dispatch is
      procedure Run_Polymorphic (Gen : in out Abstract_Csprng'Class; Label : String) is
         Buf : Byte_Array (1 .. 5);
      begin
         Generate (Gen, Buf);
         Check ("Polymorphic call success for " & Label, True);
      end Run_Polymorphic;

      Cha : Cha_Cha_20_Generator;
      Bbs : Bbs_Generator;
      Rc4 : Rc4_Generator;
   begin
      Put_Line ("TEST 10 - Polymorphic Dispatch");
      Initialize (Cha, Zero_Key, Zero_Nonce);
      Initialize (Bbs, 11, 19, 3);
      Initialize (Rc4, [1 => 99]);
      Run_Polymorphic (Cha, "ChaCha20");
      Run_Polymorphic (Bbs, "BBS");
      Run_Polymorphic (Rc4, "RC4");
   end Test_Polymorphic_Dispatch;

   procedure Test_Unseeded_Generators is
      Cha : Cha_Cha_20_Generator;
      Bbs : Bbs_Generator;
      Rc4 : Rc4_Generator;
      Buf : Byte_Array (1 .. 1);
   begin
      Put_Line ("TEST 11 - Unseeded Generator Class-Wide Preconditions");
      begin
         Generate (Cha, Buf);
         Check ("ChaCha unseeded should fail", False);
      exception
         when Ada.Assertions.Assertion_Error => Check ("Caught ChaCha unseeded", True);
      end;
      begin
         Generate (Bbs, Buf);
         Check ("BBS unseeded should fail", False);
      exception
         when Ada.Assertions.Assertion_Error => Check ("Caught BBS unseeded", True);
      end;
      begin
         Generate (Rc4, Buf);
         Check ("RC4 unseeded should fail", False);
      exception
         when Ada.Assertions.Assertion_Error => Check ("Caught RC4 unseeded", True);
      end;
   end Test_Unseeded_Generators;

   procedure Test_ChaCha_Key_Independence is
      Gen1, Gen2 : Cha_Cha_20_Generator;
      Alt_Key    : constant Cha_Cha_Key := [1 => 1, others => 0];
      B1, B2     : Byte_Array (1 .. 64);
   begin
      Put_Line ("TEST 12 - ChaCha20 Key Independence");
      Initialize (Gen1, Zero_Key, Zero_Nonce);
      Initialize (Gen2, Alt_Key, Zero_Nonce);
      Generate (Gen1, B1);
      Generate (Gen2, B2);
      Check ("Byte 1 differs", B1 (1) /= B2 (1));
      Check ("Byte 32 differs", B1 (32) /= B2 (32));
      Check ("Byte 64 differs", B1 (64) /= B2 (64));
   end Test_ChaCha_Key_Independence;

   procedure Test_Large_Output_Stability is
      Cha : Cha_Cha_20_Generator;
      Bbs : Bbs_Generator;
      Rc4 : Rc4_Generator;
      B_C : Byte_Array (1 .. 5000);
      B_B : Byte_Array (1 .. 500);
      B_R : Byte_Array (1 .. 5000);
   begin
      Put_Line ("TEST 13 - Large Request Size Bounds Stability");
      Initialize (Cha, Zero_Key, Zero_Nonce);
      Generate (Cha, B_C);
      Check ("ChaCha handled 5000 bytes successfully", True);
      
      Initialize (Bbs, 11, 19, 3);
      Generate (Bbs, B_B);
      Check ("BBS handled 500 bytes successfully", True);
      
      Initialize (Rc4, [1 => 1]);
      Generate (Rc4, B_R);
      Check ("RC4 handled 5000 bytes successfully", True);
   end Test_Large_Output_Stability;

begin
   Test_ChaCha_Determinism;
   Test_ChaCha_Block_Crossing;
   Test_ChaCha_Nonce_Independence;
   Test_BBS_Determinism;
   Test_BBS_Large_Primes;
   Test_BBS_Invalid_P_Q_Congruence;
   Test_BBS_Invalid_Equality_And_Seed;
   Test_RC4_RFC_Vector;
   Test_RC4_Empty_Key_And_Determinism;
   Test_Polymorphic_Dispatch;
   Test_Unseeded_Generators;
   Test_ChaCha_Key_Independence;
   Test_Large_Output_Stability;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

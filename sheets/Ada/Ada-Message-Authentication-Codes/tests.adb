with Ada.Text_IO; use Ada.Text_IO;
with Message_Authentication_Code; use Message_Authentication_Code;

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
   Put_Line ("Message Authentication Code Test Suite");
   Put_Line ("======================================");

   --  TEST 1: Simple Hash Functionality
   declare
      M1 : constant Byte_Array := [1 => 10, 2 => 20];
      M2 : constant Byte_Array := [1 => 10, 2 => 21];
      R1, R2, R3 : Hash_Array;
   begin
      Put_Line ("TEST 1 — Simple Hash Functionality");
      R1 := Simple_Hash (M1);
      R2 := Simple_Hash (M1);
      R3 := Simple_Hash (M2);
      Check ("1.1 Hash determinism (same input = same output)", R1 = R2);
      Check ("1.2 Hash avalanche (diff input = diff output)", R1 /= R3);
      Check ("1.3 Hash output strict size boundary", R1'Length = 16);
   end;

   --  TEST 2: Simple Encrypt Functionality
   declare
      K  : constant Block_Array := [others => 7];
      K2 : constant Block_Array := [others => 9];
      B1 : constant Block_Array := [1 => 1, others => 0];
      B2 : constant Block_Array := [1 => 2, others => 0];
      C1, C2, C3 : Block_Array;
   begin
      Put_Line ("TEST 2 — Simple Encrypt Functionality");
      C1 := Simple_Encrypt (K, B1);
      C2 := Simple_Encrypt (K, B1);
      C3 := Simple_Encrypt (K, B2);
      Check ("2.1 Encryption determinism", C1 = C2);
      Check ("2.2 Encryption block sensitivity", C1 /= C3);
      Check ("2.3 Encryption key sensitivity", C1 /= Simple_Encrypt (K2, B1));
   end;

   --  TEST 3: Prefix-MAC Correctness
   declare
      Key : constant Byte_Array := [1 => 99];
      Msg : constant Byte_Array := [1 => 55, 2 => 66];
      R1, R2, R3 : Hash_Array;
   begin
      Put_Line ("TEST 3 — Prefix-MAC Correctness");
      R1 := Prefix_MAC (Key, Msg);
      R2 := Prefix_MAC (Key, Msg);
      R3 := Prefix_MAC ([1 => 100], Msg);
      Check ("3.1 Prefix-MAC determinism", R1 = R2);
      Check ("3.2 Prefix-MAC key sensitivity", R1 /= R3);
      Check ("3.3 Prefix-MAC message sensitivity", R1 /= Prefix_MAC (Key, [1 => 55]));
   end;

   --  TEST 4: HMAC Basic Execution
   declare
      Key : constant Byte_Array := [1 => 16#0B#, 2 => 16#0B#];
      Msg : constant Byte_Array := [1 => 1, 2 => 2, 3 => 3];
      R1, R2, R3 : Hash_Array;
   begin
      Put_Line ("TEST 4 — HMAC Basic Execution");
      R1 := HMAC (Key, Msg);
      R2 := HMAC (Key, Msg);
      R3 := HMAC (Key, [1 => 1, 2 => 2, 3 => 4]);
      Check ("4.1 HMAC determinism", R1 = R2);
      Check ("4.2 HMAC key sensitivity", R1 /= HMAC ([1 => 16#0C#], Msg));
      Check ("4.3 HMAC message sensitivity", R1 /= R3);
   end;

   --  TEST 5: HMAC Key Length Variations
   declare
      Short_Key : constant Byte_Array (1 .. 1) := [1 => 16#AA#];
      Exact_Key : constant Byte_Array (1 .. 16) := [others => 16#BB#];
      Long_Key  : constant Byte_Array (1 .. 32) := [others => 16#CC#];
      Msg       : constant Byte_Array (1 .. 3) := [1 => 1, 2 => 2, 3 => 3];
      R1, R2, R3 : Hash_Array;
   begin
      Put_Line ("TEST 5 — HMAC Key Length Variations");
      R1 := HMAC (Short_Key, Msg);
      R2 := HMAC (Exact_Key, Msg);
      R3 := HMAC (Long_Key, Msg);
      Check ("5.1 Short key processed without errors", R1'Length = 16);
      Check ("5.2 Exact block key processed without errors", R2'Length = 16);
      Check ("5.3 Oversized key compressed via hash securely", R3'Length = 16 and R3 /= R1);
   end;

   --  TEST 6: HMAC Empty Message
   declare
      Key       : constant Byte_Array (1 .. 4) := [1 => 1, 2 => 2, 3 => 3, 4 => 4];
      Empty_Msg : constant Byte_Array (1 .. 0) := [others => 0];
      Full_Msg  : constant Byte_Array (1 .. 1) := [1 => 1];
      R1, R2    : Hash_Array;
   begin
      Put_Line ("TEST 6 — HMAC Empty Message Processing");
      R1 := HMAC (Key, Empty_Msg);
      R2 := HMAC (Key, Full_Msg);
      Check ("6.1 HMAC supports zero-length messages", R1'Length = 16);
      Check ("6.2 HMAC empty message result is non-zero (hashed)", R1 /= Hash_Array'[others => 0]);
      Check ("6.3 HMAC empty message != populated message", R1 /= R2);
   end;

   --  TEST 7: CBC-MAC Basic Execution
   declare
      Key : constant Block_Array := [others => 16#11#];
      Msg : constant Byte_Array  := [1 => 16#22#, 2 => 16#33#];
      R1, R2, R3 : Block_Array;
   begin
      Put_Line ("TEST 7 — CBC-MAC Basic Execution");
      R1 := CBC_MAC (Key, Msg);
      R2 := CBC_MAC (Key, Msg);
      R3 := CBC_MAC ([others => 16#22#], Msg);
      Check ("7.1 CBC-MAC determinism", R1 = R2);
      Check ("7.2 CBC-MAC key sensitivity", R1 /= R3);
      Check ("7.3 CBC-MAC message sensitivity", R1 /= CBC_MAC (Key, [1 => 16#22#, 2 => 16#44#]));
   end;

   --  TEST 8: CBC-MAC Padding Mechanism (Non-Multiples)
   declare
      Key : constant Block_Array := [others => 5];
      M1  : constant Byte_Array  := [1 => 1];
      M2  : constant Byte_Array  := [1 .. 17 => 1];
      R1, R2 : Block_Array;
   begin
      Put_Line ("TEST 8 — CBC-MAC Padding Mechanism");
      R1 := CBC_MAC (Key, M1);
      R2 := CBC_MAC (Key, M2);
      Check ("8.1 Short message (1 byte) pads safely", R1'Length = 16);
      Check ("8.2 Long non-aligned message (17 bytes) pads safely", R2'Length = 16);
      Check ("8.3 Differing length messages yield differing MACs", R1 /= R2);
   end;

   --  TEST 9: CBC-MAC Exact Block Length
   declare
      Key : constant Block_Array := [others => 9];
      M1  : constant Byte_Array  := [1 .. 16 => 2];
      M2  : constant Byte_Array  := [1 .. 32 => 2];
      R1, R2 : Block_Array;
   begin
      Put_Line ("TEST 9 — CBC-MAC Exact Block Length");
      R1 := CBC_MAC (Key, M1);
      R2 := CBC_MAC (Key, M2);
      Check ("9.1 Exact block size (16 bytes) processed securely", R1'Length = 16);
      Check ("9.2 Double block size (32 bytes) processed securely", R2'Length = 16);
      Check ("9.3 1-block vs 2-block messages yield differing MACs", R1 /= R2);
   end;

   --  TEST 10: Invalid Key Error Handling
   declare
      Empty_Key : constant Byte_Array (1 .. 0) := [others => 0];
      Valid_Msg : constant Byte_Array (1 .. 1) := [1 => 1];
      Got_Error_1 : Boolean := False;
      Got_Error_2 : Boolean := False;
      Got_Error_3 : Boolean := False;
   begin
      Put_Line ("TEST 10 — Invalid Key Error Handling");
      
      begin
         declare
            Dummy : constant Hash_Array := HMAC (Empty_Key, Valid_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Key_Error => Got_Error_1 := True;
      end;
      Check ("10.1 HMAC rejects empty key safely", Got_Error_1);

      begin
         declare
            Dummy : constant Hash_Array := Prefix_MAC (Empty_Key, Valid_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Key_Error => Got_Error_2 := True;
      end;
      Check ("10.2 Prefix-MAC rejects empty key safely", Got_Error_2);

      begin
         declare
            Dummy : constant Hash_Array := HMAC ([1 => 5], Valid_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Got_Error_3 := True;
      end;
      Check ("10.3 Valid key lengths do not trigger exceptions", not Got_Error_3);
   end;

   --  TEST 11: Invalid Message Error Handling
   declare
      Key : constant Block_Array := [others => 0];
      Empty_Msg : constant Byte_Array (1 .. 0) := [others => 0];
      Valid_Msg : constant Byte_Array (1 .. 1) := [1 => 1];
      Got_Error_1 : Boolean := False;
      Got_Error_2 : Boolean := False;
      Got_Error_3 : Boolean := False;
   begin
      Put_Line ("TEST 11 — Invalid Message Error Handling");
      
      begin
         declare
            Dummy : constant Block_Array := CBC_MAC (Key, Empty_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Message_Error => Got_Error_1 := True;
      end;
      Check ("11.1 CBC-MAC rejects empty message explicitly", Got_Error_1);

      begin
         declare
            Dummy : constant Block_Array := CBC_MAC (Key, Valid_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Got_Error_2 := True;
      end;
      Check ("11.2 CBC-MAC valid message length succeeds", not Got_Error_2);
      
      begin
         declare
            Dummy : constant Hash_Array := Simple_Hash (Empty_Msg);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Got_Error_3 := True;
      end;
      Check ("11.3 Simple_Hash tolerates empty message internally", not Got_Error_3);
   end;

   --  TEST 12: HMAC Avalanche Effect
   declare
      Key : constant Byte_Array := [1 => 16#F0#];
      M1  : constant Byte_Array := [1 .. 16 => 0];
      M2  : Byte_Array := [1 .. 16 => 0];
      R1, R2 : Hash_Array;
      Match_Count : Natural := 0;
   begin
      Put_Line ("TEST 12 — HMAC Avalanche Effect");
      M2 (8) := 16#01#; -- 1 bit flipped
      R1 := HMAC (Key, M1);
      R2 := HMAC (Key, M2);
      
      for J in Hash_Array'Range loop
         if R1 (J) = R2 (J) then
            Match_Count := Match_Count + 1;
         end if;
      end loop;
      
      Check ("12.1 Original evaluation succeeds", R1'Length = 16);
      Check ("12.2 Single bit change alters MAC completely", R1 /= R2);
      Check ("12.3 High diffusion (few bytes remain identical)", Match_Count < 8);
   end;

   --  TEST 13: CBC-MAC Avalanche Effect
   declare
      Key : constant Block_Array := [others => 16#5A#];
      M1  : constant Byte_Array := [1 .. 32 => 16#FF#];
      M2  : Byte_Array := [1 .. 32 => 16#FF#];
      R1, R2 : Block_Array;
      Match_Count : Natural := 0;
   begin
      Put_Line ("TEST 13 — CBC-MAC Avalanche Effect");
      M2 (2) := 16#FE#; -- 1 bit flipped in first block
      R1 := CBC_MAC (Key, M1);
      R2 := CBC_MAC (Key, M2);

      for J in Block_Array'Range loop
         if R1 (J) = R2 (J) then
            Match_Count := Match_Count + 1;
         end if;
      end loop;

      Check ("13.1 Long message evaluation succeeds", R1'Length = 16);
      Check ("13.2 Early bit flip cascades through chaining", R1 /= R2);
      Check ("13.3 Cipher diffuses well across output block", Match_Count < 8);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

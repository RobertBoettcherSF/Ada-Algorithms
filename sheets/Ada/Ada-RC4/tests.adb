with Ada.Text_IO; use Ada.Text_IO;
with RC4; use RC4;

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

   -- Helper to convert strings to byte arrays for testing
   function To_Bytes (S : String) return Byte_Array is
      Arr : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         Arr (I - S'First + 1) := Character'Pos (S (I));
      end loop;
      return Arr;
   end To_Bytes;

   Ctx : Context;
begin
   Put_Line ("--- RC4 Validation Suite ---");

   -- TEST 1 — Standard Vector 1 (Key / Plaintext)
   Put_Line ("TEST 1 — Standard Vector 1 (Key / Plaintext)");
   declare
      Key_1 : constant Byte_Array := To_Bytes ("Key");
      Pt_1  : constant Byte_Array := To_Bytes ("Plaintext");
      Exp_1 : constant Byte_Array := [16#BB#, 16#F3#, 16#16#, 16#E8#, 16#D9#, 16#40#, 16#AF#, 16#0A#, 16#D3#];
      Res_1 : Byte_Array (Pt_1'Range);
   begin
      Initialize (Ctx, Key_1);
      Res_1 := Process (Ctx, Pt_1);
      Check ("1.1 Output length matches expected length", Res_1'Length = Exp_1'Length);
      Check ("1.2 Output matches expected RC4 ciphertext", Res_1 = Exp_1);
      Initialize (Ctx, Key_1);
      Check ("1.3 Decryption recovers identical plaintext", Process (Ctx, Res_1) = Pt_1);
   end;

   -- TEST 2 — Standard Vector 2 (Wiki / pedia)
   Put_Line ("TEST 2 — Standard Vector 2 (Wiki / pedia)");
   declare
      Key_2 : constant Byte_Array := To_Bytes ("Wiki");
      Pt_2  : constant Byte_Array := To_Bytes ("pedia");
      Exp_2 : constant Byte_Array := [16#10#, 16#21#, 16#BF#, 16#04#, 16#20#];
      Res_2 : Byte_Array (Pt_2'Range);
   begin
      Initialize (Ctx, Key_2);
      Res_2 := Process (Ctx, Pt_2);
      Check ("2.1 Length matches", Res_2'Length = Exp_2'Length);
      Check ("2.2 Ciphertext matches", Res_2 = Exp_2);
      Initialize (Ctx, Key_2);
      Check ("2.3 Decryption recovers plaintext", Process (Ctx, Res_2) = Pt_2);
   end;

   -- TEST 3 — Standard Vector 3 (Secret / Attack at dawn)
   Put_Line ("TEST 3 — Standard Vector 3 (Secret / Attack at dawn)");
   declare
      Key_3 : constant Byte_Array := To_Bytes ("Secret");
      Pt_3  : constant Byte_Array := To_Bytes ("Attack at dawn");
      -- Corrected hex corresponding directly to 45A01F645FC35B383552544B9BF5
      Exp_3 : constant Byte_Array := [16#45#, 16#A0#, 16#1F#, 16#64#, 16#5F#, 16#C3#, 16#5B#, 16#38#, 16#35#, 16#52#, 16#54#, 16#4B#, 16#9B#, 16#F5#];
      Res_3 : Byte_Array (Pt_3'Range);
   begin
      Initialize (Ctx, Key_3);
      Res_3 := Process (Ctx, Pt_3);
      Check ("3.1 Length matches", Res_3'Length = Exp_3'Length);
      Check ("3.2 Ciphertext matches", Res_3 = Exp_3);
      Initialize (Ctx, Key_3);
      Check ("3.3 Decryption recovers plaintext", Process (Ctx, Res_3) = Pt_3);
   end;

   -- TEST 4 — In-Place Processing Verification
   Put_Line ("TEST 4 — In-Place Processing Verification");
   declare
      Key  : constant Byte_Array := To_Bytes ("Key");
      Pt   : constant Byte_Array := To_Bytes ("Plaintext");
      Exp  : constant Byte_Array := [16#BB#, 16#F3#, 16#16#, 16#E8#, 16#D9#, 16#40#, 16#AF#, 16#0A#, 16#D3#];
      Data : Byte_Array := Pt;
   begin
      Initialize (Ctx, Key);
      Process_In_Place (Ctx, Data);
      Check ("4.1 In-place matches out-of-place functionality", Data = Exp);
      Check ("4.2 Data length remains unchanged after in-place processing", Data'Length = Pt'Length);
      Initialize (Ctx, Key);
      Process_In_Place (Ctx, Data);
      Check ("4.3 Double application securely recovers plaintext", Data = Pt);
   end;

   -- TEST 5 — Edge Case: Minimum Key Length (1 Byte)
   Put_Line ("TEST 5 — Edge Case: Minimum Key Length (1 Byte)");
   declare
      Min_Key : constant Byte_Array := [1 => 42];
      Pt      : constant Byte_Array := [1 .. 10 => 0];
      Res     : Byte_Array (Pt'Range);
   begin
      Initialize (Ctx, Min_Key);
      Res := Process (Ctx, Pt);
      Check ("5.1 Encryption handles 1-byte key perfectly", Res'Length = Pt'Length);
      Check ("5.2 First byte is properly scrambled", Res (Res'First) /= 0);
      Initialize (Ctx, Min_Key);
      Check ("5.3 Decryption handles 1-byte key perfectly", Process (Ctx, Res) = Pt);
   end;

   -- TEST 6 — Edge Case: Maximum Key Length (256 Bytes)
   Put_Line ("TEST 6 — Edge Case: Maximum Key Length (256 Bytes)");
   declare
      Max_Key : constant Byte_Array (1 .. 256) := [others => 16#AA#];
      Pt      : constant Byte_Array := [1 .. 10 => 0];
      Res     : Byte_Array (Pt'Range);
   begin
      Initialize (Ctx, Max_Key);
      Res := Process (Ctx, Pt);
      Check ("6.1 Encryption handles 256-byte key perfectly", Res'Length = Pt'Length);
      Check ("6.2 Stream scrambles effectively", Res (Res'First) /= 0);
      Initialize (Ctx, Max_Key);
      Check ("6.3 Decryption handles 256-byte key perfectly", Process (Ctx, Res) = Pt);
   end;

   -- TEST 7 — Edge Case: Empty Input Data Processing
   Put_Line ("TEST 7 — Edge Case: Empty Input Data Processing");
   declare
      Empty_Data : constant Byte_Array (1 .. 0) := [others => 0];
      Res        : Byte_Array (1 .. 0);
   begin
      Initialize (Ctx, To_Bytes("Key"));
      Res := Process (Ctx, Empty_Data);
      Check ("7.1 Process returns securely sized empty array", Res'Length = 0);
      
      declare
         Data_In_Place : Byte_Array (1 .. 0) := [others => 0];
      begin
         Process_In_Place (Ctx, Data_In_Place);
         Check ("7.2 Process_In_Place succeeds harmlessly on empty array", Data_In_Place'Length = 0);
      end;
      
      Initialize (Ctx, To_Bytes("Key"));
      Check ("7.3 Decryption maintains zero length", Process (Ctx, Res)'Length = 0);
   end;

   -- TEST 8 — Error Handling (Invalid Key Lengths)
   Put_Line ("TEST 8 — Error Handling (Invalid Key Lengths)");
   declare
      Empty_Key : constant Byte_Array (1 .. 0) := [others => 0];
      Long_Key  : constant Byte_Array (1 .. 257) := [others => 0];
      Raised_1, Raised_2, Raised_3 : Boolean := False;
   begin
      begin
         Initialize (Ctx, Empty_Key);
      exception
         when Invalid_Key_Length => Raised_1 := True;
         when others => null;
      end;
      Check ("8.1 Initialize correctly rejects 0-length key", Raised_1);

      begin
         Initialize_Drop (Ctx, Empty_Key, 768);
      exception
         when Invalid_Key_Length => Raised_2 := True;
         when others => null;
      end;
      Check ("8.2 Initialize_Drop correctly rejects 0-length key", Raised_2);

      begin
         Initialize (Ctx, Long_Key);
      exception
         when Invalid_Key_Length => Raised_3 := True;
         when others => null;
      end;
      Check ("8.3 Initialize correctly rejects >256-length key", Raised_3);
   end;

   -- TEST 9 — RC4-Drop Standard Functionality (Drop 768)
   Put_Line ("TEST 9 — RC4-Drop Standard Functionality (Drop 768)");
   declare
      Pt       : constant Byte_Array := [1 .. 5 => 0];
      Res_Drop : Byte_Array (Pt'Range);
      Res_Std  : Byte_Array (Pt'Range);
   begin
      Initialize_Drop (Ctx, To_Bytes("Key"), 768);
      Res_Drop := Process (Ctx, Pt);
      
      Initialize (Ctx, To_Bytes("Key"));
      Res_Std := Process (Ctx, Pt);
      
      Check ("9.1 RC4-Drop output differs heavily from standard RC4", Res_Drop /= Res_Std);
      Check ("9.2 RC4-Drop produces correct payload length", Res_Drop'Length = Pt'Length);
      
      Initialize_Drop (Ctx, To_Bytes("Key"), 768);
      Check ("9.3 RC4-Drop successfully decrypts dropped stream", Process (Ctx, Res_Drop) = Pt);
   end;

   -- TEST 10 — RC4-Drop Boundary (Drop 0 bytes)
   Put_Line ("TEST 10 — RC4-Drop Boundary (Drop 0 bytes)");
   declare
      Pt        : constant Byte_Array := [1 .. 10 => 16#FF#];
      Res_Drop0 : Byte_Array (Pt'Range);
      Res_Std   : Byte_Array (Pt'Range);
   begin
      Initialize_Drop (Ctx, To_Bytes("Key"), 0);
      Res_Drop0 := Process (Ctx, Pt);
      
      Initialize (Ctx, To_Bytes("Key"));
      Res_Std := Process (Ctx, Pt);
      
      Check ("10.1 RC4-Drop 0 identically matches standard initialization", Res_Drop0 = Res_Std);
      Check ("10.2 Cipher stream payload correctly generated", Res_Drop0'Length = Pt'Length);
      
      Initialize_Drop (Ctx, To_Bytes("Key"), 0);
      Check ("10.3 Decryption recovers standard equivalent stream", Process (Ctx, Res_Drop0) = Pt);
   end;

   -- TEST 11 — Long Data Stream & State Wrap-Around
   Put_Line ("TEST 11 — Long Data Stream & State Wrap-Around");
   declare
      Long_Pt : Byte_Array (1 .. 300);
      Res     : Byte_Array (1 .. 300);
   begin
      for I in Long_Pt'Range loop
         Long_Pt (I) := Byte (I mod 256);
      end loop;
      Initialize (Ctx, To_Bytes("Key"));
      Res := Process (Ctx, Long_Pt);
      
      Check ("11.1 Processes >256 bytes completely (state boundaries bypassed)", Res'Length = 300);
      Check ("11.2 Ciphertext significantly masks predictable input pattern", Res /= Long_Pt);
      
      Initialize (Ctx, To_Bytes("Key"));
      Check ("11.3 State indices securely wrap and recover exact data", Process (Ctx, Res) = Long_Pt);
   end;

   -- TEST 12 — Stream Continuity (Chunking)
   Put_Line ("TEST 12 — Stream Continuity (Chunking)");
   declare
      Pt        : constant Byte_Array := [1 .. 10 => 16#AA#];
      Res_Full  : Byte_Array (1 .. 10);
      Res_Part1 : Byte_Array (1 .. 5);
      Res_Part2 : Byte_Array (6 .. 10);
      Ctx2      : Context;
   begin
      Initialize (Ctx, To_Bytes("Key"));
      Res_Full := Process (Ctx, Pt);
      
      Initialize (Ctx2, To_Bytes("Key"));
      Res_Part1 := Process (Ctx2, Pt (1 .. 5));
      Res_Part2 := Process (Ctx2, Pt (6 .. 10));
      
      Check ("12.1 Segmented continuous stream processing matches full stream (Part 1)", Res_Full (1 .. 5) = Res_Part1);
      Check ("12.2 Segmented continuous stream processing matches full stream (Part 2)", Res_Full (6 .. 10) = Res_Part2);
      
      Initialize (Ctx, To_Bytes("Key"));
      declare
         Rec_Pt1 : constant Byte_Array := Process (Ctx, Res_Part1);
         Rec_Pt2 : constant Byte_Array := Process (Ctx, Res_Part2);
      begin
         Check ("12.3 Decrypting continuously in chunks identically recovers parts", Rec_Pt1 = Pt (1 .. 5) and Rec_Pt2 = Pt (6 .. 10));
      end;
   end;

   -- TEST 13 — Manual PRGA API Interaction
   Put_Line ("TEST 13 — Manual PRGA API Interaction");
   declare
      Pt       : constant Byte_Array (1 .. 5) := [1, 2, 3, 4, 5];
      Res_Proc : Byte_Array (1 .. 5);
      Res_Man  : Byte_Array (1 .. 5);
      K_Stream : Byte;
   begin
      Initialize (Ctx, To_Bytes("Key"));
      Res_Proc := Process (Ctx, Pt);
      
      Initialize (Ctx, To_Bytes("Key"));
      for I in Pt'Range loop
         K_Stream := Next_Byte (Ctx);
         Res_Man (I) := Pt (I) xor K_Stream;
      end loop;
      
      Check ("13.1 Manual Next_Byte byte-by-byte XOR precisely duplicates Process function", Res_Proc = Res_Man);
      Check ("13.2 Next_Byte stream emits strictly correct sequence lengths", Res_Man'Length = 5);
      
      Initialize (Ctx, To_Bytes("Key"));
      declare
         Dec_Man : Byte_Array (1 .. 5);
      begin
         for I in Res_Man'Range loop
            K_Stream := Next_Byte (Ctx);
            Dec_Man (I) := Res_Man (I) xor K_Stream;
         end loop;
         Check ("13.3 Manual decryption with Next_Byte securely recovers plaintext", Dec_Man = Pt);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

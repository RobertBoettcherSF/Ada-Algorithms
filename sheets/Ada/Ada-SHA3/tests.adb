with Ada.Text_IO; use Ada.Text_IO;
with SHA3;        use SHA3;

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

   --  Helper: convert Hex string to Byte_Array for assertions
   function From_Hex (Hex : String) return Byte_Array is
      function Hex_Val (C : Character) return Byte is
      begin
         case C is
            when '0' .. '9' => return Byte (Character'Pos (C) - Character'Pos ('0'));
            when 'A' .. 'F' => return Byte (Character'Pos (C) - Character'Pos ('A') + 10);
            when 'a' .. 'f' => return Byte (Character'Pos (C) - Character'Pos ('a') + 10);
            when others => return 0;
         end case;
      end Hex_Val;
      Result : Byte_Array (1 .. Hex'Length / 2);
   begin
      for I in Result'Range loop
         Result (I) := Hex_Val (Hex (Hex'First + (I - 1) * 2)) * 16 +
                       Hex_Val (Hex (Hex'First + (I - 1) * 2 + 1));
      end loop;
      return Result;
   end From_Hex;

   --  Helper: convert ASCII String to Byte_Array
   function To_Bytes (S : String) return Byte_Array is
      Result : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         Result (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return Result;
   end To_Bytes;

   Empty_Msg : constant Byte_Array (1 .. 0) := [];

   procedure Run_Tests is
      Out_224 : Hash_224;
      Out_256 : Hash_256;
      Out_384 : Hash_384;
      Out_512 : Hash_512;
      Dynamic : Byte_Array (1 .. 32);
      Zero_Ar : Byte_Array (1 .. 0);
   begin
      -- TEST 1 — SHA3-224 Empty Edge Case
      Put_Line ("TEST 1 — SHA3-224 Empty Message");
      Out_224 := SHA3_224 (Empty_Msg);
      Check ("1.1 Length constraint met", Out_224'Length = 28);
      Check ("1.2 First bound check", Out_224'First = 1);
      Check ("1.3 Matches NIST empty vector",
             Byte_Array (Out_224) = From_Hex ("6B4E03423667DBB73B6E15454F0EB1ABD4597F9A1B078E3F5B5A6BC7"));

      -- TEST 2 — SHA3-256 Empty Edge Case
      Put_Line ("TEST 2 — SHA3-256 Empty Message");
      Out_256 := SHA3_256 (Empty_Msg);
      Check ("2.1 Length constraint met", Out_256'Length = 32);
      Check ("2.2 Not a zero array", Out_256 (1) /= 0);
      Check ("2.3 Matches NIST empty vector",
             Byte_Array (Out_256) = From_Hex ("A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A"));

      -- TEST 3 — SHA3-384 Empty Edge Case
      Put_Line ("TEST 3 — SHA3-384 Empty Message");
      Out_384 := SHA3_384 (Empty_Msg);
      Check ("3.1 Length constraint met", Out_384'Length = 48);
      Check ("3.2 Correct domain hash block size", Out_384'Last = 48);
      Check ("3.3 Matches NIST empty vector",
             Byte_Array (Out_384) = From_Hex ("0C63A75B845E4F7D01107D852E4C2485C51A50AAAA94FC61995E71BBEE983A2AC3713831264ADB47FB6BD1E058D5F004"));

      -- TEST 4 — SHA3-512 Empty Edge Case
      Put_Line ("TEST 4 — SHA3-512 Empty Message");
      Out_512 := SHA3_512 (Empty_Msg);
      Check ("4.1 Length constraint met", Out_512'Length = 64);
      Check ("4.2 First bound is strictly 1", Out_512'First = 1);
      Check ("4.3 Matches NIST empty vector",
             Byte_Array (Out_512) = From_Hex ("A69F73CCA23A9AC5C8B567DC185A756E97C982164FE25859E0D1DCC1475C80A615B2123AF1F5F94C11E3E9402C3AC558F500199D95B6D3E301758586281DCD26"));

      -- TEST 5 — SHAKE-128 Empty Message (16 bytes out)
      Put_Line ("TEST 5 — SHAKE-128 (16B)");
      declare
         Out_16 : constant Byte_Array := SHAKE_128 (Empty_Msg, 16);
      begin
         Check ("5.1 Variable output length satisfied", Out_16'Length = 16);
         Check ("5.2 First bound is 1", Out_16'First = 1);
         Check ("5.3 Prefix matches NIST vector",
                Out_16 = From_Hex ("7F9C2BA4E88F827D616045507605853E"));
      end;

      -- TEST 6 — SHAKE-128 Empty Message (32 bytes out)
      Put_Line ("TEST 6 — SHAKE-128 (32B)");
      Dynamic := SHAKE_128 (Empty_Msg, 32);
      Check ("6.1 Length extended", Dynamic'Length = 32);
      Check ("6.2 Check dynamic bounds", Dynamic'Last = 32);
      Check ("6.3 XOF prefix invariant strictly maintained",
             Dynamic (1 .. 16) = SHAKE_128 (Empty_Msg, 16));

      -- TEST 7 — SHAKE-256 Empty Message (32 bytes out)
      Put_Line ("TEST 7 — SHAKE-256 (32B)");
      Dynamic := SHAKE_256 (Empty_Msg, 32);
      Check ("7.1 Domain separation differs from SHAKE-128", Dynamic /= SHAKE_128 (Empty_Msg, 32));
      Check ("7.2 Length satisfied", Dynamic'Length = 32);
      Check ("7.3 XOF prefix invariant strictly maintained",
             Dynamic (1 .. 16) = SHAKE_256 (Empty_Msg, 16));

      -- TEST 8 — SHA3-224 "abc" Input
      Put_Line ("TEST 8 — SHA3-224 ""abc""");
      Out_224 := SHA3_224 (To_Bytes ("abc"));
      Check ("8.1 Hashed length stable", Out_224'Length = 28);
      Check ("8.2 Not equal to empty hash", Byte_Array (Out_224) /= SHA3_224 (Empty_Msg));
      Check ("8.3 Matches NIST vector",
             Byte_Array (Out_224) = From_Hex ("E642824C3F8CF24AD09234EE7D3C766FC9A3A5168D0C94AD73B46FDF"));

      -- TEST 9 — SHA3-256 "abc" Input
      Put_Line ("TEST 9 — SHA3-256 ""abc""");
      Out_256 := SHA3_256 (To_Bytes ("abc"));
      Check ("9.1 Hashed length stable", Out_256'Length = 32);
      Check ("9.2 Independent of other hash types", Byte_Array (Out_256) (1 .. 28) /= Byte_Array (Out_224));
      Check ("9.3 Matches NIST vector",
             Byte_Array (Out_256) = From_Hex ("3A985DA74FE225B2045C172D6BD390BD855F086E3E9D525B46BFE24511431532"));

      -- TEST 10 — SHA3-384 "abc" Input
      Put_Line ("TEST 10 — SHA3-384 ""abc""");
      Out_384 := SHA3_384 (To_Bytes ("abc"));
      Check ("10.1 Check domain width", Out_384'Length = 48);
      Check ("10.2 Consistent length behavior", Out_384'Last = 48);
      Check ("10.3 Matches NIST vector",
             Byte_Array (Out_384) = From_Hex ("EC01498288516FC926459F58E2C6AD8DF9B473CB0FC08C2596DA7CF0E49BE4B298D88CEA927AC7F539F1EDF228376D25"));

      -- TEST 11 — SHA3-512 "abc" Input
      Put_Line ("TEST 11 — SHA3-512 ""abc""");
      Out_512 := SHA3_512 (To_Bytes ("abc"));
      Check ("11.1 Maximum security length", Out_512'Length = 64);
      Check ("11.2 Check state uniqueness", Out_512 (1) /= Out_512 (2));
      Check ("11.3 Matches NIST vector",
             Byte_Array (Out_512) = From_Hex ("B751850B1A57168A5693CD924B6B096E08F621827444F70D884F5D0240D2712E10E116E9192AF3C91A7EC57647E3934057340B4CF408D5A56592F8274EEC53F0"));

      -- TEST 12 — Long Absorb Input
      Put_Line ("TEST 12 — Multi-block Absorb");
      declare
         Long_Input : constant Byte_Array (1 .. 200) := [others => 16#41#]; -- 200 'A's, exceeds 136-byte rate
      begin
         Out_256 := SHA3_256 (Long_Input);
         Check ("12.1 Survives multi-block absorb without crash", Out_256'Length = 32);
         Check ("12.2 Output differs from empty block", Byte_Array (Out_256) /= SHA3_256 (Empty_Msg));
         Check ("12.3 Output deterministic", Out_256 = SHA3_256 (Long_Input));
      end;

      -- TEST 13 — Long Squeeze Output (XOF Mode)
      Put_Line ("TEST 13 — Multi-block Squeeze");
      declare
         Long_Out : constant Byte_Array := SHAKE_128 (To_Bytes ("Test"), 400); -- Rate is 168, forces >2 squeeze loops
      begin
         Check ("13.1 Generates expected massive output length", Long_Out'Length = 400);
         Check ("13.2 Start is non-zero", Long_Out (1) /= 0 or Long_Out (2) /= 0);
         Check ("13.3 End of stream is stable", Long_Out (399) = SHAKE_128 (To_Bytes ("Test"), 400)(399));
      end;

      -- TEST 14 — Edge Case: Zero Length Request
      Put_Line ("TEST 14 — Zero-Length Squeeze");
      Zero_Ar := SHAKE_256 (To_Bytes ("abc"), 0);
      Check ("14.1 Zero elements returned", Zero_Ar'Length = 0);
      Check ("14.2 Bounds strictly inverted (First > Last)", Zero_Ar'First > Zero_Ar'Last);
      Check ("14.3 No memory exception thrown", True);
   end Run_Tests;

begin
   Run_Tests;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

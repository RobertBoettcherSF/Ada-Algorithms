with Ada.Text_IO; use Ada.Text_IO;
with Hamming_Code; use Hamming_Code;

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

   --  Helper to compare Bit_Arrays gracefully regardless of underlying index bounds
   function Eq (A, B : Bit_Array) return Boolean is
   begin
      if A'Length /= B'Length then 
         return False; 
      end if;
      for I in 0 .. A'Length - 1 loop
         if A (A'First + I) /= B (B'First + I) then 
            return False; 
         end if;
      end loop;
      return True;
   end Eq;

begin
   Put_Line ("Starting Hamming Code Test Suite...");
   Put_Line ("-----------------------------------");

   --  TEST 1: Standard Hamming Encode(7,4) Validation
   Put_Line ("TEST 1 - Standard Hamming Encode(7,4)");
   declare
      Data     : constant Bit_Array := [1, 0, 1, 1];
      Code     : constant Bit_Array := Encode (Data);
      Expected : constant Bit_Array := [0, 1, 1, 0, 0, 1, 1];
   begin
      Check ("1.1 Encode produces correct length (7 bits)", Code'Length = 7);
      Check ("1.2 Encode produces exact expected bit sequence", Eq (Code, Expected));
      Check ("1.3 Parity bits correctly established", Code (1) = 0 and Code (2) = 1 and Code (4) = 0);
   end;

   --  TEST 2: Standard Hamming Decode(7,4) Clean State
   Put_Line ("TEST 2 - Standard Hamming Decode(7,4) No Error");
   declare
      Code          : constant Bit_Array := [0, 1, 1, 0, 0, 1, 1];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode (Code, 4, Data, Status);
      Check ("2.1 Decode identifies No_Error", Status = No_Error);
      Check ("2.2 Procedural decode extracts pure data", Eq (Data, Expected_Data));
      Check ("2.3 Functional decode extracts pure data", Eq (Decode (Code, 4), Expected_Data));
   end;

   --  TEST 3: Standard Hamming Decode(7,4) - Single Data Bit Corruption
   Put_Line ("TEST 3 - Standard Hamming Decode(7,4) Single Data Error");
   declare
      --  Original: 0, 1, 1, 0, 0, 1, 1 -> Fliping bit 6 (Data 3)
      Code          : constant Bit_Array := [0, 1, 1, 0, 0, 0, 1];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode (Code, 4, Data, Status);
      Check ("3.1 Decode detects Single_Error_Corrected", Status = Single_Error_Corrected);
      Check ("3.2 Data repaired and correctly extracted", Eq (Data, Expected_Data));
      Check ("3.3 Functional API transparently corrects", Eq (Decode (Code, 4), Expected_Data));
   end;

   --  TEST 4: Standard Hamming Decode(7,4) - Single Parity Bit Corruption
   Put_Line ("TEST 4 - Standard Hamming Decode(7,4) Single Parity Error");
   declare
      --  Original: 0, 1, 1, 0, 0, 1, 1 -> Fliping bit 2 (Parity 2)
      Code          : constant Bit_Array := [0, 0, 1, 0, 0, 1, 1];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode (Code, 4, Data, Status);
      Check ("4.1 Decode detects Single_Error_Corrected", Status = Single_Error_Corrected);
      Check ("4.2 Data left strictly intact", Eq (Data, Expected_Data));
      Check ("4.3 Functional API handles gracefully", Eq (Decode (Code, 4), Expected_Data));
   end;

   --  TEST 5: Standard Hamming Encode(15,11) Generalized Extension
   Put_Line ("TEST 5 - Standard Hamming Encode(15,11)");
   declare
      Data : constant Bit_Array := [1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1];
      Code : constant Bit_Array := Encode (Data);
   begin
      Check ("5.1 Encode dynamically provisions 15 bits", Code'Length = 15);
      Check ("5.2 Decode flawlessly unwraps larger word", Eq (Decode (Code, 11), Data));
      Check ("5.3 Bound equation matches mathematical length", Encoded_Length (11) = 15);
   end;

   --  TEST 6: Extended Hamming Encode(8,4) SECDED
   Put_Line ("TEST 6 - Extended Hamming Encode(8,4)");
   declare
      Data     : constant Bit_Array := [1, 0, 1, 1];
      Code     : constant Bit_Array := Encode_Extended (Data);
      --  Standard code is 0110011 (sum is 4 -> parity 0). Extends to 01100110.
      Expected : constant Bit_Array := [0, 1, 1, 0, 0, 1, 1, 0];
   begin
      Check ("6.1 Extended encode allocates +1 bit length (8)", Code'Length = 8);
      Check ("6.2 Appends parity accurately matching expected", Eq (Code, Expected));
      Check ("6.3 Overall parity block confirms as 0", Code (Code'Last) = 0);
   end;

   --  TEST 7: Extended Hamming Decode(8,4) SECDED Clean State
   Put_Line ("TEST 7 - Extended Hamming Decode(8,4) No Error");
   declare
      Code          : constant Bit_Array := [0, 1, 1, 0, 0, 1, 1, 0];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode_Extended (Code, 4, Data, Status);
      Check ("7.1 Ext Decode identifies No_Error", Status = No_Error);
      Check ("7.2 Ext Procedural decode extracts pure data", Eq (Data, Expected_Data));
      Check ("7.3 Ext Functional decode extracts pure data", Eq (Decode_Extended (Code, 4), Expected_Data));
   end;

   --  TEST 8: Extended Hamming Decode(8,4) - Single Data Bit Corruption
   Put_Line ("TEST 8 - Extended Hamming Decode(8,4) Single Data Error");
   declare
      --  Original: 01100110 -> Fliping bit 3 (Data 1)
      Code          : constant Bit_Array := [0, 1, 0, 0, 0, 1, 1, 0];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode_Extended (Code, 4, Data, Status);
      Check ("8.1 Correctly detects as single error in SECDED", Status = Single_Error_Corrected);
      Check ("8.2 Data successfully isolated and repaired", Eq (Data, Expected_Data));
      Check ("8.3 Functional version executes correction seamlessly", Eq (Decode_Extended (Code, 4), Expected_Data));
   end;

   --  TEST 9: Extended Hamming Decode(8,4) - Overall Parity Bit Corruption
   Put_Line ("TEST 9 - Extended Hamming Decode(8,4) Single Overall Parity Error");
   declare
      --  Original: 01100110 -> Fliping bit 8 (Overall Parity itself)
      Code          : constant Bit_Array := [0, 1, 1, 0, 0, 1, 1, 1];
      Expected_Data : constant Bit_Array := [1, 0, 1, 1];
      Data          : Bit_Array (1 .. 4);
      Status        : Error_Status;
   begin
      Decode_Extended (Code, 4, Data, Status);
      Check ("9.1 Isolates single error solely inside the parity bit", Status = Single_Error_Corrected);
      Check ("9.2 Data extracted perfectly untouched", Eq (Data, Expected_Data));
      Check ("9.3 Functional decode allows this correction", Eq (Decode_Extended (Code, 4), Expected_Data));
   end;

   --  TEST 10: Extended Hamming Decode(8,4) - Double Error Detection!
   Put_Line ("TEST 10 - Extended Hamming Decode(8,4) Double Error Detection");
   declare
      --  Original: 01100110 -> Flipping bits 3 and 6
      Code   : constant Bit_Array := [0, 1, 0, 0, 0, 0, 1, 0];
      Data   : Bit_Array (1 .. 4);
      pragma Unreferenced (Data);
      Status : Error_Status;
   begin
      Decode_Extended (Code, 4, Data, Status);
      Check ("10.1 Gracefully rejects silently bypassing 2 errors", Status = Double_Error_Detected);
      Check ("10.2 Distinctly identifies failure separate from uncorrectable anomalies", Status /= Uncorrectable_Error);
      Check ("10.3 Avoids false positive corrections", Status /= Single_Error_Corrected);
   end;

   --  TEST 11: Edge Case - Single Bit Data
   Put_Line ("TEST 11 - Edge Case (Data length 1)");
   declare
      Data     : constant Bit_Array (1 .. 1) := [1 => 1];
      Code     : constant Bit_Array := Encode (Data);
      --  M=2, N=3. Encodes as triple repetition. P1=1, P2=1, D1=1.
      Expected : constant Bit_Array := [1, 1, 1];
   begin
      Check ("11.1 Bound scales perfectly down to M=2 for N=3", Code'Length = 3);
      Check ("11.2 Result acts precisely as a triple repetition code", Eq (Code, Expected));
      Check ("11.3 Extended variants account correctly (+1 bit)", Extended_Encoded_Length (1) = 4);
   end;

   --  TEST 12: Exception Handling - Standard Uncorrectable Block
   Put_Line ("TEST 12 - Exception Handling (Standard Uncorrectable Block)");
   declare
      --  A 5-bit code where N=5 (Data_Length = 2). Create syndrome = 6 (out of bounds).
      --  We can force this manually.
      Code_Err         : constant Bit_Array (1 .. 5) := [0, 1, 0, 1, 0];
      Status           : Error_Status;
      Data             : Bit_Array (1 .. 2);
      pragma Unreferenced (Data);
      Exception_Raised : Boolean := False;
   begin
      Decode (Code_Err, 2, Data, Status);
      Check ("12.1 Procedure returns safe Uncorrectable_Error enum", Status = Uncorrectable_Error);
      begin
         declare
            Dummy : constant Bit_Array := Decode (Code_Err, 2);
         begin
            Check ("12.X Dummy length (Should Not Fire)", Dummy'Length > 0);
         end;
      exception
         when Hamming_Error => 
            Exception_Raised := True;
      end;
      Check ("12.2 Functional decode correctly traps and raises exception", Exception_Raised);
      Check ("12.3 Status distinct from SECDED double error detection", Status /= Double_Error_Detected);
   end;

   --  TEST 13: Exception Handling - Extended SECDED Double Error
   Put_Line ("TEST 13 - Exception Handling (Extended SECDED Double Error)");
   declare
      --  Utilizing the double error block from Test 10
      Code             : constant Bit_Array := [0, 1, 0, 0, 0, 0, 1, 0];
      Exception_Raised : Boolean := False;
   begin
      Check ("13.1 Invalid block maintains SECDED valid length (8)", Code'Length = 8);
      begin
         declare
            Dummy : constant Bit_Array := Decode_Extended (Code, 4);
         begin
            Check ("13.X Dummy length (Should Not Fire)", Dummy'Length > 0);
         end;
      exception
         when Hamming_Error => 
            Exception_Raised := True;
      end;
      Check ("13.2 Functional wrapper strictly refuses to return corrupt data", Exception_Raised);
      Check ("13.3 Double check error setup remains parity-correct (even parity)", Code (Code'Last) = 0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Warnings (Off);
   pragma Assert (Fail_Count = 0, "Some tests failed during validation.");
   pragma Warnings (On);
end Tests;

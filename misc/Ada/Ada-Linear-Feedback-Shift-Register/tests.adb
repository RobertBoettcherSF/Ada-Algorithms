with Ada.Text_IO; use Ada.Text_IO;
with System.Assertions;
with Linear_Feedback_Shift_Register; use Linear_Feedback_Shift_Register;

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

   -- TEST PROCEDURES

   procedure Test_1_Init_Fibonacci is
      Engine : LFSR_Engine;
   begin
      Put_Line ("TEST 1 - Fibonacci Initialization");
      Initialize (Engine, Fibonacci, 4, 1, 9);
      Check ("1.1 Variant is Fibonacci", Get_Variant (Engine) = Fibonacci);
      Check ("1.2 Length is 4", Get_Length (Engine) = 4);
      Check ("1.3 State matches seed", Get_State (Engine) = 1);
      Check ("1.4 Taps map perfectly", Get_Taps (Engine) = 9);
   end Test_1_Init_Fibonacci;

   procedure Test_2_Init_Galois is
      Engine : LFSR_Engine;
   begin
      Put_Line ("TEST 2 - Galois Initialization");
      Initialize (Engine, Galois, 16, 16#ACE1#, 16#B400#);
      Check ("2.1 Variant is Galois", Get_Variant (Engine) = Galois);
      Check ("2.2 Length is 16", Get_Length (Engine) = 16);
      Check ("2.3 State matches hex seed", Get_State (Engine) = 16#ACE1#);
   end Test_2_Init_Galois;

   procedure Test_3_Exception_On_Zero_Seed is
      Engine : LFSR_Engine;
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 3 - Invalid Zero Seed Setup");
      begin
         Initialize (Engine, Fibonacci, 8, 0, 16#8E#);
      exception
         when System.Assertions.Assert_Failure | Invalid_State_Error =>
            Caught := True;
      end;
      Check ("3.1 Exception caught when seeding with 0", Caught);
   end Test_3_Exception_On_Zero_Seed;

   procedure Test_4_Exception_Seed_Out_Of_Bounds is
      Engine : LFSR_Engine;
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 4 - Seed Out of Bounds");
      begin
         Initialize (Engine, Galois, 4, 16, 9); -- 16 requires 5 bits
      exception
         when System.Assertions.Assert_Failure | Invalid_State_Error =>
            Caught := True;
      end;
      Check ("4.1 Exception caught on oversized seed", Caught);
   end Test_4_Exception_Seed_Out_Of_Bounds;

   procedure Test_5_Exception_Taps_Out_Of_Bounds is
      Engine : LFSR_Engine;
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 5 - Taps Out of Bounds");
      begin
         Initialize (Engine, Galois, 4, 1, 32);
      exception
         when System.Assertions.Assert_Failure | Invalid_State_Error =>
            Caught := True;
      end;
      Check ("5.1 Exception caught on oversized taps mask", Caught);
   end Test_5_Exception_Taps_Out_Of_Bounds;

   procedure Test_6_Fibonacci_Period is
      Engine : LFSR_Engine;
      Seed   : constant Register_Value := 1;
      Output : Bit;
      Ones   : Natural := 0;
      Zeros  : Natural := 0;
   begin
      Put_Line ("TEST 6 - Fibonacci Maximal Period (4-bit)");
      Initialize (Engine, Fibonacci, 4, Seed, 9);
      for Dummy in 1 .. 15 loop
         pragma Unreferenced (Dummy);
         Next_Bit (Engine, Output);
         if Output = 1 then
            Ones := Ones + 1;
         else
            Zeros := Zeros + 1;
         end if;
      end loop;
      Check ("6.1 Returns to initial seed after 2^n - 1 steps", Get_State (Engine) = Seed);
      Check ("6.2 Sequence contains exact 2^(n-1) ones (8)", Ones = 8);
      Check ("6.3 Sequence contains exact 2^(n-1)-1 zeros (7)", Zeros = 7);
   end Test_6_Fibonacci_Period;

   procedure Test_7_Galois_Period is
      Engine : LFSR_Engine;
      Seed   : constant Register_Value := 1;
      Output : Bit;
      Ones   : Natural := 0;
      Zeros  : Natural := 0;
   begin
      Put_Line ("TEST 7 - Galois Maximal Period (4-bit)");
      Initialize (Engine, Galois, 4, Seed, 9);
      for Dummy in 1 .. 15 loop
         pragma Unreferenced (Dummy);
         Next_Bit (Engine, Output);
         if Output = 1 then
            Ones := Ones + 1;
         else
            Zeros := Zeros + 1;
         end if;
      end loop;
      Check ("7.1 Returns to initial seed after 2^n - 1 steps", Get_State (Engine) = Seed);
      Check ("7.2 Sequence contains exact 2^(n-1) ones (8)", Ones = 8);
      Check ("7.3 Sequence contains exact 2^(n-1)-1 zeros (7)", Zeros = 7);
   end Test_7_Galois_Period;

   procedure Test_8_Parity_Function is
   begin
      Put_Line ("TEST 8 - Parity Calculation Correctness");
      Check ("8.1 Parity of 0 is 0", Parity (0) = 0);
      Check ("8.2 Parity of 1 is 1", Parity (1) = 1);
      Check ("8.3 Parity of 3 is 0", Parity (3) = 0);
      Check ("8.4 Parity of 255 (8 bits) is 0", Parity (16#FF#) = 0);
      Check ("8.5 Parity of 170 (10101010) is 0", Parity (16#AA#) = 0);
      Check ("8.6 Parity of 171 (10101011) is 1", Parity (16#AB#) = 1);
   end Test_8_Parity_Function;

   procedure Test_9_Next_Bits is
      Engine : LFSR_Engine;
      Extracted : Register_Value;
   begin
      Put_Line ("TEST 9 - Extracting Multiple Bits");
      Initialize (Engine, Galois, 4, 1, 9);
      -- The first 4 output bits of this Galois configuration are 1, 1, 1, 1 (see period math)
      Extracted := Next_Bits (Engine, 4);
      Check ("9.1 Next_Bits extracts expected pattern (1111 binary = 15)", Extracted = 15);
   end Test_9_Next_Bits;

   procedure Test_10_Fibonacci_Sequence is
      Engine : LFSR_Engine;
      Output : Bit;
   begin
      Put_Line ("TEST 10 - Fibonacci Step-by-Step State");
      Initialize (Engine, Fibonacci, 4, 1, 9);
      Step_Fibonacci (Engine, Output);
      Check ("10.1 Step 1 State = 8", Get_State (Engine) = 8);
      Check ("10.2 Step 1 Output = 1", Output = 1);
      Step_Fibonacci (Engine, Output);
      Check ("10.3 Step 2 State = 12", Get_State (Engine) = 12);
      Check ("10.4 Step 2 Output = 0", Output = 0);
   end Test_10_Fibonacci_Sequence;

   procedure Test_11_Galois_Sequence is
      Engine : LFSR_Engine;
      Output : Bit;
   begin
      Put_Line ("TEST 11 - Galois Step-by-Step State");
      Initialize (Engine, Galois, 4, 1, 9);
      Step_Galois (Engine, Output);
      Check ("11.1 Step 1 State = 9", Get_State (Engine) = 9);
      Check ("11.2 Step 1 Output = 1", Output = 1);
      Step_Galois (Engine, Output);
      Check ("11.3 Step 2 State = 13", Get_State (Engine) = 13);
      Check ("11.4 Step 2 Output = 1", Output = 1);
   end Test_11_Galois_Sequence;

   procedure Test_12_64_Bit_Boundary is
      Engine : LFSR_Engine;
      Output : Bit;
   begin
      Put_Line ("TEST 12 - 64-Bit Boundary Setup");
      -- Initialize a 64-bit Galois LFSR with maximum unsigned 64 value
      Initialize (Engine, Galois, 64, 16#FFFF_FFFF_FFFF_FFFF#, 16#D800_0000_0000_0000#);
      Check ("12.1 Accepted 64-bit parameters safely", Get_Length (Engine) = 64);
      Next_Bit (Engine, Output);
      Check ("12.2 Single step operates correctly", Get_State (Engine) /= 16#FFFF_FFFF_FFFF_FFFF#);
   end Test_12_64_Bit_Boundary;

   procedure Test_13_Variant_Precondition is
      Engine : LFSR_Engine;
      Output : Bit;
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 13 - Contract Enforcements on Variants");
      Initialize (Engine, Galois, 4, 1, 9);
      begin
         -- Attempting to run Fibonacci step on a Galois engine
         Step_Fibonacci (Engine, Output);
      exception
         when System.Assertions.Assert_Failure =>
            Caught := True;
      end;
      Check ("13.1 Assert_Failure caught when mixing variant routines", Caught);
   end Test_13_Variant_Precondition;

   procedure Test_14_Extract_64_Bits is
      Engine : LFSR_Engine;
      Val    : Register_Value;
   begin
      Put_Line ("TEST 14 - Full 64-Bit Extraction");
      Initialize (Engine, Fibonacci, 16, 16#ACE1#, 16#B400#);
      Val := Next_Bits (Engine, 64);
      Check ("14.1 Extraction of 64 bits complete without bounds errors", Val > 0);
   end Test_14_Extract_64_Bits;

begin
   Test_1_Init_Fibonacci;
   Test_2_Init_Galois;
   Test_3_Exception_On_Zero_Seed;
   Test_4_Exception_Seed_Out_Of_Bounds;
   Test_5_Exception_Taps_Out_Of_Bounds;
   Test_6_Fibonacci_Period;
   Test_7_Galois_Period;
   Test_8_Parity_Function;
   Test_9_Next_Bits;
   Test_10_Fibonacci_Sequence;
   Test_11_Galois_Sequence;
   Test_12_64_Bit_Boundary;
   Test_13_Variant_Precondition;
   Test_14_Extract_64_Bits;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

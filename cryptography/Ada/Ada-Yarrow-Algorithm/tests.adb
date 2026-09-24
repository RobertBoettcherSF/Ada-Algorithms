with Ada.Text_IO; use Ada.Text_IO;
with Yarrow; use Yarrow;

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
   Put_Line ("Beginning Yarrow Core Component Verification...");
   Put_Line ("===============================================");

   -- TEST 1: System Initialization State
   declare
      Ctx : Context;
   begin
      Put_Line ("TEST 1 — System Initialization");
      Check ("1.1 Uninitialized by default", not Is_Initialized (Ctx));
      Initialize (Ctx);
      Check ("1.2 Initialized after procedure", Is_Initialized (Ctx));
      Check ("1.3 Buffer starts empty", Get_Block_Buffer_Index (Ctx) = 0);
      Check ("1.4 Clean entropy pools", Get_Fast_Entropy (Ctx, 0) = 0);
   end;

   -- TEST 2: Entropy Input (Fast Pool Priority)
   declare
      Ctx : Context;
      Env_Data : constant Byte_Array (1 .. 4) := [1, 2, 3, 4];
   begin
      Put_Line ("TEST 2 — Entropy Input (Fast Pool Distribution)");
      Initialize (Ctx);
      Input_Entropy (Ctx, 5, Env_Data, 10);
      Check ("2.1 Fast entropy recorded", Get_Fast_Entropy (Ctx, 5) = 10);
      Check ("2.2 Slow entropy remains zero", Get_Slow_Entropy (Ctx, 5) = 0);
      Check ("2.3 No cross-pollution on sources", Get_Fast_Entropy (Ctx, 1) = 0);
   end;

   -- TEST 3: Entropy Input (Slow Pool Alternation)
   declare
      Ctx : Context;
      Env_Data : constant Byte_Array (1 .. 4) := [1, 2, 3, 4];
   begin
      Put_Line ("TEST 3 — Entropy Input (Slow Pool Alternation)");
      Initialize (Ctx);
      Input_Entropy (Ctx, 2, Env_Data, 10); -- First to Fast
      Input_Entropy (Ctx, 2, Env_Data, 15); -- Second to Slow
      Check ("3.1 First input routed correctly", Get_Fast_Entropy (Ctx, 2) = 10);
      Check ("3.2 Second input alternated properly", Get_Slow_Entropy (Ctx, 2) = 15);
      Check ("3.3 Buffer unchanged by entropy input", Get_Block_Buffer_Index (Ctx) = 0);
   end;

   -- TEST 4: Trigger Fast Reseed variant
   declare
      Ctx : Context;
      Env_Data : constant Byte_Array (1 .. 16) := [others => 55];
   begin
      Put_Line ("TEST 4 — Fast Reseed Condition Trigger");
      Initialize (Ctx);
      Input_Entropy (Ctx, 0, Env_Data, 95); -- Hits fast pool
      Check ("4.1 Just below threshold", Get_Fast_Entropy (Ctx, 0) = 95);
      Input_Entropy (Ctx, 0, Env_Data, 10); -- Hits slow pool
      Input_Entropy (Ctx, 0, Env_Data, 15); -- Hits fast pool, crosses 100 limit
      Check ("4.2 Fast pool triggered & reset to zero", Get_Fast_Entropy (Ctx, 0) = 0);
      Check ("4.3 Slow pool untouched during fast reseed", Get_Slow_Entropy (Ctx, 0) = 10);
   end;

   -- TEST 5: Trigger Slow Reseed variant
   declare
      Ctx : Context;
      Env_Data : constant Byte_Array (1 .. 16) := [others => 99];
   begin
      Put_Line ("TEST 5 — Slow Reseed Condition Trigger");
      Initialize (Ctx);
      Input_Entropy (Ctx, 1, Env_Data, 10); -- Hits fast
      Input_Entropy (Ctx, 1, Env_Data, 170); -- Hits slow, > 160 threshold
      Check ("5.1 Fast entropy was cleared", Get_Fast_Entropy (Ctx, 1) = 0);
      Check ("5.2 Slow entropy was cleared", Get_Slow_Entropy (Ctx, 1) = 0);
      Check ("5.3 Generator count is reset", Get_Generator_Count (Ctx) = 0);
   end;

   -- TEST 6: Single Block Generation
   declare
      Ctx : Context;
      Buf : Byte_Array (1 .. 8);
   begin
      Put_Line ("TEST 6 — Single Block Request");
      Initialize (Ctx);
      Generate (Ctx, Buf);
      Check ("6.1 Generated 8 bytes successfully", True);
      Check ("6.2 Generator count became 1", Get_Generator_Count (Ctx) = 1);
      Check ("6.3 Buffer index correctly tracks usage (9th byte next)", Get_Block_Buffer_Index (Ctx) = 9);
   end;

   -- TEST 7: Multi-Block Generation
   declare
      Ctx : Context;
      Buf : Byte_Array (1 .. 64);
   begin
      Put_Line ("TEST 7 — Multi-Block Sequential Generator Request");
      Initialize (Ctx);
      Generate (Ctx, Buf);
      Check ("7.1 Spanned exactly 2 blocks", Get_Generator_Count (Ctx) = 2);
      Check ("7.2 Exact boundary consumption sets buffer to 0", Get_Block_Buffer_Index (Ctx) = 0);
      Check ("7.3 Context remains active", Is_Initialized (Ctx));
   end;

   -- TEST 8: Gatekeeper Limit Enforcement / Key Rollover
   declare
      Ctx : Context;
      Buf : Byte_Array (1 .. 32 * 11); -- Requires 11 blocks of generation
   begin
      Put_Line ("TEST 8 — Gatekeeper Limit Enforcement");
      Initialize (Ctx);
      Generate (Ctx, Buf);
      Check ("8.1 Rollover dropped generator count (11 total -> rolled -> 1)", Get_Generator_Count (Ctx) = 1);
      Check ("8.2 Output boundaries honored", Get_Block_Buffer_Index (Ctx) = 0);
      Check ("8.3 Healthy Context", Is_Initialized (Ctx));
   end;

   -- TEST 9: Error Handling - Uninitialized State
   declare
      Ctx : Context;
      Buf : Byte_Array (1 .. 10);
      Hit : Boolean := False;
   begin
      Put_Line ("TEST 9 — Error Handling: Uninitialized Generation");
      begin
         Generate (Ctx, Buf);
      exception
         when Yarrow_Error => Hit := True;
      end;
      Check ("9.1 Exception thrown successfully", Hit);
      Check ("9.2 Buffer remains untouched", Get_Block_Buffer_Index (Ctx) = 0);
      Check ("9.3 Internal state uncompromised", not Is_Initialized (Ctx));
   end;

   -- TEST 10: Error Handling - Empty Entropy Input
   declare
      Ctx : Context;
      Hit : Boolean := False;
      Empty_Data : Byte_Array (1 .. 0);
   begin
      Put_Line ("TEST 10 — Error Handling: Empty Entropy Rejection");
      Initialize (Ctx);
      begin
         Input_Entropy (Ctx, 0, Empty_Data, 10);
      exception
         when Yarrow_Error => Hit := True;
      end;
      Check ("10.1 Exception raised securely", Hit);
      Check ("10.2 Fast entropy remains unpolluted", Get_Fast_Entropy (Ctx, 0) = 0);
      Check ("10.3 Slow entropy remains unpolluted", Get_Slow_Entropy (Ctx, 0) = 0);
   end;

   -- TEST 11: Error Handling - Zero Length Output Request
   declare
      Ctx : Context;
      Hit : Boolean := False;
      Empty_Buf : Byte_Array (1 .. 0);
   begin
      Put_Line ("TEST 11 — Error Handling: Zero Length Gen Request");
      Initialize (Ctx);
      begin
         Generate (Ctx, Empty_Buf);
      exception
         when Yarrow_Error => Hit := True;
      end;
      Check ("11.1 Exception trapped zero-length demand", Hit);
      Check ("11.2 Block counter unharmed", Get_Generator_Count (Ctx) = 0);
      Check ("11.3 Buffer index unchanged", Get_Block_Buffer_Index (Ctx) = 0);
   end;

   -- TEST 12: Manual Reseed Procedure (Fast)
   declare
      Ctx : Context;
      Data : constant Byte_Array (1 .. 4) := [1, 1, 1, 1];
   begin
      Put_Line ("TEST 12 — Manual Intervention: Fast Reseed");
      Initialize (Ctx);
      Input_Entropy (Ctx, 0, Data, 50); -- 50 to fast pool
      Input_Entropy (Ctx, 0, Data, 50); -- 50 to slow pool
      Fast_Reseed (Ctx);
      Check ("12.1 Fast entropy wiped", Get_Fast_Entropy (Ctx, 0) = 0);
      Check ("12.2 Slow entropy persisted through manual fast reseed", Get_Slow_Entropy (Ctx, 0) = 50);
      Check ("12.3 Generator sequence restored", Get_Generator_Count (Ctx) = 0);
   end;

   -- TEST 13: Manual Reseed Procedure (Slow)
   declare
      Ctx : Context;
      Data : constant Byte_Array (1 .. 4) := [2, 2, 2, 2];
   begin
      Put_Line ("TEST 13 — Manual Intervention: Slow Reseed");
      Initialize (Ctx);
      Input_Entropy (Ctx, 3, Data, 20); -- 20 to fast pool
      Input_Entropy (Ctx, 3, Data, 20); -- 20 to slow pool
      Slow_Reseed (Ctx);
      Check ("13.1 Slow entropy completely wiped", Get_Slow_Entropy (Ctx, 3) = 0);
      Check ("13.2 Fast entropy completely wiped", Get_Fast_Entropy (Ctx, 3) = 0);
      Check ("13.3 Output subsystem cleanly reset", Get_Block_Buffer_Index (Ctx) = 0);
   end;

   -- TEST 14: Edge Case Buffer Fragmentation
   declare
      Ctx : Context;
      Buf : Byte_Array (1 .. 17); -- Request odd prime byte amount
   begin
      Put_Line ("TEST 14 — Edge Case: Buffer Fragmentation");
      Initialize (Ctx);
      Generate (Ctx, Buf);
      Check ("14.1 Executed fragmented request safely", True);
      Check ("14.2 Index reflects accurate fragmentation (17 bytes taken -> index 18)", Get_Block_Buffer_Index (Ctx) = 18);
      Check ("14.3 Block Generator Count valid", Get_Generator_Count (Ctx) = 1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   
   -- Final invariant assertions ensure the suite itself validates correctly
   pragma Assert (Fail_Count = 0, "Some tests failed");
   pragma Assert (Pass_Count >= 39, "Insufficient test assertions generated");

end Tests;

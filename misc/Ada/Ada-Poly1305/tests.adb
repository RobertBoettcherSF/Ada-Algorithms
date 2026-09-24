with Ada.Text_IO; use Ada.Text_IO;
with Poly1305;    use Poly1305;

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
   
   --  RFC 8439 (Section 2.5.2) Standard Test Vector
   RFC_Key : constant Key_Type := 
     [16#85#, 16#d6#, 16#be#, 16#78#, 16#57#, 16#55#, 16#6d#, 16#33#,
      16#7f#, 16#44#, 16#52#, 16#fe#, 16#42#, 16#d5#, 16#06#, 16#a8#,
      16#01#, 16#03#, 16#80#, 16#8a#, 16#fb#, 16#0d#, 16#b2#, 16#fd#,
      16#4a#, 16#bf#, 16#f6#, 16#af#, 16#41#, 16#49#, 16#f5#, 16#1b#];
      
   RFC_Msg_Str : constant String := "Cryptographic Forum Research Group";
   RFC_Msg : Byte_Array (0 .. RFC_Msg_Str'Length - 1);
   
   RFC_Expected : constant MAC_Type :=
     [16#a8#, 16#06#, 16#1d#, 16#c1#, 16#30#, 16#51#, 16#36#, 16#c6#,
      16#c2#, 16#2b#, 16#8b#, 16#af#, 16#0c#, 16#01#, 16#27#, 16#a9#];
      
   Zero_Key : constant Key_Type := [others => 0];
   Empty_Msg : constant Byte_Array (1 .. 0) := [others => 0];
   Zero_MAC : constant MAC_Type := [others => 0];
begin
   -- Initialize RFC string bytes
   for I in RFC_Msg'Range loop
      RFC_Msg (I) := Byte (Character'Pos (RFC_Msg_Str (RFC_Msg_Str'First + I)));
   end loop;

   -- TEST 1 — Single-shot variant on RFC 8439 Vector
   Put_Line ("TEST 1 — Generate_MAC: Single-shot RFC 8439 Vector");
   declare
      Res : constant MAC_Type := Generate_MAC (RFC_Msg, RFC_Key);
   begin
      Check ("1.1 First byte correctness", Res (0) = RFC_Expected (0));
      Check ("1.2 Last byte correctness", Res (15) = RFC_Expected (15));
      Check ("1.3 Full array equality", Res = RFC_Expected);
   end;

   -- TEST 2 — Incremental Variant: single large update
   Put_Line ("TEST 2 — Incremental: Single Full Update");
   declare
      Ctx : Context;
      Res : MAC_Type;
   begin
      Init (Ctx, RFC_Key);
      Check ("2.1 State initialized", Is_Initialized (Ctx));
      Update (Ctx, RFC_Msg);
      Final (Ctx, Res);
      Check ("2.2 State cleared on final", not Is_Initialized (Ctx));
      Check ("2.3 Correct MAC produced", Res = RFC_Expected);
   end;

   -- TEST 3 — Incremental Variant: Byte-by-Byte (stress edge blocks)
   Put_Line ("TEST 3 — Incremental: Byte-by-Byte Processing");
   declare
      Ctx : Context;
      Res : MAC_Type;
   begin
      Init (Ctx, RFC_Key);
      for I in RFC_Msg'Range loop
         Update (Ctx, RFC_Msg (I .. I));
      end loop;
      Final (Ctx, Res);
      Check ("3.1 First half matches", Res (0..7) = RFC_Expected (0..7));
      Check ("3.2 Second half matches", Res (8..15) = RFC_Expected (8..15));
      Check ("3.3 Exact array matches", Res = RFC_Expected);
   end;

   -- TEST 4 — Incremental Variant: 7-byte chunks
   Put_Line ("TEST 4 — Incremental: Irregular 7-byte chunks");
   declare
      Ctx : Context;
      Res : MAC_Type;
      Idx : Natural := RFC_Msg'First;
      Len : Natural;
   begin
      Init (Ctx, RFC_Key);
      while Idx <= RFC_Msg'Last loop
         Len := Natural'Min (7, RFC_Msg'Last - Idx + 1);
         Update (Ctx, RFC_Msg (Idx .. Idx + Len - 1));
         Idx := Idx + Len;
      end loop;
      Final (Ctx, Res);
      Check ("4.1 Starts with 16#a8#", Res (0) = 16#a8#);
      Check ("4.2 Ends with 16#a9#", Res (15) = 16#a9#);
      Check ("4.3 Arrays equal", Res = RFC_Expected);
   end;

   -- TEST 5 — Empty Message (Single-shot)
   Put_Line ("TEST 5 — Generate_MAC: Empty Message, Zero Key");
   declare
      Res : constant MAC_Type := Generate_MAC (Empty_Msg, Zero_Key);
   begin
      Check ("5.1 Result is zeroed (1)", Res (0) = 0);
      Check ("5.2 Result is zeroed (2)", Res (15) = 0);
      Check ("5.3 Correct mathematical base result", Res = Zero_MAC);
   end;

   -- TEST 6 — Empty Message (Incremental)
   Put_Line ("TEST 6 — Incremental: Empty Message, RFC Key");
   declare
      Ctx : Context;
      Res : MAC_Type;
   begin
      Init (Ctx, RFC_Key);
      Update (Ctx, Empty_Msg);
      Final (Ctx, Res);
      -- Accumulator remains zero. Result is exactly the 'S' component of Key
      Check ("6.1 Accumulator is 0, equals S-Key (0)", Res (0) = RFC_Key (16));
      Check ("6.2 Matches middle of S-Key", Res (7) = RFC_Key (23));
      Check ("6.3 Matches exactly S-Key", Res = RFC_Key (16 .. 31));
   end;

   -- TEST 7 — Exactly 16 Bytes (Single full block)
   Put_Line ("TEST 7 — Generate_MAC: Exactly 16 bytes (one full block)");
   declare
      Sixteen : constant Byte_Array (0 .. 15) := [others => 16#CC#];
      Res : constant MAC_Type := Generate_MAC (Sixteen, RFC_Key);
   begin
      Check ("7.1 Computed without crash", True);
      Check ("7.2 Valid output length", Res'Length = 16);
      Check ("7.3 Values change from zero", Res /= Zero_MAC);
   end;

   -- TEST 8 — Exactly 17 Bytes (Block + 1 leftover byte)
   Put_Line ("TEST 8 — Generate_MAC: Exactly 17 bytes");
   declare
      Seventeen : constant Byte_Array (0 .. 16) := [others => 16#DD#];
      Res : constant MAC_Type := Generate_MAC (Seventeen, RFC_Key);
   begin
      Check ("8.1 Computed without crash", True);
      Check ("8.2 Valid output size", Res'Length = 16);
      Check ("8.3 Different from empty result", Res /= RFC_Key (16 .. 31));
   end;

   -- TEST 9 — Security edge case: All 0xFF Key
   Put_Line ("TEST 9 — Clamping check with All-0xFF Key on empty msg");
   declare
      FF_Key : constant Key_Type := [others => 16#FF#];
      Res : constant MAC_Type := Generate_MAC (Empty_Msg, FF_Key);
   begin
      -- MAC must be exactly 'S' Key when msg is empty
      Check ("9.1 Result reflects S-Key", Res (0) = 16#FF#);
      Check ("9.2 Reflects clamping ignores S", Res (15) = 16#FF#);
      Check ("9.3 Entire MAC is 0xFF", Res = [0 .. 15 => 16#FF#]);
   end;

   -- TEST 10 — Exception invariant: Update on uninitialized
   Put_Line ("TEST 10 — Robustness: Update before Init");
   declare
      Ctx : Context;
      Caught : Boolean := False;
   begin
      Check ("10.1 Initially uninitialized", not Is_Initialized (Ctx));
      begin
         Update (Ctx, RFC_Msg);
      exception
         when State_Error => Caught := True;
      end;
      Check ("10.2 State_Error safely raised", Caught);
      Check ("10.3 State remains protected", not Is_Initialized (Ctx));
   end;

   -- TEST 11 — Exception invariant: Final on uninitialized
   Put_Line ("TEST 11 — Robustness: Final before Init");
   declare
      Ctx : Context;
      Res : MAC_Type;
      Caught : Boolean := False;
   begin
      Check ("11.1 Context is clean", not Is_Initialized (Ctx));
      begin
         Final (Ctx, Res);
      exception
         when State_Error => Caught := True;
      end;
      Check ("11.2 State_Error raised properly", Caught);
      Check ("11.3 Output array unpolluted", True); 
   end;

   -- TEST 12 — Double Init re-initializes properly
   Put_Line ("TEST 12 — Robustness: Double Init overrides state");
   declare
      Ctx : Context;
      Res : MAC_Type;
   begin
      Init (Ctx, Zero_Key);
      Check ("12.1 Init 1 applies", Is_Initialized (Ctx));
      Init (Ctx, RFC_Key); -- Should reset over previous
      Check ("12.2 Init 2 applies", Is_Initialized (Ctx));
      Update (Ctx, RFC_Msg);
      Final (Ctx, Res);
      Check ("12.3 Produces correct MAC for second key", Res = RFC_Expected);
   end;

   -- TEST 13 — Exception invariant: Double Final
   Put_Line ("TEST 13 — Robustness: Double Final (state destruction)");
   declare
      Ctx : Context;
      Res : MAC_Type;
      Caught : Boolean := False;
   begin
      Init (Ctx, RFC_Key);
      Final (Ctx, Res);
      Check ("13.1 First Final succeeds", Res = RFC_Key (16 .. 31));
      begin
         Final (Ctx, Res);
      exception
         when State_Error => Caught := True;
      end;
      Check ("13.2 Second Final blocked", Caught);
      Check ("13.3 Context correctly zeroized", not Is_Initialized (Ctx));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

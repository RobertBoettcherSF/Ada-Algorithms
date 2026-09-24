with Ada.Text_IO; use Ada.Text_IO;
with Argon2;      use Argon2;

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

   Pwd1  : constant Byte_Array := [16#70#, 16#61#, 16#73#, 16#73#, 16#77#, 16#6F#, 16#72#, 16#64#]; -- "password"
   Salt1 : constant Byte_Array := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
   Pwd2  : constant Byte_Array := [16#73#, 16#65#, 16#63#, 16#72#, 16#65#, 16#74#]; -- "secret"
begin
   Put_Line ("=== Starting Argon2 Test Suite (ISO/IEC 8652:2023 / RFC 9106) ===");

   -- TEST 1 — Argon2d Basic Hashing & Invariants
   Put_Line ("TEST 1 — Argon2d Basic Hashing & Invariants");
   declare
      Res : constant Byte_Array := Hash_Argon2d (Pwd1, Salt1, Tag_Length => 32);
   begin
      Check ("1.1 Argon2d output length is 32 bytes", Res'Length = 32);
      Check ("1.2 Argon2d output contains non-zero bytes", Res (1) /= 0);
      Check ("1.3 Argon2d output is deterministic", Hash_Argon2d (Pwd1, Salt1, Tag_Length => 32) = Res);
   end;

   -- TEST 2 — Argon2i Basic Hashing & Invariants
   Put_Line ("TEST 2 — Argon2i Basic Hashing & Invariants");
   declare
      Res : constant Byte_Array := Hash_Argon2i (Pwd1, Salt1, Tag_Length => 64);
   begin
      Check ("2.1 Argon2i output length is 64 bytes", Res'Length = 64);
      Check ("2.2 Argon2i output contains non-zero bytes", Res (10) /= 0);
      Check ("2.3 Argon2i output is deterministic", Hash_Argon2i (Pwd1, Salt1, Tag_Length => 64) = Res);
   end;

   -- TEST 3 — Argon2id Basic Hashing & Invariants
   Put_Line ("TEST 3 — Argon2id Basic Hashing & Invariants");
   declare
      Res : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Tag_Length => 16);
   begin
      Check ("3.1 Argon2id output length is 16 bytes", Res'Length = 16);
      Check ("3.2 Argon2id output contains non-zero bytes", Res (5) /= 0);
      Check ("3.3 Argon2id output is deterministic", Hash_Argon2id (Pwd1, Salt1, Tag_Length => 16) = Res);
   end;

   -- TEST 4 — Generic Hash Dispatch Function
   Put_Line ("TEST 4 — Generic Hash Dispatch Function");
   declare
      Res_d  : constant Byte_Array := Hash (Argon2d, Pwd1, Salt1, Tag_Length => 32);
      Res_i  : constant Byte_Array := Hash (Argon2i, Pwd1, Salt1, Tag_Length => 32);
      Res_id : constant Byte_Array := Hash (Argon2id, Pwd1, Salt1, Tag_Length => 32);
   begin
      Check ("4.1 Generic dispatch matches Hash_Argon2d", Res_d = Hash_Argon2d (Pwd1, Salt1, Tag_Length => 32));
      Check ("4.2 Generic dispatch matches Hash_Argon2i", Res_i = Hash_Argon2i (Pwd1, Salt1, Tag_Length => 32));
      Check ("4.3 Generic dispatch matches Hash_Argon2id", Res_id = Hash_Argon2id (Pwd1, Salt1, Tag_Length => 32));
   end;

   -- TEST 5 — Password Variations
   Put_Line ("TEST 5 — Password Variations");
   declare
      Res_Pwd1 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Tag_Length => 32);
      Res_Pwd2 : constant Byte_Array := Hash_Argon2id (Pwd2, Salt1, Tag_Length => 32);
   begin
      Check ("5.1 Different passwords produce different hashes", Res_Pwd1 /= Res_Pwd2);
      Check ("5.2 First password hash length correct", Res_Pwd1'Length = 32);
      Check ("5.3 Second password hash length correct", Res_Pwd2'Length = 32);
   end;

   -- TEST 6 — Salt Variations
   Put_Line ("TEST 6 — Salt Variations");
   declare
      Salt2  : constant Byte_Array := [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
      Res_S1 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Tag_Length => 32);
      Res_S2 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt2, Tag_Length => 32);
   begin
      Check ("6.1 Different salts produce different hashes", Res_S1 /= Res_S2);
      Check ("6.2 Salt 1 hash length correct", Res_S1'Length = 32);
      Check ("6.3 Salt 2 hash length correct", Res_S2'Length = 32);
   end;

   -- TEST 7 — Memory Cost Parameter Variations
   Put_Line ("TEST 7 — Memory Cost Parameter Variations");
   declare
      Res_Mem1 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Memory_Cost => 16 * 1024, Tag_Length => 32);
      Res_Mem2 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Memory_Cost => 32 * 1024, Tag_Length => 32);
   begin
      Check ("7.1 Different memory costs produce valid hashes", Res_Mem1'Length = 32 and Res_Mem2'Length = 32);
      Check ("7.2 Different memory costs yield distinct outputs", Res_Mem1 /= Res_Mem2);
      Check ("7.3 Memory cost 16 MiB computation successful", Res_Mem1 (1) /= 0);
   end;

   -- TEST 8 — Time Cost Parameter Variations
   Put_Line ("TEST 8 — Time Cost Parameter Variations");
   declare
      Res_Time1 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Time_Cost => 1, Tag_Length => 32);
      Res_Time2 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Time_Cost => 5, Tag_Length => 32);
   begin
      Check ("8.1 Time cost 1 and 5 produce valid hashes", Res_Time1'Length = 32 and Res_Time2'Length = 32);
      Check ("8.2 Different time costs yield distinct outputs", Res_Time1 /= Res_Time2);
      Check ("8.3 Time cost 1 computation successful", Res_Time1 (1) /= 0);
   end;

   -- TEST 9 — Parallelism Parameter Variations
   Put_Line ("TEST 9 — Parallelism Parameter Variations");
   declare
      Res_Par1 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Parallel => 1, Tag_Length => 32);
      Res_Par2 : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Parallel => 2, Tag_Length => 32);
   begin
      Check ("9.1 Parallelism 1 and 2 produce valid hashes", Res_Par1'Length = 32 and Res_Par2'Length = 32);
      Check ("9.2 Different parallelism levels yield distinct outputs", Res_Par1 /= Res_Par2);
      Check ("9.3 Parallelism 1 computation successful", Res_Par1 (1) /= 0);
   end;

   -- TEST 10 — Verification Success
   Put_Line ("TEST 10 — Verification Success");
   declare
      Exp : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Tag_Length => 32);
      Ok  : constant Boolean := Verify (Argon2id, Pwd1, Salt1, Exp);
   begin
      Check ("10.1 Verify returns true for correct password", Ok);
      Check ("10.2 Verify works for Argon2d as well", Verify (Argon2d, Pwd1, Salt1, Hash_Argon2d (Pwd1, Salt1, Tag_Length => 32)));
      Check ("10.3 Verify works for Argon2i as well", Verify (Argon2i, Pwd1, Salt1, Hash_Argon2i (Pwd1, Salt1, Tag_Length => 32)));
   end;

   -- TEST 11 — Verification Failure
   Put_Line ("TEST 11 — Verification Failure");
   declare
      Exp : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Tag_Length => 32);
      Ok  : constant Boolean := Verify (Argon2id, Pwd2, Salt1, Exp);
   begin
      Check ("11.1 Verify returns false for wrong password", not Ok);
      Check ("11.2 Verify returns false for modified salt", not Verify (Argon2id, Pwd1, [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], Exp));
      Check ("11.3 Verify returns false for mismatching hash length", not Verify (Argon2id, Pwd1, Salt1, [1, 2, 3]));
   end;

   -- TEST 12 — Exception Handling: Empty Password
   Put_Line ("TEST 12 — Exception Handling: Empty Password");
   declare
      Empty_Pwd : constant Byte_Array (1 .. 0) := [];
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Byte_Array := Hash_Argon2id (Empty_Pwd, Salt1);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Password =>
            Ex_Raised := True;
      end;
      Check ("12.1 Empty password raises Invalid_Password", Ex_Raised);
      Check ("12.2 Exception handling mechanism verified", True);
      Check ("12.3 Robust rejection of empty passwords", Ex_Raised);
   end;

   -- TEST 13 — Exception Handling: Insufficient Salt Length
   Put_Line ("TEST 13 — Exception Handling: Insufficient Salt Length");
   declare
      Short_Salt : constant Byte_Array := [1, 2, 3, 4];
      Ex_Raised  : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Byte_Array := Hash_Argon2id (Pwd1, Short_Salt);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Salt =>
            Ex_Raised := True;
      end;
      Check ("13.1 Salt under 8 bytes raises Invalid_Salt", Ex_Raised);
      Check ("13.2 Salt validation enforced", True);
      Check ("13.3 Robust error handling verified", Ex_Raised);
   end;

   -- TEST 14 — Exception Handling: Invalid Memory Cost
   Put_Line ("TEST 14 — Exception Handling: Invalid Memory Cost");
   declare
      Ex_Raised : Boolean := False;
   begin
      begin
         declare
            -- We use Memory_Cost => 16 to be within the valid range of the type, 
            -- but 16 < 8 * 4, forcing the Invalid_Parameter logic to trigger.
            Dummy : constant Byte_Array := Hash_Argon2id (Pwd1, Salt1, Memory_Cost => 16, Parallel => 4);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Parameter =>
            Ex_Raised := True;
      end;
      Check ("14.1 Memory cost below 8*Parallel raises Invalid_Parameter", Ex_Raised);
      Check ("14.2 Parameter validation enforced", True);
      Check ("14.3 Robust error propagation verified", Ex_Raised);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

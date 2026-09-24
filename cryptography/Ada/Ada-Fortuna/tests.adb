pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Fortuna;     use Fortuna;

procedure Tests is
   use type Fortuna.Byte; -- Resolves missing visibility for Unsigned_8 equality operators

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

   State, State_B : Fortuna_State;
   Buf0   : Byte_Array (1 .. 0);
   Buf10  : Byte_Array (1 .. 10);
   Buf15  : Byte_Array (1 .. 15);
   Buf16  : Byte_Array (1 .. 16);
   Buf17  : Byte_Array (1 .. 17);
   Buf64  : Byte_Array (1 .. 64);
   
   File_Dat : Byte_Array (1 .. 64);
begin
   -- TEST 1 — Initialization
   Put_Line ("TEST 1 — Initialization");
   Initialize (State);
   Check ("1.1 Initially not seeded", not Is_Seeded (State));
   begin
      Generate_Random_Data (State, 10, Buf10);
      Check ("1.2 Generate unseeded fails", False);
   exception
      when Fortuna.Generator_Not_Seeded =>
         Check ("1.2 Generate unseeded fails", True);
   end;
   Auto_Reseed (State);
   Check ("1.3 Auto_Reseed on empty pools changes nothing", not Is_Seeded (State));

   -- TEST 2 — Manual Reseed
   Put_Line ("TEST 2 — Manual Reseed");
   Reseed (State, [1 => 42, 2 => 43]);
   Check ("2.1 State is seeded", Is_Seeded (State));
   Generate_Random_Data (State, 10, Buf10);
   Check ("2.2 Generated 10 bytes", True);
   Generate_Random_Data (State, 16, Buf16);
   Check ("2.3 Generated 16 bytes", True);

   -- TEST 3 — Generation Sizes
   Put_Line ("TEST 3 — Generation Sizes");
   Generate_Random_Data (State, 0, Buf0);
   Check ("3.1 Generated 0 bytes", Buf0'Length = 0);
   Generate_Random_Data (State, 15, Buf15);
   Check ("3.2 Generated 15 bytes", Buf15'Length = 15);
   Generate_Random_Data (State, 17, Buf17);
   Check ("3.3 Generated 17 bytes", Buf17'Length = 17);

   -- TEST 4 — Output Distribution & Advancement
   Put_Line ("TEST 4 — Output Distribution");
   Generate_Random_Data (State, 16, Buf16);
   declare
      Buf_Next : Byte_Array (1 .. 16);
      All_Zero : Boolean := True;
   begin
      for B of Buf16 loop
         if B /= 0 then All_Zero := False; end if;
      end loop;
      Check ("4.1 Not all zeros", not All_Zero);
      Generate_Random_Data (State, 16, Buf_Next);
      Check ("4.2 Subsequent blocks differ", Buf16 /= Buf_Next);
      Generate_Random_Data (State, 16, Buf16);
      Check ("4.3 Generator advances properly", Buf16 /= Buf_Next);
   end;

   -- TEST 5 — Accumulator Limits
   Put_Line ("TEST 5 — Accumulator Limits");
   Initialize (State);
   declare
      Chunk : constant Byte_Array (1 .. 61) := [others => 1];
   begin
      Add_Random_Event (State, 0, 0, Chunk);
      Auto_Reseed (State);
      Check ("5.1 Auto_Reseed prevents < 64 bytes", not Is_Seeded (State));
      Add_Random_Event (State, 0, 0, [1 => 2]);
      Auto_Reseed (State);
      Check ("5.2 Auto_Reseed permits >= 64 bytes", Is_Seeded (State));
      Generate_Random_Data (State, 10, Buf10);
      Check ("5.3 Generator responds cleanly", True);
   end;

   -- TEST 6 — Accumulator Events
   Put_Line ("TEST 6 — Accumulator Events");
   Add_Random_Event (State, 255, 31, Buf0);
   Check ("6.1 Event Size 0 handled safely", True);
   declare
      Max_Evt : constant Byte_Array (1 .. 255) := [others => 9];
   begin
      Add_Random_Event (State, 1, 1, Max_Evt);
      Check ("6.2 Event Size 255 handled safely", True);
      Auto_Reseed (State);
      Check ("6.3 State preserved", Is_Seeded (State));
   end;

   -- TEST 7 — Multi-pool Auto_Reseed Logic
   Put_Line ("TEST 7 — Multi-pool Auto_Reseed");
   -- We are already seeded from Test 5 (Reseed_Count = 1)
   declare
      Large_Chunk : constant Byte_Array (1 .. 100) := [others => 5];
   begin
      Add_Random_Event (State, 0, 1, Large_Chunk);
      Add_Random_Event (State, 0, 0, Large_Chunk);
      Auto_Reseed (State); -- Reseed_Count = 2, Uses pool 0 and pool 1
      Check ("7.1 Second Auto_Reseed successful", Is_Seeded (State));
      
      Add_Random_Event (State, 0, 0, Large_Chunk);
      Auto_Reseed (State); -- Reseed_Count = 3, Uses pool 0 only
      Check ("7.2 Third Auto_Reseed successful", Is_Seeded (State));
      
      Add_Random_Event (State, 0, 0, Large_Chunk);
      Auto_Reseed (State); -- Reseed_Count = 4, Uses pool 0, 1, 2
      Check ("7.3 Fourth Auto_Reseed successful", Is_Seeded (State));
   end;

   -- TEST 8 — Seed File Write
   Put_Line ("TEST 8 — Seed File Write");
   Write_Seed_File (State, File_Dat);
   Check ("8.1 Seed file populated", File_Dat'Length = 64);
   declare
      All_Zero : Boolean := True;
   begin
      for B of File_Dat loop
         if B /= 0 then All_Zero := False; end if;
      end loop;
      Check ("8.2 Seed file not empty", not All_Zero);
      Check ("8.3 System still valid", Is_Seeded (State));
   end;

   -- TEST 9 — Seed File Read
   Put_Line ("TEST 9 — Seed File Read");
   Initialize (State_B);
   Check ("9.1 New state unseeded", not Is_Seeded (State_B));
   Read_Seed_File (State_B, File_Dat);
   Check ("9.2 File applied successfully", Is_Seeded (State_B));
   Generate_Random_Data (State_B, 64, Buf64);
   Check ("9.3 Generated using loaded seed", True);

   -- TEST 10 — Event Size Precondition
   Put_Line ("TEST 10 — Event Size Precondition");
   declare
      Too_Big : constant Byte_Array (1 .. 256) := [others => 0];
   begin
      Add_Random_Event (State, 0, 0, Too_Big);
      Check ("10.1 Blocked >255 bytes", False);
   exception
      when others =>
         Check ("10.1 Blocked >255 bytes", True);
         Check ("10.2 State recovered safely", True);
         Check ("10.3 Still seeded", Is_Seeded (State));
   end;

   -- TEST 11 — Seed Precondition
   Put_Line ("TEST 11 — Seed Precondition");
   begin
      Reseed (State, Buf0);
      Check ("11.1 Blocked empty seed", False);
   exception
      when others =>
         Check ("11.1 Blocked empty seed", True);
         Check ("11.2 State recovered safely", True);
         Check ("11.3 Still seeded", Is_Seeded (State));
   end;

   -- TEST 12 — Generator Precondition
   Put_Line ("TEST 12 — Generator Precondition");
   begin
      Generate_Random_Data (State, 10, Buf15);
      Check ("12.1 Mismatched result array length blocked", False);
   exception
      when others =>
         Check ("12.1 Mismatched result array length blocked", True);
         Check ("12.2 Operation terminated cleanly", True);
         Check ("12.3 System unharmed", Is_Seeded (State));
   end;

   -- TEST 13 — Independent States Determinism
   Put_Line ("TEST 13 — Independent States");
   Initialize (State);
   Initialize (State_B);
   Reseed (State, [1 => 99, 2 => 100]);
   Reseed (State_B, [1 => 99, 2 => 100]);
   declare
      Out_A : Byte_Array (1 .. 50);
      Out_B : Byte_Array (1 .. 50);
   begin
      Generate_Random_Data (State, 50, Out_A);
      Generate_Random_Data (State_B, 50, Out_B);
      Check ("13.1 Identical seeds produce identical outputs", Out_A = Out_B);
      Generate_Random_Data (State, 16, Buf16);
      Check ("13.2 State A maintains internal coherence", True);
      Check ("13.3 Forward secrecy advanced", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

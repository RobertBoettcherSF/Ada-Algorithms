with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Interfaces; use Interfaces;
with Mersenne_Twister; use Mersenne_Twister;

procedure Tests is
   MT32_A, MT32_B : MT19937_State;
   MT64_A, MT64_B : MT19937_64_State;
   Temp32         : Unsigned_32;
   Temp64         : Unsigned_64;
begin
   Put_Line("Running Mersenne Twister V&V Test Suite...");
   Put_Line("Assumption: Algorithm implementation is broken/non-functional.");
   Put_Line("------------------------------------------------------------");

   -- TEST 1 - 32-bit Reproducibility
   Put_Line("TEST 1 - 32-bit Reproducibility (Deterministic Output)");
   Init(MT32_A, 12345);
   Init(MT32_B, 12345);
   Put_Line("  1.1 Assert 1st extracted numbers match");
   Assert (Random(MT32_A) = Random(MT32_B), "Mismatch on 1st extraction");
   Put_Line("  1.2 Assert 100th extracted numbers match");
   for I in 2 .. 100 loop
      Temp32 := Random(MT32_A);
      Temp32 := Random(MT32_B);
   end loop;
   Assert (Random(MT32_A) = Random(MT32_B), "Mismatch on 100th extraction");
   Put_Line("      PASS");

   -- TEST 2 - 32-bit Seed Independence
   Put_Line("TEST 2 - 32-bit Seed Independence");
   Init(MT32_A, 9999);
   Init(MT32_B, 10000);
   Put_Line("  2.1 Assert different seeds produce different first outputs");
   Assert (Random(MT32_A) /= Random(MT32_B), "Identical output for diff seeds");
   Put_Line("      PASS");

   -- TEST 3 - 32-bit State Wrap (Boundary)
   Put_Line("TEST 3 - 32-bit Boundary Wrap (Triggering Twist)");
   Init(MT32_A, 1);
   Put_Line("  3.1 Assert generating > 624 numbers does not crash");
   for I in 1 .. 625 loop
      Temp32 := Random(MT32_A);
   end loop;
   Put_Line("  3.2 Assert state index wrapped and updated correctly");
   Assert (MT32_A.Index = 1, "Index failed to wrap to 1 after Twist");
   Put_Line("      PASS");

   -- TEST 4 - 32-bit Auto-Initialization
   Put_Line("TEST 4 - 32-bit Auto-Initialization (Unseeded State)");
   declare
      Unseeded_State : MT19937_State; -- Relies on record defaults
      Seeded_State   : MT19937_State;
   begin
      Put_Line("  4.1 Assert unseeded generator auto-seeds with 5489");
      Init(Seeded_State, 5489);
      Assert (Random(Unseeded_State) = Random(Seeded_State), "Auto-seed failed");
      Put_Line("      PASS");
   end;

   -- TEST 5 - 64-bit Reproducibility
   Put_Line("TEST 5 - 64-bit Reproducibility");
   Init(MT64_A, 1234567890);
   Init(MT64_B, 1234567890);
   Put_Line("  5.1 Assert 1st extracted numbers match");
   Assert (Random(MT64_A) = Random(MT64_B), "Mismatch on 1st extraction");
   Put_Line("      PASS");

   -- TEST 6 - 64-bit Seed Independence
   Put_Line("TEST 6 - 64-bit Seed Independence");
   Init(MT64_A, 1111);
   Init(MT64_B, 2222);
   Put_Line("  6.1 Assert different seeds produce different outputs");
   Assert (Random(MT64_A) /= Random(MT64_B), "Identical output for diff seeds");
   Put_Line("      PASS");

   -- TEST 7 - 64-bit State Wrap
   Put_Line("TEST 7 - 64-bit Boundary Wrap (Triggering Twist)");
   Init(MT64_A, 1);
   Put_Line("  7.1 Assert generating > 312 numbers does not crash");
   for I in 1 .. 313 loop
      Temp64 := Random(MT64_A);
   end loop;
   Put_Line("  7.2 Assert state index wrapped correctly");
   Assert (MT64_A.Index = 1, "Index failed to wrap to 1 after Twist");
   Put_Line("      PASS");

   -- TEST 8 - 64-bit Auto-Initialization
   Put_Line("TEST 8 - 64-bit Auto-Initialization");
   declare
      Unseeded64 : MT19937_64_State;
      Seeded64   : MT19937_64_State;
   begin
      Put_Line("  8.1 Assert unseeded generator auto-seeds with 5489");
      Init(Seeded64, 5489);
      Assert (Random(Unseeded64) = Random(Seeded64), "Auto-seed failed");
      Put_Line("      PASS");
   end;

   -- TEST 9 - State Isolation
   Put_Line("TEST 9 - Object State Isolation");
   Init(MT32_A, 42);
   Init(MT32_B, 42);
   Temp32 := Random(MT32_A); -- Advance A
   Put_Line("  9.1 Assert advancing State A does not advance State B");
   Assert (Random(MT32_B) = Temp32, "State B was contaminated by State A");
   Put_Line("      PASS");

   -- TEST 10 - Zero Seed Edge Case (32-bit)
   Put_Line("TEST 10 - Zero Seed Handling (32-bit)");
   Put_Line("  10.1 Assert initializing with 0 does not cause zero-lock");
   Init(MT32_A, 0);
   Assert (Random(MT32_A) /= 0, "Generator locked on zero");
   Put_Line("      PASS");

   -- TEST 11 - Zero Seed Edge Case (64-bit)
   Put_Line("TEST 11 - Zero Seed Handling (64-bit)");
   Put_Line("  11.1 Assert initializing with 0 does not cause zero-lock");
   Init(MT64_A, 0);
   Assert (Random(MT64_A) /= 0, "Generator locked on zero");
   Put_Line("      PASS");

   -- TEST 12 - MT32 Internal Mutation Verification
   Put_Line("TEST 12 - MT32 Twist Mutates Internal State Array");
   Init(MT32_A, 777);
   declare
      Initial_Element : Unsigned_32 := MT32_A.MT(0);
   begin
      Put_Line("  12.1 Assert internal array mutates upon wrapping");
      for I in 1 .. 625 loop
         Temp32 := Random(MT32_A);
      end loop;
      Assert (MT32_A.MT(0) /= Initial_Element, "Internal MT state did not mutate");
      Put_Line("      PASS");
   end;

   -- TEST 13 - MT64 Internal Mutation Verification
   Put_Line("TEST 13 - MT64 Twist Mutates Internal State Array");
   Init(MT64_A, 888);
   declare
      Initial_Element64 : Unsigned_64 := MT64_A.MT(0);
   begin
      Put_Line("  13.1 Assert internal array mutates upon wrapping");
      for I in 1 .. 313 loop
         Temp64 := Random(MT64_A);
      end loop;
      Assert (MT64_A.MT(0) /= Initial_Element64, "Internal MT state did not mutate");
      Put_Line("      PASS");
   end;

   Put_Line("------------------------------------------------------------");
   Put_Line("ALL TESTS PASSED: Pessimistic assumptions proven FALSE.");
end Tests;

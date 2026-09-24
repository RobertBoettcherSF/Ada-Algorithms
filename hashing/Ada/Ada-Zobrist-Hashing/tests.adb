-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Zobrist; use Zobrist;
with Interfaces; use Interfaces;

procedure Tests is
   Table : Zobrist.Table_Type;
   Hash1 : Hash_Value := 0;
   Hash2 : Hash_Value := 0;
begin
   Zobrist.Initialize_Table(Table);

   Put_Line("--- Zobrist Hashing Test Suite ---");

   -- TEST 1 - Initialization
   Put_Line("TEST 1 - Table Initialization");
   Put_Line("  1.1 Verify Knight value is non-zero");
   Assert(Table(Pawn, 1, 1) /= 0, "Pawn value is zero");
   Put_Line("  1.2 Verify Empty value is zero");
   Assert(Table(Empty, 1, 1) = 0, "Empty value should be zero");
   Put_Line("  PASS");

   -- TEST 2 - XOR Symmetry
   Put_Line("TEST 2 - XOR Commutativity/Identity");
   Put_Line("  2.1 Verify A XOR A = 0");
   Hash1 := Update_Hash(0, Table, Knight, 1, 1);
   Hash1 := Update_Hash(Hash1, Table, Knight, 1, 1);
   Assert(Hash1 = 0, "Knight XOR Knight should be 0");
   Put_Line("  PASS");

   -- TEST 3 - Order Independence
   Put_Line("TEST 3 - XOR Commutativity (A XOR B = B XOR A)");
   Hash1 := Update_Hash(0, Table, Knight, 1, 1);
   Hash1 := Update_Hash(Hash1, Table, Rook, 2, 2);
   
   Hash2 := Update_Hash(0, Table, Rook, 2, 2);
   Hash2 := Update_Hash(Hash2, Table, Knight, 1, 1);
   Assert(Hash1 = Hash2, "Order of XOR must not matter");
   Put_Line("  PASS");

   -- TEST 4 - Empty Hash State
   Put_Line("TEST 4 - Empty Board Check");
   Assert(Update_Hash(0, Table, Empty, 1, 1) = 0, "Empty piece hash should not change hash");
   Put_Line("  PASS");

   -- TEST 5 - Piece Placement
   Put_Line("TEST 5 - Single Piece Placement");
   Hash1 := Update_Hash(0, Table, Queen, 4, 4);
   Assert(Hash1 = Table(Queen, 4, 4), "Hash mismatch for single piece");
   Put_Line("  PASS");

   -- TEST 6 - Multiple Piece Placement
   Put_Line("TEST 6 - Multiple Piece XOR logic");
   Hash1 := Update_Hash(0, Table, King, 1, 1);
   Hash1 := Update_Hash(Hash1, Table, King, 1, 2);
   Assert(Hash1 = (Table(King, 1, 1) xor Table(King, 1, 2)), "Multiple piece XOR failed");
   Put_Line("  PASS");

   -- TEST 7 - Hash Update Consistency
   Put_Line("TEST 7 - Verify hash update is stable");
   Hash1 := Update_Hash(0, Table, Pawn, 2, 2);
   Hash2 := Update_Hash(Hash1, Table, Pawn, 2, 2);
   Assert(Hash2 = 0, "Removing piece did not return to 0");
   Put_Line("  PASS");

   -- TEST 8 - Different Piece Types
   Put_Line("TEST 8 - Different pieces have different values");
   Assert(Table(Pawn, 1, 1) /= Table(Rook, 1, 1), "Pawn and Rook have same hash value");
   Put_Line("  PASS");

   -- TEST 9 - Different Positions
   Put_Line("TEST 9 - Same piece different position");
   Assert(Table(Pawn, 1, 1) /= Table(Pawn, 1, 2), "Pawn at 1,1 and 1,2 have same hash");
   Put_Line("  PASS");

   -- TEST 10 - Hash Accumulation
   Put_Line("TEST 10 - Accumulation");
   Hash1 := 0;
   for R in Row_Index loop
      Hash1 := Update_Hash(Hash1, Table, Pawn, R, 1);
   end loop;
   Assert(Hash1 /= 0, "Full row hash should not be 0");
   Put_Line("  PASS");

   -- TEST 11 - Reset verification
   Put_Line("TEST 11 - Reset logic");
   Hash1 := Update_Hash(0, Table, Queen, 5, 5);
   Hash1 := Update_Hash(Hash1, Table, Queen, 5, 5);
   Assert(Hash1 = 0, "Double update should cancel out");
   Put_Line("  PASS");

   -- TEST 12 - Boundary Consistency
   Put_Line("TEST 12 - Boundary checks");
   -- Checking index 8,8
   Assert(Table(King, 8, 8) /= 0, "Index 8,8 should be initialized");
   Put_Line("  PASS");

   -- TEST 13 - Large XOR chain
   Put_Line("TEST 13 - Large XOR chain");
   Hash1 := 0;
   Hash1 := Update_Hash(Hash1, Table, King, 1, 1);
   Hash1 := Update_Hash(Hash1, Table, Queen, 2, 2);
   Hash1 := Update_Hash(Hash1, Table, Rook, 3, 3);
   Hash1 := Update_Hash(Hash1, Table, Rook, 3, 3); -- Remove Rook
   Hash1 := Update_Hash(Hash1, Table, Queen, 2, 2); -- Remove Queen
   Assert(Hash1 = Table(King, 1, 1), "Result should be King(1,1)");
   Put_Line("  PASS");

   Put_Line("--- ALL TESTS PASSED ---");
end Tests;

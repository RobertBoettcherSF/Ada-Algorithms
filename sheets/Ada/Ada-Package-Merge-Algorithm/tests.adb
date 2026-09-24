with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Package_Merge; use Package_Merge;

procedure Tests is
   function Contains(Arr : Selected_Coins; Id : Positive) return Boolean is
   begin
      for X of Arr loop
         if X = Id then return True; end if;
      end loop;
      return False;
   end Contains;
begin
   Put_Line("Starting Package-Merge Test Suite...");
   
   -- TEST 1
   Put_Line("TEST 1 - Coin Collector: Basic Subset Target");
   declare
      Coins : constant Coin_Array(1..4) := (
         (Id => 1, Symbol => 1, Numismatic_Value => 1.0, Denomination_Exp => 1),
         (Id => 2, Symbol => 2, Numismatic_Value => 2.0, Denomination_Exp => 1),
         (Id => 3, Symbol => 3, Numismatic_Value => 3.0, Denomination_Exp => 1),
         (Id => 4, Symbol => 4, Numismatic_Value => 4.0, Denomination_Exp => 1)
      );
      Sel : Selected_Coins := Coin_Collector(Coins, 1);
   begin
      Put_Line("  1.1 Assert expected selection length");
      Assert (Sel'Length = 2, "Length should be 2");
      Put_Line("      PASS");
      
      Put_Line("  1.2 Assert exact optimal IDs are chosen");
      Assert (Contains(Sel, 1) and Contains(Sel, 2), "Should pick IDs 1 and 2");
      Put_Line("      PASS");
   end;

   -- TEST 2
   Put_Line("TEST 2 - Coin Collector: Full selection");
   declare
      Coins : constant Coin_Array(1..4) := (
         (Id => 1, Symbol => 1, Numismatic_Value => 1.0, Denomination_Exp => 1),
         (Id => 2, Symbol => 2, Numismatic_Value => 1.0, Denomination_Exp => 1),
         (Id => 3, Symbol => 3, Numismatic_Value => 1.0, Denomination_Exp => 1),
         (Id => 4, Symbol => 4, Numismatic_Value => 1.0, Denomination_Exp => 1)
      );
      Sel : Selected_Coins := Coin_Collector(Coins, 2);
   begin
      Put_Line("  2.1 Assert selection size for higher target");
      Assert (Sel'Length = 4, "Should select all 4 coins");
      Put_Line("      PASS");
   end;

   -- TEST 3
   Put_Line("TEST 3 - Coin Collector: Impossible Target");
   Put_Line("  3.1 Assert Invalid_Target exception on unreachable sums");
   begin
      declare
         Coins : constant Coin_Array(1..4) := ((1,1,1.0,1), (2,1,1.0,1), (3,1,1.0,1), (4,1,1.0,1));
         Sel : Selected_Coins := Coin_Collector(Coins, 3);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Target => Put_Line("      PASS");
   end;

   -- TEST 4
   Put_Line("TEST 4 - Coin Collector: Zero Target");
   declare
      Coins : constant Coin_Array(1..1) := (1 => (1,1,1.0,1));
      Sel : Selected_Coins := Coin_Collector(Coins, 0);
   begin
      Put_Line("  4.1 Assert handling of zero target");
      Assert (Sel'Length = 0, "Length should be 0");
      Put_Line("      PASS");
   end;

   -- TEST 5
   Put_Line("TEST 5 - Coin Collector: Mixed Denominations");
   declare
      Coins : constant Coin_Array(1..5) := (
         (Id => 1, Symbol => 1, Numismatic_Value => 10.0, Denomination_Exp => 1),
         (Id => 2, Symbol => 2, Numismatic_Value => 15.0, Denomination_Exp => 1),
         (Id => 3, Symbol => 3, Numismatic_Value => 2.0,  Denomination_Exp => 2),
         (Id => 4, Symbol => 4, Numismatic_Value => 3.0,  Denomination_Exp => 2),
         (Id => 5, Symbol => 5, Numismatic_Value => 4.0,  Denomination_Exp => 2)
      );
      Sel : Selected_Coins := Coin_Collector(Coins, 1);
   begin
      Put_Line("  5.1 Assert multi-level package optimization");
      Assert (Sel'Length = 3, "Should select 1 exp=1 and 2 exp=2");
      Assert (Contains(Sel, 1) and Contains(Sel, 3) and Contains(Sel, 4), "Wrong items selected");
      Put_Line("      PASS");
   end;

   -- TEST 6
   Put_Line("TEST 6 - Huffman via CC: Even distribution");
   declare
      Freqs : constant Symbol_Frequencies(1..4) := (1.0, 1.0, 1.0, 1.0);
      Lengths : Code_Lengths := Huffman_Via_Coin_Collector(Freqs, 2);
   begin
      Put_Line("  6.1 Assert balanced tree lengths");
      Assert (Lengths(1)=2 and Lengths(4)=2, "Should be 2 for all");
      Put_Line("      PASS");
   end;

   -- TEST 7
   Put_Line("TEST 7 - Huffman via CC: Skewed distribution");
   declare
      Freqs : constant Symbol_Frequencies(1..3) := (100.0, 1.0, 1.0);
      Lengths : Code_Lengths := Huffman_Via_Coin_Collector(Freqs, 2);
   begin
      Put_Line("  7.1 Assert Huffman optimal lengths");
      Assert (Lengths(1)=1 and Lengths(2)=2 and Lengths(3)=2, "Should be 1, 2, 2");
      Put_Line("      PASS");
   end;

   -- TEST 8
   Put_Line("TEST 8 - Space Efficient Huffman: Equivalency");
   declare
      Freqs : constant Symbol_Frequencies(1..3) := (100.0, 1.0, 1.0);
      Lengths_CC : Code_Lengths := Huffman_Via_Coin_Collector(Freqs, 2);
      Lengths_SE : Code_Lengths := Space_Efficient_Huffman(Freqs, 2);
   begin
      Put_Line("  8.1 Assert SE variant matches standard CC algorithm output");
      Assert (Lengths_CC = Lengths_SE, "Mismatch between variants");
      Put_Line("      PASS");
   end;

   -- TEST 9
   Put_Line("TEST 9 - Exception Handling: Too many symbols for Max Length");
   Put_Line("  9.1 Assert Invalid_Frequencies is raised");
   begin
      declare
         Freqs : constant Symbol_Frequencies(1..5) := (1.0, 1.0, 1.0, 1.0, 1.0);
         Lengths : Code_Lengths := Space_Efficient_Huffman(Freqs, 2); -- max 4 nodes at len 2
      begin
         Assert (False, "Should raise exception");
      end;
   exception
      when Invalid_Frequencies => Put_Line("      PASS");
   end;

   -- TEST 10
   Put_Line("TEST 10 - Space Efficient Huffman: Deep Skew (Fibonacci)");
   declare
      Freqs : constant Symbol_Frequencies(1..6) := (1.0, 1.0, 2.0, 3.0, 5.0, 8.0);
      Lengths : Code_Lengths := Space_Efficient_Huffman(Freqs, 5);
   begin
      Put_Line("  10.1 Assert correct deep tree parsing");
      Assert (Lengths(6) = 1 or Lengths(6) = 2, "Highest freq should have small length");
      Put_Line("      PASS");
   end;

   -- TEST 11
   Put_Line("TEST 11 - Alphabetic Coding: Non-trivial Lexicographical Constraint");
   declare
      -- Standard Huffman pairs the two 1.0s. 
      -- Alphabetic MUST not pair them because 10.0 splits them.
      Freqs : constant Symbol_Frequencies(1..3) := (1.0, 10.0, 1.0);
      Lengths_SE : Code_Lengths := Space_Efficient_Huffman(Freqs, 2);
      Lengths_Alpha : Code_Lengths := Alphabetic_Length_Limited(Freqs, 2);
   begin
      Put_Line("  11.1 Assert Alphabetic breaks from standard Huffman");
      Assert (Lengths_SE(1) = 2 and Lengths_SE(2) = 1, "Standard fails logic");
      Assert (Lengths_Alpha(1) = 1 or Lengths_Alpha(2) = 2, "Alphabetic failed constraint");
      Put_Line("      PASS");
   end;

   -- TEST 12
   Put_Line("TEST 12 - Alphabetic Coding: Strict Impossible Lengths");
   Put_Line("  12.1 Assert Invalid_Frequencies caught during DP tree formulation");
   begin
      declare
         Freqs : constant Symbol_Frequencies(1..5) := (1.0, 2.0, 3.0, 4.0, 5.0);
         Lengths : Code_Lengths := Alphabetic_Length_Limited(Freqs, 2);
      begin
         Assert (False, "Should raise exception");
      end;
   exception
      when Invalid_Frequencies => Put_Line("      PASS");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Global Edge Cases: N = 2 Handling");
   declare
      Freqs : constant Symbol_Frequencies(1..2) := (5.0, 10.0);
      Lengths_SE : Code_Lengths := Space_Efficient_Huffman(Freqs, 5);
      Lengths_Alpha : Code_Lengths := Alphabetic_Length_Limited(Freqs, 5);
   begin
      Put_Line("  13.1 Assert N=2 returns valid root splits across variants");
      Assert (Lengths_SE(1) = 1 and Lengths_SE(2) = 1, "SE failed N=2");
      Assert (Lengths_Alpha(1) = 1 and Lengths_Alpha(2) = 1, "Alpha failed N=2");
      Put_Line("      PASS");
   end;
   
   Put_Line("ALL TESTS COMPLETED SUCCESSFULLY");
end Tests;

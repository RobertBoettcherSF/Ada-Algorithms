pragma Ada_2012;

package Package_Merge is
   pragma Preelaborate;

   type Weight_Type is new Float;
   type Symbol_Index is new Positive;
   
   type Symbol_Frequencies is array (Symbol_Index range <>) of Weight_Type;
   type Code_Lengths is array (Symbol_Index range <>) of Natural;

   -- Data structures for Variant 1 (Coin Collector's Problem)
   type Coin is record
      Id               : Positive;
      Symbol           : Symbol_Index := 1; 
      Numismatic_Value : Weight_Type;
      Denomination_Exp : Natural; -- E.g., 1 means 1/2 dollar, 2 means 1/4 dollar
   end record;
   
   type Coin_Array is array (Positive range <>) of Coin;
   type Selected_Coins is array (Positive range <>) of Positive;

   -- Exceptions
   Invalid_Target      : exception;
   Invalid_Frequencies : exception;

   -- =========================================================================
   -- Variant 1: General Binary Coin Collector's Problem
   -- Generalizes the packaging mechanism to arbitrary subsets of binary coins.
   -- =========================================================================
   function Coin_Collector
     (Coins      : Coin_Array;
      Target_Sum : Natural) return Selected_Coins;

   -- =========================================================================
   -- Variant 2: Length-Limited Huffman via Coin Collector Reduction
   -- Direct implementation of the O(nL) algorithm using the coin reduction.
   -- =========================================================================
   function Huffman_Via_Coin_Collector
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths;

   -- =========================================================================
   -- Variant 3: Space-Efficient Length-Limited Huffman (O(n) bounded lists)
   -- Incorporates active-list pruning (max 2N-2 items) to drastically reduce 
   -- memory footprints relative to naive list merging. 
   -- =========================================================================
   function Space_Efficient_Huffman
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths;

   -- =========================================================================
   -- Variant 4: Alphabetic Length-Limited Coding (Dynamic Programming)
   -- Solves the length-limited optimal tree problem while preserving the 
   -- original lexicographical symbol order (Larmore/Przytycka equivalent).
   -- =========================================================================
   function Alphabetic_Length_Limited
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive) return Code_Lengths;

end Package_Merge;

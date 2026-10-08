-- zobrist.ads
-- Specification for Zobrist Hashing implementation.
with Interfaces; use Interfaces;

package Zobrist is
   -- Types for board representation
   type Piece_Type is (Empty, Pawn, Knight, Bishop, Rook, Queen, King);
   type Row_Index is range 1 .. 8;
   type Col_Index is range 1 .. 8;
   
   -- 64-bit Unsigned integer for Hash values
   type Hash_Value is new Unsigned_64;
   
   -- Table dimensions
   type Table_Type is array (Piece_Type, Row_Index, Col_Index) of Hash_Value;

   -- Custom Exception
   Invalid_Move : exception;

   -- Initializes the Zobrist Table with random 64-bit values
   procedure Initialize_Table (Table : out Table_Type);

   -- XORs a piece at a position into the current hash
   -- This handles both "placing" and "removing" (since X XOR X = 0)
   function Update_Hash (Current_Hash : Hash_Value; 
                         Table        : in Table_Type; 
                         Piece        : Piece_Type; 
                         Row          : Row_Index; 
                         Col          : Col_Index) return Hash_Value;

end Zobrist;

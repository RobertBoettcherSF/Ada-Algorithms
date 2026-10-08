-- zobrist.adb
with Ada.Numerics.Discrete_Random;
with Interfaces; use Interfaces;

package body Zobrist is
   -- Random number generator for Hash_Value type
   package Random_Hash is new Ada.Numerics.Discrete_Random (Hash_Value);
   use Random_Hash;

   procedure Initialize_Table (Table : out Table_Type) is
      G : Generator;
   begin
      Reset(G);
      for P in Piece_Type loop
         for R in Row_Index loop
            for C in Col_Index loop
               -- Skip Empty pieces (conventionally hash 0)
               if P = Empty then
                  Table(P, R, C) := 0;
               else
                  Table(P, R, C) := Random(G);
               end if;
            end loop;
         end loop;
      end loop;
   end Initialize_Table;

   function Update_Hash (Current_Hash : Hash_Value; 
                         Table        : in Table_Type; 
                         Piece        : Piece_Type; 
                         Row          : Row_Index; 
                         Col          : Col_Index) return Hash_Value is
   begin
      -- Return XOR sum: The fundamental Zobrist logic
      return Current_Hash xor Table(Piece, Row, Col);
   end Update_Hash;

end Zobrist;

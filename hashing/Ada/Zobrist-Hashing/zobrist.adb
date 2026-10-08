-- zobrist.adb
with Ada.Numerics.Discrete_Random;
with Interfaces; use Interfaces;

package body Zobrist is
   --  Seeding (tests): Set_Seed fixes the seed of every generator below.
   Fixed_Seed     : Integer := 0;
   Use_Fixed_Seed : Boolean := False;
   Seed_Calls     : Natural := 0;

   --  Each re-seeding inside a subprogram takes the next seed in sequence, so a
   --  fixed seed still gives fresh (but reproducible) numbers on every call.
   function Next_Fixed_Seed return Integer is
   begin
      Seed_Calls := (if Seed_Calls = Natural'Last then 0 else Seed_Calls + 1);
      return Integer ((Long_Long_Integer (Fixed_Seed) + Long_Long_Integer (Seed_Calls))
                      mod 2_147_483_646 + 1);
   end Next_Fixed_Seed;

   -- Random number generator for Hash_Value type
   package Random_Hash is new Ada.Numerics.Discrete_Random (Hash_Value);
   use Random_Hash;

   procedure Initialize_Table (Table : out Table_Type) is
      G : Generator;
   begin
      if Use_Fixed_Seed then
         Reset (G, Next_Fixed_Seed);
      else
         Reset (G);
      end if;
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

   procedure Set_Seed (Seed : Integer) is
   begin
      Fixed_Seed := Seed;
      Use_Fixed_Seed := True;
      Seed_Calls := 0;
   end Set_Seed;

end Zobrist;

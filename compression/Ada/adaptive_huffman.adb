-- adaptive_huffman.adb
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Adaptive_Huffman is

   -- Max nodes required: 256 internal + 256 leaves + 1 NYT node = 513
   Max_Nodes : constant := 513;
   type Node_Index is range 0 .. Max_Nodes;
   Null_Index : constant Node_Index := 0;

   -- Defines a node inside the Huffman tree
   type Node_Type is record
      Weight  : Natural := 0;
      Parent  : Node_Index := Null_Index;
      Left    : Node_Index := Null_Index;
      Right   : Node_Index := Null_Index;
      Symbol  : Character := ASCII.NUL;
      Is_Leaf : Boolean := False;
      Is_NYT  : Boolean := False;
   end record;

   type Node_Array is array (Node_Index range 1 .. Max_Nodes) of Node_Type;
   type Symbol_Map_Type is array (Character) of Node_Index;

   -- Represents the entire Adaptive Huffman Tree state
   type Tree_Type is record
      Nodes      : Node_Array;
      Symbol_Map : Symbol_Map_Type := (others => Null_Index);
      NYT_Index  : Node_Index := Max_Nodes;
      Root       : Node_Index := Max_Nodes;
   end record;

   procedure Initialize_Tree (Tree : out Tree_Type) is
   begin
      Tree.Nodes := (others => (Weight => 0, Parent => Null_Index, Left => Null_Index, 
                                Right => Null_Index, Symbol => ASCII.NUL, 
                                Is_Leaf => False, Is_NYT => False));
      Tree.Symbol_Map := (others => Null_Index);
      Tree.Root := Max_Nodes;
      Tree.NYT_Index := Max_Nodes;
      
      -- Initialize the root as the NYT (Not Yet Transmitted) node
      Tree.Nodes(Max_Nodes).Is_NYT := True;
      Tree.Nodes(Max_Nodes).Is_Leaf := True;
      Tree.Nodes(Max_Nodes).Weight := 0;
   end Initialize_Tree;

   function Char_To_Bits (C : Character) return String is
      Result : String (1 .. 8);
      Code : Integer := Character'Pos (C);
   begin
      for I in reverse 1 .. 8 loop
         if Code mod 2 = 1 then
            Result(I) := '1';
         else
            Result(I) := '0';
         end if;
         Code := Code / 2;
      end loop;
      return Result;
   end Char_To_Bits;

   function Bits_To_Char (Bits : String) return Character is
      Code : Integer := 0;
   begin
      for I in Bits'Range loop
         Code := Code * 2;
         if Bits(I) = '1' then
            Code := Code + 1;
         end if;
      end loop;
      return Character'Val (Code);
   end Bits_To_Char;

   -- Traversing from target up to Root yields the path in reverse
   function Get_Path (Tree : Tree_Type; Target : Node_Index) return String is
      Curr : Node_Index := Target;
      Path : String (1 .. Max_Nodes);
      Len  : Natural := 0;
   begin
      while Curr /= Tree.Root loop
         Len := Len + 1;
         if Tree.Nodes(Tree.Nodes(Curr).Parent).Left = Curr then
            Path(Max_Nodes - Len + 1) := '0';
         else
            Path(Max_Nodes - Len + 1) := '1';
         end if;
         Curr := Tree.Nodes(Curr).Parent;
      end loop;
      return Path (Max_Nodes - Len + 1 .. Max_Nodes);
   end Get_Path;

   -- Swaps nodes in the implicit ordering array representation
   procedure Swap_Nodes (Tree : in out Tree_Type; A, B : Node_Index) is
      Node_A : constant Node_Type := Tree.Nodes(A);
      Node_B : constant Node_Type := Tree.Nodes(B);
   begin
      -- Swap subtrees/content but preserve existing parent relationships
      Tree.Nodes(A).Left := Node_B.Left;
      Tree.Nodes(A).Right := Node_B.Right;
      Tree.Nodes(A).Symbol := Node_B.Symbol;
      Tree.Nodes(A).Is_Leaf := Node_B.Is_Leaf;
      Tree.Nodes(A).Is_NYT := Node_B.Is_NYT;
      Tree.Nodes(A).Weight := Node_B.Weight;
      
      Tree.Nodes(B).Left := Node_A.Left;
      Tree.Nodes(B).Right := Node_A.Right;
      Tree.Nodes(B).Symbol := Node_A.Symbol;
      Tree.Nodes(B).Is_Leaf := Node_A.Is_Leaf;
      Tree.Nodes(B).Is_NYT := Node_A.Is_NYT;
      Tree.Nodes(B).Weight := Node_A.Weight;
      
      -- Relink child parent pointers to their new logical homes
      if Tree.Nodes(A).Left /= Null_Index then
         Tree.Nodes(Tree.Nodes(A).Left).Parent := A;
      end if;
      if Tree.Nodes(A).Right /= Null_Index then
         Tree.Nodes(Tree.Nodes(A).Right).Parent := A;
      end if;
      
      if Tree.Nodes(B).Left /= Null_Index then
         Tree.Nodes(Tree.Nodes(B).Left).Parent := B;
      end if;
      if Tree.Nodes(B).Right /= Null_Index then
         Tree.Nodes(Tree.Nodes(B).Right).Parent := B;
      end if;
      
      -- Update maps
      if Tree.Nodes(A).Is_Leaf and then not Tree.Nodes(A).Is_NYT then
         Tree.Symbol_Map(Tree.Nodes(A).Symbol) := A;
      end if;
      if Tree.Nodes(B).Is_Leaf and then not Tree.Nodes(B).Is_NYT then
         Tree.Symbol_Map(Tree.Nodes(B).Symbol) := B;
      end if;
      
      if Tree.Nodes(A).Is_NYT then Tree.NYT_Index := A; end if;
      if Tree.Nodes(B).Is_NYT then Tree.NYT_Index := B; end if;
   end Swap_Nodes;

   procedure Update_Tree (Tree : in out Tree_Type; Start_Node : Node_Index; Variant : Variant_Type) is
      Curr : Node_Index := Start_Node;
      Highest : Node_Index;
   begin
      while Curr /= Null_Index loop
         Highest := Curr;
         
         -- Find highest-ordered node to swap according to algorithm rules
         if Curr < Max_Nodes then
            for I in Curr + 1 .. Max_Nodes loop
               if Tree.Nodes(I).Weight = Tree.Nodes(Curr).Weight and then
                  I /= Tree.Nodes(Curr).Parent 
               then
                  if Variant = FGK then
                     Highest := I;
                  else
                     -- Vitter specific rule: Leaves always precede internal nodes of the same weight.
                     if not Tree.Nodes(Curr).Is_Leaf then
                        -- An internal node can only swap past other internal nodes
                        if not Tree.Nodes(I).Is_Leaf then
                           Highest := I;
                        end if;
                     else
                        Highest := I;
                     end if;
                  end if;
               end if;
            end loop;
         end if;

         if Highest /= Curr then
            Swap_Nodes (Tree, Curr, Highest);
            Curr := Highest;
         end if;

         Tree.Nodes(Curr).Weight := Tree.Nodes(Curr).Weight + 1;
         Curr := Tree.Nodes(Curr).Parent;
      end loop;
   end Update_Tree;

   function Encode (Text : String; Variant : Variant_Type) return String is
      Tree : Tree_Type;
      Result : Unbounded_String;
   begin
      if Text'Length = 0 then return ""; end if;
      
      Initialize_Tree (Tree);
      for I in Text'Range loop
         declare
            Char : Character := Text(I);
            Node : Node_Index := Tree.Symbol_Map (Char);
         begin
            if Node /= Null_Index then
               Append (Result, Get_Path (Tree, Node));
               Update_Tree (Tree, Node, Variant);
            else
               -- Unseen symbol: Send NYT path + raw bits
               Append (Result, Get_Path (Tree, Tree.NYT_Index));
               Append (Result, Char_To_Bits (Char));
               
               declare
                  Old_NYT : Node_Index := Tree.NYT_Index;
                  New_NYT : Node_Index := Old_NYT - 2;
                  New_Sym : Node_Index := Old_NYT - 1;
               begin
                  Tree.Nodes(New_NYT) := (Weight => 0, Parent => Old_NYT, Left => Null_Index, Right => Null_Index, Symbol => ASCII.NUL, Is_Leaf => True, Is_NYT => True);
                  Tree.Nodes(New_Sym) := (Weight => 1, Parent => Old_NYT, Left => Null_Index, Right => Null_Index, Symbol => Char, Is_Leaf => True, Is_NYT => False);
                  
                  Tree.Nodes(Old_NYT).Left := New_NYT;
                  Tree.Nodes(Old_NYT).Right := New_Sym;
                  Tree.Nodes(Old_NYT).Is_NYT := False;
                  Tree.Nodes(Old_NYT).Is_Leaf := False;
                  
                  Tree.Symbol_Map(Char) := New_Sym;
                  Tree.NYT_Index := New_NYT;
                  
                  Update_Tree (Tree, Old_NYT, Variant);
               end;
            end if;
         end;
      end loop;
      
      return To_String (Result);
   end Encode;

   function Decode (Bits : String; Variant : Variant_Type) return String is
      Tree : Tree_Type;
      Result : String (1 .. Bits'Length);
      Result_Len : Natural := 0;
      Curr_Bit : Positive := Bits'First;
      Curr_Node : Node_Index;
   begin
      if Bits'Length = 0 then return ""; end if;

      Initialize_Tree (Tree);
      
      while Curr_Bit <= Bits'Last loop
         Curr_Node := Tree.Root;
         
         while not Tree.Nodes(Curr_Node).Is_Leaf loop
            if Curr_Bit > Bits'Last then raise Invalid_Bit_Stream; end if;
            
            if Bits(Curr_Bit) = '0' then
               Curr_Node := Tree.Nodes(Curr_Node).Left;
            elsif Bits(Curr_Bit) = '1' then
               Curr_Node := Tree.Nodes(Curr_Node).Right;
            else
               raise Invalid_Bit_Stream;
            end if;
            Curr_Bit := Curr_Bit + 1;
         end loop;
         
         declare
            Decoded_Char : Character;
         begin
            if Tree.Nodes(Curr_Node).Is_NYT then
               if Curr_Bit + 7 > Bits'Last then raise Invalid_Bit_Stream; end if;
               Decoded_Char := Bits_To_Char (Bits (Curr_Bit .. Curr_Bit + 7));
               Curr_Bit := Curr_Bit + 8;
               
               Result_Len := Result_Len + 1;
               Result (Result_Len) := Decoded_Char;
               
               declare
                  Old_NYT : Node_Index := Tree.NYT_Index;
                  New_NYT : Node_Index := Old_NYT - 2;
                  New_Sym : Node_Index := Old_NYT - 1;
               begin
                  Tree.Nodes(New_NYT) := (Weight => 0, Parent => Old_NYT, Left => Null_Index, Right => Null_Index, Symbol => ASCII.NUL, Is_Leaf => True, Is_NYT => True);
                  Tree.Nodes(New_Sym) := (Weight => 1, Parent => Old_NYT, Left => Null_Index, Right => Null_Index, Symbol => Decoded_Char, Is_Leaf => True, Is_NYT => False);
                  
                  Tree.Nodes(Old_NYT).Left := New_NYT;
                  Tree.Nodes(Old_NYT).Right := New_Sym;
                  Tree.Nodes(Old_NYT).Is_NYT := False;
                  Tree.Nodes(Old_NYT).Is_Leaf := False;
                  
                  Tree.Symbol_Map(Decoded_Char) := New_Sym;
                  Tree.NYT_Index := New_NYT;
                  
                  Update_Tree (Tree, Old_NYT, Variant);
               end;
            else
               Decoded_Char := Tree.Nodes(Curr_Node).Symbol;
               Result_Len := Result_Len + 1;
               Result (Result_Len) := Decoded_Char;
               Update_Tree (Tree, Curr_Node, Variant);
            end if;
         end;
      end loop;
      
      return Result (1 .. Result_Len);
   end Decode;

end Adaptive_Huffman;

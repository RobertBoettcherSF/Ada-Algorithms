-- huffman_coding.adb
-- Implementation body for Huffman Coding algorithms.

with Ada.Unchecked_Deallocation;

package body Huffman_Coding is

   -- Helper to free individual nodes
   procedure Free is new Ada.Unchecked_Deallocation(Huffman_Node, Tree_Access);

   ----------------------------------------------------------------------------
   -- Get_Frequencies
   ----------------------------------------------------------------------------
   function Get_Frequencies (Text : String) return Frequency_Map is
      Map : Frequency_Map;
   begin
      if Text'Length = 0 then
         raise Empty_Input;
      end if;
      
      for Char of Text loop
         if Map.Contains (Char) then
            Map.Include (Char, Map.Element (Char) + 1);
         else
            Map.Insert (Char, 1);
         end if;
      end loop;
      return Map;
   end Get_Frequencies;

   ----------------------------------------------------------------------------
   -- Build_Tree (Standard Huffman)
   ----------------------------------------------------------------------------
   function Build_Tree (Frequencies : Frequency_Map) return Tree_Access is
      -- Using a simple array to act as our working pool since ASCII max is 256.
      -- This avoids heavy queue overhead while maintaining O(N^2) which is negligible for N<=256.
      type Node_Array is array (1 .. 256) of Tree_Access;
      Nodes : Node_Array;
      Count : Natural := 0;
      
      Min1_Idx, Min2_Idx : Natural;
      Min1, Min2 : Tree_Access;
      New_Node : Tree_Access;
   begin
      if Frequencies.Is_Empty then
         raise Empty_Input;
      end if;

      -- Populate initial nodes
      for Position in Frequencies.Iterate loop
         Count := Count + 1;
         Nodes (Count) := new Huffman_Node'(
            Symbol => Frequency_Maps.Key(Position),
            Weight => Frequency_Maps.Element(Position),
            Left   => null,
            Right  => null
         );
      end loop;

      -- Edge case: If only one unique character exists, return a dummy root with one leaf
      if Count = 1 then
         return new Huffman_Node'(
            Symbol => ASCII.NUL,
            Weight => Nodes(1).Weight,
            Left   => Nodes(1),
            Right  => null
         );
      end if;

      -- Build the tree
      while Count > 1 loop
         -- Find first minimum
         Min1_Idx := 1;
         for I in 2 .. Count loop
            if Nodes(I).Weight < Nodes(Min1_Idx).Weight then
               Min1_Idx := I;
            end if;
         end loop;
         Min1 := Nodes(Min1_Idx);
         Nodes(Min1_Idx) := Nodes(Count);
         Count := Count - 1;
         
         -- Find second minimum
         Min2_Idx := 1;
         for I in 2 .. Count loop
            if Nodes(I).Weight < Nodes(Min2_Idx).Weight then
               Min2_Idx := I;
            end if;
         end loop;
         Min2 := Nodes(Min2_Idx);
         Nodes(Min2_Idx) := Nodes(Count);
         Count := Count - 1;
         
         -- Create parent node combining Min1 and Min2
         New_Node := new Huffman_Node'(
            Symbol => ASCII.NUL,
            Weight => Min1.Weight + Min2.Weight,
            Left   => Min1,
            Right  => Min2
         );
         
         -- Insert back into pool
         Count := Count + 1;
         Nodes(Count) := New_Node;
      end loop;

      return Nodes(1);
   end Build_Tree;

   ----------------------------------------------------------------------------
   -- Generate_Codes
   ----------------------------------------------------------------------------
   function Generate_Codes (Tree : Tree_Access) return Code_Map is
      Map : Code_Map;

      procedure Traverse (Node : Tree_Access; Current_Code : String) is
      begin
         if Node = null then
            return;
         end if;
         
         -- Leaf node
         if Node.Left = null and Node.Right = null then
            -- Edge case: string of single repeating character
            if Current_Code = "" then
               Map.Insert (Node.Symbol, To_Unbounded_String("0"));
            else
               Map.Insert (Node.Symbol, To_Unbounded_String(Current_Code));
            end if;
         else
            Traverse (Node.Left, Current_Code & "0");
            Traverse (Node.Right, Current_Code & "1");
         end if;
      end Traverse;

   begin
      if Tree = null then
         raise Invalid_Tree;
      end if;
      Traverse (Tree, "");
      return Map;
   end Generate_Codes;

   ----------------------------------------------------------------------------
   -- Encode
   ----------------------------------------------------------------------------
   function Encode (Text : String; Codes : Code_Map) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Text'Length = 0 then
         raise Empty_Input;
      end if;
      
      for Char of Text loop
         if not Codes.Contains (Char) then
            raise Data_Error; -- Character not in standard codes
         end if;
         Result := Result & Codes.Element(Char);
      end loop;
      return To_String (Result);
   end Encode;

   ----------------------------------------------------------------------------
   -- Decode
   ----------------------------------------------------------------------------
   function Decode (Encoded_Text : String; Tree : Tree_Access) return String is
      Result  : Unbounded_String := Null_Unbounded_String;
      Current : Tree_Access := Tree;
   begin
      if Tree = null then
         raise Invalid_Tree;
      end if;
      if Encoded_Text'Length = 0 then
         raise Empty_Input;
      end if;

      for Bit of Encoded_Text loop
         if Bit = '0' then
            if Current.Left /= null then
               Current := Current.Left;
            else
               raise Data_Error; -- Malformed tree or corrupted bitstream
            end if;
         elsif Bit = '1' then
            if Current.Right /= null then
               Current := Current.Right;
            else
               raise Data_Error;
            end if;
         else
            raise Data_Error; -- Invalid character in bitstream (not 0 or 1)
         end if;
         
         -- If we reached a leaf, append symbol and reset to root
         if Current.Left = null and Current.Right = null then
            Result := Result & Current.Symbol;
            Current := Tree;
         end if;
      end loop;

      -- If parsing finishes but we aren't back at the root, bitstream is incomplete
      if Current /= Tree then
         raise Data_Error;
      end if;

      return To_String (Result);
   end Decode;

   ----------------------------------------------------------------------------
   -- Generate_Canonical_Codes
   ----------------------------------------------------------------------------
   function Generate_Canonical_Codes (Standard_Codes : Code_Map) return Code_Map is
      -- Define structure to help sorting lengths
      type Code_Entry is record
         Symbol : Character;
         Length : Positive;
      end record;
      type Entry_Array is array (1 .. 256) of Code_Entry;
      
      Entries : Entry_Array;
      Count   : Natural := 0;
      Temp    : Code_Entry;
      Result  : Code_Map;
      
      Code_Val       : Natural := 0;
      Current_Length : Positive;
      
      -- Converts a natural integer into a zero-padded binary string
      function To_Binary_String (Value : Natural; Len : Positive) return Unbounded_String is
         Bin_Str : String (1 .. Len) := (others => '0');
         Val : Natural := Value;
      begin
         for I in reverse 1 .. Len loop
            if Val mod 2 = 1 then
               Bin_Str (I) := '1';
            end if;
            Val := Val / 2;
         end loop;
         return To_Unbounded_String (Bin_Str);
      end To_Binary_String;
      
   begin
      -- Extract Symbol and Code Lengths
      for Position in Standard_Codes.Iterate loop
         Count := Count + 1;
         Entries(Count) := (Symbol => Code_Maps.Key(Position), 
                            Length => Length(Code_Maps.Element(Position)));
      end loop;
      
      -- Bubble sort: Sort by Length (Ascending), then by Symbol (Ascending)
      for I in 1 .. Count - 1 loop
         for J in 1 .. Count - I loop
            if Entries(J).Length > Entries(J+1).Length or else
               (Entries(J).Length = Entries(J+1).Length and then Entries(J).Symbol > Entries(J+1).Symbol) 
            then
               Temp := Entries(J);
               Entries(J) := Entries(J+1);
               Entries(J+1) := Temp;
            end if;
         end loop;
      end loop;
      
      -- Generate canonical codes
      if Count > 0 then
         Current_Length := Entries(1).Length;
         for I in 1 .. Count loop
            -- Shift code left if the length increases
            while Current_Length < Entries(I).Length loop
               Code_Val := Code_Val * 2;
               Current_Length := Current_Length + 1;
            end loop;
            
            Result.Insert (Entries(I).Symbol, To_Binary_String(Code_Val, Current_Length));
            Code_Val := Code_Val + 1;
         end loop;
      end if;
      
      return Result;
   end Generate_Canonical_Codes;

   ----------------------------------------------------------------------------
   -- Encode_Adaptive (Placeholder)
   ----------------------------------------------------------------------------
   procedure Encode_Adaptive (Text : String; Result : out Unbounded_String) is
   begin
      raise Not_Implemented;
   end Encode_Adaptive;

   ----------------------------------------------------------------------------
   -- Free_Tree
   ----------------------------------------------------------------------------
   procedure Free_Tree (Tree : in out Tree_Access) is
   begin
      if Tree /= null then
         Free_Tree (Tree.Left);
         Free_Tree (Tree.Right);
         Free (Tree);
      end if;
   end Free_Tree;

end Huffman_Coding;

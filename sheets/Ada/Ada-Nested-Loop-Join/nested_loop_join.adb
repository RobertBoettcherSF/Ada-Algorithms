package body Nested_Loop_Join is

   -- Hash function implementation for Key_Type
   function Hash (K : Key_Type) return Ada.Containers.Hash_Type is
   begin
      -- Absolute value mod prime for simple distribution
      return Ada.Containers.Hash_Type (abs (Integer (K)) mod 997);
   end Hash;

   -----------------------------------------------------------------------------
   -- 1. Naive Nested Loop Join
   -----------------------------------------------------------------------------
   function Naive_Nested_Loop_Join
     (Outer_Rel : Tuple_Array;
      Inner_Rel : Tuple_Array) return Joined_Relation
   is
      Result : Joined_Relation;
   begin
      -- Edge Case: Empty relations inherently bypass loops
      for O_Tuple of Outer_Rel loop
         for I_Tuple of Inner_Rel loop
            -- Join condition: Equality on Key
            if O_Tuple.Key = I_Tuple.Key then
               Result.Append ((Outer_Key  => O_Tuple.Key,
                               Outer_Data => O_Tuple.Data,
                               Inner_Data => I_Tuple.Data));
            end if;
         end loop;
      end loop;
      
      return Result;
   end Naive_Nested_Loop_Join;

   -----------------------------------------------------------------------------
   -- 2. Block Nested Loop Join
   -----------------------------------------------------------------------------
   function Block_Nested_Loop_Join
     (Outer_Rel  : Tuple_Array;
      Inner_Rel  : Tuple_Array;
      Block_Size : Integer) return Joined_Relation
   is
      Result     : Joined_Relation;
      Num_Blocks : Integer;
   begin
      -- Validation: Block size must be strictly positive
      if Block_Size <= 0 then
         raise Invalid_Block_Size;
      end if;

      -- Handle empty outer relation cleanly
      if Outer_Rel'Length = 0 then
         return Result;
      end if;

      -- Calculate total blocks needed (ceiling division)
      Num_Blocks := (Outer_Rel'Length + Block_Size - 1) / Block_Size;

      for B in 0 .. Num_Blocks - 1 loop
         declare
            Start_Idx : constant Positive := Outer_Rel'First + B * Block_Size;
            End_Idx   : constant Positive := Integer'Min (Start_Idx + Block_Size - 1, Outer_Rel'Last);
         begin
            -- The inner relation is scanned completely for each Block
            for I_Tuple of Inner_Rel loop
               -- Process all elements inside the current Outer block
               for O_Idx in Start_Idx .. End_Idx loop
                  if Outer_Rel (O_Idx).Key = I_Tuple.Key then
                     Result.Append ((Outer_Key  => Outer_Rel (O_Idx).Key,
                                     Outer_Data => Outer_Rel (O_Idx).Data,
                                     Inner_Data => I_Tuple.Data));
                  end if;
               end loop;
            end loop;
         end;
      end loop;

      return Result;
   end Block_Nested_Loop_Join;

   -----------------------------------------------------------------------------
   -- 3. Helper: Build Index
   -----------------------------------------------------------------------------
   function Build_Index (Inner_Rel : Tuple_Array) return Inner_Index is
      Index : Inner_Index;
   begin
      for I_Tuple of Inner_Rel loop
         if Index.Contains (I_Tuple.Key) then
            declare
               -- Extract current vector, append new tuple (handles 1-to-N duplicate keys)
               Vec : Tuple_Vectors.Vector := Index.Element (I_Tuple.Key);
            begin
               Vec.Append (I_Tuple);
               Index.Replace (I_Tuple.Key, Vec);
            end;
         else
            declare
               Vec : Tuple_Vectors.Vector;
            begin
               Vec.Append (I_Tuple);
               Index.Insert (I_Tuple.Key, Vec);
            end;
         end if;
      end loop;
      
      return Index;
   end Build_Index;

   -----------------------------------------------------------------------------
   -- 4. Index Nested Loop Join
   -----------------------------------------------------------------------------
   function Index_Nested_Loop_Join
     (Outer_Rel : Tuple_Array;
      Index     : Inner_Index) return Joined_Relation
   is
      Result : Joined_Relation;
   begin
      -- Outer loop iterates normally, but inner uses index lookup (O(1) average)
      for O_Tuple of Outer_Rel loop
         if Index.Contains (O_Tuple.Key) then
            -- Iterate over all matching inner tuples for this specific key
            for I_Tuple of Index.Element (O_Tuple.Key) loop
               Result.Append ((Outer_Key  => O_Tuple.Key,
                               Outer_Data => O_Tuple.Data,
                               Inner_Data => I_Tuple.Data));
            end loop;
         end if;
      end loop;
      
      return Result;
   end Index_Nested_Loop_Join;

end Nested_Loop_Join;

-- block_nested_loop.adb
package body Block_Nested_Loop is

   ------------------------
   -- Nested_Loop_Join --
   ------------------------
   function Nested_Loop_Join 
     (R : Table_R; 
      S : Table_S) return Joined_Table 
   is
      -- Maximum possible size is the Cartesian product
      Max_Results : constant Natural := R'Length * S'Length;
      Result      : Joined_Table (1 .. Max_Results);
      Count       : Natural := 0;
   begin
      -- Return empty immediately if either table is empty
      if R'Length = 0 or else S'Length = 0 then
         return Result (1 .. 0);
      end if;

      -- Iterate tuple-by-tuple
      for I in R'Range loop
         for J in S'Range loop
            if R(I).Key = S(J).Key then
               Count := Count + 1;
               Result(Count) := (Key    => R(I).Key, 
                                 Data_R => R(I).Data, 
                                 Data_S => S(J).Data);
            end if;
         end loop;
      end loop;

      -- Return tightly packed array of actual matches
      return Result (1 .. Count);
   end Nested_Loop_Join;

   ------------------------------
   -- Block_Nested_Loop_Join --
   ------------------------------
   function Block_Nested_Loop_Join 
     (R          : Table_R; 
      S          : Table_S; 
      Block_Size : Integer) return Joined_Table 
   is
      Max_Results : constant Natural := R'Length * S'Length;
      Result      : Joined_Table (1 .. Max_Results);
      Count       : Natural := 0;

      Block_Start : Natural;
      Block_End   : Natural;
   begin
      -- Validate Block_Size to avoid infinite loops or memory errors
      if Block_Size <= 0 then
         raise Invalid_Block_Size with "Block size must be strictly positive.";
      end if;

      if R'Length = 0 or else S'Length = 0 then
         return Result (1 .. 0);
      end if;

      Block_Start := R'First;

      -- Process relation R in chunks of Block_Size
      while Block_Start <= R'Last loop
         
         -- Calculate block end, truncating if it exceeds the array boundary
         Block_End := Block_Start + Block_Size - 1;
         if Block_End > R'Last then
            Block_End := R'Last;
         end if;

         -- For each tuple in the inner relation S
         for J in S'Range loop
            -- Compare the inner tuple against every tuple in the *current chunk* of R
            for I in Block_Start .. Block_End loop
               if R(I).Key = S(J).Key then
                  Count := Count + 1;
                  Result(Count) := (Key    => R(I).Key, 
                                    Data_R => R(I).Data, 
                                    Data_S => S(J).Data);
               end if;
            end loop;
         end loop;

         -- Move to the next block
         Block_Start := Block_End + 1;
      end loop;

      return Result (1 .. Count);
   end Block_Nested_Loop_Join;

end Block_Nested_Loop;

-- topological_sorting.adb
-- Implementation of Topological Sorting algorithms.

package body Topological_Sorting is

   procedure Add_Edge (G : in out Graph; From, To : Node_ID) is
   begin
      -- Validate bounds
      if Natural(From) > G.Num_Nodes or Natural(To) > G.Num_Nodes then
         raise Invalid_Graph;
      end if;
      G.Edges(Natural(From)).Append(To);
   end Add_Edge;


   function Is_Valid_Sort (G : in Graph; Result : in Node_Array) return Boolean is
      Position : array (1 .. G.Num_Nodes) of Natural := (others => 0);
   begin
      if Result'Length /= G.Num_Nodes then 
         return False; 
      end if;
      
      -- Map each node to its index in the sorted result
      for I in Result'Range loop
         Position(Natural(Result(I))) := I;
      end loop;

      -- For every edge U -> V, U must appear BEFORE V in the result
      for U in 1 .. G.Num_Nodes loop
         for V of G.Edges(U) loop
            if Position(U) >= Position(Natural(V)) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Sort;


   -- Variant 1: Kahn's Algorithm
   procedure Kahn_Sort 
     (G       : in Graph; 
      Result  : out Node_Array; 
      Success : out Boolean) 
   is
      In_Degree : array (1 .. G.Num_Nodes) of Natural := (others => 0);
      Zero_In   : Node_Vectors.Vector; -- Queue of nodes with 0 in-degree
      Result_Idx: Natural := Result'First;
      Current   : Node_ID;
   begin
      -- Step 1: Calculate initial in-degrees for all nodes
      for I in 1 .. G.Num_Nodes loop
         for Neighbor of G.Edges(I) loop
            In_Degree(Natural(Neighbor)) := In_Degree(Natural(Neighbor)) + 1;
         end loop;
      end loop;

      -- Step 2: Enqueue all nodes with in-degree 0
      for I in 1 .. G.Num_Nodes loop
         if In_Degree(I) = 0 then
            Zero_In.Append(Node_ID(I));
         end if;
      end loop;

      -- Step 3: Process the queue
      while not Zero_In.Is_Empty loop
         Current := Zero_In.Last_Element;
         Zero_In.Delete_Last;
         
         Result(Result_Idx) := Current;
         Result_Idx := Result_Idx + 1;

         -- Decrease in-degree of all neighbors
         for Neighbor of G.Edges(Natural(Current)) loop
            In_Degree(Natural(Neighbor)) := In_Degree(Natural(Neighbor)) - 1;
            if In_Degree(Natural(Neighbor)) = 0 then
               Zero_In.Append(Neighbor);
            end if;
         end loop;
      end loop;

      -- Step 4: Check if cycle exists (processed nodes < total nodes)
      if Result_Idx - Result'First < G.Num_Nodes then
         Success := False; -- Cycle detected
      else
         Success := True;
      end if;
   end Kahn_Sort;


   -- Variant 2: Depth-First Search Algorithm
   procedure DFS_Sort 
     (G       : in Graph; 
      Result  : out Node_Array; 
      Success : out Boolean) 
   is
      type Mark_Type is (Unmarked, Temporary, Permanent);
      Marks      : array (1 .. G.Num_Nodes) of Mark_Type := (others => Unmarked);
      Result_Idx : Natural := Result'Last;
      Has_Cycle  : Boolean := False;

      procedure Visit (N : Node_ID) is
      begin
         if Has_Cycle then return; end if; -- Fast exit if cycle found

         if Marks(Natural(N)) = Permanent then
            return;
         end if;
         
         if Marks(Natural(N)) = Temporary then
            Has_Cycle := True;
            return;
         end if;

         -- Mark current node as visiting (Temporary) to catch cycles
         Marks(Natural(N)) := Temporary;

         -- Visit all neighbors
         for Neighbor of G.Edges(Natural(N)) loop
            Visit(Neighbor);
         end loop;

         -- Mark as fully explored (Permanent) and prepend to result
         Marks(Natural(N)) := Permanent;
         Result(Result_Idx) := N;
         
         if Result_Idx > Result'First then
            Result_Idx := Result_Idx - 1;
         end if;
      end Visit;

   begin
      -- Visit all unmarked nodes
      for I in 1 .. G.Num_Nodes loop
         if Marks(I) = Unmarked then
            Visit(Node_ID(I));
         end if;
      end loop;

      Success := not Has_Cycle;
   end DFS_Sort;

end Topological_Sorting;

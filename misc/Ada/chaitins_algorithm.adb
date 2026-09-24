package body Chaitins_Algorithm is

   ------------------
   -- Stack Helper --
   ------------------

   type Stack_Array is array (1 .. Maximum_Nodes) of Node_ID;
   
   type Node_Stack is record
      Elements : Stack_Array := [others => 1];
      Top      : Node_Count := 0;
   end record;

   procedure Push (S : in out Node_Stack; N : Node_ID) is
   begin
      S.Top := S.Top + 1;
      S.Elements (Integer (S.Top)) := N;
   end Push;

   procedure Pop (S : in out Node_Stack; N : out Node_ID) is
   begin
      N := S.Elements (Integer (S.Top));
      S.Top := S.Top - 1;
   end Pop;

   ------------------
   -- Graph Helper --
   ------------------

   --  Removes a node and updates the degrees of all its active neighbors.
   procedure Remove_Node (Graph : in out Interference_Graph; N : Node_ID) is
   begin
      Graph.Nodes (N) := False;
      Graph.Active_Node_Count := Graph.Active_Node_Count - 1;

      for V in Node_ID loop
         if Graph.Edges (N, V) and then Graph.Nodes (V) then
            if Graph.Degrees (V) > 0 then
               Graph.Degrees (V) := Graph.Degrees (V) - 1;
            end if;
         end if;
      end loop;
   end Remove_Node;

   ----------------------
   -- Initialize_Graph --
   ----------------------

   procedure Initialize_Graph (Graph : out Interference_Graph; Nodes : Node_Count) is
   begin
      Graph := (Active_Node_Count => Nodes, 
                Nodes             => Empty_Node_Set,
                Edges             => [others => [others => False]], 
                Degrees           => [others => 0]);
                
      for I in 1 .. Nodes loop
         Graph.Nodes (Node_ID (I)) := True;
      end loop;
   end Initialize_Graph;

   --------------
   -- Add_Edge --
   --------------

   procedure Add_Edge (Graph : in out Interference_Graph; U, V : Node_ID) is
   begin
      if not Graph.Nodes (U) or else not Graph.Nodes (V) then
         raise Graph_Error with "Cannot add edge to inactive node";
      end if;

      if U /= V and then not Graph.Edges (U, V) then
         Graph.Edges (U, V) := True;
         Graph.Edges (V, U) := True;
         Graph.Degrees (U) := Graph.Degrees (U) + 1;
         Graph.Degrees (V) := Graph.Degrees (V) + 1;
      end if;
   end Add_Edge;

   ----------------------------
   -- Basic_Chaitin_Allocate --
   ----------------------------

   procedure Basic_Chaitin_Allocate (
      Graph      : in  Interference_Graph;
      K          : in  Register_Count;
      Allocation : out Allocation_Map;
      Spilled    : out Node_Set
   ) is
      Working_Graph : Interference_Graph := Graph;
      Stack         : Node_Stack;
      Found         : Boolean;
      Best_Spill    : Node_ID;
      Max_Deg       : Node_Count;
      Popped_Node   : Node_ID;
      Available     : array (Color_ID range 1 .. Color_ID (K)) of Boolean;
      Assigned      : Boolean;
   begin
      Allocation := Empty_Allocation;
      Spilled    := Empty_Node_Set;

      --  Phase 1: Build & Simplify
      while Working_Graph.Active_Node_Count > 0 loop
         Found := False;
         
         --  Look for a node with degree strictly less than K
         for N in Node_ID loop
            if Working_Graph.Nodes (N) and then Working_Graph.Degrees (N) < Node_Count (K) then
               Push (Stack, N);
               Remove_Node (Working_Graph, N);
               Found := True;
               exit;
            end if;
         end loop;

         --  If no node can be simplified, we must spill. 
         --  We use maximum degree as a heuristic for spill choice.
         if not Found then
            Max_Deg := 0;
            Best_Spill := 1;
            
            for N in Node_ID loop
               if Working_Graph.Nodes (N) and then Working_Graph.Degrees (N) >= Max_Deg then
                  Max_Deg := Working_Graph.Degrees (N);
                  Best_Spill := N;
               end if;
            end loop;

            --  Basic Chaitin immediately marks it spilled and removes it entirely.
            Spilled (Best_Spill) := True;
            Remove_Node (Working_Graph, Best_Spill);
         end if;
      end loop;

      --  Phase 2: Select
      while Stack.Top > 0 loop
         Pop (Stack, Popped_Node);
         Available := [others => True];

         --  Find colors used by neighbors in the original graph
         for V in Node_ID loop
            if Graph.Edges (Popped_Node, V) and then Allocation (V) /= Spilled_Color then
               Available (Allocation (V)) := False;
            end if;
         end loop;

         --  Assign the first available color
         Assigned := False;
         for C in Color_ID range 1 .. Color_ID (K) loop
            if Available (C) then
               Allocation (Popped_Node) := C;
               Assigned := True;
               exit;
            end if;
         end loop;

         --  Nodes simplified must be colorable by definition of degree < K.
         pragma Assert (Assigned, "Basic Chaitin: Failed to color a simplified node");
      end loop;
   end Basic_Chaitin_Allocate;

   -----------------------------
   -- Chaitin_Briggs_Allocate --
   -----------------------------

   procedure Chaitin_Briggs_Allocate (
      Graph      : in  Interference_Graph;
      K          : in  Register_Count;
      Allocation : out Allocation_Map;
      Spilled    : out Node_Set
   ) is
      Working_Graph : Interference_Graph := Graph;
      Stack         : Node_Stack;
      Found         : Boolean;
      Best_Spill    : Node_ID;
      Max_Deg       : Node_Count;
      Popped_Node   : Node_ID;
      Available     : array (Color_ID range 1 .. Color_ID (K)) of Boolean;
      Assigned      : Boolean;
   begin
      Allocation := Empty_Allocation;
      Spilled    := Empty_Node_Set;

      --  Phase 1: Build & Simplify
      while Working_Graph.Active_Node_Count > 0 loop
         Found := False;
         
         for N in Node_ID loop
            if Working_Graph.Nodes (N) and then Working_Graph.Degrees (N) < Node_Count (K) then
               Push (Stack, N);
               Remove_Node (Working_Graph, N);
               Found := True;
               exit;
            end if;
         end loop;

         --  If no node can be simplified, choose a node to potentially spill (optimistic)
         if not Found then
            Max_Deg := 0;
            Best_Spill := 1;
            
            for N in Node_ID loop
               if Working_Graph.Nodes (N) and then Working_Graph.Degrees (N) >= Max_Deg then
                  Max_Deg := Working_Graph.Degrees (N);
                  Best_Spill := N;
               end if;
            end loop;

            --  Chaitin-Briggs pushes the potential spill onto the stack anyway.
            Push (Stack, Best_Spill);
            Remove_Node (Working_Graph, Best_Spill);
         end if;
      end loop;

      --  Phase 2: Select (Optimistic check)
      while Stack.Top > 0 loop
         Pop (Stack, Popped_Node);
         Available := [others => True];

         --  Check neighbor colors. Some might have been spilled or coalesced.
         for V in Node_ID loop
            if Graph.Edges (Popped_Node, V) and then Allocation (V) /= Spilled_Color then
               Available (Allocation (V)) := False;
            end if;
         end loop;

         Assigned := False;
         for C in Color_ID range 1 .. Color_ID (K) loop
            if Available (C) then
               Allocation (Popped_Node) := C;
               Assigned := True;
               exit;
            end if;
         end loop;

         --  If no color is available, this node must be heavily spilled.
         if not Assigned then
            Spilled (Popped_Node) := True;
            Allocation (Popped_Node) := Spilled_Color;
         end if;
      end loop;
   end Chaitin_Briggs_Allocate;

end Chaitins_Algorithm;

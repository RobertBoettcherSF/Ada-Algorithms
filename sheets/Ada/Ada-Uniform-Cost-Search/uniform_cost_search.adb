package body Uniform_Cost_Search is

   ----------------------------------
   -- Priority Queue Implementation--
   ----------------------------------
   -- Element stored in the Priority Queue
   type PQ_Element is record
      Node : Node_Id;
      Cost : Cost_Type;
      Path : Path_Vectors.Vector;
   end record;

   type PQ_Array is array (Positive range <>) of PQ_Element;

   -- A bounded Min-Heap Priority Queue for O(log n) inserts/pops
   protected type Priority_Queue (Capacity : Positive) is
      procedure Push (Item : PQ_Element);
      procedure Pop (Item : out PQ_Element);
      function Is_Empty return Boolean;
   private
      Data : PQ_Array (1 .. Capacity);
      Size : Natural := 0;
   end Priority_Queue;

   protected body Priority_Queue is
      procedure Push (Item : PQ_Element) is
         Idx : Positive;
         Parent : Positive;
      begin
         if Size >= Capacity then
            raise Program_Error with "Priority Queue Overflow";
         end if;
         Size := Size + 1;
         Idx := Size;
         -- Bubble up
         while Idx > 1 loop
            Parent := Idx / 2;
            if Data (Parent).Cost <= Item.Cost then
               exit;
            end if;
            Data (Idx) := Data (Parent);
            Idx := Parent;
         end loop;
         Data (Idx) := Item;
      end Push;

      procedure Pop (Item : out PQ_Element) is
         Idx, Child : Positive;
         Temp : PQ_Element;
      begin
         if Size = 0 then
            raise Program_Error with "Priority Queue Underflow";
         end if;
         Item := Data (1);
         Temp := Data (Size);
         Size := Size - 1;
         
         if Size > 0 then
            Idx := 1;
            -- Bubble down
            while Idx * 2 <= Size loop
               Child := Idx * 2;
               if Child < Size and then Data (Child + 1).Cost < Data (Child).Cost then
                  Child := Child + 1;
               end if;
               if Temp.Cost <= Data (Child).Cost then
                  exit;
               end if;
               Data (Idx) := Data (Child);
               Idx := Child;
            end loop;
            Data (Idx) := Temp;
         end if;
      end Pop;

      function Is_Empty return Boolean is
      begin
         return Size = 0;
      end Is_Empty;
   end Priority_Queue;

   ----------------------------------
   -- Graph Modifiers and Helpers  --
   ----------------------------------

   procedure Add_Node (G : in out Graph; Node : Node_Id) is
   begin
      if Node = Invalid_Node then raise Graph_Error with "Invalid Node ID"; end if;
      G.Presence (Node) := True;
   end Add_Node;

   procedure Add_Edge (G : in out Graph; From, To : Node_Id; Cost : Cost_Type) is
   begin
      if not G.Presence (From) then Add_Node (G, From); end if;
      if not G.Presence (To) then Add_Node (G, To); end if;
      G.Edges (From).Append ((Target => To, Cost => Cost));
   end Add_Edge;

   function Contains_Node (G : Graph; Node : Node_Id) return Boolean is
   begin
      if Node = Invalid_Node or Node > Node_Id (Max_Nodes_Limit) then return False; end if;
      return G.Presence (Node);
   end Contains_Node;

   ----------------------------------
   -- Uniform Cost Search Algorithms-
   ----------------------------------

   -- Variant 1: Graph Search
   function UCS_Graph_Search (G : Graph; Start, Goal : Node_Id) return Search_Result is
      PQ : Priority_Queue (Capacity => 100_000);
      Explored : array (Node_Id range 1 .. Node_Id (Max_Nodes_Limit)) of Boolean := (others => False);
      Current : PQ_Element;
      New_Path : Path_Vectors.Vector;
   begin
      if not Contains_Node (G, Start) or not Contains_Node (G, Goal) then
         raise Graph_Error with "Start or Goal node not in graph";
      end if;

      New_Path.Append (Start);
      PQ.Push ((Node => Start, Cost => 0, Path => New_Path));

      while not PQ.Is_Empty loop
         PQ.Pop (Current);

         -- Goal Check
         if Current.Node = Goal then
            return (Found => True, Cost => Current.Cost, Path => Current.Path);
         end if;

         -- Explored set prevents processing cycles and duplicate suboptimal paths
         if not Explored (Current.Node) then
            Explored (Current.Node) := True;

            for E of G.Edges (Current.Node) loop
               if not Explored (E.Target) then
                  New_Path := Current.Path;
                  New_Path.Append (E.Target);
                  PQ.Push ((Node => E.Target, Cost => Current.Cost + E.Cost, Path => New_Path));
               end if;
            end loop;
         end if;
      end loop;

      return (Found => False, Cost => Unreachable, Path => Path_Vectors.Empty_Vector);
   end UCS_Graph_Search;

   -- Variant 2: Tree Search
   function UCS_Tree_Search (G : Graph; Start, Goal : Node_Id; Max_Expansions : Natural := 10000) return Search_Result is
      PQ : Priority_Queue (Capacity => 100_000);
      Current : PQ_Element;
      New_Path : Path_Vectors.Vector;
      Expansions : Natural := 0;
   begin
      if not Contains_Node (G, Start) or not Contains_Node (G, Goal) then
         raise Graph_Error with "Start or Goal node not in graph";
      end if;

      New_Path.Append (Start);
      PQ.Push ((Node => Start, Cost => 0, Path => New_Path));

      while not PQ.Is_Empty loop
         PQ.Pop (Current);
         Expansions := Expansions + 1;

         if Expansions > Max_Expansions then
            raise Search_Limit_Exceeded with "Tree Search encountered cyclic explosion or exceeded limit";
         end if;

         -- Goal Check
         if Current.Node = Goal then
            return (Found => True, Cost => Current.Cost, Path => Current.Path);
         end if;

         -- No explored check: blindly expand all children
         for E of G.Edges (Current.Node) loop
            New_Path := Current.Path;
            New_Path.Append (E.Target);
            PQ.Push ((Node => E.Target, Cost => Current.Cost + E.Cost, Path => New_Path));
         end loop;
      end loop;

      return (Found => False, Cost => Unreachable, Path => Path_Vectors.Empty_Vector);
   end UCS_Tree_Search;

end Uniform_Cost_Search;

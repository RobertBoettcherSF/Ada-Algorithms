package body Cheneys_Algorithm is

   procedure Initialize (State : out GC_State) is
   begin
      State.From_ID := Space_A;
      State.To_ID   := Space_B;
      State.Spaces(State.From_ID).Free := 1;
      State.Spaces(State.To_ID).Free := 1;
   end Initialize;

   function Allocate (State : in out GC_State; 
                      Data  : Integer; 
                      Ref_1 : Reference := Null_Reference; 
                      Ref_2 : Reference := Null_Reference) return Reference is
      Free_Ptr : Reference := State.Spaces(State.From_ID).Free;
   begin
      if Free_Ptr > Max_Heap_Size then
         raise Out_Of_Memory;
      end if;
      
      State.Spaces(State.From_ID).Memory(Free_Ptr) := (
         Forwarded => False,
         New_Addr  => Null_Reference,
         Data      => Data,
         Ref_1     => Ref_1,
         Ref_2     => Ref_2
      );
      
      State.Spaces(State.From_ID).Free := Free_Ptr + 1;
      return Free_Ptr;
   end Allocate;

   function Copy_Node (State : in out GC_State; Ref : Reference) return Reference is
      Old_Node : Node;
      New_Ref  : Reference;
   begin
      if Ref = Null_Reference then
         return Null_Reference;
      end if;

      Old_Node := State.Spaces(State.From_ID).Memory(Ref);
      
      -- Cheney's Variant: Shared/Cyclic references.
      -- If the node was already moved, just update the pointer to the new address.
      if Old_Node.Forwarded then
         return Old_Node.New_Addr;
      end if;

      New_Ref := State.Spaces(State.To_ID).Free;
      if New_Ref > Max_Heap_Size then
         raise Out_Of_Memory;
      end if;

      -- Copy Data to To-Space, clearing internal GC metadata
      State.Spaces(State.To_ID).Memory(New_Ref) := Old_Node;
      State.Spaces(State.To_ID).Memory(New_Ref).Forwarded := False;
      State.Spaces(State.To_ID).Memory(New_Ref).New_Addr  := Null_Reference;
      State.Spaces(State.To_ID).Free := New_Ref + 1;

      -- Leave a Forwarding Address in the From-Space
      State.Spaces(State.From_ID).Memory(Ref).Forwarded := True;
      State.Spaces(State.From_ID).Memory(Ref).New_Addr  := New_Ref;

      return New_Ref;
   end Copy_Node;

   procedure Collect (State : in out GC_State; Roots : in out Root_Set) is
      Scan    : Reference := 1;
      Temp_ID : Space_ID;
   begin
      -- 1. Reset To-Space for the new collection cycle
      -- All live objects will be copied here, starting from address 1
      State.Spaces(State.To_ID).Free := 1;

      -- 2. Traverse and relocate Root Nodes (Initial BFS Queue population)
      -- Copy all root references to To-Space. This initializes the BFS queue.
      -- After this, Scan=1 and Free points to the first unallocated position.
      for I in Roots'Range loop
         Roots(I) := Copy_Node (State, Roots(I));
      end loop;

      -- 3. BFS Scan Phase
      -- Cheney's algorithm implicitly forms a BFS queue between 'Scan' and 'Free':
      --   - Objects at positions [1..Scan-1] have been fully processed
      --   - Objects at positions [Scan..Free-1] have been copied but not processed
      --   - Objects at positions [Free..Max_Heap_Size] are free space
      -- The queue grows as Copy_Node adds new objects, and shrinks as Scan advances.
      while Scan < State.Spaces(State.To_ID).Free loop
         State.Spaces(State.To_ID).Memory(Scan).Ref_1 := 
            Copy_Node (State, State.Spaces(State.To_ID).Memory(Scan).Ref_1);
            
         State.Spaces(State.To_ID).Memory(Scan).Ref_2 := 
            Copy_Node (State, State.Spaces(State.To_ID).Memory(Scan).Ref_2);
            
         Scan := Scan + 1;
      end loop;

      -- 4. Swap active Semi-Spaces
      -- After collection, To-Space becomes the new From-Space (containing all live objects)
      -- and the old From-Space becomes the new To-Space (ready for next collection)
      Temp_ID       := State.From_ID;
      State.From_ID := State.To_ID;
      State.To_ID   := Temp_ID;
   end Collect;

   -- Helper Functions for testing state
   function Get_Node (State : GC_State; Ref : Reference) return Node is
   begin
      return State.Spaces(State.From_ID).Memory(Ref);
   end Get_Node;

   function Get_Free_Pointer (State : GC_State) return Reference is
   begin
      return State.Spaces(State.From_ID).Free;
   end Get_Free_Pointer;

   function Get_From_Space_ID (State : GC_State) return Space_ID is
   begin
      return State.From_ID;
   end Get_From_Space_ID;

end Cheneys_Algorithm;

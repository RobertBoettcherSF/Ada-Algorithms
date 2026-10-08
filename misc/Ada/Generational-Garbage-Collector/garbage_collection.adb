--  Garbage_Collection.adb
--  Implementation of Garbage Collection algorithms.

with Ada.Text_IO; use Ada.Text_IO;

package body Garbage_Collection is

   ------------------
   -- Initialize   --
   ------------------
   procedure Initialize is
   begin
      for I in Heap'Range loop
         Heap (I).Is_Active := False;
         Heap (I).Marked    := False;
         Heap (I).Age       := 0;
         Heap (I).Ref_Count := 0;
         Heap (I).Edges     := (others => Null_Node);
      end loop;
      Root_Count := 0;
   end Initialize;

   ------------------
   -- Allocate     --
   ------------------
   function Allocate return Node_ID is
   begin
      for I in Heap'Range loop
         if not Heap (I).Is_Active then
            Heap (I).Is_Active := True;
            Heap (I).Marked    := False;
            Heap (I).Age       := 0;
            Heap (I).Ref_Count := 0; -- Will be incremented when linked
            Heap (I).Edges     := (others => Null_Node);
            return I;
         end if;
      end loop;
      raise Out_Of_Memory_Error;
   end Allocate;

   ------------------
   -- Add_Root     --
   ------------------
   procedure Add_Root (ID : Node_ID) is
   begin
      if ID = Null_Node or else not Heap (ID).Is_Active then
         raise Invalid_Node_Error;
      end if;
      
      --  Prevent duplicate roots
      for I in 1 .. Root_Count loop
         if Roots (I) = ID then
            return; 
         end if;
      end loop;
      
      Root_Count := Root_Count + 1;
      Roots (Root_Count) := ID;
      Heap (ID).Ref_Count := Heap (ID).Ref_Count + 1;
   end Add_Root;

   ------------------
   -- Remove_Root  --
   ------------------
   procedure Remove_Root (ID : Node_ID) is
   begin
      for I in 1 .. Root_Count loop
         if Roots (I) = ID then
            --  Swap with last and decrement
            Roots (I) := Roots (Root_Count);
            Roots (Root_Count) := Null_Node;
            Root_Count := Root_Count - 1;
            
            --  Ref counting GC triggers here
            if Heap (ID).Ref_Count > 0 then
               Heap (ID).Ref_Count := Heap (ID).Ref_Count - 1;
               if Heap (ID).Ref_Count = 0 then
                  Free_Node (ID, Ref_Counting);
               end if;
            end if;
            return;
         end if;
      end loop;
   end Remove_Root;

   ------------------
   -- Add_Edge     --
   ------------------
   procedure Add_Edge (From, To : Node_ID; Algo : GC_Algorithm := Tracing) is
   begin
      if From = Null_Node or To = Null_Node then raise Invalid_Node_Error; end if;
      
      for I in Heap (From).Edges'Range loop
         if Heap (From).Edges (I) = Null_Node then
            Heap (From).Edges (I) := To;
            if Algo = Ref_Counting then
               Heap (To).Ref_Count := Heap (To).Ref_Count + 1;
            end if;
            return;
         end if;
      end loop;
      raise Max_Edges_Error;
   end Add_Edge;

   ------------------
   -- Remove_Edge  --
   ------------------
   procedure Remove_Edge (From, To : Node_ID; Algo : GC_Algorithm := Tracing) is
   begin
      if From = Null_Node or To = Null_Node then raise Invalid_Node_Error; end if;
      
      for I in Heap (From).Edges'Range loop
         if Heap (From).Edges (I) = To then
            Heap (From).Edges (I) := Null_Node;
            
            if Algo = Ref_Counting then
               if Heap (To).Ref_Count > 0 then
                  Heap (To).Ref_Count := Heap (To).Ref_Count - 1;
                  if Heap (To).Ref_Count = 0 then
                     Free_Node (To, Ref_Counting);
                  end if;
               end if;
            end if;
            return;
         end if;
      end loop;
   end Remove_Edge;

   ------------------
   -- Free_Node    --
   ------------------
   procedure Free_Node (ID : Node_ID; Algo : GC_Algorithm) is
   begin
      if not Heap (ID).Is_Active then return; end if;
      
      --  If ref counting, we recursively remove outgoing edges (Cascading delete)
      if Algo = Ref_Counting then
         for I in Heap (ID).Edges'Range loop
            if Heap (ID).Edges (I) /= Null_Node then
               Remove_Edge (ID, Heap (ID).Edges (I), Ref_Counting);
            end if;
         end loop;
      end if;
      
      Heap (ID).Is_Active := False;
   end Free_Node;

   ------------------
   -- Mark_Node    --
   ------------------
   procedure Mark_Node (ID : Node_ID) is
   begin
      if ID = Null_Node or else not Heap (ID).Is_Active or else Heap (ID).Marked then
         return;
      end if;
      
      Heap (ID).Marked := True;
      for I in Heap (ID).Edges'Range loop
         if Heap (ID).Edges (I) /= Null_Node then
            Mark_Node (Heap (ID).Edges (I));
         end if;
      end loop;
   end Mark_Node;

   --------------------------
   -- Run_Mark_And_Sweep   --
   --------------------------
   procedure Run_Mark_And_Sweep is
   begin
      --  1. Clear all marks
      for I in Heap'Range loop
         Heap (I).Marked := False;
      end loop;
      
      --  2. Mark from roots (Tracing)
      for I in 1 .. Root_Count loop
         Mark_Node (Roots (I));
      end loop;
      
      --  3. Sweep unreachable and promote age
      for I in Heap'Range loop
         if Heap (I).Is_Active then
            if not Heap (I).Marked then
               Free_Node (I, Tracing);
            else
               Heap (I).Age := Heap (I).Age + 1; -- Age survivor
            end if;
         end if;
      end loop;
   end Run_Mark_And_Sweep;

   --------------------------
   -- Run_Minor_Collection --
   --------------------------
   -- Generational variant: Only reclaims young objects (Age = 0)
   procedure Run_Minor_Collection is
   begin
      for I in Heap'Range loop
         Heap (I).Marked := False;
      end loop;
      
      --  Mark from roots
      for I in 1 .. Root_Count loop
         Mark_Node (Roots (I));
      end loop;
      
      --  Also mark from Old Generation (Simulating Write Barrier/Remembered Sets)
      for I in Heap'Range loop
         if Heap (I).Is_Active and then Heap (I).Age > 0 then
            Mark_Node (I);
         end if;
      end loop;
      
      --  Sweep ONLY young generation
      for I in Heap'Range loop
         if Heap (I).Is_Active and then Heap (I).Age = 0 then
            if not Heap (I).Marked then
               Free_Node (I, Tracing);
            else
               Heap (I).Age := 1; -- Promote to old gen
            end if;
         end if;
      end loop;
   end Run_Minor_Collection;

   ------------------
   -- Helpers      --
   ------------------
   function Is_Allocated (ID : Node_ID) return Boolean is
   begin
      return Heap (ID).Is_Active;
   end Is_Allocated;

   function Get_Allocated_Count return Natural is
      Count : Natural := 0;
   begin
      for I in Heap'Range loop
         if Heap (I).Is_Active then Count := Count + 1; end if;
      end loop;
      return Count;
   end Get_Allocated_Count;

   function Get_Ref_Count (ID : Node_ID) return Natural is
   begin
      return Heap (ID).Ref_Count;
   end Get_Ref_Count;

   function Get_Age (ID : Node_ID) return Natural is
   begin
      return Heap (ID).Age;
   end Get_Age;

end Garbage_Collection;

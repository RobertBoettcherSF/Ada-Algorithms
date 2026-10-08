-- src/buddy_allocators.adb
-- Version 0.03
-- Description: Implementation of Buddy Memory Allocator variants.

package body Buddy_Allocators is

   -- -------------------------------------------------------------------------
   -- Math Helpers
   -- -------------------------------------------------------------------------
   function Is_Power_Of_2 (N : Positive) return Boolean is
      Temp : Positive := N;
   begin
      while Temp > 1 loop
         if Temp mod 2 /= 0 then
            return False;
         end if;
         Temp := Temp / 2;
      end loop;
      return True;
   end Is_Power_Of_2;

   function Is_Valid_Initial_Size (Variant : Variant_Type; Size : Positive) return Boolean is
      Fib : constant array(1..20) of Positive := 
        (1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946);
   begin
      case Variant is
         when Binary =>
            return Is_Power_Of_2(Size);
         when Fibonacci =>
            for I in 1 .. Fib'Last loop
               if Fib(I) = Size then return True; end if;
            end loop;
            return False;
         when Weighted =>
            -- Weighted sizes must be 2^k or 3 * 2^k
            return Is_Power_Of_2(Size) or else (Size mod 3 = 0 and then Is_Power_Of_2(Size / 3));
      end case;
   end Is_Valid_Initial_Size;

   -- Calculates the size of the left and right splits based on the variant's mathematical rules.
   procedure Get_Splits (Variant : Variant_Type; Size : Positive; Left, Right : out Natural; Can_Split : out Boolean) is
      Fib : constant array(1..20) of Positive := 
        (1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946);
   begin
      Left := 0; Right := 0; Can_Split := False;
      case Variant is
         when Binary =>
            -- Halves the block. E.g., 64 -> 32 and 32.
            if Size > 1 and then Size mod 2 = 0 then
               Left := Size / 2;
               Right := Size / 2;
               Can_Split := True;
            end if;
         when Fibonacci =>
            -- Splits Fn into Fn-1 and Fn-2. E.g., 55 -> 34 and 21.
            for I in 3 .. Fib'Last loop
               if Fib(I) = Size then
                  Left := Fib(I-1);
                  Right := Fib(I-2);
                  Can_Split := True;
                  exit;
               end if;
            end loop;
         when Weighted =>
            -- Splits 3*2^k into 2^(k+1) and 2^k. E.g., 12 -> 8 and 4.
            -- Splits 2^k into 2^(k-1) and 2^(k-1). E.g., 8 -> 4 and 4.
            if Size mod 3 = 0 and then Is_Power_Of_2(Size / 3) then
               Left := (Size / 3) * 2;
               Right := Size / 3;
               Can_Split := True;
            elsif Size > 1 and then Is_Power_Of_2(Size) then
               Left := Size / 2;
               Right := Size / 2;
               Can_Split := True;
            end if;
      end case;
   end Get_Splits;

   -- Retrieves a new free node from the static array, acting as a simple Garbage Collector
   -- by reusing inactive nodes before expanding the Count boundary.
   function New_Node (P : in out Pool) return Node_Id is
   begin
      for I in 1 .. P.Count loop
         if not P.Nodes(I).Is_Active then
            P.Nodes(I).Is_Active := True;
            return I;
         end if;
      end loop;
      
      if P.Count < Max_Nodes then
         P.Count := P.Count + 1;
         P.Nodes(P.Count).Is_Active := True;
         return P.Count;
      else
         raise Allocation_Error with "Metadata node limit reached";
      end if;
   end New_Node;

   -- -------------------------------------------------------------------------
   -- Core API Implementations
   -- -------------------------------------------------------------------------

   procedure Initialize (P : in out Pool; Total_Size : Positive) is
   begin
      if not Is_Valid_Initial_Size(P.Variant, Total_Size) then
         raise Initialization_Error with "Invalid Total_Size for chosen variant";
      end if;

      -- Wipe existing metadata
      P.Count := 0;
      for I in P.Nodes'Range loop
         P.Nodes(I).Is_Active := False;
      end loop;

      -- Create the root block representing the entire free memory pool
      declare
         Root : constant Node_Id := New_Node(P);
      begin
         P.Nodes(Root).Addr := 0;
         P.Nodes(Root).Size := Total_Size;
         P.Nodes(Root).Is_Free := True;
         P.Nodes(Root).Is_Leaf := True;
      end;
   end Initialize;

   function Allocate (P : in out Pool; Size : Positive) return Address is
      Best_Node : Node_Id := Null_Node;
      Best_Size : Positive := Positive'Last;
      L, R      : Natural;
      Can_Split : Boolean;
      L_Node, R_Node : Node_Id;
   begin
      -- Phase 1: Search for the best-fit free leaf block.
      -- This minimizes wasted space (internal fragmentation).
      for I in 1 .. P.Count loop
         if P.Nodes(I).Is_Active and then P.Nodes(I).Is_Leaf and then P.Nodes(I).Is_Free then
            if P.Nodes(I).Size >= Size and then P.Nodes(I).Size < Best_Size then
               Best_Node := I;
               Best_Size := P.Nodes(I).Size;
            end if;
         end if;
      end loop;

      if Best_Node = Null_Node then
         return Null_Address; -- No valid block found
      end if;

      -- Phase 2: Split the block recursively if it is larger than necessary.
      loop
         Get_Splits(P.Variant, P.Nodes(Best_Node).Size, L, R, Can_Split);
         
         -- Stop splitting if it can't be split mathematically, or if splitting 
         -- it would result in BOTH children being too small to hold the requested size.
         exit when not Can_Split;
         if L < Size and R < Size then
            exit; 
         end if;

         -- Perform split mapping in the binary tree
         L_Node := New_Node(P);
         R_Node := New_Node(P);

         P.Nodes(L_Node) := (Is_Active => True, Addr => P.Nodes(Best_Node).Addr, Size => L, Is_Free => True, Is_Leaf => True, Left_Child => Null_Node, Right_Child => Null_Node, Parent => Best_Node);
         P.Nodes(R_Node) := (Is_Active => True, Addr => P.Nodes(Best_Node).Addr + Address(L), Size => R, Is_Free => True, Is_Leaf => True, Left_Child => Null_Node, Right_Child => Null_Node, Parent => Best_Node);

         P.Nodes(Best_Node).Is_Leaf := False;
         P.Nodes(Best_Node).Is_Free := False;
         P.Nodes(Best_Node).Left_Child := L_Node;
         P.Nodes(Best_Node).Right_Child := R_Node;

         -- Choose the tightest fitting child block to continue the process
         if L >= Size and R >= Size then
            if L <= R then Best_Node := L_Node; else Best_Node := R_Node; end if;
         elsif L >= Size then
            Best_Node := L_Node;
         else
            Best_Node := R_Node;
         end if;
      end loop;

      -- Phase 3: Mark the final chosen block as allocated
      P.Nodes(Best_Node).Is_Free := False;
      return P.Nodes(Best_Node).Addr;
   end Allocate;

   procedure Deallocate (P : in out Pool; Addr : Address) is
      Found : Boolean := False;
      Curr  : Node_Id := Null_Node;
      P_Id, L_Id, R_Id : Node_Id;
   begin
      -- Phase 1: Locate the specific allocated leaf node based on the memory address.
      for I in 1 .. P.Count loop
         if P.Nodes(I).Is_Active and then P.Nodes(I).Is_Leaf and then 
            not P.Nodes(I).Is_Free and then P.Nodes(I).Addr = Addr then
            Curr := I;
            Found := True;
            exit;
         end if;
      end loop;

      if not Found then
         raise Deallocation_Error with "Invalid address or double free detected";
      end if;

      P.Nodes(Curr).Is_Free := True;

      -- Phase 2: Buddy Merging. 
      -- Traverse upward via Parent pointers. If a node's left and right children 
      -- are both free leaves, they are "Buddies" and can be merged back into the parent.
      while P.Nodes(Curr).Parent /= Null_Node loop
         P_Id := P.Nodes(Curr).Parent;
         L_Id := P.Nodes(P_Id).Left_Child;
         R_Id := P.Nodes(P_Id).Right_Child;

         if P.Nodes(L_Id).Is_Free and then P.Nodes(L_Id).Is_Leaf and then
            P.Nodes(R_Id).Is_Free and then P.Nodes(R_Id).Is_Leaf then
            
            -- Reclaim the parent node as a single contiguous free block
            P.Nodes(P_Id).Is_Leaf := True;
            P.Nodes(P_Id).Is_Free := True;
            P.Nodes(P_Id).Left_Child := Null_Node;
            P.Nodes(P_Id).Right_Child := Null_Node;

            -- Free up the metadata array slots for the children so New_Node can reuse them
            P.Nodes(L_Id).Is_Active := False;
            P.Nodes(R_Id).Is_Active := False;

            Curr := P_Id; -- Move up the tree to check if we can merge again
         else
            exit; -- Stop merging if the buddy is currently allocated or split
         end if;
      end loop;
   end Deallocate;

end Buddy_Allocators;

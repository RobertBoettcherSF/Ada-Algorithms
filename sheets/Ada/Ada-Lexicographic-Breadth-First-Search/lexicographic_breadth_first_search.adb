--  Lexicographic_Breadth_First_Search body — partition refinement Lex-BFS
--  and perfect-elimination-order check.

pragma Ada_2022;

package body Lexicographic_Breadth_First_Search
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   function Has_Arc (G : Graph; From, To : Vertex_Id) return Boolean is
      E_Idx : Natural := G.Head (From);
   begin
      while E_Idx /= 0 loop
         if G.To (E_Idx) = To then
            return True;
         end if;
         E_Idx := G.Next (E_Idx);
      end loop;
      return False;
   end Has_Arc;

   procedure Append_Arc (G : in out Graph; From, To : Vertex_Id) is
   begin
      if G.Arcs = Max_Arcs then
         raise Invalid_Argument;
      end if;
      G.Arcs := G.Arcs + 1;
      G.To (G.Arcs) := To;
      G.Next (G.Arcs) := G.Head (From);
      G.Head (From) := G.Arcs;
   end Append_Arc;

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.E := 0;
      G.Arcs := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         return;
      end if;
      if Has_Arc (G, U, V) then
         return;
      end if;
      if G.E = Max_Edges then
         raise Invalid_Argument;
      end if;
      Append_Arc (G, U, V);
      Append_Arc (G, V, U);
      G.E := G.E + 1;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return G.E;
   end Edge_Count;

   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         return False;
      end if;
      return Has_Arc (G, U, V);
   end Is_Adjacent;

   -------------------------------------------------------------------------
   -- Lex-BFS (partition refinement)
   -------------------------------------------------------------------------

   procedure Lex_BFS_From
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array)
   is
      N : constant Natural := G.N;

      --  Partition cells (sets in Σ). At most N non-empty cells; one extra
      --  slot covers the brief Alloc before a singleton set is freed.
      --  Empty cells are recycled via Free_List. Cell 0 is null.
      Max_Cells : constant := Max_Vertices + 1;
      subtype Cell_Id is Natural range 0 .. Max_Cells;

      V_Prev : array (Vertex_Id) of Natural := [others => 0];
      V_Next : array (Vertex_Id) of Natural := [others => 0];
      V_Cell : array (Vertex_Id) of Cell_Id := [others => 0];

      C_Head  : array (Cell_Id) of Natural := [others => 0];
      C_Count : array (Cell_Id) of Natural := [others => 0];
      C_Prev  : array (Cell_Id) of Cell_Id := [others => 0];
      C_Next  : array (Cell_Id) of Cell_Id := [others => 0];
      --  During one pivot, C_Twin (S) is the new cell T placed before S
      --  (0 ⇒ S not yet refined for this pivot).
      C_Twin  : array (Cell_Id) of Cell_Id := [others => 0];

      First_Cell : Cell_Id := 0;
      Free_List  : Cell_Id := 0;
      Next_Fresh : Natural := 1;
      Out_Pos    : Natural := 0;

      function Alloc_Cell return Cell_Id is
         C : Cell_Id;
      begin
         if Free_List /= 0 then
            C := Free_List;
            Free_List := C_Next (C);
         else
            if Next_Fresh > Max_Cells then
               raise Program_Error with "Lex-BFS cell overflow";
            end if;
            C := Cell_Id (Next_Fresh);
            Next_Fresh := Next_Fresh + 1;
         end if;
         C_Head (C) := 0;
         C_Count (C) := 0;
         C_Prev (C) := 0;
         C_Next (C) := 0;
         C_Twin (C) := 0;
         return C;
      end Alloc_Cell;

      procedure Free_Cell (C : Cell_Id) is
      begin
         C_Head (C) := 0;
         C_Count (C) := 0;
         C_Prev (C) := 0;
         C_Twin (C) := 0;
         C_Next (C) := Free_List;
         Free_List := C;
      end Free_Cell;

      procedure Insert_Vertex_Front (C : Cell_Id; V : Vertex_Id) is
         Old : constant Natural := C_Head (C);
      begin
         V_Cell (V) := C;
         V_Prev (V) := 0;
         V_Next (V) := Old;
         if Old /= 0 then
            V_Prev (Vertex_Id (Old)) := Natural (V);
         end if;
         C_Head (C) := Natural (V);
         C_Count (C) := C_Count (C) + 1;
      end Insert_Vertex_Front;

      procedure Remove_Vertex (V : Vertex_Id) is
         C    : constant Cell_Id := V_Cell (V);
         Prev : constant Natural := V_Prev (V);
         Succ : constant Natural := V_Next (V);
      begin
         if C = 0 then
            return;
         end if;
         if Prev /= 0 then
            V_Next (Vertex_Id (Prev)) := Succ;
         else
            C_Head (C) := Succ;
         end if;
         if Succ /= 0 then
            V_Prev (Vertex_Id (Succ)) := Prev;
         end if;
         V_Prev (V) := 0;
         V_Next (V) := 0;
         V_Cell (V) := 0;
         C_Count (C) := C_Count (C) - 1;
      end Remove_Vertex;

      procedure Unlink_And_Free (C : Cell_Id) is
         P : constant Cell_Id := C_Prev (C);
         Q : constant Cell_Id := C_Next (C);
      begin
         if P /= 0 then
            C_Next (P) := Q;
         else
            First_Cell := Q;
         end if;
         if Q /= 0 then
            C_Prev (Q) := P;
         end if;
         Free_Cell (C);
      end Unlink_And_Free;

      procedure Insert_Cell_Before (New_C, S : Cell_Id) is
         P : constant Cell_Id := C_Prev (S);
      begin
         C_Prev (New_C) := P;
         C_Next (New_C) := S;
         C_Prev (S) := New_C;
         if P /= 0 then
            C_Next (P) := New_C;
         else
            First_Cell := New_C;
         end if;
      end Insert_Cell_Before;

      procedure Output_Vertex (V : Vertex_Id) is
      begin
         Out_Pos := Out_Pos + 1;
         Order (Vertex_Id (Out_Pos)) := V;
      end Output_Vertex;

      procedure Refine_From (V : Vertex_Id) is
         E_Idx   : Natural;
         W       : Vertex_Id;
         S, T    : Cell_Id;
         Touched : array (1 .. Max_Cells) of Cell_Id := [others => 0];
         Touch_N : Natural := 0;

         procedure Clear_Touched (Cell : Cell_Id) is
         begin
            for I in 1 .. Touch_N loop
               if Touched (I) = Cell then
                  Touched (I) := 0;
                  return;
               end if;
            end loop;
         end Clear_Touched;
      begin
         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            S := V_Cell (W);
            if S /= 0 then
               if C_Twin (S) = 0 then
                  T := Alloc_Cell;
                  Insert_Cell_Before (T, S);
                  C_Twin (S) := T;
                  Touch_N := Touch_N + 1;
                  Touched (Touch_N) := S;
               else
                  T := C_Twin (S);
               end if;
               Remove_Vertex (W);
               Insert_Vertex_Front (T, W);
               if C_Count (S) = 0 then
                  Clear_Touched (S);
                  C_Twin (S) := 0;
                  Unlink_And_Free (S);
               end if;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;

         for I in 1 .. Touch_N loop
            S := Touched (I);
            if S /= 0 then
               C_Twin (S) := 0;
            end if;
         end loop;
      end Refine_From;

      Start_Cell : Cell_Id;
      Rest_Cell  : Cell_Id;
      C          : Cell_Id;
      V          : Vertex_Id;
   begin
      if Order'First /= 1 or else Natural (Order'Last) < N then
         raise Invalid_Argument;
      end if;

      if Natural (Start) > N then
         raise Invalid_Argument;
      end if;

      for I in Order'Range loop
         Order (I) := Vertex_Id'First;
      end loop;

      --  Σ := [{Start}, V \ {Start}] so the first selected vertex is Start.
      Start_Cell := Alloc_Cell;
      Insert_Vertex_Front (Start_Cell, Start);
      First_Cell := Start_Cell;

      if N > 1 then
         Rest_Cell := Alloc_Cell;
         C_Next (Start_Cell) := Rest_Cell;
         C_Prev (Rest_Cell) := Start_Cell;
         for U in Vertex_Id range 1 .. Vertex_Id (N) loop
            if U /= Start then
               Insert_Vertex_Front (Rest_Cell, U);
            end if;
         end loop;
      end if;

      while First_Cell /= 0 loop
         C := First_Cell;
         if C_Count (C) = 0 then
            Unlink_And_Free (C);
         else
            V := Vertex_Id (C_Head (C));
            Remove_Vertex (V);
            if C_Count (C) = 0 then
               Unlink_And_Free (C);
            end if;
            Output_Vertex (V);
            Refine_From (V);
         end if;
      end loop;

      if Out_Pos /= N then
         raise Program_Error with "Lex-BFS incomplete ordering";
      end if;
   end Lex_BFS_From;

   procedure Lex_BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array)
   is
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Lex_BFS_From (G, Start, Order);
   end Lex_BFS;

   procedure Lex_BFS (G : Graph; Order : out Order_Array) is
   begin
      if G.N = 0 then
         if Order'First /= 1 then
            raise Invalid_Argument;
         end if;
         return;
      end if;
      Lex_BFS_From (G, 1, Order);
   end Lex_BFS;

   -------------------------------------------------------------------------
   -- Perfect elimination ordering
   -------------------------------------------------------------------------

   function Is_PEO (G : Graph; Order : Order_Array) return Boolean is
      N : constant Natural := G.N;
      Pos         : array (Vertex_Id) of Natural := [others => 0];
      Seen        : array (Vertex_Id) of Boolean := [others => False];
      V, U, W     : Vertex_Id;
      Later_Count : Natural;
      Later       : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
   begin
      if N = 0 then
         return True;
      end if;

      if Order'First /= 1 or else Natural (Order'Last) < N then
         raise Invalid_Argument;
      end if;

      for I in 1 .. N loop
         V := Order (Vertex_Id (I));
         if Natural (V) > N then
            raise Invalid_Argument;
         end if;
         if Seen (V) then
            raise Invalid_Argument;
         end if;
         Seen (V) := True;
         Pos (V) := I;
      end loop;

      for I in 1 .. N loop
         V := Order (Vertex_Id (I));
         Later_Count := 0;
         declare
            E_Idx : Natural := G.Head (V);
         begin
            while E_Idx /= 0 loop
               U := G.To (E_Idx);
               if Pos (U) > I then
                  Later_Count := Later_Count + 1;
                  Later (Later_Count) := U;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end;

         for A in 1 .. Later_Count loop
            for B in A + 1 .. Later_Count loop
               U := Later (A);
               W := Later (B);
               if not Has_Arc (G, U, W) then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;

      return True;
   end Is_PEO;

end Lexicographic_Breadth_First_Search;

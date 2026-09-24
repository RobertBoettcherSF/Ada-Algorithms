--  Kosarajus_Algorithm body — two DFS passes (G then G^T) with finish stack.

pragma Ada_2022;

package body Kosarajus_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.E := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.E = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.E := G.E + 1;
      G.To (G.E) := To;
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.E);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Kosaraju–Sharir SCC (finish-order DFS + transpose DFS)
   -------------------------------------------------------------------------

   procedure Compute_SCC
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      Visited : array (Vertex_Id) of Boolean := [others => False];

      --  Finish-order stack L (vertices pushed after exploring out-edges).
      Order     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Order_Top : Natural := 0;

      --  Transpose adjacency G^T (same edge-pool layout as Graph).
      T_Head : Head_Array := [others => 0];
      T_To   : To_Array := [others => Vertex_Id'First];
      T_Next : Next_Array := [others => 0];
      T_E    : Edge_Count_T := 0;

      Next_Comp : Natural := 0;

      procedure Visit_First (V : Vertex_Id) is
         E_Idx : Natural;
         W     : Vertex_Id;
      begin
         Visited (V) := True;
         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if not Visited (W) then
               Visit_First (W);
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
         Order_Top := Order_Top + 1;
         Order (Order_Top) := V;
      end Visit_First;

      procedure Assign (V : Vertex_Id; Comp : Component_Id) is
         E_Idx : Natural;
         W     : Vertex_Id;
      begin
         if V < Component_Of'First or else V > Component_Of'Last then
            return;
         end if;
         if Component_Of (V) /= 0 then
            return;
         end if;
         Component_Of (V) := Comp;
         E_Idx := T_Head (V);
         while E_Idx /= 0 loop
            W := T_To (E_Idx);
            Assign (W, Comp);
            E_Idx := T_Next (E_Idx);
         end loop;
      end Assign;

      procedure Add_Transpose_Edge (From, To : Vertex_Id) is
      begin
         --  G has at most Max_Edges edges; G^T uses the same budget.
         T_E := T_E + 1;
         T_To (T_E) := To;
         T_Next (T_E) := T_Head (From);
         T_Head (From) := T_E;
      end Add_Transpose_Edge;

      U     : Vertex_Id;
      E_Idx : Natural;
      W     : Vertex_Id;
   begin
      if N = 0 then
         Component_Count := 0;
         return;
      end if;

      if Component_Of'First /= 1
        or else Natural (Component_Of'Last) < N
      then
         raise Invalid_Argument;
      end if;

      for V in Component_Of'Range loop
         Component_Of (V) := 0;
      end loop;

      --  Phase 1: DFS on G, record finish order.
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if not Visited (V) then
            Visit_First (V);
         end if;
      end loop;

      --  Phase 2: build transpose adjacency from G's edge pool.
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            Add_Transpose_Edge (W, V);
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      --  Phase 3: DFS on G^T in reverse finish order.
      while Order_Top > 0 loop
         U := Order (Order_Top);
         Order_Top := Order_Top - 1;
         if Component_Of (U) = 0 then
            Next_Comp := Next_Comp + 1;
            Assign (U, Component_Id (Next_Comp));
         end if;
      end loop;

      Component_Count := Next_Comp;
   end Compute_SCC;

   function Same_SCC
     (Component_Of : Component_Array;
      U, V         : Vertex_Id) return Boolean
   is
   begin
      if U not in Component_Of'Range or else V not in Component_Of'Range then
         raise Invalid_Argument;
      end if;
      return Component_Of (U) /= 0
        and then Component_Of (U) = Component_Of (V);
   end Same_SCC;

end Kosarajus_Algorithm;

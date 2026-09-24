--  Strongly_Connected_Components body — inline Tarjan, Kosaraju–Sharir,
--  and path-based (Gabow / Cheriyan–Mehlhorn) SCC implementations.

pragma Ada_2022;

package body Strongly_Connected_Components
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
   -- Shared precondition check
   -------------------------------------------------------------------------

   procedure Check_Component_Bounds
     (Component_Of : Component_Array; N : Natural)
   is
   begin
      if N = 0 then
         return;
      end if;
      if Component_Of'First /= 1
        or else Natural (Component_Of'Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Check_Component_Bounds;

   procedure Zero_Components (Component_Of : in out Component_Array) is
   begin
      for V in Component_Of'Range loop
         Component_Of (V) := 0;
      end loop;
   end Zero_Components;

   -------------------------------------------------------------------------
   -- Tarjan (1972): one DFS + stack + low-link
   -------------------------------------------------------------------------

   procedure Compute_SCC_Tarjan
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      subtype Time_T is Natural;
      Index_Of   : array (Vertex_Id) of Time_T := [others => 0];
      Low_Link   : array (Vertex_Id) of Time_T := [others => 0];
      On_Stack   : array (Vertex_Id) of Boolean := [others => False];

      Stack     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top : Natural := 0;

      Next_Index : Time_T := 0;
      Next_Comp  : Natural := 0;

      procedure Push (V : Vertex_Id) is
      begin
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := V;
         On_Stack (V) := True;
      end Push;

      function Pop return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Stack (Stack_Top);
         Stack_Top := Stack_Top - 1;
         On_Stack (V) := False;
         return V;
      end Pop;

      procedure Strong_Connect (V : Vertex_Id) is
         E_Idx  : Natural;
         W      : Vertex_Id;
         Popped : Vertex_Id;
      begin
         Next_Index := Next_Index + 1;
         Index_Of (V) := Next_Index;
         Low_Link (V) := Next_Index;
         Push (V);

         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if Index_Of (W) = 0 then
               Strong_Connect (W);
               if Low_Link (W) < Low_Link (V) then
                  Low_Link (V) := Low_Link (W);
               end if;
            elsif On_Stack (W) then
               if Index_Of (W) < Low_Link (V) then
                  Low_Link (V) := Index_Of (W);
               end if;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;

         if Low_Link (V) = Index_Of (V) then
            Next_Comp := Next_Comp + 1;
            loop
               Popped := Pop;
               if Popped <= Component_Of'Last
                 and then Popped >= Component_Of'First
               then
                  Component_Of (Popped) := Component_Id (Next_Comp);
               end if;
               exit when Popped = V;
            end loop;
         end if;
      end Strong_Connect;

   begin
      if N = 0 then
         Component_Count := 0;
         return;
      end if;

      Check_Component_Bounds (Component_Of, N);
      Zero_Components (Component_Of);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Index_Of (V) = 0 then
            Strong_Connect (V);
         end if;
      end loop;

      Component_Count := Next_Comp;
   end Compute_SCC_Tarjan;

   -------------------------------------------------------------------------
   -- Kosaraju–Sharir: finish-order DFS on G, Assign on G^T
   -------------------------------------------------------------------------

   procedure Compute_SCC_Kosaraju
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      Visited : array (Vertex_Id) of Boolean := [others => False];

      Order     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Order_Top : Natural := 0;

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

      Check_Component_Bounds (Component_Of, N);
      Zero_Components (Component_Of);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if not Visited (V) then
            Visit_First (V);
         end if;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            Add_Transpose_Edge (W, V);
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      while Order_Top > 0 loop
         U := Order (Order_Top);
         Order_Top := Order_Top - 1;
         if Component_Of (U) = 0 then
            Next_Comp := Next_Comp + 1;
            Assign (U, Component_Id (Next_Comp));
         end if;
      end loop;

      Component_Count := Next_Comp;
   end Compute_SCC_Kosaraju;

   -------------------------------------------------------------------------
   -- Path-based (Gabow / Cheriyan–Mehlhorn): two stacks S, P
   -------------------------------------------------------------------------

   procedure Compute_SCC_Path_Based
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      subtype Time_T is Natural;
      Preorder : array (Vertex_Id) of Time_T := [others => 0];
      Assigned : array (Vertex_Id) of Boolean := [others => False];

      S     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      S_Top : Natural := 0;

      P     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      P_Top : Natural := 0;

      C         : Time_T := 0;
      Next_Comp : Natural := 0;

      procedure Visit (V : Vertex_Id) is
         E_Idx  : Natural;
         W      : Vertex_Id;
         Popped : Vertex_Id;
      begin
         C := C + 1;
         Preorder (V) := C;
         S_Top := S_Top + 1;
         S (S_Top) := V;
         P_Top := P_Top + 1;
         P (P_Top) := V;

         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if Preorder (W) = 0 then
               Visit (W);
            elsif not Assigned (W) then
               while P_Top > 0
                 and then Preorder (P (P_Top)) > Preorder (W)
               loop
                  P_Top := P_Top - 1;
               end loop;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;

         if P_Top > 0 and then P (P_Top) = V then
            Next_Comp := Next_Comp + 1;
            loop
               Popped := S (S_Top);
               S_Top := S_Top - 1;
               Assigned (Popped) := True;
               if Popped <= Component_Of'Last
                 and then Popped >= Component_Of'First
               then
                  Component_Of (Popped) := Component_Id (Next_Comp);
               end if;
               exit when Popped = V;
            end loop;
            P_Top := P_Top - 1;
         end if;
      end Visit;

   begin
      if N = 0 then
         Component_Count := 0;
         return;
      end if;

      Check_Component_Bounds (Component_Of, N);
      Zero_Components (Component_Of);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Preorder (V) = 0 then
            Visit (V);
         end if;
      end loop;

      Component_Count := Next_Comp;
   end Compute_SCC_Path_Based;

   -------------------------------------------------------------------------
   -- Public dispatcher
   -------------------------------------------------------------------------

   procedure Compute_SCC
     (G               : Graph;
      Algo            : Method;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
   begin
      case Algo is
         when Tarjan =>
            Compute_SCC_Tarjan (G, Component_Of, Component_Count);
         when Kosaraju =>
            Compute_SCC_Kosaraju (G, Component_Of, Component_Count);
         when Path_Based =>
            Compute_SCC_Path_Based (G, Component_Of, Component_Count);
      end case;
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

end Strongly_Connected_Components;

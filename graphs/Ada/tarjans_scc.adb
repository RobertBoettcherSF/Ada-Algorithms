--  Tarjans_SCC body — Tarjan DFS with stack + low-link values.

pragma Ada_2022;

package body Tarjans_SCC
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
   -- Tarjan SCC
   -------------------------------------------------------------------------

   procedure Compute_SCC
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      --  DFS discovery time; 0 means unvisited.
      subtype Time_T is Natural;
      Index_Of   : array (Vertex_Id) of Time_T := [others => 0];
      Low_Link   : array (Vertex_Id) of Time_T := [others => 0];
      On_Stack   : array (Vertex_Id) of Boolean := [others => False];

      Stack      : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top  : Natural := 0;

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
         E_Idx : Natural;
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
               --  Classic Tarjan update with Index(W), not Low_Link(W).
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

      if Component_Of'First /= 1
        or else Natural (Component_Of'Last) < N
      then
         raise Invalid_Argument;
      end if;

      for V in Component_Of'Range loop
         Component_Of (V) := 0;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Index_Of (V) = 0 then
            Strong_Connect (V);
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

end Tarjans_SCC;

--  Path_Based_Strong_Component body — Gabow / Cheriyan–Mehlhorn DFS
--  with two stacks (S unassigned, P path / preorder merge frontier).

pragma Ada_2022;

package body Path_Based_Strong_Component
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
   -- Path-based (two-stack) SCC
   -------------------------------------------------------------------------

   procedure Compute_SCC
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
   is
      N : constant Natural := G.N;

      --  Discovery / preorder number; 0 means unvisited.
      subtype Time_T is Natural;
      Preorder : array (Vertex_Id) of Time_T := [others => 0];
      Assigned : array (Vertex_Id) of Boolean := [others => False];

      --  S: vertices not yet assigned to an SCC (discovery order).
      S     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      S_Top : Natural := 0;

      --  P: path / preorder merge stack (prospective SCC roots).
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
               --  Tree edge: recurse.
               Visit (W);
            elsif not Assigned (W) then
               --  Forward / back / cross edge into the current forest:
               --  contract P until its top can reach W (preorder <= W's).
               while P_Top > 0
                 and then Preorder (P (P_Top)) > Preorder (W)
               loop
                  P_Top := P_Top - 1;
               end loop;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;

         --  V is an SCC root iff it remains on top of P.
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

      if Component_Of'First /= 1
        or else Natural (Component_Of'Last) < N
      then
         raise Invalid_Argument;
      end if;

      for V in Component_Of'Range loop
         Component_Of (V) := 0;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Preorder (V) = 0 then
            Visit (V);
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

end Path_Based_Strong_Component;

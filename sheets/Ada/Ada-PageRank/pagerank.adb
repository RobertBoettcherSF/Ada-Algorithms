--  PageRank body — classic / personalized PageRank power iteration.

pragma Ada_2022;

package body PageRank
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
      G.Custom_Teleport := False;
      for V in Vertex_Id loop
         G.Head (V) := 0;
         G.Outdeg (V) := 0;
         G.Teleport_Mass (V) := 0.0;
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
      G.Outdeg (From) := G.Outdeg (From) + 1;
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
   -- Teleport / personalization
   -------------------------------------------------------------------------

   procedure Clear_Teleport (G : in out Graph) is
   begin
      G.Custom_Teleport := False;
      for V in Vertex_Id loop
         G.Teleport_Mass (V) := 0.0;
      end loop;
   end Clear_Teleport;

   function Has_Custom_Teleport (G : Graph) return Boolean is
   begin
      return G.Custom_Teleport;
   end Has_Custom_Teleport;

   procedure Set_Teleport (G : in out Graph; Mass : Teleport_Array) is
      N     : constant Natural := G.N;
      Total : Float := 0.0;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Mass'First /= 1 or else Natural (Mass'Last) < N then
         raise Invalid_Argument;
      end if;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Mass (V) < 0.0 then
            raise Invalid_Argument;
         end if;
         Total := Total + Mass (V);
      end loop;
      if Total <= 0.0 then
         raise Invalid_Argument;
      end if;
      G.Custom_Teleport := True;
      for V in Vertex_Id loop
         G.Teleport_Mass (V) := 0.0;
      end loop;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         G.Teleport_Mass (V) := Mass (V);
      end loop;
   end Set_Teleport;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float
   is
   begin
      if V < Scores'First or else V > Scores'Last then
         raise Invalid_Argument;
      end if;
      return Scores (V);
   end Score_Of;

   procedure Build_Teleport_Vector
     (G : Graph; S : out Score_Array; N : Natural)
   is
      Total : Float := 0.0;
      Inv   : Float;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         S (V) := 0.0;
      end loop;

      if G.Custom_Teleport then
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            S (V) := G.Teleport_Mass (V);
            Total := Total + S (V);
         end loop;
         if Total <= 0.0 then
            raise Invalid_Argument;
         end if;
         Inv := 1.0 / Total;
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            S (V) := S (V) * Inv;
         end loop;
      else
         Inv := 1.0 / Float (N);
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            S (V) := Inv;
         end loop;
      end if;
   end Build_Teleport_Vector;

   -------------------------------------------------------------------------
   -- Power iteration: r ← α T r + (1−α) s
   -------------------------------------------------------------------------

   procedure Compute
     (G          : Graph;
      Damping    : Float := 0.85;
      Max_Iters  : Positive := 100;
      Tolerance  : Float := 1.0e-6;
      Scores     : out Score_Array;
      Iterations : out Natural)
   is
      N : constant Natural := G.N;

      S      : Score_Array (1 .. Vertex_Id (Max_Vertices));
      Curr   : Score_Array (1 .. Vertex_Id (Max_Vertices));
      Next_R : Score_Array (1 .. Vertex_Id (Max_Vertices));

      Alpha : constant Float := Damping;
      Tele  : constant Float := 1.0 - Damping;

      Dangling_Mass : Float;
      Diff          : Float;
      Eidx          : Natural;
      Dest          : Vertex_Id;
      Contrib       : Float;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Scores'First /= 1 or else Natural (Scores'Last) < N then
         raise Invalid_Argument;
      end if;
      if Damping < 0.0 or else Damping > 1.0 then
         raise Invalid_Argument;
      end if;
      if Tolerance < 0.0 then
         raise Invalid_Argument;
      end if;

      Build_Teleport_Vector (G, S, N);

      --  Initialise r₀ = s
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Curr (V) := S (V);
      end loop;

      Iterations := 0;

      for Iter in 1 .. Max_Iters loop
         Iterations := Iter;

         --  Dangling mass: sum of Curr(u) over u with outdeg(u) = 0
         Dangling_Mass := 0.0;
         for U in Vertex_Id range 1 .. Vertex_Id (N) loop
            if G.Outdeg (U) = 0 then
               Dangling_Mass := Dangling_Mass + Curr (U);
            end if;
         end loop;

         --  Next_R ← (1−α) s + α · dangling_mass · s
         --         = (Tele + Alpha * Dangling_Mass) * s
         --  then add α · T · Curr from non-dangling nodes.
         declare
            Base : constant Float := Tele + Alpha * Dangling_Mass;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               Next_R (V) := Base * S (V);
            end loop;
         end;

         for U in Vertex_Id range 1 .. Vertex_Id (N) loop
            if G.Outdeg (U) > 0 then
               Contrib := Alpha * Curr (U) / Float (G.Outdeg (U));
               Eidx := G.Head (U);
               while Eidx /= 0 loop
                  Dest := G.To (Edge_Index (Eidx));
                  Next_R (Dest) := Next_R (Dest) + Contrib;
                  Eidx := G.Next (Edge_Index (Eidx));
               end loop;
            end if;
         end loop;

         --  L1 change
         Diff := 0.0;
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            Diff := Diff + abs (Next_R (V) - Curr (V));
            Curr (V) := Next_R (V);
         end loop;

         exit when Diff <= Tolerance;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Scores (V) := Curr (V);
      end loop;
   end Compute;

end PageRank;

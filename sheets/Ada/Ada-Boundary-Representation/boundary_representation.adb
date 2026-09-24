package body Boundary_Representation is

   procedure Initialize (Model : out B_Rep_Model) is
      Empty_Model : constant B_Rep_Model :=
        (Num_Vertices => 0, Num_Edges => 0, Num_Faces => 0, others => <>);
   begin
      Model := Empty_Model;
   end Initialize;

   function Active_Vertices (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Vertices;
   end Active_Vertices;

   function Active_Edges (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Edges;
   end Active_Edges;

   function Active_Faces (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Faces;
   end Active_Faces;

   function Make_Vertex (Model : in out B_Rep_Model; P : Point_3D) return Vertex_ID is
   begin
      for I in Vertex_ID range 1 .. Max_Items loop
         if Model.Vertices (I).State = Free then
            Model.Vertices (I).State := Active;
            Model.Vertices (I).Point := P;
            Model.Num_Vertices := Model.Num_Vertices + 1;
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Vertex;

   function Make_Edge (Model : in out B_Rep_Model; V1, V2 : Vertex_ID) return Edge_ID is
   begin
      if V1 = Invalid_Vertex or else V2 = Invalid_Vertex then
         raise Invalid_ID_Error;
      end if;
      
      if Model.Vertices (V1).State = Free or else Model.Vertices (V2).State = Free then
         raise Invalid_ID_Error;
      end if;

      for I in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (I).State = Free then
            Model.Edges (I).State := Active;
            Model.Edges (I).V1 := V1;
            Model.Edges (I).V2 := V2;
            Model.Num_Edges := Model.Num_Edges + 1;
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Edge;

   function Make_Face (Model : in out B_Rep_Model; Edges : Edge_Array) return Face_ID is
   begin
      if Edges'Length > Max_Face_Edges then
         raise Capacity_Error;
      end if;

      for I in Face_ID range 1 .. Max_Items loop
         if Model.Faces (I).State = Free then
            Model.Faces (I).State := Active;
            Model.Faces (I).Edges.Count := Edges'Length;
            for J in Edges'Range loop
               Model.Faces (I).Edges.Elements (J - Edges'First + 1) := Edges (J);
            end loop;
            Model.Num_Faces := Model.Num_Faces + 1;
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Face;

   function Euler_Poincare_Characteristic (Model : B_Rep_Model) return Integer is
   begin
      -- Standard Euler formula for a single shell: V - E + F
      return Model.Num_Vertices - Model.Num_Edges + Model.Num_Faces;
   end Euler_Poincare_Characteristic;

   function Is_Valid_Manifold (Model : B_Rep_Model) return Boolean is
   begin
      -- A valid closed 2-manifold without holes (genus 0) has Euler characteristic exactly 2
      return Euler_Poincare_Characteristic (Model) = 2;
   end Is_Valid_Manifold;

   procedure Make_Vertex_Face_Shell 
     (Model : out B_Rep_Model; 
      P     : Point_3D; 
      V     : out Vertex_ID; 
      F     : out Face_ID) 
   is
      Temp     : B_Rep_Model;
      No_Edges : constant Edge_Array (1 .. 0) := [others => Invalid_Edge];
   begin
      -- MVFS creates the initial topology starting point (1 Vertex, 1 Face, 0 Edges)
      Initialize (Temp);
      V := Make_Vertex (Temp, P);
      F := Make_Face (Temp, No_Edges);
      Model := Temp;
   end Make_Vertex_Face_Shell;

   procedure Make_Edge_Vertex 
     (Model   : in out B_Rep_Model; 
      V_Start : Vertex_ID; 
      P_End   : Point_3D;
      V_End   : out Vertex_ID; 
      E       : out Edge_ID) 
   is
   begin
      -- MEV safely extends a single vertex into a wire segment
      V_End := Make_Vertex (Model, P_End);
      E     := Make_Edge (Model, V_Start, V_End);
   end Make_Edge_Vertex;

   procedure Make_Edge_Face 
     (Model : in out B_Rep_Model; 
      V1    : Vertex_ID; 
      V2    : Vertex_ID;
      E     : out Edge_ID; 
      F_New : out Face_ID) 
   is
      New_Edges : Edge_Array (1 .. 1);
   begin
      -- MEF creates a new edge and bounds a new face with it, preserving manifold properties
      E := Make_Edge (Model, V1, V2);
      New_Edges (1) := E;
      F_New := Make_Face (Model, New_Edges);
   end Make_Edge_Face;

   procedure Kill_Edge_Vertex (Model : in out B_Rep_Model; E : Edge_ID; V : Vertex_ID) is
   begin
      if E = Invalid_Edge or else V = Invalid_Vertex then
         raise Invalid_ID_Error;
      end if;

      if Model.Edges (E).State = Free or else Model.Vertices (V).State = Free then
         raise Invalid_ID_Error;
      end if;

      -- Validate that the edge actually connects to the vertex
      if Model.Edges (E).V1 /= V and then Model.Edges (E).V2 /= V then
         raise Topology_Error;
      end if;

      Model.Edges (E).State := Free;
      Model.Num_Edges       := Model.Num_Edges - 1;

      Model.Vertices (V).State := Free;
      Model.Num_Vertices       := Model.Num_Vertices - 1;
   end Kill_Edge_Vertex;

   procedure Kill_Edge_Face (Model : in out B_Rep_Model; E : Edge_ID; F : Face_ID) is
   begin
      if E = Invalid_Edge or else F = Invalid_Face then
         raise Invalid_ID_Error;
      end if;

      if Model.Edges (E).State = Free or else Model.Faces (F).State = Free then
         raise Invalid_ID_Error;
      end if;

      Model.Edges (E).State := Free;
      Model.Num_Edges       := Model.Num_Edges - 1;

      Model.Faces (F).State := Free;
      Model.Num_Faces       := Model.Num_Faces - 1;
   end Kill_Edge_Face;

   function Get_Vertex_Point (Model : B_Rep_Model; V : Vertex_ID) return Point_3D is
   begin
      if V = Invalid_Vertex or else Model.Vertices (V).State = Free then
         raise Invalid_ID_Error;
      end if;
      return Model.Vertices (V).Point;
   end Get_Vertex_Point;

   function Are_Connected (Model : B_Rep_Model; V1, V2 : Vertex_ID) return Boolean is
   begin
      if V1 = Invalid_Vertex or else V2 = Invalid_Vertex then
         return False;
      end if;

      for I in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (I).State = Active then
            if (Model.Edges (I).V1 = V1 and then Model.Edges (I).V2 = V2) or else
               (Model.Edges (I).V1 = V2 and then Model.Edges (I).V2 = V1) 
            then
               return True;
            end if;
         end if;
      end loop;
      
      return False;
   end Are_Connected;

end Boundary_Representation;

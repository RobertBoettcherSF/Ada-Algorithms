--  Hyperlink_Induced_Topic_Search body — Kleinberg HITS hubs & authorities.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;

package body Hyperlink_Induced_Topic_Search
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
         G.Out_Head (V) := 0;
         G.In_Head (V) := 0;
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
      --  Out-list: From -> To
      G.Out_To (G.E) := To;
      G.Out_Next (G.E) := G.Out_Head (From);
      G.Out_Head (From) := G.E;
      --  In-list: From -> To (stored at To)
      G.In_From (G.E) := From;
      G.In_Next (G.E) := G.In_Head (To);
      G.In_Head (To) := G.E;
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

   procedure L2_Normalize
     (Vec : in out Score_Array; N : Natural)
   is
      Sum_Sq : Float := 0.0;
      Norm   : Float;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Sum_Sq := Sum_Sq + Vec (V) * Vec (V);
      end loop;
      if Sum_Sq <= 0.0 then
         --  Edgeless / zero contribution: leave as zeros.
         return;
      end if;
      Norm := Sqrt (Sum_Sq);
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Vec (V) := Vec (V) / Norm;
      end loop;
   end L2_Normalize;

   -------------------------------------------------------------------------
   -- HITS iteration: a <- A^T h, h <- A a, L2-normalize each
   -------------------------------------------------------------------------

   procedure Compute
     (G           : Graph;
      Max_Iters   : Positive := 100;
      Tolerance   : Float := 1.0e-6;
      Authorities : out Score_Array;
      Hubs        : out Score_Array;
      Iterations  : out Natural)
   is
      N : constant Natural := G.N;

      Auth  : Score_Array (1 .. Vertex_Id (Max_Vertices));
      Hub   : Score_Array (1 .. Vertex_Id (Max_Vertices));
      New_A : Score_Array (1 .. Vertex_Id (Max_Vertices));
      New_H : Score_Array (1 .. Vertex_Id (Max_Vertices));

      Diff : Float;
      Eidx : Natural;
      Src  : Vertex_Id;
      Dest : Vertex_Id;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Authorities'First /= 1
        or else Natural (Authorities'Last) < N
      then
         raise Invalid_Argument;
      end if;
      if Hubs'First /= 1 or else Natural (Hubs'Last) < N then
         raise Invalid_Argument;
      end if;
      if Tolerance < 0.0 then
         raise Invalid_Argument;
      end if;

      --  Initialise auth = hub = 1
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Auth (V) := 1.0;
         Hub (V) := 1.0;
      end loop;

      Iterations := 0;

      for Iter in 1 .. Max_Iters loop
         Iterations := Iter;

         --  Authority update: a(v) = sum hub(u) over u -> v
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            New_A (V) := 0.0;
            Eidx := G.In_Head (V);
            while Eidx /= 0 loop
               Src := G.In_From (Edge_Index (Eidx));
               New_A (V) := New_A (V) + Hub (Src);
               Eidx := G.In_Next (Edge_Index (Eidx));
            end loop;
         end loop;
         L2_Normalize (New_A, N);

         --  Hub update: h(u) = sum auth(v) over u -> v
         for U in Vertex_Id range 1 .. Vertex_Id (N) loop
            New_H (U) := 0.0;
            Eidx := G.Out_Head (U);
            while Eidx /= 0 loop
               Dest := G.Out_To (Edge_Index (Eidx));
               New_H (U) := New_H (U) + New_A (Dest);
               Eidx := G.Out_Next (Edge_Index (Eidx));
            end loop;
         end loop;
         L2_Normalize (New_H, N);

         --  L1 change of both vectors
         Diff := 0.0;
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            Diff := Diff + abs (New_A (V) - Auth (V));
            Diff := Diff + abs (New_H (V) - Hub (V));
            Auth (V) := New_A (V);
            Hub (V) := New_H (V);
         end loop;

         exit when Diff <= Tolerance;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Authorities (V) := Auth (V);
         Hubs (V) := Hub (V);
      end loop;
   end Compute;

end Hyperlink_Induced_Topic_Search;

--  Coin_Graph body — disk collection, tangency tests, contact extraction.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Coin_Graph
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Packing mutators / queries
   ---------------------------------------------------------------------------

   procedure Clear (P : in out Packing) is
   begin
      P.N := 0;
   end Clear;

   procedure Add_Circle (P : in out Packing; C : Circle) is
   begin
      if C.R <= 0 then
         raise Invalid_Argument;
      end if;
      if P.N >= Max_Circles then
         raise Invalid_Argument;
      end if;
      P.N := P.N + 1;
      P.Circles (P.N) := C;
   end Add_Circle;

   function Circle_Count (P : Packing) return Natural is (P.N);

   function Get_Circle (P : Packing; Index : Circle_Index) return Circle is
   begin
      if Natural (Index) > P.N then
         raise Invalid_Argument;
      end if;
      return P.Circles (Natural (Index));
   end Get_Circle;

   ---------------------------------------------------------------------------
   -- Geometry helpers
   ---------------------------------------------------------------------------

   function Euclidean_Distance (A, B : Circle) return Long_Float is
      use Ada.Numerics.Long_Elementary_Functions;
      DX : constant Long_Integer :=
        Long_Integer (A.X) - Long_Integer (B.X);
      DY : constant Long_Integer :=
        Long_Integer (A.Y) - Long_Integer (B.Y);
      Sq : constant Long_Integer := DX * DX + DY * DY;
   begin
      return Sqrt (Long_Float (Sq));
   end Euclidean_Distance;

   function Sum_Of_Radii (A, B : Circle) return Long_Float is
     (Long_Float (A.R) + Long_Float (B.R));

   function Are_Externally_Tangent (A, B : Circle) return Boolean is
      D   : constant Long_Float := Euclidean_Distance (A, B);
      Sum : constant Long_Float := Sum_Of_Radii (A, B);
   begin
      return abs (D - Sum) <= Epsilon;
   end Are_Externally_Tangent;

   function Interiors_Overlap (A, B : Circle) return Boolean is
      D   : constant Long_Float := Euclidean_Distance (A, B);
      Sum : constant Long_Float := Sum_Of_Radii (A, B);
   begin
      return D + Epsilon < Sum;
   end Interiors_Overlap;

   ---------------------------------------------------------------------------
   -- Validity / tangency / contact graph
   ---------------------------------------------------------------------------

   function Is_Valid_Packing (P : Packing) return Boolean is
   begin
      for I in 1 .. P.N - 1 loop
         for J in I + 1 .. P.N loop
            if Interiors_Overlap (P.Circles (I), P.Circles (J)) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Packing;

   function Are_Tangent
     (P : Packing; I, J : Circle_Index) return Boolean
   is
      NI : constant Natural := Natural (I);
      NJ : constant Natural := Natural (J);
   begin
      if NI > P.N or else NJ > P.N or else I = J then
         raise Invalid_Argument;
      end if;
      return Are_Externally_Tangent (P.Circles (NI), P.Circles (NJ));
   end Are_Tangent;

   procedure Require_Edge_Buffer (N : Natural; Edges : Edge_List) is
      Need : Natural;
   begin
      if Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         return;
      end if;
      Need := N * (N - 1) / 2;
      if Edges'Last < Need then
         raise Invalid_Argument;
      end if;
   end Require_Edge_Buffer;

   procedure Build_Contact_Graph
     (P     : Packing;
      Edges : in out Edge_List;
      Count : out Natural)
   is
      K : Natural := 0;
   begin
      Require_Edge_Buffer (P.N, Edges);
      for I in 1 .. P.N - 1 loop
         for J in I + 1 .. P.N loop
            if Are_Externally_Tangent (P.Circles (I), P.Circles (J)) then
               K := K + 1;
               Edges (K) :=
                 (U => Circle_Index (I), V => Circle_Index (J));
            end if;
         end loop;
      end loop;
      Count := K;
   end Build_Contact_Graph;

   procedure Contact_Edges
     (P     : Packing;
      Edges : in out Edge_List;
      Count : out Natural)
   is
   begin
      Build_Contact_Graph (P, Edges, Count);
   end Contact_Edges;

   ---------------------------------------------------------------------------
   -- Equal-radius grid helper
   ---------------------------------------------------------------------------

   procedure Add_Equal_Radius_Grid
     (P        : in out Packing;
      Rows     : Positive;
      Cols     : Positive;
      Radius   : Positive;
      Origin_X : Integer := 0;
      Origin_Y : Integer := 0)
   is
      Step : constant Integer := 2 * Integer (Radius);
      Need : constant Natural := Natural (Rows) * Natural (Cols);
   begin
      if P.N + Need > Max_Circles then
         raise Invalid_Argument;
      end if;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            Add_Circle
              (P,
               (X => Origin_X + (Integer (C) - 1) * Step,
                Y => Origin_Y + (Integer (R) - 1) * Step,
                R => Integer (Radius)));
         end loop;
      end loop;
   end Add_Equal_Radius_Grid;

end Coin_Graph;

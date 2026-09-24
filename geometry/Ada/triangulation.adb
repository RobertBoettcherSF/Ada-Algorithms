--  Triangulation body — survey: ear-clip polygon + fan / Bowyer–Watson-lite
--  point-set drivers (educational Float; Max_Points = 64).

pragma Ada_2022;

package body Triangulation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   ---------------------------------------------------------------------------
   -- Orientation / area / predicates
   ---------------------------------------------------------------------------

   function Orient2D (A, B, C : Point) return Real is
   begin
      return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
   end Orient2D;

   function CCW (A, B, C : Point) return Boolean is
   begin
      return Orient2D (A, B, C) > Epsilon;
   end CCW;

   function Triangle_Area (A, B, C : Point) return Real is
   begin
      return abs (Orient2D (A, B, C)) / 2.0;
   end Triangle_Area;

   function Signed_Area (Polygon : Point_Array) return Real is
      Sum : Real := 0.0;
      N   : constant Natural := Polygon'Length;
      J   : Point_Index;
   begin
      if N < 3 then
         return 0.0;
      end if;
      for I in Polygon'Range loop
         if I = Polygon'Last then
            J := Polygon'First;
         else
            J := I + 1;
         end if;
         Sum := Sum + Polygon (I).X * Polygon (J).Y
                    - Polygon (J).X * Polygon (I).Y;
      end loop;
      return Sum;
   end Signed_Area;

   function Area (Polygon : Point_Array) return Real is
   begin
      return abs (Signed_Area (Polygon)) / 2.0;
   end Area;

   function Polygon_Triangle_Count (N : Natural) return Natural is
   begin
      if N < 3 then
         return 0;
      end if;
      return N - 2;
   end Polygon_Triangle_Count;

   function Point_In_Triangle
     (P, A, B, C : Point; Strict : Boolean := True) return Boolean
   is
      O  : constant Real := Orient2D (A, B, C);
      O1 : constant Real := Orient2D (A, B, P);
      O2 : constant Real := Orient2D (B, C, P);
      O3 : constant Real := Orient2D (C, A, P);
      Tol : constant Real := Epsilon;
   begin
      if abs (O) <= Tol then
         return False;
      end if;
      if O > 0.0 then
         if Strict then
            return O1 > Tol and then O2 > Tol and then O3 > Tol;
         else
            return O1 >= -Tol and then O2 >= -Tol and then O3 >= -Tol;
         end if;
      else
         if Strict then
            return O1 < -Tol and then O2 < -Tol and then O3 < -Tol;
         else
            return O1 <= Tol and then O2 <= Tol and then O3 <= Tol;
         end if;
      end if;
   end Point_In_Triangle;

   function In_Circumcircle (A, B, C, P : Point) return Boolean is
      Adx : constant Real := A.X - P.X;
      Ady : constant Real := A.Y - P.Y;
      Bdx : constant Real := B.X - P.X;
      Bdy : constant Real := B.Y - P.Y;
      Cdx : constant Real := C.X - P.X;
      Cdy : constant Real := C.Y - P.Y;
      Ad2 : constant Real := Adx * Adx + Ady * Ady;
      Bd2 : constant Real := Bdx * Bdx + Bdy * Bdy;
      Cd2 : constant Real := Cdx * Cdx + Cdy * Cdy;
      Det : constant Real :=
        Adx * (Bdy * Cd2 - Bd2 * Cdy)
        - Ady * (Bdx * Cd2 - Bd2 * Cdx)
        + Ad2 * (Bdx * Cdy - Bdy * Cdx);
   begin
      return Det > Epsilon;
   end In_Circumcircle;

   ---------------------------------------------------------------------------
   -- Pre-checks
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box is
      B : Bounding_Box;
   begin
      B.Min_X := Points (Points'First).X;
      B.Max_X := Points (Points'First).X;
      B.Min_Y := Points (Points'First).Y;
      B.Max_Y := Points (Points'First).Y;
      for I in Points'Range loop
         if Points (I).X < B.Min_X then
            B.Min_X := Points (I).X;
         end if;
         if Points (I).X > B.Max_X then
            B.Max_X := Points (I).X;
         end if;
         if Points (I).Y < B.Min_Y then
            B.Min_Y := Points (I).Y;
         end if;
         if Points (I).Y > B.Max_Y then
            B.Max_Y := Points (I).Y;
         end if;
      end loop;
      return B;
   end Bounds_Of;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
   is
      Tol2 : constant Real := Tol * Tol;
   begin
      for I in Points'Range loop
         for J in Points'Range loop
            if J > I and then Dist2 (Points (I), Points (J)) <= Tol2 then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Near_Duplicate;

   function Is_Simple_Enough (Polygon : Point_Array) return Boolean is
      N : constant Natural := Polygon'Length;
   begin
      if N < 3 or else N > Max_Points then
         return False;
      end if;
      for I in Polygon'Range loop
         declare
            J : Point_Index;
         begin
            if I = Polygon'Last then
               J := Polygon'First;
            else
               J := I + 1;
            end if;
            if Near_Point (Polygon (I), Polygon (J)) then
               return False;
            end if;
         end;
      end loop;
      if abs (Signed_Area (Polygon)) <= Epsilon then
         return False;
      end if;
      return True;
   end Is_Simple_Enough;

   ---------------------------------------------------------------------------
   -- Dense index helpers
   ---------------------------------------------------------------------------

   function Dense_Of (Pts : Point_Array; Abs_Index : Point_Index)
     return Positive
   is
   begin
      return Positive (Abs_Index - Pts'First + 1);
   end Dense_Of;

   function Abs_Of (Pts : Point_Array; Dense_Index : Positive)
     return Point_Index
   is
   begin
      return Point_Index (Pts'First + Dense_Index - 1);
   end Abs_Of;

   ---------------------------------------------------------------------------
   -- Mesh helpers
   ---------------------------------------------------------------------------

   function Uses_Vertex
     (Tri : Triangle; V : Point_Index) return Boolean
   is
   begin
      return Tri.A = V or else Tri.B = V or else Tri.C = V;
   end Uses_Vertex;

   function Triangle_Count_Of (T : Mesh) return Triangle_Count is
   begin
      return T.Count;
   end Triangle_Count_Of;

   function Get_Triangle
     (T : Mesh; Index : Triangle_Index) return Triangle
   is
   begin
      return T.Tris (Index);
   end Get_Triangle;

   procedure Append_Triangle (M : in out Mesh; Tri : Triangle) is
   begin
      if M.Count = Max_Triangles then
         raise Capacity_Exceeded;
      end if;
      M.Count := M.Count + 1;
      M.Tris (M.Count) := Tri;
   end Append_Triangle;

   function Make_CCW
     (Pts : Point_Array; A, B, C : Point_Index) return Triangle
   is
   begin
      if Orient2D (Pts (A), Pts (B), Pts (C)) >= 0.0 then
         return (A => A, B => B, C => C);
      else
         return (A => A, B => C, C => B);
      end if;
   end Make_CCW;

   ---------------------------------------------------------------------------
   -- Ear-clipping polygon triangulation
   ---------------------------------------------------------------------------

   function Triangulate_Polygon (Polygon : Point_Array) return Mesh is
      N_In : constant Natural := Polygon'Length;
      Result : Mesh;
   begin
      if N_In < 3 or else N_In > Max_Points then
         raise Invalid_Argument;
      end if;
      if not Is_Simple_Enough (Polygon) then
         raise Invalid_Argument;
      end if;

      declare
         N : Positive := N_In;
         Ring  : array (1 .. Max_Points) of Positive;
         Verts : array (1 .. Max_Points) of Point;

         function R_Prev (I : Positive) return Positive is
           (if I = 1 then N else I - 1);
         function R_Next (I : Positive) return Positive is
           (if I = N then 1 else I + 1);

         procedure Remove_At (Pos : Positive) is
         begin
            for J in Pos .. N - 1 loop
               Ring (J) := Ring (J + 1);
               Verts (J) := Verts (J + 1);
            end loop;
            N := N - 1;
         end Remove_At;

         function Ring_Is_Ear (Pos : Positive) return Boolean is
            Pv : constant Positive := R_Prev (Pos);
            Nx : constant Positive := R_Next (Pos);
            A  : constant Point := Verts (Pv);
            B  : constant Point := Verts (Pos);
            C  : constant Point := Verts (Nx);
            O  : constant Real := Orient2D (A, B, C);
         begin
            if O <= Epsilon then
               return False;
            end if;
            if N = 3 then
               return True;
            end if;
            for I in 1 .. N loop
               if I /= Pv and then I /= Pos and then I /= Nx then
                  if Point_In_Triangle
                    (Verts (I), A, B, C, Strict => True)
                  then
                     return False;
                  end if;
               end if;
            end loop;
            return True;
         end Ring_Is_Ear;

         Found : Boolean;
         Tip   : Positive;
         Tri_N : Natural := 0;
      begin
         for I in 1 .. N_In loop
            Ring (I) := I;
            Verts (I) := Polygon (Abs_Of (Polygon, I));
         end loop;

         if Signed_Area (Polygon) < -Epsilon then
            declare
               L, R : Positive;
               Tmp_I : Positive;
               Tmp_P : Point;
            begin
               L := 1;
               R := N_In;
               while L < R loop
                  Tmp_I := Ring (L);
                  Ring (L) := Ring (R);
                  Ring (R) := Tmp_I;
                  Tmp_P := Verts (L);
                  Verts (L) := Verts (R);
                  Verts (R) := Tmp_P;
                  L := L + 1;
                  R := R - 1;
               end loop;
            end;
         end if;

         while N > 3 loop
            Found := False;
            Tip := 1;
            for Pos in 1 .. N loop
               if Ring_Is_Ear (Pos) then
                  Tip := Pos;
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               raise Invalid_Argument;
            end if;
            if Tri_N >= Max_Triangles then
               raise Capacity_Exceeded;
            end if;
            Tri_N := Tri_N + 1;
            Result.Tris (Triangle_Index (Tri_N)) :=
              (A => Point_Index (Ring (R_Prev (Tip))),
               B => Point_Index (Ring (Tip)),
               C => Point_Index (Ring (R_Next (Tip))));
            Remove_At (Tip);
         end loop;

         if Tri_N >= Max_Triangles then
            raise Capacity_Exceeded;
         end if;
         Tri_N := Tri_N + 1;
         Result.Tris (Triangle_Index (Tri_N)) :=
           (A => Point_Index (Ring (1)),
            B => Point_Index (Ring (2)),
            C => Point_Index (Ring (3)));
         Result.Count := Triangle_Count (Tri_N);
      end;

      if Result.Count /= Triangle_Count (Polygon_Triangle_Count (N_In)) then
         raise Invalid_Argument;
      end if;
      return Result;
   end Triangulate_Polygon;

   ---------------------------------------------------------------------------
   -- Fan from a vertex of an ordered ring
   ---------------------------------------------------------------------------

   function Fan_From_Vertex
     (Points : Point_Array; Apex : Point_Index) return Mesh
   is
      N : constant Natural := Points'Length;
      Result : Mesh;
      Apex_D : Positive;
      Seq : array (1 .. Max_Points) of Positive;
      S_N : Natural := 0;
      K : Positive;
   begin
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
      if Apex < Points'First or else Apex > Points'Last then
         raise Invalid_Argument;
      end if;
      if Has_Near_Duplicate (Points) then
         raise Invalid_Argument;
      end if;

      Apex_D := Dense_Of (Points, Apex);

      --  Cyclic order starting just after Apex.
      K := Apex_D;
      for Step in 1 .. N - 1 loop
         if K = N then
            K := 1;
         else
            K := K + 1;
         end if;
         S_N := S_N + 1;
         Seq (S_N) := K;
      end loop;

      --  Fan: △(Apex, Seq(j), Seq(j+1)) for j = 1 .. S_N-1.
      for J in 1 .. S_N - 1 loop
         declare
            A : constant Point := Points (Abs_Of (Points, Apex_D));
            B : constant Point := Points (Abs_Of (Points, Seq (J)));
            C : constant Point := Points (Abs_Of (Points, Seq (J + 1)));
         begin
            if abs (Orient2D (A, B, C)) > Epsilon then
               Append_Triangle
                 (Result,
                  (A => Point_Index (Apex_D),
                   B => Point_Index (Seq (J)),
                   C => Point_Index (Seq (J + 1))));
            end if;
         end;
      end loop;

      if Result.Count = 0 then
         raise Invalid_Argument;
      end if;
      return Result;
   end Fan_From_Vertex;

   ---------------------------------------------------------------------------
   -- Bowyer–Watson-lite
   ---------------------------------------------------------------------------

   type Edge is record
      U, V : Point_Index := 1;
   end record;

   type Edge_Array is array (Positive range <>) of Edge;

   function Same_Undirected (E1, E2 : Edge) return Boolean is
   begin
      return (E1.U = E2.U and then E1.V = E2.V)
        or else (E1.U = E2.V and then E1.V = E2.U);
   end Same_Undirected;

   procedure Build_Super_Triangle
     (User_Pts : Point_Array;
      Work     : in out Point_Array;
      N_User   : Point_Count;
      Super_A, Super_B, Super_C : out Point_Index)
   is
      Box : constant Bounding_Box := Bounds_Of (User_Pts);
      DX  : constant Real := Box.Max_X - Box.Min_X;
      DY  : constant Real := Box.Max_Y - Box.Min_Y;
      Span : Real := DX;
      Mid_X, Mid_Y, Margin : Real;
   begin
      if DY > Span then
         Span := DY;
      end if;
      if Span < 1.0 then
         Span := 1.0;
      end if;
      Margin := 20.0 * Span + 10.0;
      Mid_X := (Box.Min_X + Box.Max_X) / 2.0;
      Mid_Y := (Box.Min_Y + Box.Max_Y) / 2.0;
      Super_A := Point_Index (N_User + 1);
      Super_B := Point_Index (N_User + 2);
      Super_C := Point_Index (N_User + 3);
      Work (Super_A) := (X => Mid_X - Margin, Y => Mid_Y - Margin);
      Work (Super_B) := (X => Mid_X + Margin, Y => Mid_Y - Margin);
      Work (Super_C) := (X => Mid_X,         Y => Mid_Y + Margin);
   end Build_Super_Triangle;

   procedure Insert_Point
     (Work  : Point_Array;
      M     : in out Mesh;
      P_Idx : Point_Index)
   is
      Bad       : array (1 .. Max_Triangles) of Boolean := [others => False];
      Bad_Count : Natural := 0;
      Hole      : Edge_Array (1 .. Max_Hole_Edges);
      Hole_N    : Natural := 0;
      P         : constant Point := Work (P_Idx);
      New_Mesh  : Mesh;
      Shared    : Boolean;
   begin
      for I in 1 .. M.Count loop
         declare
            Tri : constant Triangle := M.Tris (I);
         begin
            if In_Circumcircle
              (Work (Tri.A), Work (Tri.B), Work (Tri.C), P)
            then
               Bad (I) := True;
               Bad_Count := Bad_Count + 1;
            end if;
         end;
      end loop;

      if Bad_Count = 0 then
         return;
      end if;

      for I in 1 .. M.Count loop
         if Bad (I) then
            declare
               Tri : constant Triangle := M.Tris (I);
               E1  : constant Edge := (U => Tri.A, V => Tri.B);
               E2  : constant Edge := (U => Tri.B, V => Tri.C);
               E3  : constant Edge := (U => Tri.C, V => Tri.A);

               procedure Consider (E : Edge) is
               begin
                  Shared := False;
                  for J in 1 .. M.Count loop
                     if Bad (J) and then J /= I then
                        declare
                           Tj : constant Triangle := M.Tris (J);
                           F1 : constant Edge := (U => Tj.A, V => Tj.B);
                           F2 : constant Edge := (U => Tj.B, V => Tj.C);
                           F3 : constant Edge := (U => Tj.C, V => Tj.A);
                        begin
                           if Same_Undirected (E, F1)
                             or else Same_Undirected (E, F2)
                             or else Same_Undirected (E, F3)
                           then
                              Shared := True;
                              exit;
                           end if;
                        end;
                     end if;
                  end loop;
                  if not Shared then
                     if Hole_N >= Max_Hole_Edges then
                        raise Capacity_Exceeded;
                     end if;
                     Hole_N := Hole_N + 1;
                     Hole (Hole_N) := E;
                  end if;
               end Consider;
            begin
               Consider (E1);
               Consider (E2);
               Consider (E3);
            end;
         end if;
      end loop;

      New_Mesh.Count := 0;
      for I in 1 .. M.Count loop
         if not Bad (I) then
            Append_Triangle (New_Mesh, M.Tris (I));
         end if;
      end loop;

      for K in 1 .. Hole_N loop
         Append_Triangle
           (New_Mesh, Make_CCW (Work, Hole (K).U, Hole (K).V, P_Idx));
      end loop;

      M := New_Mesh;
   end Insert_Point;

   function Bowyer_Watson_Lite (Points : Point_Array) return Mesh is
      N : constant Natural := Points'Length;
      Work : Point_Array (1 .. Max_Points + 3);
      M : Mesh;
      Super_A, Super_B, Super_C : Point_Index;
      Result : Mesh;
      Src : Point_Index;
   begin
      Src := 1;
      for I in Points'Range loop
         Work (Src) := Points (I);
         Src := Src + 1;
      end loop;

      Build_Super_Triangle
        (User_Pts => Points,
         Work     => Work,
         N_User   => Point_Count (N),
         Super_A  => Super_A,
         Super_B  => Super_B,
         Super_C  => Super_C);

      M.Count := 0;
      Append_Triangle (M, Make_CCW (Work, Super_A, Super_B, Super_C));

      for P_Idx in 1 .. Point_Index (N) loop
         Insert_Point (Work, M, P_Idx);
      end loop;

      Result.Count := 0;
      for I in 1 .. M.Count loop
         declare
            Tri : constant Triangle := M.Tris (I);
         begin
            if not Uses_Vertex (Tri, Super_A)
              and then not Uses_Vertex (Tri, Super_B)
              and then not Uses_Vertex (Tri, Super_C)
            then
               Append_Triangle (Result, Tri);
            end if;
         end;
      end loop;

      if Result.Count = 0 then
         raise Invalid_Argument;
      end if;
      return Result;
   end Bowyer_Watson_Lite;

   ---------------------------------------------------------------------------
   -- Hull + fan-from-interior
   ---------------------------------------------------------------------------

   function Fan_From_Interior (Points : Point_Array) return Mesh is
      N : constant Natural := Points'Length;
      Work : Point_Array (1 .. Max_Points);
      --  Sorted by X then Y for monotone chain.
      Order : array (1 .. Max_Points) of Point_Index;
      Lower : array (1 .. Max_Points) of Point_Index := [others => 1];
      Upper : array (1 .. Max_Points) of Point_Index := [others => 1];
      Hull  : array (1 .. Max_Points) of Point_Index := [others => 1];
      Low_N, Up_N, Hull_N : Natural := 0;
      On_Hull : array (1 .. Max_Points) of Boolean := [others => False];
      Interior : array (1 .. Max_Points) of Point_Index;
      Int_N : Natural := 0;
      Result : Mesh;
      Apex : Point_Index;
   begin
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
      if Has_Near_Duplicate (Points) then
         raise Invalid_Argument;
      end if;

      declare
         K : Point_Index := 1;
      begin
         for I in Points'Range loop
            Work (K) := Points (I);
            Order (Positive (K)) := K;
            K := K + 1;
         end loop;
      end;

      --  Sort Order by (X, Y).
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            declare
               PI : constant Point := Work (Order (I));
               PJ : constant Point := Work (Order (J));
               Tmp : Point_Index;
            begin
               if PJ.X < PI.X
                 or else (Near (PJ.X, PI.X) and then PJ.Y < PI.Y)
               then
                  Tmp := Order (I);
                  Order (I) := Order (J);
                  Order (J) := Tmp;
               end if;
            end;
         end loop;
      end loop;

      --  Lower hull.
      for I in 1 .. N loop
         declare
            Idx : constant Point_Index := Order (I);
         begin
            while Low_N >= 2
              and then Orient2D
                (Work (Lower (Low_N - 1)),
                 Work (Lower (Low_N)),
                 Work (Idx)) <= Epsilon
            loop
               Low_N := Low_N - 1;
            end loop;
            Low_N := Low_N + 1;
            Lower (Low_N) := Idx;
         end;
      end loop;

      --  Upper hull.
      for I in reverse 1 .. N loop
         declare
            Idx : constant Point_Index := Order (I);
         begin
            while Up_N >= 2
              and then Orient2D
                (Work (Upper (Up_N - 1)),
                 Work (Upper (Up_N)),
                 Work (Idx)) <= Epsilon
            loop
               Up_N := Up_N - 1;
            end loop;
            Up_N := Up_N + 1;
            Upper (Up_N) := Idx;
         end;
      end loop;

      --  Concatenate (drop duplicate endpoints).
      Hull_N := 0;
      for I in 1 .. Low_N - 1 loop
         Hull_N := Hull_N + 1;
         Hull (Hull_N) := Lower (I);
      end loop;
      for I in 1 .. Up_N - 1 loop
         Hull_N := Hull_N + 1;
         Hull (Hull_N) := Upper (I);
      end loop;

      if Hull_N < 3 then
         raise Invalid_Argument;
      end if;

      for I in 1 .. Hull_N loop
         On_Hull (Positive (Hull (I))) := True;
      end loop;

      for I in 1 .. N loop
         if not On_Hull (I) then
            Int_N := Int_N + 1;
            Interior (Int_N) := Point_Index (I);
         end if;
      end loop;

      if Int_N = 0 then
         --  Convex position: fan hull from Hull (1).
         Apex := Hull (1);
         for J in 2 .. Hull_N - 1 loop
            Append_Triangle
              (Result,
               Make_CCW
                 (Work, Apex, Hull (J), Hull (J + 1)));
         end loop;
      elsif Int_N = 1 then
         --  Single interior site: fan to consecutive hull edges.
         Apex := Interior (1);
         for J in 1 .. Hull_N loop
            declare
               Nx : Point_Index;
            begin
               if J = Hull_N then
                  Nx := Hull (1);
               else
                  Nx := Hull (J + 1);
               end if;
               Append_Triangle
                 (Result, Make_CCW (Work, Apex, Hull (J), Nx));
            end;
         end loop;
      else
         --  Multiple interior sites: fan sketch insufficient.
         raise Invalid_Argument;
      end if;

      if Result.Count = 0 then
         raise Invalid_Argument;
      end if;
      return Result;
   end Fan_From_Interior;

   ---------------------------------------------------------------------------
   -- Point-set driver
   ---------------------------------------------------------------------------

   function Triangulate_Point_Set (Points : Point_Array) return Mesh is
      N : constant Natural := Points'Length;
   begin
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
      if Has_Near_Duplicate (Points) then
         raise Invalid_Argument;
      end if;

      --  Prefer fan from interior / hull when the set is convex or has a
      --  single interior site; otherwise Bowyer–Watson-lite.
      declare
         Fan : Mesh;
      begin
         Fan := Fan_From_Interior (Points);
         return Fan;
      exception
         when Invalid_Argument =>
            return Bowyer_Watson_Lite (Points);
      end;
   end Triangulate_Point_Set;

begin
   null;
end Triangulation;

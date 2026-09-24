--  Marching_Triangles body — advancing-front surface reconstruction
--  from a 3-D point cloud (educational Float).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Marching_Triangles
  with SPARK_Mode => Off
is

   package LEF renames Ada.Numerics.Long_Elementary_Functions;

   function Sqrt_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (LEF.Sqrt (Long_Float (X)));
   end Sqrt_R;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point3; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol)
        and then Near (A.Y, B.Y, Tol)
        and then Near (A.Z, B.Z, Tol);
   end Near_Point;

   function Dist3_Squared (A, B : Point3) return Real is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
      DZ : constant Real := A.Z - B.Z;
   begin
      return DX * DX + DY * DY + DZ * DZ;
   end Dist3_Squared;

   function Dist3 (A, B : Point3) return Real is
   begin
      return Sqrt_R (Dist3_Squared (A, B));
   end Dist3;

   function Dot (U, V : Point3) return Real is
   begin
      return U.X * V.X + U.Y * V.Y + U.Z * V.Z;
   end Dot;

   function Cross (U, V : Point3) return Point3 is
   begin
      return
        (X => U.Y * V.Z - U.Z * V.Y,
         Y => U.Z * V.X - U.X * V.Z,
         Z => U.X * V.Y - U.Y * V.X);
   end Cross;

   function Sub (A, B : Point3) return Point3 is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end Sub;

   function Length (V : Point3) return Real is
   begin
      return Sqrt_R (V.X * V.X + V.Y * V.Y + V.Z * V.Z);
   end Length;

   function Normalize (V : Point3) return Point3 is
      L : constant Real := Length (V);
   begin
      if L <= Epsilon then
         return (X => 0.0, Y => 0.0, Z => 0.0);
      end if;
      return (X => V.X / L, Y => V.Y / L, Z => V.Z / L);
   end Normalize;

   ---------------------------------------------------------------------------
   -- Triangle / edge helpers
   ---------------------------------------------------------------------------

   function Normal_Of_Triangle (A, B, C : Point3) return Point3 is
      AB : constant Point3 := Sub (A => B, B => A);
      AC : constant Point3 := Sub (A => C, B => A);
   begin
      return Normalize (Cross (U => AB, V => AC));
   end Normal_Of_Triangle;

   function Triangle_Area (A, B, C : Point3) return Real is
      AB : constant Point3 := Sub (A => B, B => A);
      AC : constant Point3 := Sub (A => C, B => A);
   begin
      return 0.5 * Length (Cross (U => AB, V => AC));
   end Triangle_Area;

   function Make_Edge_Key (I, J : Point_Index) return Edge_Key is
   begin
      if I <= J then
         return (Lo => I, Hi => J);
      else
         return (Lo => J, Hi => I);
      end if;
   end Make_Edge_Key;

   function Same_Edge (E1, E2 : Edge_Key) return Boolean is
   begin
      return E1.Lo = E2.Lo and then E1.Hi = E2.Hi;
   end Same_Edge;

   function Contains_Edge
     (Set : Boundary_Edge_Set; Key : Edge_Key) return Boolean
   is
   begin
      for K in 1 .. Set.Count loop
         if Same_Edge (Set.Edges (K), Key) then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Edge;

   procedure Toggle_Boundary_Edge
     (Set : in out Boundary_Edge_Set; Key : Edge_Key)
   is
   begin
      for K in 1 .. Set.Count loop
         if Same_Edge (Set.Edges (K), Key) then
            Set.Edges (K) := Set.Edges (Set.Count);
            Set.Count := Set.Count - 1;
            return;
         end if;
      end loop;
      if Set.Count = Max_Boundary_Edges then
         raise Capacity_Exceeded;
      end if;
      Set.Count := Set.Count + 1;
      Set.Edges (Set.Count) := Key;
   end Toggle_Boundary_Edge;

   function Has_Near_Duplicate
     (Cloud : Point_Array; Tol : Real := Epsilon) return Boolean
   is
      Tol2 : constant Real := Tol * Tol;
   begin
      for I in Cloud'Range loop
         for J in I + 1 .. Cloud'Last loop
            if Dist3_Squared (Cloud (I), Cloud (J)) <= Tol2 then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Near_Duplicate;

   ---------------------------------------------------------------------------
   -- Internal: remap cloud to 1 .. N working table
   ---------------------------------------------------------------------------

   procedure Copy_Cloud
     (Cloud : Point_Array;
      Work  : out Point_Array;
      N     : out Point_Count)
   is
      K : Point_Index := 1;
   begin
      N := Cloud'Length;
      for I in Cloud'Range loop
         Work (K) := Cloud (I);
         if K < N then
            K := K + 1;
         end if;
      end loop;
   end Copy_Cloud;

   function Perimeter (A, B, C : Point3) return Real is
   begin
      return Dist3 (A, B) + Dist3 (B, C) + Dist3 (C, A);
   end Perimeter;

   ---------------------------------------------------------------------------
   -- Seed triangle
   ---------------------------------------------------------------------------

   function Find_Seed_Triangle
     (Cloud : Point_Array) return Triangle
   is
      Raw_N : constant Natural := Cloud'Length;
      N : Point_Count;
      Work : Point_Array (1 .. Max_Points);
      NN : Point_Count;
      Best : Triangle := (A => 1, B => 2, C => 3);
      Best_Perim : Real := Real'Last;
      Found : Boolean := False;
      Area, Peri : Real;
      PA, PB, PC : Point3;
   begin
      if Raw_N < 3 or else Raw_N > Max_Points then
         raise Invalid_Argument;
      end if;
      N := Point_Count (Raw_N);
      Copy_Cloud (Cloud, Work, NN);
      pragma Assert (NN = N);

      for I in 1 .. N loop
         for J in I + 1 .. N loop
            for K in J + 1 .. N loop
               PA := Work (I);
               PB := Work (J);
               PC := Work (K);
               Area := Triangle_Area (PA, PB, PC);
               if Area > Area_Tol then
                  Peri := Perimeter (PA, PB, PC);
                  if (not Found) or else Peri < Best_Perim then
                     Best_Perim := Peri;
                     Best := (A => I, B => J, C => K);
                     Found := True;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;

      if not Found then
         raise Invalid_Argument;
      end if;
      return Best;
   end Find_Seed_Triangle;

   ---------------------------------------------------------------------------
   -- Mesh accessors
   ---------------------------------------------------------------------------

   function Triangle_Count_Of (M : Mesh) return Triangle_Count is
   begin
      return M.Count;
   end Triangle_Count_Of;

   function Get_Triangle
     (M : Mesh; Index : Triangle_Index) return Triangle
   is
   begin
      return M.Tris (Index);
   end Get_Triangle;

   function All_Indices_In_Range
     (M : Mesh; N : Point_Count) return Boolean
   is
      T : Triangle;
   begin
      for I in 1 .. M.Count loop
         T := M.Tris (I);
         if Natural (T.A) > Natural (N)
           or else Natural (T.B) > Natural (N)
           or else Natural (T.C) > Natural (N)
         then
            return False;
         end if;
      end loop;
      return True;
   end All_Indices_In_Range;

   ---------------------------------------------------------------------------
   -- Advancing-front reconstruction
   ---------------------------------------------------------------------------

   procedure Append_Triangle
     (M   : in out Mesh;
      Tri : Triangle;
      Set : in out Boundary_Edge_Set)
   is
   begin
      if M.Count = Max_Triangles then
         raise Capacity_Exceeded;
      end if;
      M.Count := M.Count + 1;
      M.Tris (M.Count) := Tri;
      Toggle_Boundary_Edge (Set, Make_Edge_Key (Tri.A, Tri.B));
      Toggle_Boundary_Edge (Set, Make_Edge_Key (Tri.B, Tri.C));
      Toggle_Boundary_Edge (Set, Make_Edge_Key (Tri.C, Tri.A));
   end Append_Triangle;

   function Edge_Incident_Count
     (M : Mesh; Key : Edge_Key) return Natural
   is
      T : Triangle;
      Count : Natural := 0;
      E1, E2, E3 : Edge_Key;
   begin
      for I in 1 .. M.Count loop
         T := M.Tris (I);
         E1 := Make_Edge_Key (T.A, T.B);
         E2 := Make_Edge_Key (T.B, T.C);
         E3 := Make_Edge_Key (T.C, T.A);
         if Same_Edge (E1, Key) or else Same_Edge (E2, Key)
           or else Same_Edge (E3, Key)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Edge_Incident_Count;

   function Third_Vertex
     (M : Mesh; I, J : Point_Index; Found : out Boolean) return Point_Index
   is
      --  Third vertex of the unique triangle containing undirected edge IJ.
      T : Triangle;
      Key : constant Edge_Key := Make_Edge_Key (I, J);
      E1, E2, E3 : Edge_Key;
   begin
      Found := False;
      for K in 1 .. M.Count loop
         T := M.Tris (K);
         E1 := Make_Edge_Key (T.A, T.B);
         E2 := Make_Edge_Key (T.B, T.C);
         E3 := Make_Edge_Key (T.C, T.A);
         if Same_Edge (E1, Key) or else Same_Edge (E2, Key)
           or else Same_Edge (E3, Key)
         then
            Found := True;
            if T.A /= I and then T.A /= J then
               return T.A;
            elsif T.B /= I and then T.B /= J then
               return T.B;
            else
               return T.C;
            end if;
         end if;
      end loop;
      return I;
   end Third_Vertex;

   function Is_Exterior_Side
     (Work : Point_Array;
      I, J, Opp, P : Point_Index) return Boolean
   is
      --  Educational half-space / fold test for frontier edge IJ whose
      --  existing opposite vertex is Opp:
      --    * If P is on the opposite radial side of line IJ from Opp
      --      (Dot of the two edge-cross products < 0), accept — this is
      --      the planar-patch closing case (square diagonal).
      --    * If P is on the same radial side but significantly out of the
      --      plane of triangle IJOpp, accept — closed/polyhedral growth
      --      (tetrahedron apex above a seed face).
      --    * If P is same-side and nearly coplanar, reject — prevents
      --      double-covering a planar region from a boundary edge.
      IJ : constant Point3 := Sub (A => Work (J), B => Work (I));
      IOpp : constant Point3 := Sub (A => Work (Opp), B => Work (I));
      IP : constant Point3 := Sub (A => Work (P), B => Work (I));
      C1 : constant Point3 := Cross (U => IJ, V => IOpp);
      C2 : constant Point3 := Cross (U => IJ, V => IP);
      D : constant Real := Dot (C1, C2);
      Plane_N : constant Point3 := Normal_Of_Triangle
        (Work (I), Work (J), Work (Opp));
      Height : constant Real := abs (Dot (Plane_N, IP));
      Edge_Len : constant Real := Length (IJ);
      Coplanar_Tol : constant Real := 0.15 * (Edge_Len + Epsilon);
   begin
      if D < -Area_Tol then
         return True;
      end if;
      return Height > Coplanar_Tol;
   end Is_Exterior_Side;

   function Same_Face (T : Triangle; I, J, P : Point_Index) return Boolean is
      --  True iff T's vertices are exactly the set {I,J,P}.
   begin
      return
        (T.A = I or else T.A = J or else T.A = P)
        and then (T.B = I or else T.B = J or else T.B = P)
        and then (T.C = I or else T.C = J or else T.C = P)
        and then T.A /= T.B and then T.B /= T.C and then T.A /= T.C;
   end Same_Face;

   function Face_Exists
     (M : Mesh; I, J, P : Point_Index) return Boolean
   is
   begin
      for K in 1 .. M.Count loop
         if Same_Face (M.Tris (K), I, J, P) then
            return True;
         end if;
      end loop;
      return False;
   end Face_Exists;

   function Candidate_OK
     (Work : Point_Array;
      M    : Mesh;
      I, J : Point_Index;
      P    : Point_Index) return Boolean
   is
      Area : Real;
      Key_IP, Key_JP : Edge_Key;
      Opp : Point_Index;
      Has_Opp : Boolean;
   begin
      if P = I or else P = J then
         return False;
      end if;
      if Face_Exists (M, I, J, P) then
         return False;
      end if;
      Opp := Third_Vertex (M, I, J, Has_Opp);
      if Has_Opp and then not Is_Exterior_Side (Work, I, J, Opp, P) then
         return False;
      end if;
      Area := Triangle_Area (Work (I), Work (J), Work (P));
      if Area <= Area_Tol then
         return False;
      end if;
      Key_IP := Make_Edge_Key (I, P);
      Key_JP := Make_Edge_Key (J, P);
      if Edge_Incident_Count (M, Key_IP) >= 2 then
         return False;
      end if;
      if Edge_Incident_Count (M, Key_JP) >= 2 then
         return False;
      end if;
      if Edge_Incident_Count (M, Make_Edge_Key (I, J)) >= 2 then
         return False;
      end if;
      return True;
   end Candidate_OK;

   function Score_Candidate
     (Work : Point_Array;
      I, J, P : Point_Index) return Real
   is
      Mid : constant Point3 :=
        (X => 0.5 * (Work (I).X + Work (J).X),
         Y => 0.5 * (Work (I).Y + Work (J).Y),
         Z => 0.5 * (Work (I).Z + Work (J).Z));
      Base : constant Real := Dist3 (Work (I), Work (J));
      D_Mid : constant Real := Dist3 (Work (P), Mid);
      Area : constant Real := Triangle_Area (Work (I), Work (J), Work (P));
      Peri : constant Real :=
        Dist3 (Work (I), Work (J))
        + Dist3 (Work (J), Work (P))
        + Dist3 (Work (P), Work (I));
      Sliver : Real;
   begin
      if Area <= Area_Tol then
         return Real'Last;
      end if;
      Sliver := Peri * Peri / (Area + Area_Tol);
      return D_Mid + 0.05 * Sliver
        + 0.1 * abs (Dist3 (Work (P), Work (I))
                     + Dist3 (Work (P), Work (J))
                     - 2.0 * Base);
   end Score_Candidate;

   function Reconstruct_Mesh (Cloud : Point_Array) return Mesh is
      Raw_N : constant Natural := Cloud'Length;
      N : Point_Count;
      Work : Point_Array (1 .. Max_Points);
      NN : Point_Count;
      M : Mesh;
      Frontier : Boundary_Edge_Set;
      Seed : Triangle;
      Used : array (Point_Index) of Boolean := [others => False];
      Progress : Boolean;
      Best_P : Point_Index;
      Best_Score : Real;
      Found_Cand : Boolean;
      Mid : Point3;
      Radius, D2, Score : Real;
      Edge : Edge_Key;
      I, J : Point_Index;
      E_Idx : Edge_Index;
   begin
      if Raw_N < 3 or else Raw_N > Max_Points then
         raise Invalid_Argument;
      end if;
      N := Point_Count (Raw_N);
      if Has_Near_Duplicate (Cloud) then
         raise Invalid_Argument;
      end if;

      Copy_Cloud (Cloud, Work, NN);
      pragma Assert (NN = N);

      Seed := Find_Seed_Triangle (Cloud);
      Append_Triangle (M, Seed, Frontier);
      Used (Seed.A) := True;
      Used (Seed.B) := True;
      Used (Seed.C) := True;

      loop
         Progress := False;
         E_Idx := 1;
         while E_Idx <= Frontier.Count loop
            Edge := Frontier.Edges (E_Idx);
            I := Edge.Lo;
            J := Edge.Hi;
            Mid :=
              (X => 0.5 * (Work (I).X + Work (J).X),
               Y => 0.5 * (Work (I).Y + Work (J).Y),
               Z => 0.5 * (Work (I).Z + Work (J).Z));
            Radius := Candidate_Radius_Factor * Dist3 (Work (I), Work (J));
            if Radius < Epsilon then
               Radius := Epsilon;
            end if;

            Found_Cand := False;
            Best_Score := Real'Last;
            Best_P := 1;

            --  Pass 1: unused points (grow into free cloud).
            for P in 1 .. N loop
               if not Used (P) then
                  D2 := Dist3_Squared (Work (P), Mid);
                  if D2 <= Radius * Radius
                    and then Candidate_OK (Work, M, I, J, P)
                  then
                     Score := Score_Candidate (Work, I, J, P);
                     if (not Found_Cand) or else Score < Best_Score then
                        Best_Score := Score;
                        Best_P := P;
                        Found_Cand := True;
                     end if;
                  end if;
               end if;
            end loop;

            --  Pass 2: already-used vertices that close along the frontier.
            if not Found_Cand then
               for P in 1 .. N loop
                  if Used (P) and then P /= I and then P /= J then
                     D2 := Dist3_Squared (Work (P), Mid);
                     if D2 <= Radius * Radius
                       and then Candidate_OK (Work, M, I, J, P)
                     then
                        if Contains_Edge (Frontier, Make_Edge_Key (I, P))
                          or else Contains_Edge
                                    (Frontier, Make_Edge_Key (J, P))
                        then
                           Score := Score_Candidate (Work, I, J, P);
                           if (not Found_Cand) or else Score < Best_Score
                           then
                              Best_Score := Score;
                              Best_P := P;
                              Found_Cand := True;
                           end if;
                        end if;
                     end if;
                  end if;
               end loop;
            end if;

            if Found_Cand then
               Append_Triangle
                 (M, (A => I, B => J, C => Best_P), Frontier);
               Used (Best_P) := True;
               Progress := True;
               exit;
            else
               E_Idx := E_Idx + 1;
            end if;
         end loop;

         exit when not Progress;
         exit when M.Count = Max_Triangles;
      end loop;

      return M;
   end Reconstruct_Mesh;

end Marching_Triangles;

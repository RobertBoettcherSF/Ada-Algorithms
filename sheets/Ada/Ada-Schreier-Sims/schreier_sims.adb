--  Schreier_Sims body — deterministic educational Schreier–Sims:
--  orbit + Schreier tree → Schreier lemma → stabilizer generators → chain.

pragma Ada_2022;

package body Schreier_Sims is

   ------------------------------------------------------------------
   --  Validation helpers
   ------------------------------------------------------------------

   function Is_Bijective (Img : Image_Array; N : Positive) return Boolean is
      Seen : array (Point) of Boolean := [others => False];
      Y    : Point;
   begin
      if N > Max_N then
         return False;
      end if;
      for X in 1 .. N loop
         Y := Img (X);
         if Y > N then
            return False;
         end if;
         if Seen (Y) then
            return False;
         end if;
         Seen (Y) := True;
      end loop;
      return True;
   end Is_Bijective;

   procedure Ensure_Degree (N : Natural) is
   begin
      if N < 1 or else N > Max_N then
         raise Invalid_Argument;
      end if;
   end Ensure_Degree;

   procedure Ensure_Same_Degree (A, B : Permutation) is
   begin
      if A.N = 0 or else B.N = 0 or else A.N /= B.N then
         raise Invalid_Argument;
      end if;
   end Ensure_Same_Degree;

   ------------------------------------------------------------------
   --  Basic permutation operations
   ------------------------------------------------------------------

   function Identity (N : Positive) return Permutation is
      P : Permutation;
   begin
      Ensure_Degree (N);
      P.N := N;
      for I in 1 .. N loop
         P.Image (I) := I;
      end loop;
      return P;
   end Identity;

   function Make_Permutation
     (Img : Image_Array; N : Positive) return Permutation
   is
      P : Permutation;
   begin
      Ensure_Degree (N);
      if not Is_Bijective (Img, N) then
         raise Invalid_Argument;
      end if;
      P.N := N;
      for I in 1 .. N loop
         P.Image (I) := Img (I);
      end loop;
      return P;
   end Make_Permutation;

   function Apply (G : Permutation; X : Point) return Point is
   begin
      if G.N = 0 or else Natural (X) > G.N then
         raise Invalid_Argument;
      end if;
      return G.Image (X);
   end Apply;

   function Compose (A, B : Permutation) return Permutation is
      R : Permutation;
   begin
      Ensure_Same_Degree (A, B);
      R.N := A.N;
      for X in 1 .. A.N loop
         R.Image (X) := B.Image (A.Image (X));
      end loop;
      return R;
   end Compose;

   function Inverse (G : Permutation) return Permutation is
      R : Permutation;
   begin
      Ensure_Degree (G.N);
      R.N := G.N;
      for X in 1 .. G.N loop
         R.Image (G.Image (X)) := X;
      end loop;
      return R;
   end Inverse;

   function Is_Identity (G : Permutation) return Boolean is
   begin
      if G.N = 0 then
         return True;
      end if;
      for X in 1 .. G.N loop
         if G.Image (X) /= X then
            return False;
         end if;
      end loop;
      return True;
   end Is_Identity;

   function Equal (A, B : Permutation) return Boolean is
   begin
      if A.N /= B.N then
         return False;
      end if;
      for X in 1 .. A.N loop
         if A.Image (X) /= B.Image (X) then
            return False;
         end if;
      end loop;
      return True;
   end Equal;

   ------------------------------------------------------------------
   --  Orbit / Schreier tree under a generating set
   ------------------------------------------------------------------

   procedure Compute_Orbit
     (Beta      : Point;
      Gens      : Generator_List;
      Gen_Count : Natural;
      N         : Positive;
      L         : in out Level)
   is
      Queue      : array (1 .. Max_N) of Point;
      Head, Tail : Natural := 0;
      P, Q       : Point;
      Id         : constant Permutation := Identity (N);
   begin
      L.Beta := Beta;
      L.Orbit_Size := 0;
      L.In_Orbit := [others => False];
      for I in Point loop
         L.U (I) := Id;
      end loop;

      Head := 1;
      Tail := 1;
      Queue (1) := Beta;
      L.In_Orbit (Beta) := True;
      L.U (Beta) := Id;
      L.Orbit_Size := 1;

      while Head <= Tail loop
         P := Queue (Head);
         Head := Head + 1;
         for G in 1 .. Gen_Count loop
            Q := Gens (G).Image (P);
            if not L.In_Orbit (Q) then
               L.In_Orbit (Q) := True;
               L.Orbit_Size := L.Orbit_Size + 1;
               --  Beta --U(P)--> P --Gens(G)--> Q
               L.U (Q) := Compose (L.U (P), Gens (G));
               Tail := Tail + 1;
               Queue (Tail) := Q;
            end if;
         end loop;
      end loop;
   end Compute_Orbit;

   function Already_Have
     (Buf   : Generator_List;
      Count : Natural;
      H     : Permutation) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Equal (Buf (I), H) then
            return True;
         end if;
      end loop;
      return False;
   end Already_Have;

   --  Schreier lemma: generators for the stabilizer of Beta.
   procedure Schreier_Generators
     (L          : Level;
      Gens       : Generator_List;
      Gen_Count  : Natural;
      N          : Positive;
      Stab       : out Generator_List;
      Stab_Count : out Natural)
   is
      Q   : Point;
      Sch : Permutation;
   begin
      Stab_Count := 0;
      for P in 1 .. N loop
         if L.In_Orbit (P) then
            for G in 1 .. Gen_Count loop
               Q := Gens (G).Image (P);
               --  sch = U(P) * s * U(Q)^{-1}; fixes Beta.
               Sch :=
                 Compose (Compose (L.U (P), Gens (G)), Inverse (L.U (Q)));
               if not Is_Identity (Sch)
                 and then not Already_Have (Stab, Stab_Count, Sch)
               then
                  if Stab_Count >= Stab'Length then
                     raise Invalid_Argument;
                  end if;
                  Stab_Count := Stab_Count + 1;
                  Stab (Stab_Count) := Sch;
               end if;
            end loop;
         end if;
      end loop;
   end Schreier_Generators;

   function First_Moved
     (Gens : Generator_List; Gen_Count : Natural; N : Positive) return Natural
   is
   begin
      for X in 1 .. N loop
         for G in 1 .. Gen_Count loop
            if Gens (G).Image (X) /= X then
               return X;
            end if;
         end loop;
      end loop;
      return 0;
   end First_Moved;

   --  Copy non-identity unique perms into Dest; return count (capped).
   function Copy_Gens
     (Src       : Generator_List;
      Src_Count : Natural;
      Dest      : out Generator_List) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Src_Count loop
         if not Is_Identity (Src (I))
           and then not Already_Have (Dest, Count, Src (I))
         then
            if Count >= Dest'Length then
               exit;
            end if;
            Count := Count + 1;
            Dest (Count) := Src (I);
         end if;
      end loop;
      return Count;
   end Copy_Gens;

   ------------------------------------------------------------------
   --  Build BSGS
   ------------------------------------------------------------------

   function Build_BSGS (Generators : Generator_List) return BSGS is
      Result      : BSGS;
      N           : Natural := 0;
      Cur         : Generator_List (1 .. Max_Schreier);
      Cur_Count   : Natural := 0;
      Stab        : Generator_List (1 .. Max_Schreier);
      Stab_Count  : Natural;
      Beta        : Natural;
      Seen_Non_Id : Boolean := False;
      Work        : Generator_List (1 .. Max_Schreier);
      Work_Count  : Natural;
   begin
      if Generators'Length = 0 then
         raise Invalid_Argument;
      end if;

      for I in Generators'Range loop
         Ensure_Degree (Generators (I).N);
         if not Is_Bijective (Generators (I).Image, Generators (I).N) then
            raise Invalid_Argument;
         end if;
         if N = 0 then
            N := Generators (I).N;
         elsif Generators (I).N /= N then
            raise Invalid_Argument;
         end if;
         if not Is_Identity (Generators (I)) then
            Seen_Non_Id := True;
         end if;
      end loop;

      Result.N := N;
      Result.Length := 0;

      for I in Generators'Range loop
         if not Already_Have (Cur, Cur_Count, Generators (I)) then
            Cur_Count := Cur_Count + 1;
            if Cur_Count > Cur'Length then
               raise Invalid_Argument;
            end if;
            Cur (Cur_Count) := Generators (I);
         end if;
      end loop;

      if not Seen_Non_Id then
         return Result;
      end if;

      while Cur_Count > 0 loop
         --  Drop identities for the working generating set.
         Work_Count := Copy_Gens (Cur, Cur_Count, Work);
         exit when Work_Count = 0;

         Beta := First_Moved (Work, Work_Count, N);
         exit when Beta = 0;

         Result.Length := Result.Length + 1;
         if Result.Length > Max_N then
            raise Invalid_Argument;
         end if;

         declare
            L : Level renames Result.Levels (Result.Length);
         begin
            --  Persist strong generators (educational observers).
            L.Gen_Count := 0;
            for I in 1 .. Work_Count loop
               if L.Gen_Count < Max_Generators then
                  L.Gen_Count := L.Gen_Count + 1;
                  L.Gens (L.Gen_Count) := Work (I);
               end if;
            end loop;

            --  Orbit / tree under the FULL working set (not the capped copy).
            Compute_Orbit
              (Beta      => Point (Beta),
               Gens      => Work,
               Gen_Count => Work_Count,
               N         => N,
               L         => L);

            Schreier_Generators
              (L          => L,
               Gens       => Work,
               Gen_Count  => Work_Count,
               N          => N,
               Stab       => Stab,
               Stab_Count => Stab_Count);

            Cur_Count := 0;
            for I in 1 .. Stab_Count loop
               Cur_Count := Cur_Count + 1;
               Cur (Cur_Count) := Stab (I);
            end loop;
         end;
      end loop;

      return Result;
   end Build_BSGS;

   ------------------------------------------------------------------
   --  Order and membership
   ------------------------------------------------------------------

   function Order (G : BSGS) return Long_Long_Integer is
      O : Long_Long_Integer := 1;
   begin
      if G.N = 0 or else G.Length = 0 then
         return 1;
      end if;
      for I in 1 .. G.Length loop
         O := O * Long_Long_Integer (G.Levels (I).Orbit_Size);
      end loop;
      return O;
   end Order;

   function Contains (G : BSGS; Perm : Permutation) return Boolean is
      Remnant : Permutation;
      Gamma   : Point;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      if Perm.N /= G.N then
         raise Invalid_Argument;
      end if;
      if not Is_Bijective (Perm.Image, Perm.N) then
         raise Invalid_Argument;
      end if;

      if G.Length = 0 then
         return Is_Identity (Perm);
      end if;

      Remnant := Perm;
      for I in 1 .. G.Length loop
         declare
            L : Level renames G.Levels (I);
         begin
            Gamma := Remnant.Image (L.Beta);
            if not L.In_Orbit (Gamma) then
               return False;
            end if;
            Remnant := Compose (Remnant, Inverse (L.U (Gamma)));
         end;
      end loop;
      return Is_Identity (Remnant);
   end Contains;

   function Base_Length (G : BSGS) return Natural is
   begin
      return G.Length;
   end Base_Length;

   function Base_Point (G : BSGS; I : Positive) return Point is
   begin
      if I > G.Length then
         raise Invalid_Argument;
      end if;
      return G.Levels (I).Beta;
   end Base_Point;

end Schreier_Sims;

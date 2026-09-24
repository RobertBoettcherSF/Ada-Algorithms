--  Bron–Kerbosch body — maximal-clique enumeration with Tomita pivoting.

pragma Ada_2022;

with Interfaces; use Interfaces;

package body Bron_Kerbosch
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Bit helpers (vertex V ↔ bit V-1)
   -------------------------------------------------------------------------

   function Bit_Of (V : Vertex_Id) return Bit_Word is
     (Shift_Left (Bit_Word'(1), Natural (V) - 1));

   function Is_Set (W : Bit_Word; V : Vertex_Id) return Boolean is
     ((W and Bit_Of (V)) /= 0);

   function Pop_Count (W : Bit_Word) return Natural is
      X     : Bit_Word := W;
      Count : Natural := 0;
   begin
      while X /= 0 loop
         Count := Count + 1;
         X := X and (X - 1);
      end loop;
      return Count;
   end Pop_Count;

   function All_Bits (N : Natural) return Bit_Word is
   begin
      if N = 0 then
         return 0;
      elsif N = 64 then
         return Bit_Word'Last;
      else
         return Shift_Left (Bit_Word'(1), N) - 1;
      end if;
   end All_Bits;

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
         G.Adj (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         return;
      end if;
      if Is_Set (G.Adj (U), V) then
         return;
      end if;
      G.Adj (U) := G.Adj (U) or Bit_Of (V);
      G.Adj (V) := G.Adj (V) or Bit_Of (U);
      G.E := G.E + 1;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return G.E;
   end Edge_Count;

   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         return False;
      end if;
      return Is_Set (G.Adj (U), V);
   end Is_Adjacent;

   -------------------------------------------------------------------------
   -- Vertex_Set helpers
   -------------------------------------------------------------------------

   function Set_Size (S : Vertex_Set; N : Natural) return Natural is
      Count : Natural := 0;
   begin
      if N > Max_Vertices then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         if S (Vertex_Id (I)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Set_Size;

   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean is
      N : constant Natural := G.N;
   begin
      for I in 1 .. N loop
         if S (Vertex_Id (I)) then
            for J in I + 1 .. N loop
               if S (Vertex_Id (J)) then
                  if not Is_Set (G.Adj (Vertex_Id (I)), Vertex_Id (J)) then
                     return False;
                  end if;
               end if;
            end loop;
         end if;
      end loop;
      return True;
   end Is_Clique;

   function Is_Maximal_Clique (G : Graph; S : Vertex_Set) return Boolean is
      N     : constant Natural := G.N;
      Mask  : Bit_Word := 0;
      Size  : Natural := 0;
      Common : Bit_Word;
      V     : Vertex_Id;
   begin
      for I in 1 .. N loop
         V := Vertex_Id (I);
         if S (V) then
            Mask := Mask or Bit_Of (V);
            Size := Size + 1;
         end if;
      end loop;

      if Size = 0 then
         return False;
      end if;

      if not Is_Clique (G, S) then
         return False;
      end if;

      --  Common neighbours of all members of S that are outside S.
      Common := All_Bits (N) and not Mask;
      for I in 1 .. N loop
         V := Vertex_Id (I);
         if Is_Set (Mask, V) then
            Common := Common and G.Adj (V);
         end if;
      end loop;

      return Common = 0;
   end Is_Maximal_Clique;

   -------------------------------------------------------------------------
   -- Bron–Kerbosch with Tomita pivoting
   -------------------------------------------------------------------------

   procedure Enumerate_Maximal_Cliques
     (G       : Graph;
      Cliques : out Clique_List;
      Count   : out Natural)
   is
      N : constant Natural := G.N;

      R_Mask : Bit_Word := 0;
      Found  : Natural := 0;

      procedure Report_Clique is
         V : Vertex_Id;
      begin
         if Found >= Max_Cliques then
            raise Too_Many_Cliques;
         end if;
         Found := Found + 1;
         Cliques.Items (Found) := [others => False];
         for I in 1 .. N loop
            V := Vertex_Id (I);
            if Is_Set (R_Mask, V) then
               Cliques.Items (Found) (V) := True;
            end if;
         end loop;
      end Report_Clique;

      --  Choose pivot u in P ∪ X maximizing |P ∩ N(u)| (Tomita heuristic).
      function Choose_Pivot (P, X : Bit_Word) return Vertex_Id is
         Best_U    : Vertex_Id := Vertex_Id'First;
         Best_Cov  : Integer := -1;
         Cov       : Natural;
         U         : Vertex_Id;
         Candidates : constant Bit_Word := P or X;
      begin
         for I in 1 .. N loop
            U := Vertex_Id (I);
            if Is_Set (Candidates, U) then
               Cov := Pop_Count (P and G.Adj (U));
               if Integer (Cov) > Best_Cov then
                  Best_Cov := Integer (Cov);
                  Best_U := U;
               end if;
            end if;
         end loop;
         return Best_U;
      end Choose_Pivot;

      procedure BK (P, X : Bit_Word) is
         P_Work : Bit_Word := P;
         X_Work : Bit_Word := X;
         U      : Vertex_Id;
         Candidates : Bit_Word;
         V      : Vertex_Id;
         Nu     : Bit_Word;
      begin
         if P_Work = 0 and then X_Work = 0 then
            Report_Clique;
            return;
         end if;

         if P_Work = 0 then
            --  X nonempty ⇒ no maximal clique in this branch
            return;
         end if;

         U := Choose_Pivot (P_Work, X_Work);
         --  Only try vertices in P \ N(u)
         Candidates := P_Work and not G.Adj (U);

         for I in 1 .. N loop
            V := Vertex_Id (I);
            if Is_Set (Candidates, V) and then Is_Set (P_Work, V) then
               Nu := G.Adj (V);
               R_Mask := R_Mask or Bit_Of (V);
               BK (P_Work and Nu, X_Work and Nu);
               R_Mask := R_Mask and not Bit_Of (V);
               P_Work := P_Work and not Bit_Of (V);
               X_Work := X_Work or Bit_Of (V);
            end if;
         end loop;
      end BK;

   begin
      Cliques := (Items => [others => [others => False]]);
      Count := 0;
      Found := 0;

      if N = 0 then
         return;
      end if;

      BK (All_Bits (N), 0);
      Count := Found;
   end Enumerate_Maximal_Cliques;

   function Maximal_Clique_Count (G : Graph) return Natural is
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      return Count;
   end Maximal_Clique_Count;

end Bron_Kerbosch;

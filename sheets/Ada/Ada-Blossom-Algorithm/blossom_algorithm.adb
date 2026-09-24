--  Blossom_Algorithm body — Edmonds alternating forest + blossom
--  contraction; optional subset-DP / bitset matching oracle.

pragma Ada_2022;

package body Blossom_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Graph mutators / inspectors
   ---------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.M := 0;
      G.A := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Append_Arc (G : in out Graph; From, To : Vertex_Id) is
   begin
      G.A := G.A + 1;
      G.To (G.A) := To;
      G.Next (G.A) := G.Head (From);
      G.Head (From) := G.A;
   end Append_Arc;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      G.EU (G.M) := U;
      G.EV (G.M) := V;
      Append_Arc (G, U, V);
      Append_Arc (G, V, U);
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.M);
   end Edge_Count;

   procedure Validate_Edge_Index (G : Graph; Index : Positive) is
   begin
      if Index > G.M then
         raise Invalid_Argument;
      end if;
   end Validate_Edge_Index;

   function Edge_U (G : Graph; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.EU (Index);
   end Edge_U;

   function Edge_V (G : Graph; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.EV (Index);
   end Edge_V;

   ---------------------------------------------------------------------------
   -- Edge existence (for Is_Valid_Matching)
   ---------------------------------------------------------------------------

   function Has_Edge
     (G : Graph; U, V : Vertex_Id) return Boolean
   is
      E : Natural := G.Head (U);
   begin
      while E /= 0 loop
         if G.To (E) = V then
            return True;
         end if;
         E := G.Next (E);
      end loop;
      return False;
   end Has_Edge;

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean
   is
      Count : Natural := 0;
      W     : Natural;
   begin
      if Result.N /= G.N then
         return False;
      end if;
      if G.N = 0 then
         return Result.Size = 0;
      end if;

      for V in 1 .. G.N loop
         W := Result.Mate (V);
         if W = 0 then
            null;
         elsif W > G.N then
            return False;
         elsif Result.Mate (W) /= V then
            return False;
         elsif not Has_Edge (G, Vertex_Id (V), Vertex_Id (W)) then
            return False;
         elsif V < W then
            Count := Count + 1;
         end if;
      end loop;

      return Count = Result.Size;
   end Is_Valid_Matching;

   ---------------------------------------------------------------------------
   -- Edmonds blossom: alternating forest + contraction of odd cycles
   ---------------------------------------------------------------------------

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result) is
      N : constant Natural := G.N;

      type NV_Array is array (0 .. Max_Vertices) of Natural;
      type NB_Array is array (0 .. Max_Vertices) of Boolean;
      type Q_Array is array (0 .. Max_Vertices) of Natural;

      Mate   : NV_Array := [others => 0];
      Father : NV_Array := [others => 0];
      Base   : NV_Array := [others => 0];
      Inq    : NB_Array := [others => False];
      Inb    : NB_Array := [others => False];
      Q      : Q_Array := [others => 0];
      Q_Len  : Natural := 0;
      Matching : Natural := 0;
      T      : Natural;

      function LCA (Root, U0, V0 : Natural) return Natural is
         Vis : NB_Array := [others => False];
         U   : Natural := U0;
         V   : Natural := V0;
      begin
         loop
            U := Base (U);
            Vis (U) := True;
            exit when U = Root;
            exit when Mate (U) = 0;
            U := Father (Mate (U));
            exit when U = 0;
         end loop;
         loop
            V := Base (V);
            if Vis (V) then
               return V;
            end if;
            if Mate (V) = 0 then
               return V;
            end if;
            V := Father (Mate (V));
            if V = 0 then
               return Root;
            end if;
         end loop;
      end LCA;

      procedure Mark_Blossom (A, U0 : Natural) is
         U : Natural := U0;
         V : Natural;
      begin
         while Base (U) /= A loop
            V := Mate (U);
            Inb (Base (U)) := True;
            Inb (Base (V)) := True;
            U := Father (V);
            if Base (U) /= A then
               Father (U) := V;
            end if;
         end loop;
      end Mark_Blossom;

      procedure Blossom_Contraction (S, UU, VV : Natural) is
         A : constant Natural := LCA (S, UU, VV);
      begin
         Inb := [others => False];
         Mark_Blossom (A, UU);
         Mark_Blossom (A, VV);
         if Base (UU) /= A then
            Father (UU) := VV;
         end if;
         if Base (VV) /= A then
            Father (VV) := UU;
         end if;
         for X in 1 .. N loop
            if Inb (Base (X)) then
               Base (X) := A;
               if not Inq (X) then
                  Inq (X) := True;
                  Q (Q_Len) := X;
                  Q_Len := Q_Len + 1;
               end if;
            end if;
         end loop;
      end Blossom_Contraction;

      function Find_Augmenting_Path (S : Natural) return Natural is
         Qh : Natural := 0;
         U  : Natural;
         V  : Natural;
         W  : Natural;
         E  : Natural;
      begin
         Inq := [others => False];
         Father := [others => 0];
         for I in 0 .. Max_Vertices loop
            Base (I) := I;
         end loop;
         Q_Len := 1;
         Q (0) := S;
         Inq (S) := True;
         while Qh < Q_Len loop
            U := Q (Qh);
            Qh := Qh + 1;
            E := G.Head (Vertex_Id (U));
            while E /= 0 loop
               V := Natural (G.To (E));
               if Base (U) /= Base (V) and then Mate (U) /= V then
                  if V = S
                    or else
                      (Mate (V) /= 0 and then Father (Mate (V)) /= 0)
                  then
                     Blossom_Contraction (S, U, V);
                  elsif Father (V) = 0 then
                     Father (V) := U;
                     if Mate (V) = 0 then
                        return V;
                     end if;
                     W := Mate (V);
                     if not Inq (W) then
                        Inq (W) := True;
                        Q (Q_Len) := W;
                        Q_Len := Q_Len + 1;
                     end if;
                  end if;
               end if;
               E := G.Next (E);
            end loop;
         end loop;
         return 0;
      end Find_Augmenting_Path;

      procedure Augment_Path (TV : Natural) is
         U : Natural := TV;
         V : Natural;
         W : Natural;
      begin
         while U /= 0 loop
            V := Father (U);
            W := Mate (V);
            Mate (V) := U;
            Mate (U) := V;
            U := W;
         end loop;
      end Augment_Path;

   begin
      Result.Size := 0;
      Result.N := N;
      Result.Mate := [others => 0];

      if N = 0 then
         return;
      end if;

      for U in 1 .. N loop
         if Mate (U) = 0 then
            T := Find_Augmenting_Path (U);
            if T /= 0 then
               Augment_Path (T);
               Matching := Matching + 1;
            end if;
         end if;
      end loop;

      Result.Size := Matching;
      for U in 1 .. N loop
         Result.Mate (U) := Mate (U);
      end loop;
   end Maximum_Matching;

   ---------------------------------------------------------------------------
   -- Matching_Oracle_Brute (subset DP / bitset)
   ---------------------------------------------------------------------------

   procedure Matching_Oracle_Brute
     (G : Graph; Result : out Matching_Result)
   is
      type Bits is mod 2 ** Max_Oracle;
      type DP_Store is array (Bits) of Natural;
      type Adj_Store is array (1 .. Max_Oracle) of Bits;

      N      : constant Natural := G.N;
      Adj    : Adj_Store := [others => 0];
      DP     : DP_Store := [others => 0];
      Choice : DP_Store := [others => 0];
      Full   : Bits;
      E      : Natural;
      W      : Natural;
      Mask   : Bits;
      Rest   : Bits;
      Neigh  : Bits;
      Bbit   : Bits;
      Cbit   : Bits;
      B, C   : Natural;
      Best   : Natural;
      Ch     : Natural;
      Cand   : Natural;

      function Bit_Of (V : Natural) return Bits is
      begin
         return Bits (2 ** (V - 1));
      end Bit_Of;

      function Lowest_Vertex (M0 : Bits) return Natural is
         M : Bits := M0;
         V : Natural := 1;
      begin
         while (M and 1) = 0 loop
            M := M / 2;
            V := V + 1;
         end loop;
         return V;
      end Lowest_Vertex;

   begin
      if N > Max_Oracle then
         raise Invalid_Argument;
      end if;

      Result.Size := 0;
      Result.N := N;
      Result.Mate := [others => 0];

      if N = 0 then
         return;
      end if;

      for U in 1 .. N loop
         E := G.Head (Vertex_Id (U));
         while E /= 0 loop
            W := Natural (G.To (E));
            Adj (U) := Adj (U) or Bit_Of (W);
            E := G.Next (E);
         end loop;
      end loop;

      Full := Bits (2 ** N - 1);
      for I in 1 .. (2 ** N) - 1 loop
         Mask := Bits (I);
         B := Lowest_Vertex (Mask);
         Bbit := Bit_Of (B);
         Rest := Mask and not Bbit;
         Best := DP (Rest);
         Ch := 0;
         Neigh := Adj (B) and Rest;
         while Neigh /= 0 loop
            C := Lowest_Vertex (Neigh);
            Cbit := Bit_Of (C);
            Cand := 1 + DP (Rest and not Cbit);
            if Cand > Best then
               Best := Cand;
               Ch := C;
            end if;
            Neigh := Neigh and not Cbit;
         end loop;
         DP (Mask) := Best;
         Choice (Mask) := Ch;
      end loop;

      Result.Size := DP (Full);
      Mask := Full;
      while Mask /= 0 loop
         B := Lowest_Vertex (Mask);
         Bbit := Bit_Of (B);
         Ch := Choice (Mask);
         if Ch = 0 then
            Mask := Mask and not Bbit;
         else
            Result.Mate (B) := Ch;
            Result.Mate (Ch) := B;
            Mask := Mask and not Bbit and not Bit_Of (Ch);
         end if;
      end loop;
   end Matching_Oracle_Brute;

end Blossom_Algorithm;

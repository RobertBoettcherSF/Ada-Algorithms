--  MaxCliqueDyn body — colouring-bound branch-and-bound maximum clique.

pragma Ada_2022;

with Interfaces; use Interfaces;

package body MaxCliqueDyn
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

   -------------------------------------------------------------------------
   -- Colouring-bound branch-and-bound
   -------------------------------------------------------------------------

   procedure Find_Maximum_Clique
     (G      : Graph;
      Clique : out Vertex_Set;
      Size   : out Natural)
   is
      N : constant Natural := G.N;

      Qmax_Mask : Bit_Word := 0;
      Qmax_Size : Natural := 0;

      Q_Mask : Bit_Word := 0;
      Q_Size : Natural := 0;

      procedure Fill_Clique_From_Mask is
         V : Vertex_Id;
      begin
         Clique := [others => False];
         for I in 1 .. N loop
            V := Vertex_Id (I);
            if Is_Set (Qmax_Mask, V) then
               Clique (V) := True;
            end if;
         end loop;
      end Fill_Clique_From_Mask;

      procedure Record_Incumbent is
      begin
         Qmax_Mask := Q_Mask;
         Qmax_Size := Q_Size;
         Fill_Clique_From_Mask;
      end Record_Incumbent;

      --  Each Expand frame owns its Order/Color so recursion cannot clobber
      --  the parent's candidate list.
      procedure Expand (R : Bit_Word) is
         Order : array (1 .. Max_Vertices) of Vertex_Id :=
           [others => Vertex_Id'First];
         Color : array (1 .. Max_Vertices) of Natural := [others => 0];
         Deg   : array (Vertex_Id) of Natural := [others => 0];
         Tmp_V : array (1 .. Max_Vertices) of Vertex_Id :=
           [others => Vertex_Id'First];
         Class : array (0 .. Max_Vertices) of Bit_Word := [others => 0];

         Len   : Natural := 0;
         Count : Natural := 0;
         Kmin  : Natural;
         Max_No : Natural;
         Front : Natural;
         P     : Vertex_Id;
         K     : Natural;
         Rp    : Bit_Word;
         C_P   : Natural;
         W     : Bit_Word;
         V     : Vertex_Id;
         J     : Natural;
      begin
         --  Collect R into Tmp_V and compute induced degrees.
         for I in 1 .. N loop
            P := Vertex_Id (I);
            if Is_Set (R, P) then
               Count := Count + 1;
               Tmp_V (Count) := P;
               Deg (P) := Pop_Count (G.Adj (P) and R);
            end if;
         end loop;

         if Count = 0 then
            return;
         end if;

         --  Sort Tmp_V by nonincreasing induced degree (insertion sort).
         for I in 2 .. Count loop
            declare
               Key_V : constant Vertex_Id := Tmp_V (I);
               Key_D : constant Natural := Deg (Key_V);
               Pos   : Natural := I;
            begin
               while Pos > 1 and then Deg (Tmp_V (Pos - 1)) < Key_D loop
                  Tmp_V (Pos) := Tmp_V (Pos - 1);
                  Pos := Pos - 1;
               end loop;
               Tmp_V (Pos) := Key_V;
            end;
         end loop;

         --  kmin = |Qmax| - |Q| + 1, clamped to ≥ 1 (avoid Natural underflow
         --  when the growing clique already exceeds the incumbent).
         if Qmax_Size + 1 > Q_Size then
            Kmin := Qmax_Size - Q_Size + 1;
         else
            Kmin := 1;
         end if;

         for C in Class'Range loop
            Class (C) := 0;
         end loop;
         Max_No := 0;
         Front := 0;

         --  Greedy colouring in degree order (ColorSort).
         for I in 1 .. Count loop
            P := Tmp_V (I);
            K := 1;
            while K <= Max_No and then (Class (K) and G.Adj (P)) /= 0 loop
               K := K + 1;
            end loop;
            if K > Max_No then
               Max_No := K;
            end if;
            Class (K) := Class (K) or Bit_Of (P);
            if K < Kmin then
               Front := Front + 1;
               Order (Front) := P;
               Color (Front) := 0;
            end if;
         end loop;

         J := Front;
         for Kc in Kmin .. Max_No loop
            W := Class (Kc);
            for I in 1 .. N loop
               V := Vertex_Id (I);
               if Is_Set (W, V) then
                  J := J + 1;
                  Order (J) := V;
                  Color (J) := Kc;
               end if;
            end loop;
         end loop;
         Len := J;

         --  Expand highest colour first.
         while Len > 0 loop
            P := Order (Len);
            C_P := Color (Len);
            Len := Len - 1;

            if C_P = 0 then
               return;
            end if;

            if Q_Size + C_P <= Qmax_Size then
               return;
            end if;

            Q_Mask := Q_Mask or Bit_Of (P);
            Q_Size := Q_Size + 1;

            Rp := 0;
            for I in 1 .. Len loop
               Rp := Rp or Bit_Of (Order (I));
            end loop;
            Rp := Rp and G.Adj (P);

            if Rp = 0 then
               if Q_Size > Qmax_Size then
                  Record_Incumbent;
               end if;
            else
               Expand (Rp);
            end if;

            Q_Mask := Q_Mask and not Bit_Of (P);
            Q_Size := Q_Size - 1;
         end loop;
      end Expand;

   begin
      Clique := [others => False];
      Size := 0;

      if N = 0 then
         return;
      end if;

      --  Singleton lower bound (ω(G) ≥ 1 when N ≥ 1).
      Q_Mask := Bit_Of (1);
      Q_Size := 1;
      Record_Incumbent;
      Q_Mask := 0;
      Q_Size := 0;

      Expand (All_Bits (N));
      Size := Qmax_Size;
   end Find_Maximum_Clique;

   function Maximum_Clique_Size (G : Graph) return Natural is
      Clique : Vertex_Set;
      Size   : Natural;
   begin
      Find_Maximum_Clique (G, Clique, Size);
      return Size;
   end Maximum_Clique_Size;

end MaxCliqueDyn;

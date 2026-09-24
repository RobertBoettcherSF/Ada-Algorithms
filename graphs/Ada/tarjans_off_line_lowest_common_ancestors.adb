--  Tarjans_Off_Line_Lowest_Common_Ancestors body — offline LCA via DFS
--  + Union–Find, plus in-package Naive_LCA (depth-lift walk).

pragma Ada_2022;

package body Tarjans_Off_Line_Lowest_Common_Ancestors
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Tree mutators / queries
   ---------------------------------------------------------------------------

   procedure Clear
     (T            : in out Tree;
      Vertex_Count : Natural;
      Root         : Vertex_Id := 1)
   is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      if Vertex_Count > 0 and then Natural (Root) > Vertex_Count then
         raise Invalid_Argument;
      end if;

      T.N          := Vertex_Count;
      T.R          := (if Vertex_Count = 0 then 1 else Root);
      T.Parent     := [others => 0];
      T.Edge_Count := 0;
      T.Child_Head := [others => 0];
      T.Child_Of   := [others => 1];
      T.Next_Child := [others => 0];
      T.Q          := 0;
      T.Done       := False;
      T.QInc_Head  := [others => 0];
      T.QInc_Count := 0;
      T.QInc_Next  := [others => 0];
      T.Answers    := [others => 1];
   end Clear;

   procedure Set_Parent
     (T : in out Tree; Child, Parent : Vertex_Id)
   is
      C : constant Natural := Natural (Child);
      P : constant Natural := Natural (Parent);
      E : Natural;
   begin
      if T.N = 0 then
         raise Invalid_Argument;
      end if;
      if C > T.N or else P > T.N then
         raise Invalid_Argument;
      end if;
      if Child = T.R then
         raise Invalid_Argument;
      end if;
      if T.Parent (C) /= 0 then
         raise Invalid_Argument;
      end if;
      if Child = Parent then
         raise Invalid_Argument;
      end if;

      T.Parent (C) := P;
      T.Edge_Count := T.Edge_Count + 1;
      E := T.Edge_Count;
      T.Child_Of (E)   := Child;
      T.Next_Child (E) := T.Child_Head (P);
      T.Child_Head (P) := E;
      T.Done := False;
   end Set_Parent;

   procedure Add_Child
     (T : in out Tree; Parent, Child : Vertex_Id)
   is
   begin
      Set_Parent (T, Child, Parent);
   end Add_Child;

   function Vertex_Count (T : Tree) return Natural is (T.N);

   function Root (T : Tree) return Vertex_Id is
   begin
      if T.N = 0 then
         raise Invalid_Argument;
      end if;
      return T.R;
   end Root;

   function Parent_Of (T : Tree; V : Vertex_Id) return Natural is
   begin
      if T.N = 0 or else Natural (V) > T.N then
         raise Invalid_Argument;
      end if;
      return T.Parent (Natural (V));
   end Parent_Of;

   function Query_Count (T : Tree) return Natural is (T.Q);

   function Computed (T : Tree) return Boolean is (T.Done);

   procedure Add_Query (T : in out Tree; U, V : Vertex_Id) is
      procedure Link (Vertex : Natural; QIdx : Positive) is
         Slot : Natural;
      begin
         T.QInc_Count := T.QInc_Count + 1;
         Slot := T.QInc_Count;
         T.QInc_Query (Slot) := QIdx;
         T.QInc_Next (Slot)  := T.QInc_Head (Vertex);
         T.QInc_Head (Vertex) := Slot;
      end Link;
   begin
      if T.N = 0 then
         raise Invalid_Argument;
      end if;
      if Natural (U) > T.N or else Natural (V) > T.N then
         raise Invalid_Argument;
      end if;
      if T.Q >= Max_Queries then
         raise Invalid_Argument;
      end if;

      T.Q := T.Q + 1;
      T.Queries (T.Q) := (U => U, V => V);
      Link (Natural (U), T.Q);
      if U /= V then
         Link (Natural (V), T.Q);
      end if;
      T.Done := False;
   end Add_Query;

   ---------------------------------------------------------------------------
   -- Union-Find (1 .. N); package-body private
   ---------------------------------------------------------------------------

   type UF_Parent_Array is array (0 .. Max_Vertices) of Natural;
   type UF_Rank_Array   is array (0 .. Max_Vertices) of Natural;
   type Ancestor_Array  is array (0 .. Max_Vertices) of Natural;
   type Colour_Array    is array (0 .. Max_Vertices) of Boolean;

   procedure UF_Make_Set
     (Parent    : in out UF_Parent_Array;
      Rank      : in out UF_Rank_Array;
      Ancestor  : in out Ancestor_Array;
      X         : Natural)
   is
   begin
      Parent (X)   := X;
      Rank (X)     := 0;
      Ancestor (X) := X;
   end UF_Make_Set;

   function UF_Find
     (Parent : in out UF_Parent_Array; X : Natural) return Natural
   is
      R    : Natural := X;
      Y    : Natural;
      Next : Natural;
   begin
      while Parent (R) /= R loop
         R := Parent (R);
      end loop;
      Y := X;
      while Parent (Y) /= Y loop
         Next := Parent (Y);
         Parent (Y) := R;
         Y := Next;
      end loop;
      return R;
   end UF_Find;

   procedure UF_Union
     (Parent : in out UF_Parent_Array;
      Rank   : in out UF_Rank_Array;
      A, B   : Natural)
   is
      RA : constant Natural := UF_Find (Parent, A);
      RB : constant Natural := UF_Find (Parent, B);
   begin
      if RA = RB then
         return;
      end if;
      if Rank (RA) < Rank (RB) then
         Parent (RA) := RB;
      elsif Rank (RA) > Rank (RB) then
         Parent (RB) := RA;
      else
         Parent (RB) := RA;
         Rank (RA)   := Rank (RA) + 1;
      end if;
   end UF_Union;

   ---------------------------------------------------------------------------
   -- Validate tree
   ---------------------------------------------------------------------------

   procedure Require_Valid_Tree (T : Tree) is
      Visited : array (0 .. Max_Vertices) of Boolean := [others => False];
      Stack   : array (1 .. Max_Vertices) of Natural;
      Top     : Natural := 0;
      Seen    : Natural := 0;
      U, E, C : Natural;
   begin
      if T.N = 0 then
         return;
      end if;
      if T.Edge_Count /= T.N - 1 then
         raise Invalid_Argument;
      end if;
      if T.Parent (Natural (T.R)) /= 0 then
         raise Invalid_Argument;
      end if;
      for V in 1 .. T.N loop
         if V /= Natural (T.R) and then T.Parent (V) = 0 then
            raise Invalid_Argument;
         end if;
         if V /= Natural (T.R)
           and then (T.Parent (V) < 1 or else T.Parent (V) > T.N)
         then
            raise Invalid_Argument;
         end if;
      end loop;

      Top := 1;
      Stack (1) := Natural (T.R);
      Visited (Natural (T.R)) := True;
      Seen := 1;
      while Top > 0 loop
         U := Stack (Top);
         Top := Top - 1;
         E := T.Child_Head (U);
         while E /= 0 loop
            C := Natural (T.Child_Of (E));
            if not Visited (C) then
               Visited (C) := True;
               Seen := Seen + 1;
               Top := Top + 1;
               Stack (Top) := C;
            end if;
            E := T.Next_Child (E);
         end loop;
      end loop;
      if Seen /= T.N then
         raise Invalid_Argument;
      end if;
   end Require_Valid_Tree;

   ---------------------------------------------------------------------------
   -- Tarjan offline LCA (iterative DFS)
   ---------------------------------------------------------------------------

   type Phase_Kind is (Enter, After_Child, Finish);

   type Frame is record
      U     : Natural := 0;
      Edge  : Natural := 0;
      Phase : Phase_Kind := Enter;
   end record;

   type Frame_Array is array (1 .. Max_Vertices + Max_Vertices) of Frame;

   procedure Compute (T : in out Tree) is
      Parent_UF : UF_Parent_Array := [others => 0];
      Rank_UF   : UF_Rank_Array := [others => 0];
      Ancestor  : Ancestor_Array := [others => 0];
      Black     : Colour_Array := [others => False];
      Stack     : Frame_Array;
      Top       : Natural := 0;
      F         : Frame;
      Child_V   : Natural;
      Slot      : Natural;
      QIdx      : Positive;
      Other     : Natural;
      QU, QV    : Natural;
   begin
      Require_Valid_Tree (T);

      if T.N = 0 then
         T.Done := True;
         return;
      end if;

      for I in 1 .. T.Q loop
         T.Answers (I) := 1;
      end loop;

      Top := 1;
      Stack (1) := (U => Natural (T.R), Edge => 0, Phase => Enter);

      while Top > 0 loop
         F := Stack (Top);
         Top := Top - 1;

         case F.Phase is
            when Enter =>
               UF_Make_Set (Parent_UF, Rank_UF, Ancestor, F.U);
               Top := Top + 1;
               Stack (Top) :=
                 (U => F.U, Edge => T.Child_Head (F.U), Phase => After_Child);

            when After_Child =>
               if F.Edge = 0 then
                  Top := Top + 1;
                  Stack (Top) := (U => F.U, Edge => 0, Phase => Finish);
               else
                  Child_V := Natural (T.Child_Of (F.Edge));
                  if not Black (Child_V) then
                     -- Resume same edge after child finishes (then Union)
                     Top := Top + 1;
                     Stack (Top) :=
                       (U => F.U, Edge => F.Edge, Phase => After_Child);
                     Top := Top + 1;
                     Stack (Top) :=
                       (U => Child_V, Edge => 0, Phase => Enter);
                  else
                     UF_Union (Parent_UF, Rank_UF, F.U, Child_V);
                     Ancestor (UF_Find (Parent_UF, F.U)) := F.U;
                     Top := Top + 1;
                     Stack (Top) :=
                       (U     => F.U,
                        Edge  => T.Next_Child (F.Edge),
                        Phase => After_Child);
                  end if;
               end if;

            when Finish =>
               Black (F.U) := True;
               Slot := T.QInc_Head (F.U);
               while Slot /= 0 loop
                  QIdx := T.QInc_Query (Slot);
                  QU := Natural (T.Queries (QIdx).U);
                  QV := Natural (T.Queries (QIdx).V);
                  if QU = F.U then
                     Other := QV;
                  else
                     Other := QU;
                  end if;
                  if Black (Other) then
                     T.Answers (QIdx) :=
                       Vertex_Id (Ancestor (UF_Find (Parent_UF, Other)));
                  end if;
                  Slot := T.QInc_Next (Slot);
               end loop;
         end case;
      end loop;

      T.Done := True;
   end Compute;

   function Answer (T : Tree; Query_Index : Positive) return Vertex_Id is
   begin
      if not T.Done then
         raise Invalid_Argument;
      end if;
      if Query_Index > T.Q then
         raise Invalid_Argument;
      end if;
      return T.Answers (Query_Index);
   end Answer;

   ---------------------------------------------------------------------------
   -- Naive LCA (depth walk)
   ---------------------------------------------------------------------------

   function Depth_Of (T : Tree; V : Natural) return Natural is
      D     : Natural := 0;
      X     : Natural := V;
      Guard : Natural := 0;
   begin
      while X /= Natural (T.R) loop
         if T.Parent (X) = 0 then
            raise Invalid_Argument;
         end if;
         X := T.Parent (X);
         D := D + 1;
         Guard := Guard + 1;
         if Guard > T.N then
            raise Invalid_Argument;
         end if;
      end loop;
      return D;
   end Depth_Of;

   function Naive_LCA (T : Tree; U, V : Vertex_Id) return Vertex_Id is
      A      : Natural := Natural (U);
      B      : Natural := Natural (V);
      DA, DB : Natural;
      Guard  : Natural := 0;
   begin
      if T.N = 0 then
         raise Invalid_Argument;
      end if;
      if A > T.N or else B > T.N then
         raise Invalid_Argument;
      end if;

      DA := Depth_Of (T, A);
      DB := Depth_Of (T, B);

      while DA > DB loop
         A := T.Parent (A);
         DA := DA - 1;
      end loop;
      while DB > DA loop
         B := T.Parent (B);
         DB := DB - 1;
      end loop;

      while A /= B loop
         if T.Parent (A) = 0 or else T.Parent (B) = 0 then
            raise Invalid_Argument;
         end if;
         A := T.Parent (A);
         B := T.Parent (B);
         Guard := Guard + 1;
         if Guard > T.N then
            raise Invalid_Argument;
         end if;
      end loop;

      return Vertex_Id (A);
   end Naive_LCA;

end Tarjans_Off_Line_Lowest_Common_Ancestors;

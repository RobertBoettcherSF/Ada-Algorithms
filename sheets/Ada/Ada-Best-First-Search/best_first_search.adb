--  Best_First_Search body — greedy best-first with binary-heap open set.

pragma Ada_2022;

package body Best_First_Search
  with SPARK_Mode => Off
is

   type Visited_Array is array (Vertex_Id) of Boolean;
   type Prev_Local is array (Vertex_Id) of Natural;

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
         G.Head (V) := 0;
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
      G.To (G.E) := To;
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
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
   -- Validation
   -------------------------------------------------------------------------

   procedure Validate_Vertex (G : Graph; V : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Path (N : Natural; First, Last : Positive) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if First /= 1 or else Natural (Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Path;

   procedure Validate_H (N : Natural; H : Heuristic_Array) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Natural (H'First) > 1 or else Natural (H'Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_H;

   -------------------------------------------------------------------------
   -- Path reconstruction from Prev
   -------------------------------------------------------------------------

   function Rebuild
     (Prev   : Prev_Local;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Tmp   : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      L     : Natural := 0;
      Cur   : Vertex_Id;
      P     : Natural;
      Guard : Natural := 0;
   begin
      Length := 0;

      if Start = Goal then
         Length := 1;
         Path (1) := Start;
         return True;
      end if;

      if Prev (Goal) = 0 then
         return False;
      end if;

      Cur := Goal;
      loop
         L := L + 1;
         if L > Max_Vertices then
            Length := 0;
            return False;
         end if;
         Tmp (L) := Cur;
         exit when Cur = Start;
         P := Prev (Cur);
         if P = 0 then
            Length := 0;
            return False;
         end if;
         Cur := Vertex_Id (P);
         Guard := Guard + 1;
         if Guard > Max_Vertices then
            Length := 0;
            return False;
         end if;
      end loop;

      Length := L;
      for I in 1 .. L loop
         Path (I) := Tmp (L + 1 - I);
      end loop;
      return True;
   end Rebuild;

   -------------------------------------------------------------------------
   -- Core greedy best-first search
   -------------------------------------------------------------------------

   function Run_Search
     (G           : Graph;
      Start       : Vertex_Id;
      Goal        : Vertex_Id;
      H           : Heuristic_Array;
      Path        : out Path_Array;
      Length      : out Natural;
      Order       : out Order_Array;
      Count       : out Natural;
      Expansions  : out Natural;
      Track_Order : Boolean) return Boolean
   is
      Visited : Visited_Array := [others => False];
      Prev    : Prev_Local := [others => 0];

      --  Binary min-heap open set. Key = (H(V), Seq) for FIFO among ties.
      type Heap_Node is record
         V   : Vertex_Id := Vertex_Id'First;
         Key : Natural := 0;
         Seq : Natural := 0;
      end record;

      Heap     : array (1 .. Max_Vertices) of Heap_Node;
      H_Size   : Natural := 0;
      Next_Seq : Natural := 0;

      procedure Heap_Swap (I, J : Positive) is
         T : Heap_Node;
      begin
         T := Heap (I);
         Heap (I) := Heap (J);
         Heap (J) := T;
      end Heap_Swap;

      function Better (A, B : Heap_Node) return Boolean is
        (A.Key < B.Key or else (A.Key = B.Key and then A.Seq < B.Seq));

      procedure Sift_Up (Idx : Positive) is
         I : Positive := Idx;
         P : Positive;
      begin
         while I > 1 loop
            P := I / 2;
            if Better (Heap (I), Heap (P)) then
               Heap_Swap (I, P);
               I := P;
            else
               exit;
            end if;
         end loop;
      end Sift_Up;

      procedure Sift_Down (Idx : Positive) is
         I : Positive := Idx;
         L, R, Best : Positive;
      begin
         loop
            L := 2 * I;
            R := L + 1;
            exit when L > H_Size;
            Best := L;
            if R <= H_Size and then Better (Heap (R), Heap (L)) then
               Best := R;
            end if;
            if Better (Heap (Best), Heap (I)) then
               Heap_Swap (I, Best);
               I := Best;
            else
               exit;
            end if;
         end loop;
      end Sift_Down;

      procedure Push (V : Vertex_Id) is
      begin
         Next_Seq := Next_Seq + 1;
         H_Size := H_Size + 1;
         Heap (H_Size) := (V => V, Key => H (V), Seq => Next_Seq);
         Sift_Up (H_Size);
      end Push;

      function Pop return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Heap (1).V;
         Heap (1) := Heap (H_Size);
         H_Size := H_Size - 1;
         if H_Size >= 1 then
            Sift_Down (1);
         end if;
         return V;
      end Pop;

      function Heap_Empty return Boolean is (H_Size = 0);

      U, W  : Vertex_Id;
      E_Idx : Natural;
      Ok    : Boolean;
   begin
      Length := 0;
      Count := 0;
      Expansions := 0;

      if Start = Goal then
         Length := 1;
         Path (1) := Start;
         return True;
      end if;

      Visited (Start) := True;
      Prev (Start) := 0;
      Push (Start);

      while not Heap_Empty loop
         U := Pop;
         Expansions := Expansions + 1;

         if Track_Order then
            Count := Count + 1;
            Order (Count) := U;
         end if;

         if U = Goal then
            Ok := Rebuild (Prev, Start, Goal, Path, Length);
            return Ok;
         end if;

         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if not Visited (W) then
               Visited (W) := True;
               Prev (W) := Natural (U);
               if W = Goal then
                  if Track_Order then
                     Count := Count + 1;
                     Order (Count) := W;
                  end if;
                  Ok := Rebuild (Prev, Start, Goal, Path, Length);
                  return Ok;
               end if;
               Push (W);
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      Length := 0;
      return False;
   end Run_Search;

   -------------------------------------------------------------------------
   -- Public Search overloads
   -------------------------------------------------------------------------

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      H      : Heuristic_Array;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Order : Order_Array (1 .. Max_Vertices);
      Count : Natural := 0;
      Exp   : Natural := 0;
      Ok    : Boolean;
   begin
      Validate_Path (G.N, Path'First, Path'Last);
      Validate_H (G.N, H);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      Ok := Run_Search
        (G, Start, Goal, H, Path, Length, Order, Count, Exp, False);
      pragma Unreferenced (Count, Exp);
      return Ok;
   end Search;

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Expansions : out Natural) return Boolean
   is
      Order : Order_Array (1 .. Max_Vertices);
      Count : Natural := 0;
      Ok    : Boolean;
   begin
      Validate_Path (G.N, Path'First, Path'Last);
      Validate_H (G.N, H);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      Ok := Run_Search
        (G, Start, Goal, H, Path, Length, Order, Count, Expansions, False);
      pragma Unreferenced (Count);
      return Ok;
   end Search;

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Order      : out Order_Array;
      Count      : out Natural;
      Expansions : out Natural) return Boolean
   is
   begin
      Validate_Path (G.N, Path'First, Path'Last);
      Validate_Path (G.N, Order'First, Order'Last);
      Validate_H (G.N, H);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      return Run_Search
        (G, Start, Goal, H, Path, Length, Order, Count, Expansions, True);
   end Search_With_Order;

end Best_First_Search;

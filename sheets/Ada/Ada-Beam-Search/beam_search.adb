--  Beam_Search body — level-synchronous beam with H-ranked width β.

pragma Ada_2022;

package body Beam_Search
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

   procedure Validate_Beam_Width (Beam_Width : Natural) is
   begin
      if Beam_Width = 0 then
         raise Invalid_Argument;
      end if;
   end Validate_Beam_Width;

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
   -- Core level-synchronous beam search
   -------------------------------------------------------------------------

   function Run_Search
     (G           : Graph;
      Start       : Vertex_Id;
      Goal        : Vertex_Id;
      H           : Heuristic_Array;
      Beam_Width  : Natural;
      Path        : out Path_Array;
      Length      : out Natural;
      Order       : out Order_Array;
      Count       : out Natural;
      Expansions  : out Natural;
      Track_Order : Boolean) return Boolean
   is
      Visited : Visited_Array := [others => False];
      Prev    : Prev_Local := [others => 0];

      --  Beam and candidate pools (vertex + H key + FIFO seq).
      type Cand is record
         V   : Vertex_Id := Vertex_Id'First;
         Key : Natural := 0;
         Seq : Natural := 0;
      end record;

      Beam      : array (1 .. Max_Vertices) of Cand;
      Beam_Len  : Natural := 0;
      Cands     : array (1 .. Max_Vertices) of Cand;
      Cand_Len  : Natural := 0;
      Next_Seq  : Natural := 0;

      procedure Sort_Cands is
         --  Insertion sort by Key ascending; Seq ascending among ties
         --  (stable FIFO among equal H). Educational; |Cands| ≤ N.
         I, J : Natural;
         T    : Cand;
      begin
         for K in 2 .. Cand_Len loop
            T := Cands (K);
            I := K;
            while I > 1 loop
               J := I - 1;
               if Cands (J).Key < T.Key
                 or else (Cands (J).Key = T.Key
                          and then Cands (J).Seq <= T.Seq)
               then
                  exit;
               end if;
               Cands (I) := Cands (J);
               I := J;
            end loop;
            Cands (I) := T;
         end loop;
      end Sort_Cands;

      U, W   : Vertex_Id;
      E_Idx  : Natural;
      Keep   : Natural;
      Ok     : Boolean;
      Depths : Natural := 0;
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
      Next_Seq := 1;
      Beam_Len := 1;
      Beam (1) := (V => Start, Key => H (Start), Seq => Next_Seq);

      while Beam_Len > 0 loop
         --  Success if Goal survived into the current beam.
         for I in 1 .. Beam_Len loop
            if Beam (I).V = Goal then
               Ok := Rebuild (Prev, Start, Goal, Path, Length);
               return Ok;
            end if;
         end loop;

         Depths := Depths + 1;
         if Depths > Max_Vertices then
            Length := 0;
            return False;
         end if;

         Cand_Len := 0;
         for I in 1 .. Beam_Len loop
            U := Beam (I).V;
            Expansions := Expansions + 1;
            if Track_Order then
               Count := Count + 1;
               Order (Count) := U;
            end if;

            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W := G.To (E_Idx);
               if not Visited (W) then
                  Visited (W) := True;
                  Prev (W) := Natural (U);
                  Cand_Len := Cand_Len + 1;
                  Next_Seq := Next_Seq + 1;
                  Cands (Cand_Len) :=
                    (V => W, Key => H (W), Seq => Next_Seq);
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end loop;

         if Cand_Len = 0 then
            Length := 0;
            return False;
         end if;

         Sort_Cands;

         Keep := Cand_Len;
         if Keep > Beam_Width then
            Keep := Beam_Width;
         end if;

         Beam_Len := Keep;
         for I in 1 .. Keep loop
            Beam (I) := Cands (I);
         end loop;
      end loop;

      Length := 0;
      return False;
   end Run_Search;

   -------------------------------------------------------------------------
   -- Public Search overloads
   -------------------------------------------------------------------------

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural) return Boolean
   is
      Order : Order_Array (1 .. Max_Vertices);
      Count : Natural := 0;
      Exp   : Natural := 0;
      Ok    : Boolean;
   begin
      Validate_Path (G.N, Path'First, Path'Last);
      Validate_H (G.N, H);
      Validate_Beam_Width (Beam_Width);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      Ok := Run_Search
        (G, Start, Goal, H, Beam_Width, Path, Length,
         Order, Count, Exp, False);
      pragma Unreferenced (Count, Exp);
      return Ok;
   end Search;

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
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
      Validate_Beam_Width (Beam_Width);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      Ok := Run_Search
        (G, Start, Goal, H, Beam_Width, Path, Length,
         Order, Count, Expansions, False);
      pragma Unreferenced (Count);
      return Ok;
   end Search;

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
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
      Validate_Beam_Width (Beam_Width);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      return Run_Search
        (G, Start, Goal, H, Beam_Width, Path, Length,
         Order, Count, Expansions, True);
   end Search_With_Order;

end Beam_Search;

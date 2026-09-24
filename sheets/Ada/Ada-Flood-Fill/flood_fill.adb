--  Flood_Fill package body — seed / flood / boundary / span / pattern fills.

pragma Ada_2022;

package body Flood_Fill
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Internal neighbour tables
   ---------------------------------------------------------------------------

   type Offset is record
      DR, DC : Integer;
   end record;

   type Offset_List is array (Positive range <>) of Offset;

   Neighbours_4 : constant Offset_List :=
     [(-1, 0), (1, 0), (0, -1), (0, 1)];

   Neighbours_8 : constant Offset_List :=
     [(-1, 0), (1, 0), (0, -1), (0, 1),
      (-1, -1), (-1, 1), (1, -1), (1, 1)];

   function Neighbours_Of (Conn : Connectivity) return Offset_List is
   begin
      case Conn is
         when Four_Way =>
            return Neighbours_4;
         when Eight_Way =>
            return Neighbours_8;
      end case;
   end Neighbours_Of;

   ---------------------------------------------------------------------------
   -- Bounded pixel stack / queue (capacity = Max_Dim^2)
   ---------------------------------------------------------------------------

   Max_Cells : constant Positive := Max_Dim * Max_Dim;

   subtype Cell_Count is Natural range 0 .. Max_Cells;
   subtype Cell_Index is Positive range 1 .. Max_Cells;

   type Pixel_Buffer is array (Cell_Index) of Pixel_Coord;

   type Pixel_Stack is record
      Data  : Pixel_Buffer;
      Count : Cell_Count := 0;
   end record;

   type Pixel_Queue is record
      Data  : Pixel_Buffer;
      Head  : Cell_Count := 1;  -- next pop index (1-based when non-empty)
      Tail  : Cell_Count := 0;  -- last pushed index
      Count : Cell_Count := 0;
   end record;

   procedure Ensure_Dims (G : Grid) is
   begin
      if G'Length (1) > Max_Dim or else G'Length (2) > Max_Dim then
         raise Invalid_Argument with "grid exceeds Max_Dim";
      end if;
      if G'Length (1) = 0 or else G'Length (2) = 0 then
         raise Invalid_Argument with "empty grid";
      end if;
   end Ensure_Dims;

   procedure Push (S : in out Pixel_Stack; P : Pixel_Coord) is
   begin
      if S.Count = Max_Cells then
         raise Invalid_Argument with "pixel stack overflow";
      end if;
      S.Count := S.Count + 1;
      S.Data (S.Count) := P;
   end Push;

   function Pop (S : in out Pixel_Stack) return Pixel_Coord is
      P : Pixel_Coord;
   begin
      if S.Count = 0 then
         raise Invalid_Argument with "pixel stack underflow";
      end if;
      P := S.Data (S.Count);
      S.Count := S.Count - 1;
      return P;
   end Pop;

   procedure Enqueue (Q : in out Pixel_Queue; P : Pixel_Coord) is
      Idx : Cell_Index;
   begin
      if Q.Count = Max_Cells then
         raise Invalid_Argument with "pixel queue overflow";
      end if;
      if Q.Count = 0 then
         Q.Head := 1;
         Q.Tail := 1;
         Q.Data (1) := P;
         Q.Count := 1;
      else
         Idx := Cell_Index (((Natural (Q.Tail) mod Max_Cells) + 1));
         Q.Tail := Cell_Count (Idx);
         Q.Data (Idx) := P;
         Q.Count := Q.Count + 1;
      end if;
   end Enqueue;

   function Dequeue (Q : in out Pixel_Queue) return Pixel_Coord is
      P   : Pixel_Coord;
      Idx : Cell_Index;
   begin
      if Q.Count = 0 then
         raise Invalid_Argument with "pixel queue underflow";
      end if;
      P := Q.Data (Cell_Index (Q.Head));
      Q.Count := Q.Count - 1;
      if Q.Count = 0 then
         Q.Head := 1;
         Q.Tail := 0;
      else
         Idx := Cell_Index (((Natural (Q.Head) mod Max_Cells) + 1));
         Q.Head := Cell_Count (Idx);
      end if;
      return P;
   end Dequeue;

   ---------------------------------------------------------------------------
   -- Visited mask (for count / pattern / non-mutating walks)
   ---------------------------------------------------------------------------

   type Visit_Mask is array (Dim_Range, Dim_Range) of Boolean;

   function Empty_Mask return Visit_Mask is
      M : constant Visit_Mask := [others => [others => False]];
   begin
      return M;
   end Empty_Mask;

   ---------------------------------------------------------------------------
   -- Public helpers
   ---------------------------------------------------------------------------

   function In_Bounds
     (G : Grid; Row, Col : Integer) return Boolean
   is
   begin
      return Row >= Integer (G'First (1))
        and then Row <= Integer (G'Last (1))
        and then Col >= Integer (G'First (2))
        and then Col <= Integer (G'Last (2));
   end In_Bounds;

   function Get_Color
     (G : Grid; P : Pixel_Coord) return Color_Id
   is
   begin
      if not In_Bounds (G, Integer (P.Row), Integer (P.Col)) then
         raise Out_Of_Bounds with "Get_Color out of bounds";
      end if;
      return G (P.Row, P.Col);
   end Get_Color;

   procedure Set_Color
     (G : in out Grid; P : Pixel_Coord; C : Color_Id)
   is
   begin
      if not In_Bounds (G, Integer (P.Row), Integer (P.Col)) then
         raise Out_Of_Bounds with "Set_Color out of bounds";
      end if;
      G (P.Row, P.Col) := C;
   end Set_Color;

   function Count_Color (G : Grid; C : Color_Id) return Natural is
      N : Natural := 0;
   begin
      for R in G'Range (1) loop
         for Col in G'Range (2) loop
            if G (R, Col) = C then
               N := N + 1;
            end if;
         end loop;
      end loop;
      return N;
   end Count_Color;

   function Same_Grid (A, B : Grid) return Boolean is
   begin
      for R in A'Range (1) loop
         for C in A'Range (2) loop
            if A (R, C) /= B (R, C) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Same_Grid;

   procedure Validate_Start (G : Grid; Start : Pixel_Coord) is
   begin
      Ensure_Dims (G);
      if not In_Bounds (G, Integer (Start.Row), Integer (Start.Col)) then
         raise Out_Of_Bounds with "start pixel outside grid";
      end if;
   end Validate_Start;

   ---------------------------------------------------------------------------
   -- Recursive four-way
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Recursive_4
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
   is
      Changed : Natural := 0;

      procedure Recurse (Row, Col : Integer) is
      begin
         if not In_Bounds (G, Row, Col) then
            return;
         end if;
         if G (Row, Col) /= Target then
            return;
         end if;
         G (Row, Col) := Replacement;
         Changed := Changed + 1;
         Recurse (Row - 1, Col);
         Recurse (Row + 1, Col);
         Recurse (Row, Col - 1);
         Recurse (Row, Col + 1);
      end Recurse;
   begin
      Validate_Start (G, Start);
      Result.Pixels_Changed := 0;
      if Target = Replacement then
         return;
      end if;
      Recurse (Integer (Start.Row), Integer (Start.Col));
      Result.Pixels_Changed := Changed;
   end Flood_Fill_Recursive_4;

   ---------------------------------------------------------------------------
   -- Recursive eight-way
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Recursive_8
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
   is
      Changed : Natural := 0;

      procedure Recurse (Row, Col : Integer) is
      begin
         if not In_Bounds (G, Row, Col) then
            return;
         end if;
         if G (Row, Col) /= Target then
            return;
         end if;
         G (Row, Col) := Replacement;
         Changed := Changed + 1;
         Recurse (Row - 1, Col);
         Recurse (Row + 1, Col);
         Recurse (Row, Col - 1);
         Recurse (Row, Col + 1);
         Recurse (Row - 1, Col - 1);
         Recurse (Row - 1, Col + 1);
         Recurse (Row + 1, Col - 1);
         Recurse (Row + 1, Col + 1);
      end Recurse;
   begin
      Validate_Start (G, Start);
      Result.Pixels_Changed := 0;
      if Target = Replacement then
         return;
      end if;
      Recurse (Integer (Start.Row), Integer (Start.Col));
      Result.Pixels_Changed := Changed;
   end Flood_Fill_Recursive_8;

   ---------------------------------------------------------------------------
   -- Shared iterative fill (stack or queue discipline)
   ---------------------------------------------------------------------------

   type Store_Kind is (Use_Stack, Use_Queue);

   procedure Iterative_Seed_Fill
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Conn               : Connectivity;
      Kind               : Store_Kind;
      Result             : out Fill_Result)
   is
      Stack : Pixel_Stack;
      Queue : Pixel_Queue;
      Offs  : constant Offset_List := Neighbours_Of (Conn);
      Cur   : Pixel_Coord;
      NR, NC : Integer;
      Changed : Natural := 0;

      procedure Offer (P : Pixel_Coord) is
      begin
         case Kind is
            when Use_Stack =>
               Push (Stack, P);
            when Use_Queue =>
               Enqueue (Queue, P);
         end case;
      end Offer;

      function Take return Pixel_Coord is
      begin
         case Kind is
            when Use_Stack =>
               return Pop (Stack);
            when Use_Queue =>
               return Dequeue (Queue);
         end case;
      end Take;

      function Pending return Boolean is
      begin
         case Kind is
            when Use_Stack =>
               return Stack.Count > 0;
            when Use_Queue =>
               return Queue.Count > 0;
         end case;
      end Pending;
   begin
      Validate_Start (G, Start);
      Result.Pixels_Changed := 0;
      if Target = Replacement then
         return;
      end if;
      if G (Start.Row, Start.Col) /= Target then
         return;
      end if;

      --  Check-and-set before enqueue to shrink the worklist (Wikipedia tip).
      G (Start.Row, Start.Col) := Replacement;
      Changed := 1;
      Offer (Start);

      while Pending loop
         Cur := Take;
         for O of Offs loop
            NR := Integer (Cur.Row) + O.DR;
            NC := Integer (Cur.Col) + O.DC;
            if In_Bounds (G, NR, NC)
              and then G (NR, NC) = Target
            then
               G (NR, NC) := Replacement;
               Changed := Changed + 1;
               Offer ((Row => Dim_Range (NR), Col => Dim_Range (NC)));
            end if;
         end loop;
      end loop;

      Result.Pixels_Changed := Changed;
   end Iterative_Seed_Fill;

   procedure Flood_Fill_Stack
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Conn               : Connectivity;
      Result             : out Fill_Result)
   is
   begin
      Iterative_Seed_Fill
        (G, Start, Target, Replacement, Conn, Use_Stack, Result);
   end Flood_Fill_Stack;

   procedure Flood_Fill_Queue
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Conn               : Connectivity;
      Result             : out Fill_Result)
   is
   begin
      Iterative_Seed_Fill
        (G, Start, Target, Replacement, Conn, Use_Queue, Result);
   end Flood_Fill_Queue;

   ---------------------------------------------------------------------------
   -- Span / scanline fill (four-way), stack of seed points
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Span
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
   is
      Stack   : Pixel_Stack;
      Changed : Natural := 0;
      Seed    : Pixel_Coord;
      X, Y    : Integer;
      LX, RX  : Integer;
      Span_Added : Boolean;

      procedure Scan (Left, Right, Row : Integer) is
         XX : Integer := Left;
      begin
         if not In_Bounds (G, Row, Left) and then
            not In_Bounds (G, Row, Right)
         then
            --  Entire scan row may be out of vertical bounds.
            if Row < Integer (G'First (1)) or else Row > Integer (G'Last (1))
            then
               return;
            end if;
         end if;
         if Row < Integer (G'First (1)) or else Row > Integer (G'Last (1)) then
            return;
         end if;

         Span_Added := False;
         XX := Left;
         while XX <= Right loop
            if not In_Bounds (G, Row, XX) or else G (Row, XX) /= Target then
               Span_Added := False;
            elsif not Span_Added then
               Push (Stack, (Row => Dim_Range (Row), Col => Dim_Range (XX)));
               Span_Added := True;
            end if;
            XX := XX + 1;
         end loop;
      end Scan;
   begin
      Validate_Start (G, Start);
      Result.Pixels_Changed := 0;
      if Target = Replacement then
         return;
      end if;
      if G (Start.Row, Start.Col) /= Target then
         return;
      end if;

      Push (Stack, Start);

      while Stack.Count > 0 loop
         Seed := Pop (Stack);
         X := Integer (Seed.Col);
         Y := Integer (Seed.Row);

         if In_Bounds (G, Y, X) and then G (Y, X) = Target then
            --  Expand left
            LX := X;
            while In_Bounds (G, Y, LX - 1)
              and then G (Y, LX - 1) = Target
            loop
               LX := LX - 1;
            end loop;

            --  Expand right, filling as we go from LX
            RX := LX;
            while In_Bounds (G, Y, RX) and then G (Y, RX) = Target loop
               G (Y, RX) := Replacement;
               Changed := Changed + 1;
               RX := RX + 1;
            end loop;
            RX := RX - 1;  -- last filled column

            Scan (LX, RX, Y + 1);
            Scan (LX, RX, Y - 1);
         end if;
      end loop;

      Result.Pixels_Changed := Changed;
   end Flood_Fill_Span;

   ---------------------------------------------------------------------------
   -- Boundary fill (iterative stack; Inside = colour /= Border and /= Fill)
   ---------------------------------------------------------------------------

   procedure Boundary_Fill_Common
     (G            : in out Grid;
      Start        : Pixel_Coord;
      Border, Fill : Color_Id;
      Conn         : Connectivity;
      Result       : out Fill_Result)
   is
      Stack   : Pixel_Stack;
      Offs    : constant Offset_List := Neighbours_Of (Conn);
      Cur     : Pixel_Coord;
      NR, NC  : Integer;
      Changed : Natural := 0;

      function Is_Inside (Row, Col : Integer) return Boolean is
         Pix : Color_Id;
      begin
         if not In_Bounds (G, Row, Col) then
            return False;
         end if;
         Pix := G (Row, Col);
         return Pix /= Border and then Pix /= Fill;
      end Is_Inside;
   begin
      Validate_Start (G, Start);
      Result.Pixels_Changed := 0;
      if Border = Fill then
         raise Invalid_Argument with "border and fill colours must differ";
      end if;
      if not Is_Inside (Integer (Start.Row), Integer (Start.Col)) then
         return;
      end if;

      G (Start.Row, Start.Col) := Fill;
      Changed := 1;
      Push (Stack, Start);

      while Stack.Count > 0 loop
         Cur := Pop (Stack);
         for O of Offs loop
            NR := Integer (Cur.Row) + O.DR;
            NC := Integer (Cur.Col) + O.DC;
            if Is_Inside (NR, NC) then
               G (NR, NC) := Fill;
               Changed := Changed + 1;
               Push (Stack, (Row => Dim_Range (NR), Col => Dim_Range (NC)));
            end if;
         end loop;
      end loop;

      Result.Pixels_Changed := Changed;
   end Boundary_Fill_Common;

   procedure Boundary_Fill_4
     (G            : in out Grid;
      Start        : Pixel_Coord;
      Border, Fill : Color_Id;
      Result       : out Fill_Result)
   is
   begin
      Boundary_Fill_Common (G, Start, Border, Fill, Four_Way, Result);
   end Boundary_Fill_4;

   procedure Boundary_Fill_8
     (G            : in out Grid;
      Start        : Pixel_Coord;
      Border, Fill : Color_Id;
      Result       : out Fill_Result)
   is
   begin
      Boundary_Fill_Common (G, Start, Border, Fill, Eight_Way, Result);
   end Boundary_Fill_8;

   ---------------------------------------------------------------------------
   -- Pattern fill via visited mask + queue
   ---------------------------------------------------------------------------

   procedure Pattern_Flood_Fill
     (G       : in out Grid;
      Start   : Pixel_Coord;
      Target  : Color_Id;
      Pattern : Pattern_Grid;
      Conn    : Connectivity := Four_Way;
      Result  : out Fill_Result)
   is
      Queue   : Pixel_Queue;
      Visited : Visit_Mask := Empty_Mask;
      Offs    : constant Offset_List := Neighbours_Of (Conn);
      Cur     : Pixel_Coord;
      NR, NC  : Integer;
      Changed : Natural := 0;
      PR, PC  : Positive;
      Pat_R   : constant Positive := Pattern'Length (1);
      Pat_C   : constant Positive := Pattern'Length (2);

      function Local_Row (R : Positive) return Positive is
         Rel : constant Natural :=
           (R - G'First (1)) mod Pat_R;
      begin
         return Pattern'First (1) + Rel;
      end Local_Row;

      function Local_Col (C : Positive) return Positive is
         Rel : constant Natural :=
           (C - G'First (2)) mod Pat_C;
      begin
         return Pattern'First (2) + Rel;
      end Local_Col;

      function Is_Inside (Row, Col : Integer) return Boolean is
      begin
         if not In_Bounds (G, Row, Col) then
            return False;
         end if;
         if Visited (Dim_Range (Row), Dim_Range (Col)) then
            return False;
         end if;
         return G (Row, Col) = Target;
      end Is_Inside;

      procedure Mark_And_Set (Row, Col : Integer) is
      begin
         Visited (Dim_Range (Row), Dim_Range (Col)) := True;
         PR := Local_Row (Positive (Row));
         PC := Local_Col (Positive (Col));
         G (Row, Col) := Pattern (PR, PC);
         Changed := Changed + 1;
      end Mark_And_Set;
   begin
      Validate_Start (G, Start);
      if Pattern'Length (1) = 0 or else Pattern'Length (2) = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length (1) > Max_Pattern
        or else Pattern'Length (2) > Max_Pattern
      then
         raise Invalid_Argument with "pattern exceeds Max_Pattern";
      end if;

      Result.Pixels_Changed := 0;
      if not Is_Inside (Integer (Start.Row), Integer (Start.Col)) then
         return;
      end if;

      Mark_And_Set (Integer (Start.Row), Integer (Start.Col));
      Enqueue (Queue, Start);

      while Queue.Count > 0 loop
         Cur := Dequeue (Queue);
         for O of Offs loop
            NR := Integer (Cur.Row) + O.DR;
            NC := Integer (Cur.Col) + O.DC;
            if Is_Inside (NR, NC) then
               Mark_And_Set (NR, NC);
               Enqueue (Queue,
                        (Row => Dim_Range (NR), Col => Dim_Range (NC)));
            end if;
         end loop;
      end loop;

      Result.Pixels_Changed := Changed;
   end Pattern_Flood_Fill;

   ---------------------------------------------------------------------------
   -- Count connected region (BFS, non-mutating)
   ---------------------------------------------------------------------------

   function Count_Connected
     (G      : Grid;
      Start  : Pixel_Coord;
      Target : Color_Id;
      Conn   : Connectivity := Four_Way) return Natural
   is
      Queue   : Pixel_Queue;
      Visited : Visit_Mask := Empty_Mask;
      Offs    : constant Offset_List := Neighbours_Of (Conn);
      Cur     : Pixel_Coord;
      NR, NC  : Integer;
      Count   : Natural := 0;
   begin
      Validate_Start (G, Start);
      if G (Start.Row, Start.Col) /= Target then
         return 0;
      end if;

      Visited (Start.Row, Start.Col) := True;
      Count := 1;
      Enqueue (Queue, Start);

      while Queue.Count > 0 loop
         Cur := Dequeue (Queue);
         for O of Offs loop
            NR := Integer (Cur.Row) + O.DR;
            NC := Integer (Cur.Col) + O.DC;
            if In_Bounds (G, NR, NC)
              and then not Visited (Dim_Range (NR), Dim_Range (NC))
              and then G (NR, NC) = Target
            then
               Visited (Dim_Range (NR), Dim_Range (NC)) := True;
               Count := Count + 1;
               Enqueue (Queue,
                        (Row => Dim_Range (NR), Col => Dim_Range (NC)));
            end if;
         end loop;
      end loop;

      return Count;
   end Count_Connected;

   function Measure_Region
     (G      : Grid;
      Start  : Pixel_Coord;
      Target : Color_Id;
      Conn   : Connectivity := Four_Way) return Natural
   is
   begin
      return Count_Connected (G, Start, Target, Conn);
   end Measure_Region;

end Flood_Fill;

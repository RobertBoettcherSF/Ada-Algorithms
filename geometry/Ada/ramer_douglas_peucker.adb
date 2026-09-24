--  Package body for Ramer-Douglas-Peucker algorithm.

package body Ramer_Douglas_Peucker is

   function Euclidean_Distance (P1, P2 : Point_2D) return Distance is
      DX : constant Long_Float := Long_Float (P1.X - P2.X);
      DY : constant Long_Float := Long_Float (P1.Y - P2.Y);
   begin
      return Distance (Math.Sqrt (DX * DX + DY * DY));
   end Euclidean_Distance;

   function Perpendicular_Distance
     (P          : Point_2D;
      Line_Start : Point_2D;
      Line_End   : Point_2D) return Distance
   is
      DX : constant Long_Float := Long_Float (Line_End.X - Line_Start.X);
      DY : constant Long_Float := Long_Float (Line_End.Y - Line_Start.Y);
      Line_Len_Sq : constant Long_Float := DX * DX + DY * DY;
   begin
      --  If the line endpoints coincide, calculate point-to-point distance
      if Line_Len_Sq = 0.0 then
         return Euclidean_Distance (P, Line_Start);
      end if;

      --  Standard area-based formula for distance from point to line:
      --  |dy * x0 - dx * y0 + x2 * y1 - y2 * x1| / sqrt(dx^2 + dy^2)
      declare
         Numerator : constant Long_Float := abs (
            DY * Long_Float (P.X) -
            DX * Long_Float (P.Y) +
            Long_Float (Line_End.X) * Long_Float (Line_Start.Y) -
            Long_Float (Line_End.Y) * Long_Float (Line_Start.X)
         );
      begin
         return Distance (Numerator / Math.Sqrt (Line_Len_Sq));
      end;
   end Perpendicular_Distance;

   procedure Find_Maximum_Distance
     (Points       : Point_Array;
      First_Index  : Positive;
      Last_Index   : Positive;
      Max_Idx      : out Positive;
      Max_Dist     : out Distance)
   is
      Current_Dist : Distance;
   begin
      Max_Dist := 0.0;
      Max_Idx  := First_Index;

      if Last_Index - First_Index <= 1 then
         return;
      end if;

      for I in First_Index + 1 .. Last_Index - 1 loop
         Current_Dist := Perpendicular_Distance
           (P          => Points (I),
            Line_Start => Points (First_Index),
            Line_End   => Points (Last_Index));

         if Current_Dist > Max_Dist then
            Max_Dist := Current_Dist;
            Max_Idx  := I;
         end if;
      end loop;
   end Find_Maximum_Distance;

   --  Internal recursive procedure marking kept points in a boolean mask
   procedure RDP_Recursive_Mark
     (Points     : Point_Array;
      First_Idx  : Positive;
      Last_Idx   : Positive;
      Epsilon    : Distance;
      Keep_Mask  : in out Boolean_Array)
   is
      Max_Idx  : Positive;
      Max_Dist : Distance;
   begin
      if Last_Idx <= First_Idx then
         return;
      end if;

      Find_Maximum_Distance (Points, First_Idx, Last_Idx, Max_Idx, Max_Dist);

      if Max_Dist > Epsilon then
         Keep_Mask (Max_Idx) := True;
         RDP_Recursive_Mark (Points, First_Idx, Max_Idx, Epsilon, Keep_Mask);
         RDP_Recursive_Mark (Points, Max_Idx, Last_Idx, Epsilon, Keep_Mask);
      end if;
   end RDP_Recursive_Mark;

   function Simplify_Mask
     (Points  : Point_Array;
      Epsilon : Distance) return Boolean_Array
   is
      Mask : Boolean_Array (Points'Range) := [others => False];
   begin
      if Points'Length = 0 then
         return Mask;
      end if;

      if Points'Length <= 2 then
         Mask := [others => True];
         return Mask;
      end if;

      Mask (Points'First) := True;
      Mask (Points'Last)  := True;

      RDP_Recursive_Mark
        (Points    => Points,
         First_Idx => Points'First,
         Last_Idx  => Points'Last,
         Epsilon   => Epsilon,
         Keep_Mask => Mask);

      return Mask;
   end Simplify_Mask;

   function Simplify
     (Points  : Point_Array;
      Epsilon : Distance) return Point_Array
   is
   begin
      if Points'Length <= 2 then
         return Points;
      end if;

      declare
         Mask  : constant Boolean_Array := Simplify_Mask (Points, Epsilon);
         Count : Natural := 0;
      begin
         for Flag of Mask loop
            if Flag then
               Count := Count + 1;
            end if;
         end loop;

         declare
            Result : Point_Array (1 .. Count);
            Idx    : Positive := 1;
         begin
            for I in Points'Range loop
               if Mask (I) then
                  Result (Idx) := Points (I);
                  Idx := Idx + 1;
               end if;
            end loop;
            return Result;
         end;
      end;
   end Simplify;

   function Simplify_Iterative
     (Points  : Point_Array;
      Epsilon : Distance) return Point_Array
   is
   begin
      if Points'Length <= 2 then
         return Points;
      end if;

      declare
         type Segment is record
            First_Idx : Positive;
            Last_Idx  : Positive;
         end record;

         type Segment_Stack is array (1 .. Points'Length * 2 + 8) of Segment;
         Stack      : Segment_Stack;
         Stack_Top  : Natural := 0;
         Mask       : Boolean_Array (Points'Range) := [others => False];

         procedure Push (S : Segment) is
         begin
            Stack_Top := Stack_Top + 1;
            Stack (Stack_Top) := S;
         end Push;

         function Pop return Segment is
            Item : constant Segment := Stack (Stack_Top);
         begin
            Stack_Top := Stack_Top - 1;
            return Item;
         end Pop;

         Current_Seg : Segment;
         Max_Idx     : Positive;
         Max_Dist    : Distance;
         Kept_Count  : Natural := 0;
      begin
         Mask (Points'First) := True;
         Mask (Points'Last)  := True;

         Push ((First_Idx => Points'First, Last_Idx => Points'Last));

         while Stack_Top > 0 loop
            Current_Seg := Pop;

            if Current_Seg.Last_Idx - Current_Seg.First_Idx > 1 then
               Find_Maximum_Distance
                 (Points      => Points,
                  First_Index => Current_Seg.First_Idx,
                  Last_Index  => Current_Seg.Last_Idx,
                  Max_Idx     => Max_Idx,
                  Max_Dist    => Max_Dist);

               if Max_Dist > Epsilon then
                  Mask (Max_Idx) := True;
                  Push ((First_Idx => Current_Seg.First_Idx, Last_Idx => Max_Idx));
                  Push ((First_Idx => Max_Idx, Last_Idx => Current_Seg.Last_Idx));
               end if;
            end if;
         end loop;

         for Flag of Mask loop
            if Flag then
               Kept_Count := Kept_Count + 1;
            end if;
         end loop;

         declare
            Result : Point_Array (1 .. Kept_Count);
            Idx    : Positive := 1;
         begin
            for I in Points'Range loop
               if Mask (I) then
                  Result (Idx) := Points (I);
                  Idx := Idx + 1;
               end if;
            end loop;
            return Result;
         end;
      end;
   end Simplify_Iterative;

   function Simplify_Indices
     (Points  : Point_Array;
      Epsilon : Distance) return Index_Array
   is
   begin
      if Points'Length = 0 then
         declare
            Empty : Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Mask  : constant Boolean_Array := Simplify_Mask (Points, Epsilon);
         Count : Natural := 0;
      begin
         for Flag of Mask loop
            if Flag then
               Count := Count + 1;
            end if;
         end loop;

         declare
            Result : Index_Array (1 .. Count);
            Idx    : Positive := 1;
         begin
            for I in Points'Range loop
               if Mask (I) then
                  Result (Idx) := I;
                  Idx := Idx + 1;
               end if;
            end loop;
            return Result;
         end;
      end;
   end Simplify_Indices;

end Ramer_Douglas_Peucker;

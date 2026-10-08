with Ada.Containers.Generic_Array_Sort;

package body Marzullo is

   -- Internal tuple types to represent start (-1) and end (+1) of intervals
   type Tuple_Kind is (START_EDGE, END_EDGE);

   type Edge is record
      Offset : Time_Point;
      Kind   : Tuple_Kind;
   end record;

   type Edge_Array is array (Positive range <>) of Edge;

   -- Sorting logic: Order by time offset. 
   -- If tied, process START_EDGE before END_EDGE to maximize overlap count at boundaries.
   function "<" (Left, Right : Edge) return Boolean is
   begin
      if Left.Offset = Right.Offset then
         return Left.Kind < Right.Kind;
      else
         return Left.Offset < Right.Offset;
      end if;
   end "<";

   procedure Sort_Edges is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Edge,
      Array_Type   => Edge_Array);

   -- Helper to decompose intervals into a sorted array of edge tuples
   procedure Build_Edges (Intervals : in Interval_Array; Edges : out Edge_Array) is
      Edge_Index : Positive := 1;
   begin
      if Intervals'Length = 0 then
         raise Empty_Input_Error;
      end if;

      for I in Intervals'Range loop
         if Intervals(I).Start_Time > Intervals(I).End_Time then
            raise Invalid_Interval_Error;
         end if;
         Edges (Edge_Index)     := (Offset => Intervals(I).Start_Time, Kind => START_EDGE);
         Edges (Edge_Index + 1) := (Offset => Intervals(I).End_Time,   Kind => END_EDGE);
         Edge_Index := Edge_Index + 2;
      end loop;
      
      Sort_Edges (Edges);
   end Build_Edges;

   -- VARIANT 1: Basic Marzullo
   procedure Basic_Marzullo
     (Intervals    : in Interval_Array;
      Best_Interval: out Time_Interval;
      Max_Overlaps : out Natural)
   is
      Edges : Edge_Array (1 .. Intervals'Length * 2);
      Count : Natural := 0;
      Best  : Natural := 0;
   begin
      Build_Edges (Intervals, Edges);
      Best_Interval := (Start_Time => 0.0, End_Time => 0.0);

      for I in Edges'First .. Edges'Last - 1 loop
         if Edges(I).Kind = START_EDGE then
            Count := Count + 1;
         else
            Count := Count - 1;
         end if;

         if Count > Best then
            Best := Count;
            Best_Interval.Start_Time := Edges(I).Offset;
            Best_Interval.End_Time   := Edges(I + 1).Offset;
         end if;
      end loop;

      Max_Overlaps := Best;
   end Basic_Marzullo;

   -- VARIANT 2: Extended Marzullo
   procedure Extended_Marzullo
     (Intervals    : in Interval_Array;
      Results      : out Result_Array;
      Result_Count : out Natural;
      Max_Overlaps : out Natural)
   is
      Edges : Edge_Array (1 .. Intervals'Length * 2);
      Count : Natural := 0;
      Best  : Natural := 0;
   begin
      Build_Edges (Intervals, Edges);
      Result_Count := 0;
      Max_Overlaps := 0;

      for I in Edges'First .. Edges'Last - 1 loop
         if Edges(I).Kind = START_EDGE then
            Count := Count + 1;
         else
            Count := Count - 1;
         end if;

         if Count > Best then
            -- Found a new global maximum, reset recorded intervals
            Best := Count;
            Result_Count := 1;
            if Result_Count <= Results'Last then
               Results(Result_Count) := (Start_Time => Edges(I).Offset, End_Time => Edges(I + 1).Offset);
            end if;
         elsif Count = Best then
            -- Found another peak matching the global maximum
            Result_Count := Result_Count + 1;
            if Result_Count <= Results'Last then
               Results(Result_Count) := (Start_Time => Edges(I).Offset, End_Time => Edges(I + 1).Offset);
            end if;
         end if;
      end loop;

      Max_Overlaps := Best;
   end Extended_Marzullo;

end Marzullo;

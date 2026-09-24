-- intersection_algorithm.adb
-- Body implementing all algorithm variants cleanly.

with Ada.Containers.Generic_Array_Sort;

package body Intersection_Algorithm is

   -- Internal tuple representation for timeline events
   type Endpoint_Type is new Integer range -1 .. 1;
   
   type Tuple is record
      Offset : Float;
      T_Type : Endpoint_Type;
   end record;

   type Tuple_Array is array (Positive range <>) of Tuple;

   -- Sort function for tuples
   function "<" (Left, Right : Tuple) return Boolean is
   begin
      if Left.Offset = Right.Offset then
         return Left.T_Type < Right.T_Type;
      else
         return Left.Offset < Right.Offset;
      end if;
   end "<";

   procedure Sort_Tuples is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Tuple,
      Array_Type   => Tuple_Array,
      "<"          => "<");

   -----------------------------------------------------------------
   -- Main Variant: Intersection Algorithm (NTP Specification)
   -----------------------------------------------------------------
   function Find_Intersection (Intervals : Interval_Array) return Result_Record is
      M : constant Natural := Intervals'Length;
      Total_Tuples : constant Natural := M * 3;
      Tuples : Tuple_Array (1 .. Total_Tuples);
      Index : Positive := 1;
      F : Natural := 0;
      Endcount, Midcount : Integer;
      Lower, Upper : Float;
      Lower_Found, Upper_Found : Boolean;
   begin
      if M = 0 then
         return (Success => False, Lower => 0.0, Upper => 0.0);
      end if;

      -- Construct internal table of tuples
      for I in Intervals'Range loop
         if Intervals (I).Radius < 0.0 then
            raise Invalid_Data_Error with "Interval radius cannot be negative.";
         end if;
         Tuples (Index)     := (Offset => Intervals(I).Center - Intervals(I).Radius, T_Type => -1);
         Tuples (Index + 1) := (Offset => Intervals(I).Center, T_Type => 0);
         Tuples (Index + 2) := (Offset => Intervals(I).Center + Intervals(I).Radius, T_Type => 1);
         Index := Index + 3;
      end loop;

      Sort_Tuples (Tuples);

      loop
         -- Algorithm valid if f < M/2, else failure
         if Float (F) >= Float (M) / 2.0 then
            return (Success => False, Lower => 0.0, Upper => 0.0);
         end if;

         Endcount := 0;
         Midcount := 0;
         Lower_Found := False;

         -- Step: Find tentative lower endpoint
         for I in Tuples'Range loop
            Endcount := Endcount - Integer (Tuples (I).T_Type);
            if Endcount >= M - F then
               Lower := Tuples (I).Offset;
               Lower_Found := True;
               exit;
            end if;
            if Tuples (I).T_Type = 0 then
               Midcount := Midcount + 1;
            end if;
         end loop;

         if Lower_Found then
            Endcount := 0;
            Upper_Found := False;
            
            -- Step: Find tentative upper endpoint
            for I in reverse Tuples'Range loop
               Endcount := Endcount + Integer (Tuples (I).T_Type);
               if Endcount >= M - F then
                  Upper := Tuples (I).Offset;
                  Upper_Found := True;
                  exit;
               end if;
               if Tuples (I).T_Type = 0 then
                  Midcount := Midcount + 1;
               end if;
            end loop;

            -- Step: Validate consensus interval
            if Upper_Found then
               if Lower <= Upper and then Midcount <= F then
                  return (Success => True, Lower => Lower, Upper => Upper);
               end if;
            end if;
         end if;

         -- Consensus failed, increment falseticker assumption
         F := F + 1;
      end loop;
   end Find_Intersection;

   -----------------------------------------------------------------
   -- Base Variant: Marzullo's Algorithm
   -----------------------------------------------------------------
   function Marzullo_Algorithm (Intervals : Interval_Array) return Result_Record is
      M : constant Natural := Intervals'Length;
      Total_Tuples : constant Natural := M * 2;
      Tuples : Tuple_Array (1 .. Total_Tuples);
      Index : Positive := 1;
      Best, Cnt : Integer := 0;
      Best_Start, Best_End : Float := 0.0;
      Found : Boolean := False;
   begin
      if M = 0 then
         return (Success => False, Lower => 0.0, Upper => 0.0);
      end if;

      for I in Intervals'Range loop
         if Intervals (I).Radius < 0.0 then
            raise Invalid_Data_Error with "Interval radius cannot be negative.";
         end if;
         Tuples (Index)     := (Offset => Intervals (I).Center - Intervals (I).Radius, T_Type => -1);
         Tuples (Index + 1) := (Offset => Intervals (I).Center + Intervals (I).Radius, T_Type => 1);
         Index := Index + 2;
      end loop;

      Sort_Tuples (Tuples);

      for I in 1 .. Total_Tuples - 1 loop
         Cnt := Cnt - Integer (Tuples (I).T_Type);
         if Cnt > Best then
            Best := Cnt;
            Best_Start := Tuples (I).Offset;
            Best_End := Tuples (I + 1).Offset;
            Found := True;
         end if;
      end loop;

      return (Success => Found, Lower => Best_Start, Upper => Best_End);
   end Marzullo_Algorithm;

end Intersection_Algorithm;

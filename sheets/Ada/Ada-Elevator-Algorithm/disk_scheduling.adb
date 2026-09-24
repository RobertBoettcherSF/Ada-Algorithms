-- Version: 0.01
-- Disk Scheduling Algorithm Implementations

with Ada.Containers.Generic_Array_Sort;

package body Disk_Scheduling is

   -- Internal Array Sorter
   procedure Sort is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Cylinder,
      Array_Type   => Cylinder_Array,
      "<"          => "<");

   -- Helper to reverse an array's ordering
   function Reverse_Array (A : Cylinder_Array) return Cylinder_Array is
      Result : Cylinder_Array (A'Range);
      Idx    : Positive := Result'First;
   begin
      for I in reverse A'Range loop
         Result (Idx) := A (I);
         Idx := Idx + 1;
      end loop;
      return Result;
   end Reverse_Array;

   -- Extracts and sorts all requests strictly less than the head position
   function Get_Left (Reqs : Cylinder_Array; Head : Cylinder) return Cylinder_Array is
      Count : Natural := 0;
   begin
      for R of Reqs loop
         if R < Head then 
            Count := Count + 1; 
         end if;
      end loop;
      
      declare
         Result : Cylinder_Array (1 .. Count);
         Idx    : Positive := 1;
      begin
         for R of Reqs loop
            if R < Head then
               Result (Idx) := R;
               Idx := Idx + 1;
            end if;
         end loop;
         Sort (Result);
         return Result;
      end;
   end Get_Left;

   -- Extracts and sorts all requests greater than or equal to the head position
   function Get_Right (Reqs : Cylinder_Array; Head : Cylinder) return Cylinder_Array is
      Count : Natural := 0;
   begin
      for R of Reqs loop
         if R >= Head then 
            Count := Count + 1; 
         end if;
      end loop;
      
      declare
         Result : Cylinder_Array (1 .. Count);
         Idx    : Positive := 1;
      begin
         for R of Reqs loop
            if R >= Head then
               Result (Idx) := R;
               Idx := Idx + 1;
            end if;
         end loop;
         Sort (Result);
         return Result;
      end;
   end Get_Right;

   -----------------------------------------------------------------------------
   -- SCAN (Elevator Algorithm)
   -----------------------------------------------------------------------------
   function SCAN
     (Requests     : Cylinder_Array;
      Start_Head   : Cylinder;
      Dir          : Direction;
      Max_Cylinder : Cylinder) return Cylinder_Array
   is
      Left     : constant Cylinder_Array := Get_Left (Requests, Start_Head);
      Right    : constant Cylinder_Array := Get_Right (Requests, Start_Head);
      Zero_Arr : constant Cylinder_Array (1 .. 1) := (1 => 0);
      Max_Arr  : constant Cylinder_Array (1 .. 1) := (1 => Max_Cylinder);
   begin
      if Requests'Length = 0 then
         return Requests;
      end if;

      if Dir = Up then
         return Right & Max_Arr & Reverse_Array (Left);
      else
         return Reverse_Array (Left) & Zero_Arr & Right;
      end if;
   end SCAN;

   -----------------------------------------------------------------------------
   -- C-SCAN
   -----------------------------------------------------------------------------
   function C_SCAN
     (Requests     : Cylinder_Array;
      Start_Head   : Cylinder;
      Dir          : Direction;
      Max_Cylinder : Cylinder) return Cylinder_Array
   is
      Left     : constant Cylinder_Array := Get_Left (Requests, Start_Head);
      Right    : constant Cylinder_Array := Get_Right (Requests, Start_Head);
      Zero_Arr : constant Cylinder_Array (1 .. 1) := (1 => 0);
      Max_Arr  : constant Cylinder_Array (1 .. 1) := (1 => Max_Cylinder);
   begin
      if Requests'Length = 0 then
         return Requests;
      end if;

      if Dir = Up then
         return Right & Max_Arr & Zero_Arr & Left;
      else
         return Reverse_Array (Left) & Zero_Arr & Max_Arr & Reverse_Array (Right);
      end if;
   end C_SCAN;

   -----------------------------------------------------------------------------
   -- LOOK
   -----------------------------------------------------------------------------
   function LOOK
     (Requests   : Cylinder_Array;
      Start_Head : Cylinder;
      Dir        : Direction) return Cylinder_Array
   is
      Left  : constant Cylinder_Array := Get_Left (Requests, Start_Head);
      Right : constant Cylinder_Array := Get_Right (Requests, Start_Head);
   begin
      if Requests'Length = 0 then
         return Requests;
      end if;

      if Dir = Up then
         return Right & Reverse_Array (Left);
      else
         return Reverse_Array (Left) & Right;
      end if;
   end LOOK;

   -----------------------------------------------------------------------------
   -- C-LOOK
   -----------------------------------------------------------------------------
   function C_LOOK
     (Requests   : Cylinder_Array;
      Start_Head : Cylinder;
      Dir        : Direction) return Cylinder_Array
   is
      Left  : constant Cylinder_Array := Get_Left (Requests, Start_Head);
      Right : constant Cylinder_Array := Get_Right (Requests, Start_Head);
   begin
      if Requests'Length = 0 then
         return Requests;
      end if;

      if Dir = Up then
         return Right & Left;
      else
         return Reverse_Array (Left) & Reverse_Array (Right);
      end if;
   end C_LOOK;

   -----------------------------------------------------------------------------
   -- F-SCAN
   -----------------------------------------------------------------------------
   function F_SCAN
     (Active_Queue  : Cylinder_Array;
      Waiting_Queue : Cylinder_Array;
      Start_Head    : Cylinder;
      Dir           : Direction;
      Max_Cylinder  : Cylinder) return Cylinder_Array
   is
      Scan_1    : constant Cylinder_Array := SCAN (Active_Queue, Start_Head, Dir, Max_Cylinder);
      Next_Head : Cylinder := Start_Head;
      Next_Dir  : Direction := Dir;
   begin
      if Scan_1'Length > 0 then
         -- End position of the first queue becomes the start of the next queue
         Next_Head := Scan_1 (Scan_1'Last);
         
         -- SCAN inherently reverses head direction once it hits the edge of the disk
         if Dir = Up then
            Next_Dir := Down;
         else
            Next_Dir := Up;
         end if;
      end if;

      declare
         Scan_2 : constant Cylinder_Array := SCAN (Waiting_Queue, Next_Head, Next_Dir, Max_Cylinder);
      begin
         return Scan_1 & Scan_2;
      end;
   end F_SCAN;

end Disk_Scheduling;

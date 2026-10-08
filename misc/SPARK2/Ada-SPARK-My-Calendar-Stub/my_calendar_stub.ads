pragma SPARK_Mode (On);

package My_Calendar_Stub is
   Calendar_Size : constant := 4;
   subtype Event_Index is Positive range 1 .. Calendar_Size;
   subtype Used_Count is Natural range 0 .. Calendar_Size;
   subtype Time is Natural range 0 .. 100;
   type Event is record
      Start_Time : Time;
      Finish_Time : Time;
   end record;
   type Event_Array is array (Event_Index) of Event;

   function Can_Book
     (Events : Event_Array; Used : Used_Count;
      New_Event : Event) return Boolean;
end My_Calendar_Stub;

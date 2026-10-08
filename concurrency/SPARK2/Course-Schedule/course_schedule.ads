pragma SPARK_Mode (On);

package Course_Schedule is
   Course_Count : constant := 4;
   subtype Course is Positive range 1 .. Course_Count;
   Prerequisite_Count : constant := 4;
   type Prerequisite is record
      Course_Number : Course;
      Required      : Course;
   end record;
   type Prerequisite_Array is array (Positive range 1 .. Prerequisite_Count) of Prerequisite;

   function Can_Finish (Prerequisites : Prerequisite_Array) return Boolean;
end Course_Schedule;

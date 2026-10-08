pragma SPARK_Mode (On);

package Course_Schedule_II_Stub is
   Course_Count : constant := 4;
   subtype Course is Positive range 1 .. Course_Count;
   Prerequisite_Count : constant := 4;
   type Prerequisite is record
      Course_Number : Course;
      Required      : Course;
   end record;
   type Prerequisite_Array is array (Positive range 1 .. Prerequisite_Count) of Prerequisite;
   type Course_Array is array (Course) of Course;

   function Order (Prerequisites : Prerequisite_Array) return Course_Array;
end Course_Schedule_II_Stub;

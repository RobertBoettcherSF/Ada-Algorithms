pragma Ada_2022;
package Course_Schedule_II with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Course is Positive range 1 .. Capacity;
   type Prerequisite_Matrix is array (Course, Course) of Boolean;
   type Order is array (Course) of Course;
   type Order_Result is record
      Items   : Order;
      Success : Boolean;
   end record;

   function Build_Order (Prerequisites : Prerequisite_Matrix) return Order_Result
     with Global => null;
end Course_Schedule_II;

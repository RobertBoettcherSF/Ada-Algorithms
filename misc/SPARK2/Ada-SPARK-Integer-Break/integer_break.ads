pragma Ada_2022;
--  Scaffold for the failing test (replaced by the proved version).
package Integer_Break with SPARK_Mode => On is
   Max_N : constant := 58;
   subtype Number is Positive range 2 .. Max_N;
   subtype Part is Positive range 1 .. Max_N;
   type Part_List is array (Positive range <>) of Part;
   function Maximum (N : Number) return Positive;
   function Best_Split (N : Number) return Part_List;
end Integer_Break;

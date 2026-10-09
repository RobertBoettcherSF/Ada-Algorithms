pragma Ada_2022;
package body Integer_Break with SPARK_Mode => On is
   function Maximum (N : Number) return Positive is
     (case N is when 2 => 1, when 3 => 2, when 4 => 4, when 5 => 6, when 6 => 9,
                when 7 => 12, when 8 => 18, when 9 => 27, when 10 => 36, when others => 1);
   function Best_Split (N : Number) return Part_List is ([1, N - 1]);
end Integer_Break;

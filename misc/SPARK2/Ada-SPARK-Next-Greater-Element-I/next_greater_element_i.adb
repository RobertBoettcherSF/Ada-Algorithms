pragma Ada_2022;

package body Next_Greater_Element_I with SPARK_Mode => On is
   subtype Input_Value is Integer range 0 .. 32;
   subtype Result_Value is Integer range -1 .. 32;

   function First_Greater (A, B, C, D, Value : Input_Value) return Result_Value is
   begin
      if A > Value then return A; elsif B > Value then return B;
      elsif C > Value then return C; elsif D > Value then return D;
      else return -1; end if;
   end First_Greater;

   function Next_Greater (Values : Value_Array) return Result_Array is
   begin
      return (1 => First_Greater (Values (2), Values (3), Values (4), 0, Values (1)),
              2 => First_Greater (Values (3), Values (4), 0, 0, Values (2)),
              3 => First_Greater (Values (4), 0, 0, 0, Values (3)),
              4 => -1);
   end Next_Greater;
end Next_Greater_Element_I;

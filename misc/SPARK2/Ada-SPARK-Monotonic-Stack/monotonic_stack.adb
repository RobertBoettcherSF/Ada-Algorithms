pragma Ada_2022;

package body Monotonic_Stack with SPARK_Mode => On is
   function Greater_1 (Input : Input_Array) return Result_Value is
   begin
      if Input (2) > Input (1) then return Input (2); end if;
      if Input (3) > Input (1) then return Input (3); end if;
      if Input (4) > Input (1) then return Input (4); end if;
      if Input (5) > Input (1) then return Input (5); end if;
      return No_Greater;
   end Greater_1;

   function Greater_2 (Input : Input_Array) return Result_Value is
   begin
      if Input (3) > Input (2) then return Input (3); end if;
      if Input (4) > Input (2) then return Input (4); end if;
      if Input (5) > Input (2) then return Input (5); end if;
      return No_Greater;
   end Greater_2;

   function Greater_3 (Input : Input_Array) return Result_Value is
   begin
      if Input (4) > Input (3) then return Input (4); end if;
      if Input (5) > Input (3) then return Input (5); end if;
      return No_Greater;
   end Greater_3;

   function Greater_4 (Input : Input_Array) return Result_Value is
   begin
      if Input (5) > Input (4) then return Input (5); end if;
      return No_Greater;
   end Greater_4;

   function Next_Greater (Input : Input_Array) return Result_Array is
   begin
      return [Greater_1 (Input), Greater_2 (Input), Greater_3 (Input),
              Greater_4 (Input), No_Greater];
   end Next_Greater;
end Monotonic_Stack;

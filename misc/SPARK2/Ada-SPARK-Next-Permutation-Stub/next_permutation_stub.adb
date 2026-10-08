pragma Ada_2022;

package body Next_Permutation_Stub with SPARK_Mode => On is
   procedure Swap (Input : in out Input_Array; Left : Index; Right : Index)
     with Global => null is
      Temporary : constant Value := Input (Left);
   begin
      Input (Left) := Input (Right);
      Input (Right) := Temporary;
   end Swap;

   function Next (Input : Input_Array) return Input_Array is
      Result : Input_Array := Input;
   begin
      if Result (3) < Result (4) then
         Swap (Result, 3, 4);
      elsif Result (2) < Result (3) or else Result (2) < Result (4) then
         if Result (4) > Result (2) then
            Swap (Result, 2, 4);
         else
            Swap (Result, 2, 3);
         end if;
         Swap (Result, 3, 4);
      elsif Result (1) < Result (2) or else Result (1) < Result (3)
        or else Result (1) < Result (4) then
         if Result (4) > Result (1) then
            Swap (Result, 1, 4);
         elsif Result (3) > Result (1) then
            Swap (Result, 1, 3);
         else
            Swap (Result, 1, 2);
         end if;
         Swap (Result, 2, 4);
      else
         Swap (Result, 1, 4);
         Swap (Result, 2, 3);
      end if;
      return Result;
   end Next;
end Next_Permutation_Stub;

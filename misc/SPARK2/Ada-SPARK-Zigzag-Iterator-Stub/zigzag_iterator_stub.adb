pragma SPARK_Mode (On);
pragma Ada_2022;
package body Zigzag_Iterator_Stub is
   function Create (A : Value_Array; A_Size : Count; B : Value_Array; B_Size : Count) return Iterator is
     (A => A, B => B, A_Size => A_Size, B_Size => B_Size, A_Taken => 0, B_Taken => 0);

   function Has_Next (It : Iterator) return Boolean is
     (It.A_Taken < It.A_Size or else It.B_Taken < It.B_Size);

   procedure Next (It : in out Iterator; Result : out Value) is
   begin
      if It.A_Taken < It.A_Size
        and then (It.B_Taken = It.B_Size or else It.A_Taken <= It.B_Taken)
      then
         Result := It.A (It.A_Taken + 1);
         It.A_Taken := It.A_Taken + 1;
      else
         Result := It.B (It.B_Taken + 1);
         It.B_Taken := It.B_Taken + 1;
      end if;
   end Next;
end Zigzag_Iterator_Stub;

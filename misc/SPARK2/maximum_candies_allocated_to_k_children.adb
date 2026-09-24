pragma Ada_2022;

package body Maximum_Candies_Allocated_To_K_Children with SPARK_Mode => On is
   function Maximum_Candies
     (Piles : Pile_Array; K : Children) return Natural is
      Result : Natural range 0 .. 1_000 := 0;
   begin
      for Candidate in Candy_Count loop
         declare
            Made : Integer := 0;
         begin
            for I in Index loop
               pragma Loop_Invariant (Made in 0 .. 8_000);
               pragma Loop_Invariant (Made <= 1_000 * (I - Index'First));
               Made := Made + Integer (Piles (I)) / Integer (Candidate);
            end loop;
            if Made >= Integer (K) then
               Result := Candidate;
            end if;
         end;
      end loop;
      return Result;
   end Maximum_Candies;
end Maximum_Candies_Allocated_To_K_Children;

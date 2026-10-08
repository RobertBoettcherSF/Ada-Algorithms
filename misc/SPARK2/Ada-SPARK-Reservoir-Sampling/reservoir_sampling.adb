pragma Ada_2022;

package body Reservoir_Sampling with SPARK_Mode => On is
   procedure Sample (Input : Stream; Choice : Choices; Result : out Reservoir) is
   begin
      Result := [others => 0];
      for I in Stream_Index loop
         if I <= Capacity then
            Result (I) := Input (I);
         elsif Choice (I) /= 0 then
            Result (Slot (Choice (I))) := Input (I);
         end if;
      end loop;
   end Sample;
end Reservoir_Sampling;

pragma Ada_2022;
package body Most_Common_Word with SPARK_Mode => On is
   procedure Most_Common_Count (Input : Text; Length : Length_Type; Result : out Count_Type) is
      Best : Count_Type := 0;
      Count : Count_Type;
   begin
      for I in Index loop
         exit when I > Length;
         Count := 0;
         for J in Index loop
            exit when J > Length;
            if Input (I) = Input (J) then
               Count := Count + 1;
            end if;
            pragma Loop_Invariant (Count <= J);
         end loop;
         if Count > Best then
            Best := Count;
         end if;
         pragma Loop_Invariant (Best <= 32);
      end loop;
      Result := Best;
   end Most_Common_Count;
end Most_Common_Word;

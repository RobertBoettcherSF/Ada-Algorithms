pragma Ada_2022;

package body Online_Stock_Span with SPARK_Mode => On is
   function All_Spans (P : Prices; Length : Length_Type) return Spans is
      Result : Spans := [others => 0];
      Count : Span;
   begin
      for I in 1 .. Length loop
         Count := 1;
         for J in reverse 1 .. I - 1 loop
            exit when P (J) > P (I);
            if Count < Span'Last then
               Count := Count + 1;
            end if;
         end loop;
         Result (I) := Count;
      end loop;
      return Result;
   end All_Spans;
end Online_Stock_Span;

pragma Ada_2022;

package body Remove_Duplicate_Letters with SPARK_Mode => On is
   function Seen (A : Letters; Last : Length_Type; Value : Letter) return Boolean is
   begin
      for I in 1 .. Last loop
         if A (I) = Value then
            return True;
         end if;
      end loop;
      return False;
   end Seen;

   procedure Keep_First (Input : Letters; Length : Length_Type; Output : out Letters;
                         Output_Length : out Length_Type) is
      Write : Length_Type := 0;
   begin
      Output := [others => 0];
      for I in 1 .. Length loop
         if not Seen (Output, Write, Input (I)) then
            if Write < Length_Type'Last then
               Write := Write + 1;
               Output (Write) := Input (I);
            end if;
         end if;
      end loop;
      Output_Length := Write;
   end Keep_First;
end Remove_Duplicate_Letters;

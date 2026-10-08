pragma Ada_2022;

package body Unique_Emails with SPARK_Mode => On is
procedure Normalize
     (Input         : Text;
      Length        : Length_Type;
      Output        : out Text;
      Output_Length : out Length_Type) is
      Write       : Length_Type := 0;
      At_Domain   : Boolean := False;
      Skip_Local  : Boolean := False;
   begin
      Output := [others => ' '];
      for I in Index loop
         exit when I > Length;
         if At_Domain then
            if Write < 32 then
               Write := Write + 1;
               Output (Index (Write)) := Input (I);
            end if;
         elsif Input (I) = '@' then
            if Write < 32 then
               Write := Write + 1;
               Output (Index (Write)) := '@';
            end if;
            At_Domain := True;
         elsif Input (I) = '+' then
            Skip_Local := True;
         elsif Input (I) = '.' or else Skip_Local then
            null;
         elsif Write < 32 then
            Write := Write + 1;
            Output (Index (Write)) := Input (I);
         end if;
      end loop;
      Output_Length := Write;
   end Normalize;
end Unique_Emails;

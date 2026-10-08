pragma Ada_2022;
package body Ransom_Note with SPARK_Mode => On is
   function Can_Construct (Note : Text; Magazine : Text) return Boolean is
      Used : array (Index) of Boolean := [others => False];
      Found : Boolean;
   begin
      for I in Index loop
         Found := False;
         for J in Index loop
            if not Used (J) and then not Found and then Note (I) = Magazine (J) then
               Used (J) := True;
               Found := True;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Can_Construct;
end Ransom_Note;

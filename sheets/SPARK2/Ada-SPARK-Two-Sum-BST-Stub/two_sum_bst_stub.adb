pragma Ada_2022;

package body Two_Sum_BST_Stub with SPARK_Mode => On is
   function Has_Two_Sum (Input : Input_Array; Target : Integer) return Boolean is
      Found : Boolean := False;
   begin
      for I in Index loop
         for J in Index loop
            if I < J and then Integer (Input (I)) + Integer (Input (J)) = Target then
               Found := True;
            end if;
         end loop;
      end loop;
      return Found;
   end Has_Two_Sum;
end Two_Sum_BST_Stub;

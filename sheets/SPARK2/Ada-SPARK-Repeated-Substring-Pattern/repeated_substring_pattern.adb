pragma Ada_2022;

package body Repeated_Substring_Pattern with SPARK_Mode => On is
   function Is_Repeated (Input : Text_Array) return Boolean is
   begin
      return
        (Input (1) = Input (2) and then Input (1) = Input (3)
         and then Input (1) = Input (4) and then Input (1) = Input (5)
         and then Input (1) = Input (6))
        or else
        (Input (1) = Input (3) and then Input (1) = Input (5)
         and then Input (2) = Input (4) and then Input (2) = Input (6))
        or else
        (Input (1) = Input (4) and then Input (2) = Input (5)
         and then Input (3) = Input (6));
   end Is_Repeated;
end Repeated_Substring_Pattern;

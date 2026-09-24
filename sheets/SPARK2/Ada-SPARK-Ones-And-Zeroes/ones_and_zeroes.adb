pragma Ada_2022;
package body Ones_And_Zeroes with SPARK_Mode => On is
   function Fits (Z, O, LZ, LO : Natural) return Boolean is
   begin
      return Z <= LZ and O <= LO;
   end Fits;
   function Max_Form (Zeros, Ones : Counts; Limit_Zeros, Limit_Ones : Count) return Natural is
   begin
      if Fits (Zeros (1) + Zeros (2) + Zeros (3) + Zeros (4), Ones (1) + Ones (2) + Ones (3) + Ones (4), Limit_Zeros, Limit_Ones) then
         return 4;
      elsif Fits (Zeros (1) + Zeros (2) + Zeros (3), Ones (1) + Ones (2) + Ones (3), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (1) + Zeros (2) + Zeros (4), Ones (1) + Ones (2) + Ones (4), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (1) + Zeros (3) + Zeros (4), Ones (1) + Ones (3) + Ones (4), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (2) + Zeros (3) + Zeros (4), Ones (2) + Ones (3) + Ones (4), Limit_Zeros, Limit_Ones) then
         return 3;
      elsif Fits (Zeros (1) + Zeros (2), Ones (1) + Ones (2), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (1) + Zeros (3), Ones (1) + Ones (3), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (1) + Zeros (4), Ones (1) + Ones (4), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (2) + Zeros (3), Ones (2) + Ones (3), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (2) + Zeros (4), Ones (2) + Ones (4), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (3) + Zeros (4), Ones (3) + Ones (4), Limit_Zeros, Limit_Ones) then
         return 2;
      elsif Fits (Zeros (1), Ones (1), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (2), Ones (2), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (3), Ones (3), Limit_Zeros, Limit_Ones)
        or Fits (Zeros (4), Ones (4), Limit_Zeros, Limit_Ones) then
         return 1;
      else
         return 0;
      end if;
   end Max_Form;
end Ones_And_Zeroes;

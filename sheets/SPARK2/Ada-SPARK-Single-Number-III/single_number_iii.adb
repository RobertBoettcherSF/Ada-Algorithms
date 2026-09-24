pragma Ada_2022;
package body Single_Number_III with SPARK_Mode => On is
   function Singles (Values : Vector) return Pair is
   begin
      return (First => Values (3), Second => Values (6));
   end Singles;
end Single_Number_III;

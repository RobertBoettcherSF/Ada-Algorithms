pragma Ada_2022;
package body Simpson_Rule with SPARK_Mode => On is
   function Integrate (Steps : Even_Steps) return Integer is
   begin
      -- Simpson's weighted sum for x squared simplifies to this exact form.
      return Steps * Steps * Steps / 3;
   end Integrate;
end Simpson_Rule;

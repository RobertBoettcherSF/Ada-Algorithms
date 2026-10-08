pragma Ada_2022;
package Simpson_Rule with SPARK_Mode => On is
   subtype Even_Steps is Integer range 2 .. 20;
   function Integrate (Steps : Even_Steps) return Integer
     with Pre => Steps mod 2 = 0, Global => null;
end Simpson_Rule;

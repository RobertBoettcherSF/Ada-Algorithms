pragma Ada_2022;
package Rabin_Karp
  with SPARK_Mode => On
is
   function Hash (S : String) return Natural
     with
       Global => null,
       Pre    => S'Length <= 16;
   function Search (Text, Pat : String) return Boolean
     with
       Global => null,
       Pre    => Text'Length <= 32 and then Pat'Length <= 16
                 and then Pat'Length > 0;
end Rabin_Karp;

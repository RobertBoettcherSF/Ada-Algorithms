pragma Ada_2022;

--  Concrete instantiations so GNATprove analyzes the generic body (RM 12 /
--  SPARK: generics are proved at instantiation).
with Bounded_String_Builder;
package Spark_Instances
  with SPARK_Mode => On
is
   package Cap_16 is new Bounded_String_Builder (Capacity => 16);
   package Cap_64 is new Bounded_String_Builder (Capacity => 64);
end Spark_Instances;

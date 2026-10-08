pragma Ada_2022;
package Partition_Equal_Subset_Sum with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 6;
   subtype Value is Natural range 0 .. 10;
   type Values is array (Position) of Value;
   function Can_Partition (A : Values) return Boolean with Global => null;
end Partition_Equal_Subset_Sum;

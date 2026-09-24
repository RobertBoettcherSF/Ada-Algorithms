pragma Ada_2022;

package Path_Sum_III_Lite with SPARK_Mode => On is
   Size : constant := 32;
   subtype Index is Positive range 1 .. Size;
   subtype Node_Value is Integer range 0 .. 10;
   subtype Sum is Integer range 0 .. Size * Node_Value'Last;
   type Nodes is array (Index) of Node_Value;

   function Path_Total (A : Nodes) return Sum with Global => null;
end Path_Sum_III_Lite;

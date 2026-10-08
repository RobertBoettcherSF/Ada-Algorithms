pragma Ada_2022;
package Pacific_Atlantic_Water_Flow with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Height is Integer range 0 .. 9;
   type Grid is array (Index, Index) of Height;
   type Reachability is array (Index, Index) of Boolean;

   function Reachable (G : Grid) return Reachability with Global => null;
end Pacific_Atlantic_Water_Flow;

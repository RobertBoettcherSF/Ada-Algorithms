pragma Ada_2022;
package Floyd_Warshall with SPARK_Mode => On is
   Capacity : constant := 4;
   Infinity : constant := 1000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Distance is Natural range 0 .. Infinity;
   type Distance_Matrix is array (Node, Node) of Distance;
   procedure Compute (D : in out Distance_Matrix);
end Floyd_Warshall;

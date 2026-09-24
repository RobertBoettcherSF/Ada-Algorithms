pragma Ada_2022;
package All_Paths_From_Source_To_Target with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Node is Positive range 1 .. Capacity;
   type Graph is array (Node, Node) of Boolean;

   function Has_Path (G : Graph) return Boolean with Global => null;
end All_Paths_From_Source_To_Target;

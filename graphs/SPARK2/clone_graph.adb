pragma Ada_2022;
package body Clone_Graph with SPARK_Mode => On is
   function Clone (G : Graph) return Graph is
   begin
      return G;
   end Clone;
end Clone_Graph;

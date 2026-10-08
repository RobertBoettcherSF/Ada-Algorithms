pragma Ada_2022;
package K_Means_Step with SPARK_Mode => On is
   Max_N : constant := 8;
   subtype Point is Integer range 0 .. 100;
   subtype Count is Integer range 0 .. Max_N;
   subtype Cluster is Integer range 1 .. 2;
   function Nearest (P, C1, C2 : Point) return Cluster with Global => null;
   procedure Step
     (P : in Point; C1, C2 : in out Point; N1, N2 : in out Count)
     with Pre => N1 + N2 < Max_N, Global => null;
end K_Means_Step;

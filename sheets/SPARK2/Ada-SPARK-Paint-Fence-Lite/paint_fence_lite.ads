pragma Ada_2022;
package Paint_Fence_Lite with SPARK_Mode => On is
   subtype Number_Of_Posts is Positive range 1 .. 16;
   subtype Ways is Natural range 0 .. 4_000;
   function Count (N : Number_Of_Posts) return Ways with Global => null;
end Paint_Fence_Lite;

pragma Ada_2022;
package Number_Of_Provinces with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype City is Positive range 1 .. Capacity;
   type Connection_Matrix is array (City, City) of Boolean;
   type Province_Count is mod Capacity + 1;

   function Count_Provinces (Connections : Connection_Matrix) return Province_Count
     with Global => null;
end Number_Of_Provinces;

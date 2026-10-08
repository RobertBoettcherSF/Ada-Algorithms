pragma Ada_2022;
package Prime_Number_Of_Set_Bits with SPARK_Mode => On is
   subtype Bit_Count is Natural range 0 .. 8;
   function Is_Prime_Count (Count : Bit_Count) return Boolean
     with Global => null,
          Post => Is_Prime_Count'Result =
            (Count = 2 or else Count = 3 or else Count = 5 or else Count = 7);
end Prime_Number_Of_Set_Bits;

pragma Ada_2022;

package Beautiful_Arrangement with SPARK_Mode => On is
   subtype Size is Positive range 1 .. 8;
   subtype Value is Natural range 0 .. 8;
   type Arrangement is array (Size) of Value;
   function Is_Beautiful (A : Arrangement; N : Size) return Boolean with Global => null;
end Beautiful_Arrangement;
